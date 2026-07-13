## ADDED Requirements

### Requirement: Panel administrativo consolidado
La aplicación SHALL proporcionar al administrador un panel móvil con navegación entre solicitudes y usuarios.

#### Scenario: Indicadores de solicitudes
- **WHEN** el administrador abre el panel
- **THEN** ve los conteos pendientes y puede acceder a cada categoría

#### Scenario: Estado vacío
- **WHEN** no existen solicitudes pendientes
- **THEN** la aplicación comunica que la cola está al día

### Requirement: Confirmación de acciones sensibles
La aplicación SHALL solicitar confirmación antes de aprobar, rechazar, suspender o reactivar.

#### Scenario: Cancelación de confirmación
- **WHEN** el administrador cancela el diálogo
- **THEN** no se modifica ningún estado

### Requirement: Gestión segura de usuarios
La aplicación SHALL permitir suspender y reactivar cuentas, pero MUST impedir que el administrador suspenda su propia cuenta.

#### Scenario: Administrador intenta suspenderse
- **WHEN** el administrador visualiza su propia cuenta
- **THEN** la acción de suspensión permanece deshabilitada
