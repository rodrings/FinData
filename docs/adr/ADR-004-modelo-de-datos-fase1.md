# ADR-004: Modelo de datos — instrument, candle, interval_reference, ingestion_run

**Estado:** Aceptado
**Fecha:** 2026-08-13
**Fase:** F1 — Datos & SQL (Semana 2, S4)

---

## Contexto

Fase 1 requiere diseñar el esquema relacional que soporta series temporales
OHLCV de alto volumen (objetivo: 50M+ filas en `candle`), catálogo de
instrumentos financieros, y auditoría de procesos de ingesta. El diseño
debe sostener particionado declarativo por rango de fecha (S5) y servir
como base para el pipeline de ingesta idempotente de Fase 2.

## Decisión

Se definen 4 tablas: `instrument`, `interval_reference`, `candle` e
`ingestion_run`.

### 1. `instrument` — catálogo de activos

```sql
CREATE TYPE asset_type_enum AS ENUM ('spot', 'future', 'perpetual');

CREATE TABLE instrument (
    id                  BIGSERIAL       PRIMARY KEY,
    exchange            VARCHAR(20)     NOT NULL,
    symbol              VARCHAR(20)     NOT NULL,
    asset_type          asset_type_enum NOT NULL,
    quote_currency      VARCHAR(10)     NOT NULL,
    is_active           BOOLEAN         NOT NULL DEFAULT true,
    price_precision     SMALLINT        NOT NULL CHECK (price_precision >= 0),
    quantity_precision  SMALLINT        NOT NULL CHECK (quantity_precision >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    UNIQUE (exchange, symbol)
);
```

**PK: `id BIGSERIAL`, no `(exchange, symbol)`.** El símbolo solo es único
dentro de un exchange, y el spec habilita una fuente secundaria
(`yfinance`) en Fase 2+. Un `id` artificial evita repetir dos `VARCHAR`
en cada una de las millones de filas de `candle` que referencian a un
instrumento — el costo de la PK artificial lo paga una tabla de ~20-50
filas, no la tabla de 50M.

**`asset_type` como ENUM.** Etiqueta fija, sin metadata asociada —
caso de uso simple para ENUM.

**`updated_at` con trigger.** `instrument` es mutable (cambia
`is_active`, precisión); el trigger se escribe junto a la migración de
Alembic, el `DEFAULT now()` solo cubre el `INSERT` inicial.

### 2. `interval_reference` — tabla de referencia, no ENUM

```sql
CREATE TABLE interval_reference (
    code         VARCHAR(5)  PRIMARY KEY,
    seconds      INTEGER     NOT NULL CHECK (seconds > 0),
    display_name VARCHAR(20) NOT NULL
);
```

Se eligió tabla de referencia sobre ENUM porque `interval` necesita
metadata asociada (`seconds`, usado en Fase 2 para detección de gaps) que
un ENUM no puede portar. Es la excepción justificada al principio
"ENUM salvo que se necesite metadata".

### 3. `candle` — hecho central, series de tiempo OHLCV

```sql
CREATE TABLE candle (
    instrument_id   BIGINT         NOT NULL REFERENCES instrument(id) ON DELETE RESTRICT,
    interval        VARCHAR(5)     NOT NULL REFERENCES interval_reference(code),
    open_time       TIMESTAMPTZ    NOT NULL,
    open            NUMERIC(20,8)  NOT NULL,
    high            NUMERIC(20,8)  NOT NULL,
    low             NUMERIC(20,8)  NOT NULL,
    close           NUMERIC(20,8)  NOT NULL,
    volume          NUMERIC(30,8)  NOT NULL,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    PRIMARY KEY (instrument_id, interval, open_time),
    CHECK (high >= low),
    CHECK (high >= open),
    CHECK (high >= close),
    CHECK (low <= open),
    CHECK (low <= close),
    CHECK (volume >= 0)
);
```

**PK compuesta natural `(instrument_id, interval, open_time)`, sin
`SERIAL`.** Esta tripleta ya identifica de forma única cada vela — un
`SERIAL` adicional sería redundante y le sacaría a Postgres la garantía
automática de no-duplicados que necesita la idempotencia del backfill
(F2). El orden de las columnas sigue la regla de *leftmost prefix*:
las queries reales (`"últimas 500 velas de 1m de BTCUSDT"`) filtran por
igualdad en `instrument_id` e `interval` antes de ordenar/filtrar por
rango en `open_time` — ese orden es el único que hace que el índice de
la PK sirva también como índice de acceso rápido para esas queries, sin
duplicar un índice aparte.

