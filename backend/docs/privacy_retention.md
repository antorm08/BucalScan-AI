# Politica Simple De Privacidad Y Retencion

## Consentimiento

La aplicacion solicita consentimiento explicito antes de enviar una imagen para analisis. El backend valida el campo `consent_to_store=true` antes de ejecutar inferencia y guardar el resultado.

## Datos Guardados

Cuando existe consentimiento, el sistema guarda:

| Dato | Finalidad |
|------|-----------|
| Imagen clinica | Consulta posterior desde historial |
| Prediccion | Seguimiento del resultado |
| Confianza | Interpretacion del nivel de certeza del modelo |
| Fecha | Trazabilidad del analisis |
| Usuario autenticado | Control de acceso al historial |
| ID/nombre de paciente opcional | Identificacion clinica si el usuario decide ingresarla |

## Acceso

Los usuarios con rol `doctor` solo consultan sus propios analisis. Los usuarios `admin` pueden consultar registros globales para gestion del sistema.

## Retencion Y Borrado

Los registros se conservan para historial clinico/académico mientras el sistema este activo. Si un usuario requiere eliminar o corregir datos, debe solicitarlo al administrador del sistema.

## Recomendacion Operativa

Evitar ingresar datos nominales del paciente cuando no sean necesarios para la demo o el seguimiento del caso.
