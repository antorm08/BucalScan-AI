## ADDED Requirements

### Requirement: Administrador consulta solicitudes pendientes
El sistema SHALL permitir que un administrador de plataforma consulte centros y membresías pendientes con la identidad y datos profesionales del solicitante.

#### Scenario: Carga de pendientes
- **WHEN** un administrador abre la sección de solicitudes
- **THEN** el sistema muestra centros y accesos pendientes con tipo, profesión, especialidad y fecha

### Requirement: Administrador resuelve centros
El sistema SHALL permitir aprobar o rechazar un centro pendiente mediante una transición transaccional.

#### Scenario: Aprobación de centro nuevo
- **WHEN** el administrador aprueba un centro pendiente
- **THEN** el centro queda activo y su solicitante inicial obtiene una membresía activa como administrador de clínica

#### Scenario: Rechazo de centro nuevo
- **WHEN** el administrador rechaza un centro pendiente
- **THEN** el centro y su membresía inicial quedan rechazados

### Requirement: Administrador resuelve accesos profesionales
El sistema SHALL permitir aprobar o rechazar membresías pendientes y seleccionar un rol permitido al aprobar.

#### Scenario: Aprobación de profesional independiente
- **WHEN** el administrador aprueba la solicitud independiente
- **THEN** su workspace y membresía quedan activos y el profesional puede entrar

#### Scenario: Aprobación de membresía en centro activo
- **WHEN** el administrador aprueba una membresía pendiente con un rol permitido
- **THEN** la membresía queda activa con ese rol sin modificar otros centros

#### Scenario: Usuario no administrador intenta resolver
- **WHEN** un usuario sin rol de administrador de plataforma invoca una acción global
- **THEN** el sistema rechaza la operación con estado de autorización
