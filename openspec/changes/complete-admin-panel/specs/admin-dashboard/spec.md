## ADDED Requirements

### Requirement: Raíz administrativa consolidada
La aplicación SHALL proporcionar una raíz móvil pulida para `platform_admin` con conteos pendientes y pestañas de centros, membresías y usuarios, sin exigir workspace clínico.

#### Scenario: Administrador entra después de login
- **WHEN** la identidad recién validada es `platform_admin`
- **THEN** la navegación transiciona al panel y no al resumen clínico

#### Scenario: Indicadores se cargan
- **WHEN** el administrador abre o refresca el panel
- **THEN** ve conteos coherentes y puede navegar a cada categoría

#### Scenario: Cierre de sesión desde raíz
- **WHEN** el administrador cierra sesión sin workspace activo
- **THEN** se limpian credenciales y providers sensibles y se muestra login

### Requirement: Flutter Clean Architecture administrativa
Las operaciones administrativas SHALL seguir vista -> controlador -> caso de uso -> contrato de repositorio -> implementación -> datasource -> `ApiService`, y las vistas MUST NOT invocar API directamente.

#### Scenario: Vista solicita una acción
- **WHEN** el administrador carga, refresca o confirma una transición
- **THEN** la vista delega al controlador y renderiza su estado tipado

### Requirement: Estados completos de presentación
Cada pestaña SHALL representar carga, datos, vacío, error, reintento y acción en curso, y SHALL refrescar conteos/listas coherentemente después de una transición exitosa.

#### Scenario: No hay pendientes
- **WHEN** una categoría no contiene solicitudes pendientes
- **THEN** la aplicación comunica que la cola está al día sin confundir vacío con error

#### Scenario: Carga falla
- **WHEN** una consulta administrativa actual falla
- **THEN** se muestra un error sanitizado con reintento y se preserva navegación segura

#### Scenario: Acción está en curso
- **WHEN** una aprobación, rechazo, suspensión o reactivación está enviándose
- **THEN** la acción afectada queda bloqueada contra duplicados y las demás filas no muestran éxito prematuro

### Requirement: Etiquetas y acciones por ciclo de vida
El panel SHALL mostrar etiquetas y acciones coherentes para usuario `pending|active|suspended`, workspace `pending|active|rejected` y membresía `pending|active|inactive|rejected`, y MUST NOT ofrecer suspender/reactivar a un usuario pendiente ni reactivar rechazos terminales.

#### Scenario: Usuario pendiente se muestra
- **WHEN** el usuario aún espera aprobación de acceso
- **THEN** aparece pendiente de verificación de acceso con aprobar/rechazar donde corresponda, sin suspensión/reactivación

#### Scenario: Usuario activo o suspendido se muestra
- **WHEN** el usuario está activo o suspendido
- **THEN** se ofrece respectivamente suspensión o reactivación solo si la política lo permite

### Requirement: Confirmación de acciones sensibles
La aplicación SHALL solicitar confirmación antes de aprobar, rechazar, suspender o reactivar y SHALL reflejar claramente el objetivo y resultado esperado.

#### Scenario: Confirmación se cancela
- **WHEN** el administrador cancela el diálogo
- **THEN** no se envía la operación ni se modifica estado

### Requirement: Gestión segura de usuarios
El sistema SHALL permitir `active <-> suspended`, MUST impedir autosuspensión, SHALL bloquear aprobación de suspendidos y SHALL respetar la protección del último `clinic_admin`.

#### Scenario: Administrador visualiza su propia cuenta
- **WHEN** la fila corresponde al administrador actual
- **THEN** la suspensión permanece deshabilitada y explica la restricción

#### Scenario: Pendiente o último administrador es objetivo
- **WHEN** una acción no es legal por estado pendiente o protección del último `clinic_admin`
- **THEN** la UI no la ofrece y el backend también la rechaza si se invoca directamente

### Requirement: Errores seguros y aislamiento de sesión
El panel SHALL normalizar `detail` de FastAPI como string, mapa o lista, SHALL omitir salida Dio, stack traces, rutas internas y detalles de providers, y SHALL descartar datos/respuestas de sesiones anteriores.

#### Scenario: Backend devuelve detalle estructurado
- **WHEN** una operación falla con detalle string, mapa o lista
- **THEN** la aplicación presenta un mensaje seguro y accionable

#### Scenario: Respuesta llega después de logout
- **WHEN** una carga administrativa termina después de limpiar autenticación
- **THEN** no repuebla conteos, listas, errores ni rutas privilegiadas

### Requirement: Separación de navegación clínica y administrativa
La aplicación SHALL mantener la raíz administrativa independiente de las fichas longitudinales profesionales y SHALL resolver repetición de análisis y cambio de workspace mediante callbacks/estado de la raíz profesional validada, sin construir un `HomeView` desnudo desde una vista de detalle.

#### Scenario: Profesional cambia de workspace o repite análisis
- **WHEN** la acción nace en una ficha clínica autorizada
- **THEN** la raíz profesional limpia o selecciona contexto según corresponda sin abrir, invalidar ni reutilizar estado del panel administrativo
