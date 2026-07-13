## 1. Contratos administrativos

- [x] 1.1 Definir DTO de resumen, centro y membresía administrativa
- [x] 1.2 Implementar listado filtrable de solicitudes pendientes
- [x] 1.3 Implementar aprobación y rechazo transaccional de centros
- [x] 1.4 Implementar aprobación y rechazo de membresías con asignación de rol
- [x] 1.5 Impedir la autosuspensión administrativa en backend

## 2. Arquitectura Flutter

- [x] 2.1 Crear entidades y modelos de solicitudes administrativas
- [x] 2.2 Extender ApiService, datasource y repositorio administrativo
- [x] 2.3 Crear casos de uso y controlador de aprobaciones

## 3. Experiencia administrativa

- [x] 3.1 Convertir gestión de usuarios en panel con navegación y conteos
- [x] 3.2 Crear listas y tarjetas de centros y profesionales pendientes
- [x] 3.3 Añadir selección de rol, confirmaciones, estados vacíos y errores
- [x] 3.4 Refrescar conteos y listas después de cada decisión

## 4. Verificación

- [x] 4.1 Probar autorización y transiciones administrativas del backend
- [x] 4.2 Probar controlador y presentación administrativa Flutter
- [x] 4.3 Ejecutar pytest, flutter analyze y flutter test

## 5. Endurecimiento reciente y verificación de entrega

- [x] 5.1 Endurecer los ciclos de vida y contratos administrativos: pendiente de verificación significa aprobación de acceso, `pending -> active` solo ocurre por aprobación, rechazos son terminales, un suspendido no puede aprobarse y se protege al último `clinic_admin`; cubierto por la suite backend confirmada (`83 passed`).
- [x] 5.2 Endurecer la política de roles: independiente usa `professional`, centros activos aceptan solo roles permitidos y ninguna decisión altera otros workspaces; cubierto por la suite backend confirmada (`83 passed`) y Flutter (`167 passed`).
- [x] 5.3 Endurecer la raíz móvil con guard `platform_admin`, conteos y pestañas, etiquetas/acciones por estado, ausencia de suspender/reactivar para pendientes, autosuspensión denegada, confirmaciones, carga/vacío/error/reintento/acción y logout sin workspace; cubierto por la suite Flutter confirmada (`167 passed`) y `flutter analyze` limpio.
- [x] 5.4 Verificar por pruebas automatizadas el flujo vista -> controlador -> caso de uso -> contrato de repositorio -> implementación -> datasource -> `ApiService`, el descarte de respuestas administrativas obsoletas y errores seguros para `detail` string/map/list sin salida Dio ni detalles internos; cubierto por las suites confirmadas backend (`83 passed`) y Flutter (`167 passed`).
- [ ] 5.5 Verificar en dispositivo real el flujo institucional completo: solicitud pendiente, conteo/pestaña, aprobación o rechazo, rol inicial `clinic_admin`, login aprobado y raíz/gate correcto.
- [ ] 5.6 Verificar en dispositivo real el flujo independiente completo: solicitud privada pendiente, aprobación con rol `professional`, login aprobado y workspace activo correcto.
- [ ] 5.7 Desplegar explícitamente la última versión backend a Render y comprobar que el panel opera contra la configuración vigente de Neon sin usar evidencia automatizada como sustituto.
- [ ] 5.8 Generar el APK de entrega, registrar versión/build, nombre, SHA-256, fecha/hora y revisión fuente cuando exista, documentar instalación limpia e instalar/verificar ese artefacto exacto en dispositivo real.
