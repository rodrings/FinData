# ADR-001: Arquitectura en capas con Protocols + Dependency Injection

**Fecha:** 2026-08-05

**Contexto:** el proyecto necesita separar lógica de negocio (qué es
un Candle, cómo se calcula un backfill) de detalles de infraestructura
(Postgres, HTTP a Binance) para poder testear sin mocks pesados y
evitar que un cambio de proveedor de datos obligue a reescribir
casos de uso.

**Decisión:** domain/ define Protocols (MarketDataProvider,
CandleRepository) sin ninguna dependencia de infraestructura.
infrastructure/ implementa esos Protocols. application/ orquesta
casos de uso recibiendo las implementaciones inyectadas por
constructor (nunca las crea). Los composition roots (api/main.py,
cli/main.py) son el único lugar donde se instancian las
implementaciones concretas.

**Alternativas consideradas:**
- ORM con imports directos de SQLAlchemy en el dominio: descartado,
  acopla domain/ a infraestructura y complica tests unitarios reales.
- Sin Protocols, con herencia explícita de interfaces: descartado,
  Python permite structural typing (duck typing verificado por mypy)
  sin necesidad de herencia formal.

**Consecuencias:**
- domain/ y application/ se pueden testear con fakes/mocks simples,
  sin base de datos real.
- La regla se verifica automáticamente en CI con import-linter
  (ver ADR relacionado sobre import-linter), no depende de disciplina
  manual del equipo.
- Costo: más archivos e indirección que un CRUD directo; se acepta
  como trade-off deliberado para un proyecto de portafolio middle.
