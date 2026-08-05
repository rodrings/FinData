"""
Capa de APLICACIÓN (casos de uso).

Orquesta domain/ para cumplir un objetivo de negocio
(ej: backfill, ingest_candles, compute_metrics).

No sabe de HTTP, SQL, ni de ningún detalle de infraestructura.
Recibe sus dependencias (providers, repos) inyectadas por
constructor - nunca las crea directamente. Ver domain/ports.py
para los Protocols que definen esas dependencias.
"""
