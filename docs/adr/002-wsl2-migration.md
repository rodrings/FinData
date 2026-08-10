# ADR-002: Migración del entorno de desarrollo a WSL2 (Ubuntu)

**Fecha:** 2026-08-05

**Contexto:** ROADMAP.md requiere `make check` (S1) sobre Windows
nativo. La instalación de `make` vía Chocolatey falló por una
instalación previa corrupta de Chocolatey (detectaba instalación
existente pero el ejecutable no estaba presente en el sistema).
Se usó temporalmente un script `check.ps1` equivalente.

**Decisión:** instalar WSL2 con Ubuntu y migrar el desarrollo
completo a ese entorno, en lugar de seguir depurando el setup de
Windows. Justificado además porque Docker Desktop (Semana 0) y
`kind`/Kubernetes (Fase 6) tienen mejor soporte nativo en Linux.

**Alternativas consideradas:**
- Seguir usando check.ps1 indefinidamente: descartado, no es lo
  que especifica el roadmap y hay que sostenerlo en paralelo al
  Makefile real para cuando se use Docker/K8s.
- Reinstalar Chocolatey borrando la instalación corrupta: descartado,
  no valía la pena el tiempo de sesión para un problema no esencial
  al proyecto.

**Consecuencias:**
- `make check` corre nativo, sin scripts alternativos.
- Autenticación con GitHub migrada de HTTPS/password (deprecado)
  a SSH; luego se detectó que la red de la facultad bloquea el
  puerto 22 (y también 443 sobre ssh.github.com), por lo que se
  usa HTTPS + Personal Access Token en esa red específica.
- check.ps1 queda en el repo sin uso activo, como referencia.
