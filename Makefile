.PHONY: help sync check lint format typecheck test up down clean

help:
	@echo "Targets disponibles:"
	@echo "  make sync       - instala/sincroniza dependencias (uv sync)"
	@echo "  make check      - corre lint + typecheck (gate de calidad completo)"
	@echo "  make lint       - corre ruff check"
	@echo "  make format     - corre ruff format"
	@echo "  make typecheck  - corre mypy --strict"
	@echo "  make test       - corre pytest"
	@echo "  make up         - levanta docker-compose (Postgres, etc)"
	@echo "  make down       - baja docker-compose"
	@echo "  make clean      - borra caches (.mypy_cache, .ruff_cache, etc)"

sync:
	uv sync --all-groups

lint:
	uv run ruff check .

format:
	uv run ruff format .

typecheck:
	uv run mypy src/

check: lint typecheck
	@echo "make check: todo verde"

test:
	uv run pytest tests/ -v

up:
	docker compose up -d

down:
	docker compose down

clean:
	rm -rf .mypy_cache .ruff_cache .pytest_cache .coverage htmlcov
