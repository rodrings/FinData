"""Configuración centralizada de la aplicación, vía variables de entorno.

Única fuente de verdad para settings: nada de os.environ desperdigado
por el código (anti-patrón #4 de PROJECT_SPEC.md). Se instancia una
sola vez en el composition root (api/main.py o cli/main.py) y se
inyecta donde haga falta.
"""

from pydantic import PostgresDsn
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="forbid",  # falla rápido si hay una var no declarada acá
    )

    database_url: PostgresDsn
    log_level: str = "INFO"
    binance_api_base: str = "https://api.binance.com"
