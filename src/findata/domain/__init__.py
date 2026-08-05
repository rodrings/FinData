"""
Capa de DOMINIO.

Regla no negociable: CERO imports de infrastructure/, api/, cli/,
ni de librerías externas de I/O (sqlalchemy, httpx, fastapi, etc).

Solo puede depender de la librería estándar y de tipos propios.
Esta capa define QUÉ es el negocio, no CÓMO se implementa.
Verificado automáticamente en CI con import-linter (Fase 5).
"""
