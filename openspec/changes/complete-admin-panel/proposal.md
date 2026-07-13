## Why

Las solicitudes de centros y accesos profesionales se crean correctamente, pero no existe una interfaz administrativa completa para revisarlas. Esto deja a los nuevos profesionales bloqueados y obliga a intervenir directamente en la base de datos.

## What Changes

- Incorporar un panel móvil con resumen de solicitudes pendientes.
- Permitir revisar, aprobar y rechazar centros de atención.
- Permitir revisar, aprobar y rechazar membresías profesionales, incluyendo prácticas independientes.
- Permitir asignar el rol del profesional al aprobar una membresía.
- Mantener la activación y suspensión de cuentas, impidiendo que el administrador se suspenda a sí mismo.
- Mostrar información suficiente del solicitante, profesión, especialidad, centro, tipo y estado para decidir.
- Separar claramente las aprobaciones de acceso de la validación documental de títulos, que permanece fuera de alcance.

## Capabilities

### New Capabilities
- `admin-approvals`: Consulta y gestión administrativa de solicitudes de centros y membresías profesionales.
- `admin-dashboard`: Navegación, indicadores y gestión consolidada de usuarios desde el panel móvil.

### Modified Capabilities

## Impact

- Nuevos endpoints protegidos bajo `/api/v1/admin` y ajustes transaccionales de aprobación.
- Nuevos modelos, repositorios, casos de uso, controladores y vistas en `frontend/lib/features/admin`.
- Reutilización de las tablas `clinical_workspaces`, `workspace_memberships` y `users`; no se requieren tablas nuevas.
- Pruebas backend y Flutter para autorización, transiciones de estado y presentación.
