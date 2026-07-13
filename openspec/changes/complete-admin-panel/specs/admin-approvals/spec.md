## ADDED Requirements

### Requirement: Consulta protegida de solicitudes
El sistema SHALL permitir únicamente a `platform_admin` consultar centros y membresías pendientes con identidad, profesión, especialidad declarada, tipo, estado y fecha del solicitante.

#### Scenario: Administrador carga pendientes
- **WHEN** un `platform_admin` validado abre solicitudes
- **THEN** recibe datos y conteos actuales sin requerir workspace clínico

#### Scenario: Usuario no autorizado consulta
- **WHEN** un usuario sin rol actual `platform_admin` invoca una operación global
- **THEN** el sistema rechaza la operación sin invalidar una sesión válida por un `403` ordinario

### Requirement: Semántica de aprobación de acceso
El panel SHALL describir “Pendiente de verificación” como verificación/aprobación de ACCESO y SHALL NOT afirmar que profesión, especialidad, título, licencia o documentos fueron verificados.

#### Scenario: Solicitud pendiente se presenta
- **WHEN** el administrador revisa una solicitud
- **THEN** la interfaz explica que decide acceso y muestra profesión/especialidad como datos declarados

### Requirement: Resolución de centros
El sistema SHALL permitir resolver un workspace institucional `pending` una sola vez mediante transición atómica a `active` o `rejected`, siendo el rechazo terminal.

#### Scenario: Centro nuevo se aprueba
- **WHEN** un administrador confirma la aprobación de un centro pendiente cuyo solicitante es elegible
- **THEN** workspace y usuario quedan activos y la membresía inicial queda activa como `clinic_admin`

#### Scenario: Centro nuevo se rechaza
- **WHEN** un administrador confirma el rechazo de un centro pendiente
- **THEN** workspace y membresía inicial quedan rechazados terminalmente

#### Scenario: Solicitud ya resuelta recibe otra acción
- **WHEN** otra operación intenta resolver un workspace que ya no está pendiente
- **THEN** el sistema devuelve conflicto sanitizado y no altera estados

### Requirement: Resolución de accesos profesionales
El sistema SHALL aprobar o rechazar membresías pendientes solo mediante transiciones válidas, SHALL activar un independiente con rol `professional`, y SHALL limitar roles de centros activos a la política permitida.

#### Scenario: Profesional independiente se aprueba
- **WHEN** el administrador confirma una solicitud independiente elegible
- **THEN** usuario, workspace privado y membresía quedan activos y el rol de membresía es `professional`

#### Scenario: Membresía de centro activo se aprueba
- **WHEN** el administrador confirma una membresía pendiente con un rol permitido
- **THEN** usuario/membresía reciben acceso en ese centro sin modificar otros workspaces

#### Scenario: Membresía se rechaza
- **WHEN** el administrador confirma rechazo de membresía pendiente
- **THEN** la membresía queda `rejected` terminal y no puede reactivarse

#### Scenario: Rol no permitido se solicita
- **WHEN** una aprobación contiene un rol fuera de la política aplicable
- **THEN** el backend rechaza la transición sin cambios parciales

### Requirement: Solicitante suspendido no aprobable
El sistema MUST impedir la aprobación de centros o membresías cuyo solicitante esté suspendido, incluso si la lista fue cargada antes de la suspensión.

#### Scenario: Solicitante cambia a suspendido
- **WHEN** el administrador confirma aprobación y el estado actual del solicitante es `suspended`
- **THEN** la transacción se rechaza, no activa acceso y el panel refresca el estado

### Requirement: Gestión segura de membresías activas
El sistema SHALL permitir `active -> inactive -> active` para membresías elegibles, SHALL preservar historia y MUST proteger al último `clinic_admin` activo de cada centro activo.

#### Scenario: Membresía se desactiva
- **WHEN** una membresía elegible pasa a `inactive`
- **THEN** pierde acceso sin borrar registros históricos

#### Scenario: Último administrador de clínica es objetivo
- **WHEN** una acción suspendería al usuario o desactivaría la membresía del último `clinic_admin` activo
- **THEN** el sistema rechaza la operación hasta que exista otro administrador activo

### Requirement: Respuestas administrativas obsoletas
El cliente SHALL aplicar una respuesta administrativa solo si la sesión, token y generación de solicitud que la inició siguen vigentes.

#### Scenario: Sesión cambia durante carga
- **WHEN** una respuesta de lista o acción completa después de logout o login de otro usuario
- **THEN** se descarta y no muestra ni modifica estado visible de la sesión nueva

#### Scenario: Recarga nueva supera una anterior
- **WHEN** una carga anterior completa después de una recarga más reciente
- **THEN** el controlador conserva el resultado vigente y descarta el anterior
