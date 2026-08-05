param(
    [string]$Target = "check"
)

function Invoke-Lint {
    Write-Host "-> ruff check ..." -ForegroundColor Cyan
    uv run ruff check .
}

function Invoke-Format {
    Write-Host "-> ruff format ..." -ForegroundColor Cyan
    uv run ruff format .
}

function Invoke-Typecheck {
    Write-Host "-> mypy --strict ..." -ForegroundColor Cyan
    uv run mypy src/
}

function Invoke-Test {
    Write-Host "-> pytest ..." -ForegroundColor Cyan
    uv run pytest tests/ -v
}

function Invoke-Sync {
    uv sync --all-groups
}

switch ($Target) {
    "lint"      { Invoke-Lint }
    "format"    { Invoke-Format }
    "typecheck" { Invoke-Typecheck }
    "test"      { Invoke-Test }
    "sync"      { Invoke-Sync }
    "check" {
        Invoke-Lint
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Invoke-Typecheck
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host "check: todo verde" -ForegroundColor Green
    }
    default { Write-Host "Target desconocido: $Target" -ForegroundColor Red }
}
