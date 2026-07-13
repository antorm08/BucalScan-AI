## Context

FastAPI ya dispone de autorización para `platform_admin`, aprobación básica de workspaces y gestión de membresías por administradores de clínica. Flutter solo expone una lista de usuarios. El panel debe reunir esas operaciones sin introducir tablas nuevas ni confundir aprobación de acceso con acreditación profesional.

## Goals / Non-Goals

**Goals:**
- Proveer una cola administrativa única para centros y membresías pendientes.
- Ejecutar transiciones explícitas y auditables de aprobación o rechazo.
- Mantener las capas limpias existentes en Flutter.
- Dar estados vacíos, errores, recarga y confirmación claros en móvil.

**Non-Goals:**
- Verificar títulos, licencias o documentos profesionales.
- Crear un sistema web separado o notificaciones externas.
- Cambiar el modelo ResNet50 o el flujo clínico.

## Decisions

- Los endpoints globales vivirán bajo `/api/v1/admin`, protegidos con `require_admin`; esto evita otorgar capacidades globales a `clinic_admin`.
- Se expondrán DTO administrativos agregados con datos del solicitante y workspace para evitar múltiples llamadas desde móvil.
- Aprobar un centro nuevo activará también la membresía inicial como `clinic_admin`; rechazarlo rechazará esa membresía en la misma transacción.
- La práctica independiente se presentará como una aprobación profesional. Su aprobación activa el workspace y la membresía inicial, conservando el modelo de aislamiento existente.
- Las membresías de centros ya activos se gestionarán por separado y podrán recibir los roles permitidos.
- Flutter extenderá el feature `admin` con entidades, repositorio, casos de uso y un controlador dedicado a aprobaciones; la vista será un panel con pestañas de pendientes y usuarios.

## Risks / Trade-offs

- [Rechazos sin motivo estructurado] → Se conserva un estado simple en esta versión y se deja auditoría avanzada fuera de alcance.
- [Dos administradores actúan simultáneamente] → Los endpoints validan el estado actual y responden conflicto si ya fue resuelto.
- [Solicitudes antiguas inconsistentes] → Las respuestas se construyen con relaciones opcionales y la acción actualiza workspace y membresía de forma atómica.
- [Panel móvil con listas grandes] → Los endpoints aceptan filtro de estado y límites; la primera versión prioriza pendientes.

## Migration Plan

1. Desplegar endpoints backend compatibles con los clientes actuales.
2. Publicar el APK con el panel extendido.
3. Verificar una aprobación de cada modalidad en Neon.
4. En rollback, retirar el cliente nuevo; los estados persistidos continúan siendo válidos.

## Open Questions

- La evidencia documental y los motivos obligatorios de rechazo se abordarán en cambios posteriores.