**`NUMERIC(20,8)` para precio, `NUMERIC(30,8)` para volumen.** Binance
expone precios con hasta 8 decimales (estándar cripto, unidad mínima
tipo satoshi). 20 dígitos totales da margen amplio en la parte entera
sin arriesgar overflow; volumen usa mayor precisión entera (30) porque
puede acumular montos grandes en velas de intervalos largos (1d).
`NUMERIC` en vez de `FLOAT`/`DOUBLE` es no negociable para datos
financieros — precisión exacta, no aproximada.

**Sin `updated_at`.** `candle` es insert-only: una vela representa un
hecho de mercado ya cerrado, no se actualiza en operación normal. Pagar
el costo de un trigger de actualización en una tabla de 50M+ filas que
nunca lo usa es overhead injustificado.

**`ON DELETE RESTRICT` en la FK a `instrument`.** Datos financieros
históricos no deben poder borrarse en cascada por accidente. `RESTRICT`
obliga a una decisión explícita (borrar o migrar las velas primero)
antes de poder eliminar un instrumento.

**CHECKs de OHLC.** Codifican como contrato de base de datos las
relaciones físicamente imposibles de una vela real (`high` es el
máximo de los 4 precios, `low` el mínimo), independientemente de que la
capa de aplicación también valide — la base de datos es la garantía que
no se puede saltear.

### 4. `ingestion_run` — auditoría de ejecuciones de ingesta

```sql
CREATE TYPE ingestion_status_enum AS ENUM ('running', 'success', 'failed');

CREATE TABLE ingestion_run (
    id                BIGSERIAL               PRIMARY KEY,
    instrument_id     BIGINT                  NOT NULL REFERENCES instrument(id) ON DELETE RESTRICT,
    interval          VARCHAR(5)              NOT NULL REFERENCES interval_reference(code),
    requested_start   TIMESTAMPTZ             NOT NULL,
    requested_end     TIMESTAMPTZ             NOT NULL,
    status            ingestion_status_enum   NOT NULL DEFAULT 'running',
    rows_ingested     INTEGER,
    started_at        TIMESTAMPTZ             NOT NULL DEFAULT now(),
    finished_at       TIMESTAMPTZ,
    error_message     VARCHAR(500),
    CHECK (requested_end >= requested_start),
    CHECK (finished_at IS NULL OR finished_at >= started_at)
);
```

**Granularidad: una fila por `(instrument_id, interval)` por ejecución**,
no una lista de instrumentos por fila. Un array de instrumentos en una
sola fila impediría saber cuántas filas trajo cada uno individualmente,
o si uno falló mientras otros no — necesario para detección de gaps y
reconciliación (F2).

**`status` como ENUM** (`running`/`success`/`failed`): etiqueta fija sin
metadata asociada, mismo criterio que `asset_type`.

**`rows_ingested` y `finished_at` nullable.** Mientras `status = 'running'`
esos valores todavía no existen — forzar `NOT NULL` obligaría a un
valor ficticio (`0`, fecha dummy) que ensuciaría el dato real.

**`error_message VARCHAR(500)`, nullable.** Vacío en el caso normal
(éxito); acotado a 500 para evitar que quede como campo libre sin límite.

## Consecuencias

- **Positivas:** idempotencia del backfill soportada nativamente por la
  PK de `candle`; trazabilidad completa de cada corrida de ingesta por
  instrumento e intervalo; integridad referencial garantizada por la
  base de datos, no por la capa de aplicación; `interval_reference`
  deja lista la metadata (`seconds`) que Fase 2 necesita para detección
  de gaps.
- **Trade-offs aceptados:** `interval_reference` agrega un JOIN extra
  frente a un ENUM simple — aceptado a cambio de poder consultar
  `seconds` sin hardcodear un mapeo en Python. `ON DELETE RESTRICT`
  significa que borrar un instrumento con historial requiere un paso
  manual explícito — aceptado como salvaguarda ante datos financieros.
- **Pendiente:** particionado declarativo de `candle` por rango de
  `open_time` (S5); seed de valores de `interval_reference`; trigger de
  `updated_at` para `instrument`; migración de Alembic.
