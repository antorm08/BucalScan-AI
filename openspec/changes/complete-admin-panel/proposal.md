## Why

Las solicitudes de centros de atención y accesos profesionales necesitan una raíz administrativa móvil completa y segura; sin ella, los solicitantes quedan bloqueados o requieren cambios directos en la base de datos. La aprobación corresponde exclusivamente al acceso, no a la verificación documental de títulos, licencias o especialidades declaradas.

## What Changes

- Incorporar una raíz móvil pulida y exclusiva para `platform_admin`, con conteos pendientes, pestañas para centros, membresías y usuarios, y cierre de sesión independiente del flujo clínico.
- Permitir aprobar o rechazar centros y membresías con transiciones explícitas, atómicas y protegidas contra respuestas obsoletas.
- Aplicar una política de roles definida: el independiente se aprueba como `professional`; en centros activos solo se asignan roles permitidos y se preserva la protección del último `clinic_admin`.
- Mostrar estados `pending`, `active`, `suspended`, `inactive` y `rejected` con etiquetas y acciones coherentes; no ofrecer suspensión o reactivación para usuarios pendientes ni permitir autosuspensión.
- Bloquear la aprobación de un solicitante suspendido y exigir confirmación antes de aprobar, rechazar, suspender o reactivar.
- Proporcionar estados de carga, vacío, error, reintento y acción en curso, mensajes sanitizados, refresco coherente y aislamiento de respuestas administrativas tardías.
- Mantener Flutter Clean Architecture + Riverpod: vista -> controlador -> caso de uso -> contrato de repositorio -> implementación -> datasource -> `ApiService`, sin llamadas API directas desde vistas.
- Conservar el modelo ResNet50 y el flujo clínico sin cambios; el administrador de plataforma no entra al resumen clínico sin workspace.
- Mantener como pendientes las verificaciones manuales, de despliegue y APK/dispositivo hasta contar con evidencia real.
- Permitir que el administrador complete ciudad y dirección de centros institucionales pendientes o activos, manteniendo la solicitud profesional limitada al nombre y tipo, y bloquear la aprobación mientras falte esa ubicación.
- Preservar la separación de raíces al incorporar la ficha longitudinal profesional y el cambio seguro de workspace: ninguna pantalla clínica construye el panel administrativo ni una raíz `HomeView` sin guard, y el cambio de workspace no altera estado administrativo.

## Capabilities

### New Capabilities

- `admin-approvals`: Consulta y resolución segura de solicitudes de centros y membresías, política de roles y transiciones de ciclo de vida.
- `admin-dashboard`: Raíz administrativa móvil, conteos, pestañas, gestión de usuarios, estados de interfaz, seguridad asíncrona y cierre de sesión.

### Modified Capabilities

None.

## Impact

- Backend: endpoints protegidos bajo `/api/v1/admin`, validación de estados, transacciones, protección del último administrador de clínica y errores sanitizados.
- Flutter: entidades, repositorios, casos de uso, controladores Riverpod, vistas y navegación bajo `frontend/lib/features/admin`.
- Persistencia: reutilización de `clinical_workspaces`, `workspace_memberships` y `users`; no se agregan tablas.
- Verificación: pruebas automatizadas de autorización, transiciones, respuestas obsoletas y presentación; validación manual separada para dispositivo y producción.
