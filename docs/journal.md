# Journal

Log de 5 líneas por sesión: qué hice, qué me trabó, qué sigue.

## Sesión 1 — [completar fecha]
- Qué hice:
- Qué me trabó:
- Qué sigue:

## Sesión 1 — 2026-08-05
- Qué hice: estructura de carpetas por capas, uv + deps (prod/dev),
  ruff + mypy strict configurados, pre-commit, Makefile, primer commit.
- Qué me trabó: Chocolatey corrupto en Windows (no instalaba make);
  se resolvió migrando todo el entorno a WSL2/Ubuntu (ver ADR-002).
  También: pyproject.toml generado por `uv init` apuntaba a un módulo
  autogenerado (findata_engine) que pisaba la estructura propia.
- Qué sigue: docker-compose con Postgres, Settings, structlog (S2).

## Sesión 2 — 2026-08-07
- Qué hice: docker-compose.yml (Postgres 16, healthcheck, límites de
  recursos, volumen persistente), Settings centralizado con Pydantic,
  structlog configurado con JSON output.
- Qué me trabó: .gitignore no existía desde S1 (riesgo de commitear
  .env con credenciales — detectado y corregido a tiempo). Un
  .dockerignore genérico apareció solo (probablemente autogenerado
  por una extensión de VS Code) y se eliminó por no aplicar al stack.
- Qué sigue: import-linter, Alembic, CI, README (S3).

## Sesión 3 — 2026-08-10
- Qué hice: import-linter con 3 contratos de arquitectura en capas
  (verificado rompiendo la regla a propósito), Alembic inicializado
  en modo async y conectado a Settings, GitHub Actions CI
  (ruff + mypy + import-linter en cada push/PR), README v0.
- Qué me trabó: SSH a GitHub bloqueado por la red de la facultad
  (puerto 22 y 443 ambos bloqueados) — se resolvió con HTTPS +
  Personal Access Token para esa red.
- Qué sigue: Fase 1 - modelado de datos (instrument, candle,
  ingestion_run), particionado declarativo, 50M filas.
