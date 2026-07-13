## Context

FastAPI dispone de autorización `platform_admin`, workspaces, membresías y usuarios con estados persistidos. Flutter necesita consolidar esas operaciones en una raíz administrativa móvil sin mezclar aprobación de acceso con acreditación profesional y sin permitir que respuestas asíncronas de una sesión anterior contaminen la actual.

El panel comparte las reglas de sesión y arquitectura de la base clínica, pero no requiere un workspace clínico. El modelo ResNet50, captura y predicción quedan fuera de este cambio.

## Goals / Non-Goals

**Goals:**

- Proveer una raíz `platform_admin` pulida con conteos y pestañas para centros, membresías y usuarios.
- Aplicar transiciones explícitas, atómicas y auditables para acceso y estado de cuenta.
- Definir política de rol, solicitante suspendido, autosuspensión y último `clinic_admin`.
- Mantener Flutter Clean Architecture + Riverpod y descartar respuestas obsoletas.
- Cubrir carga, vacío, error, reintento, confirmación y acción en curso sin filtrar detalles técnicos.
- Permitir cierre de sesión desde la raíz administrativa sin depender de workspace.

**Non-Goals:**

- Verificar títulos, licencias, documentos o la veracidad de profesión/especialidad declarada.
- Introducir un panel web, notificaciones, tablas nuevas o auditoría documental.
- Cambiar ResNet50, el flujo clínico o permitir acceso clínico implícito al administrador de plataforma.
- Considerar pruebas automatizadas como evidencia de despliegue, APK o dispositivo real.

## Decisions

### 1. Raíz administrativa protegida

La navegación validada dirige `platform_admin` al panel como raíz independiente. No se infiere un workspace ni se entra al resumen clínico. Toda ruta y endpoint administrativo vuelve a comprobar el rol actual; un estado privilegiado en caché no autoriza después de una validación fallida. El botón Atrás no evita el guard y el cierre de sesión funciona desde la raíz.

### 2. Arquitectura Flutter por capas

Cada operación sigue vista -> controlador -> caso de uso -> contrato de repositorio -> implementación -> datasource -> `ApiService`. Las vistas solo expresan intención y renderizan estado; nunca llaman HTTP directamente. El controlador mantiene estados tipados de carga, datos, vacío, error, reintento y acción por elemento.

Cada solicitud captura sesión/token y generación del controlador. Su resultado se aplica solo si siguen vigentes. Cambio de autenticación, cierre de sesión o recarga reemplazante invalida resultados anteriores para que datos administrativos no aparezcan en otro usuario.

### 3. Ciclos de vida y semántica de pendiente

Se respetan los ciclos compartidos:

```text
Usuario:    pending -> active; active <-> suspended
Workspace:  pending -> active | rejected (terminal)
Membresía:  pending -> active | rejected; active -> inactive; inactive -> active; rejected terminal
```

“Pendiente de verificación” significa verificar/aprobar ACCESO, no títulos ni documentos. `pending -> active` de usuario solo ocurre al aprobar acceso. Un solicitante suspendido no puede aprobarse. No se ofrecen acciones suspender/reactivar para pendientes. Rechazos son terminales.

### 4. Resolución atómica y política de roles

Los endpoints globales viven bajo `/api/v1/admin` y exigen `platform_admin`. Aprobar un centro institucional activa workspace y membresía inicial como `clinic_admin` en una transacción. Rechazarlo rechaza ambos. Aprobar una práctica independiente activa usuario, workspace y membresía con rol fijo `professional`.

Para una membresía pendiente en centro activo, el administrador selecciona únicamente un rol permitido por la política del endpoint. La operación no modifica otros workspaces. Suspender/reactivar usuario no se ofrece para pendientes; se impide autosuspensión y cualquier desactivación que deje un centro activo sin `clinic_admin`.

### 5. Experiencia y errores seguros

El panel muestra conteos pendientes y pestañas de centros, membresías y usuarios. Etiquetas y acciones distinguen pending/active/suspended para usuario, pending/active/rejected para workspace y pending/active/inactive/rejected para membresía. Cada acción sensible exige confirmación y bloquea repetición mientras está en curso; al éxito se refrescan conteos y listas de manera coherente.

FastAPI puede devolver `detail` como string, mapa o lista. La capa de datos lo normaliza y la UI presenta texto seguro; nunca muestra salida Dio, stack traces, rutas internas, nombres de providers ni detalles de implementación.

### 6. Integración con seguimiento clínico

La nueva ficha de paciente, línea temporal de lesión, repetición de análisis y cambio confirmado de workspace pertenecen exclusivamente a la raíz profesional validada. `HomeView` conserva el callback de navegación de nivel raíz, elimina rutas clínicas obsoletas y vuelve al `WorkspaceGateView`; ninguna vista de detalle crea una raíz sin guard. El estado administrativo se mantiene separado y solo se invalida en límites de autenticación, no al cambiar un workspace clínico.

## Risks / Trade-offs

- [Dos administradores resuelven a la vez] -> Validar estado dentro de la transacción y responder conflicto sanitizado.
- [Solicitante cambia a suspendido durante aprobación] -> Releer usuario y estados relacionados antes de confirmar la transición.
- [Se elimina el último administrador de clínica] -> Rechazar suspensión/desactivación que viole el invariante.
- [Respuesta antigua reemplaza datos nuevos] -> Comparar sesión/generación y descartar completaciones obsoletas.
- [Listas grandes] -> Filtrar por estado, aplicar límites y priorizar pendientes.
- [APK verde pero no verificado] -> Mantener despliegue y dispositivo como tareas manuales abiertas.

## Migration Plan

1. Desplegar endpoints compatibles y sus guards de estado.
2. Ejecutar pruebas backend y Flutter y análisis estático.
3. Desplegar explícitamente la versión backend más reciente.
4. Generar APK versionado, registrar hash/tiempo/identidad y realizar instalación limpia.
5. Verificar en dispositivo los flujos institucional e independiente y la ruta correcta después del login aprobado.
6. En rollback, retirar el cliente nuevo; las transiciones ya confirmadas permanecen válidas.

## Open Questions

No quedan decisiones funcionales. Despliegue, APK, dispositivo y flujos manuales siguen siendo evidencia pendiente.
