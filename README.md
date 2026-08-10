# FinData Engine

> Plataforma de ingesta y métricas financieras (series temporales OHLCV).
> Proyecto de portafolio para posiciones Backend / Data Engineer Middle.

**Estado:** Fase 0 (Fundaciones) completa. Ver `ROADMAP.md` y `PROJECT_SPEC.md`
para el diseño y las fases restantes.

## Stack

Python 3.12 · PostgreSQL 16 · SQLAlchemy Core · FastAPI · Alembic ·
`uv` · `ruff` · `mypy --strict` · `import-linter` · Docker

## Cómo correrlo

Requisitos: `uv`, Docker + Docker Compose.

\`\`\`bash
git clone git@github.com:rodrings/FinData.git
cd FinData
uv sync --all-groups
cp .env.example .env

make up      # levanta Postgres (healthcheck incluido)
make check   # lint + type check + arquitectura (import boundaries)
\`\`\`

## Arquitectura

Arquitectura en capas, dependencias apuntando siempre hacia adentro:

\`\`\`
api / cli  →  application  →  domain
                  ↑
           infrastructure (implementa los Protocols de domain/ports.py)
\`\`\`

La regla "domain no depende de infrastructure" no es una promesa: se
verifica automáticamente con \`import-linter\` en cada \`make check\` y en CI.

## Decisiones de diseño

Ver \`docs/adr/\` para el historial de decisiones técnicas (ADRs).

## Desarrollo

- \`make check\` — lint + mypy strict + import boundaries
- \`make test\` — test suite (pendiente, Fase 5)
- CI corre automáticamente en cada push/PR a \`main\` (ver \`.github/workflows/ci.yml\`)
