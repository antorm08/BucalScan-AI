# Contrato Técnico: POST /api/v1/predict

## Descripción

Recibe una imagen de una lesión oral y devuelve la clasificación del modelo ONNX configurado, por ejemplo ResNet50.
El endpoint requiere autenticación JWT y persiste el análisis para historial y dashboard.

---

## Request

```
POST /api/v1/predict
Authorization: Bearer <jwt>
Content-Type: multipart/form-data
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `file` | imagen (JPEG, PNG, WEBP) | Sí | Imagen de la lesión oral |
| `consent_to_store` | boolean | Sí | Consentimiento explícito para guardar imagen y resultado |
| `patient_id` | string | No | Identificador opcional del paciente |
| `patient_name` | string | No | Nombre opcional del paciente |

**Tipos MIME aceptados:** `image/jpeg`, `image/png`, `image/webp`

**Tamaño máximo permitido:** 10 MB

---

## Response 200 — OK

```json
{
  "prediction": "benign",
  "confidence": 0.9312,
  "recommendation": "No immediate concern. Regular check-ups recommended.",
  "heatmap_url": "https://cdn.example.com/analysis_cam.png",
  "processing_time_ms": 124.5,
  "probabilities": {
    "benign": 0.9312,
    "malignant": 0.0688
  }
}
```

| Campo | Tipo | Rango | Descripción |
|-------|------|-------|-------------|
| `prediction` | `"benign"` \| `"malignant"` | — | Clase predicha por el modelo |
| `confidence` | `float` | [0.0, 1.0] | Probabilidad de la clase predicha |
| `recommendation` | `string` | — | Texto de recomendación clínica |
| `heatmap_url` | `string` | — | Mapa de activación CAM; es una explicación orientativa, no localización diagnóstica |
| `processing_time_ms` | `float` | — | Tiempo de inferencia medido por el backend |
| `probabilities` | `object` | — | Probabilidades por clase |
| `probabilities.benign` | `float` | [0.0, 1.0] | Probabilidad de lesión benigna |
| `probabilities.malignant` | `float` | [0.0, 1.0] | Probabilidad de lesión maligna |

> `probabilities.benign + probabilities.malignant = 1.0`

---

## Response 400 — Tipo de archivo no válido

```json
{
  "detail": "Invalid file type 'application/pdf'. Accepted: image/jpeg, image/png, image/webp."
}
```

## Response 400 — Imagen inválida o corrupta

```json
{
  "detail": "Cannot decode image file."
}
```

## Response 400 — Consentimiento faltante

```json
{
  "detail": "Consent is required to store the clinical image and analysis result."
}
```

---

## Response 401 — JWT faltante o inválido

```json
{
  "detail": "Not authenticated"
}
```

---

## Response 413 — Archivo demasiado grande

```json
{
  "detail": "File too large. Maximum allowed size is 10 MB."
}
```

---

## Response 500 — Error interno del modelo

```json
{
  "detail": "Model inference failed. Please try again later."
}
```

---

## Preprocesamiento del modelo

La imagen recibida pasa por el siguiente pipeline antes de la inferencia:

| Paso | Operación | Detalle |
|------|-----------|---------|
| 1 | Conversión a RGB | Descarta canal alpha si existe |
| 2 | Resize | 224 × 224 píxeles (PIL BILINEAR) |
| 3 | Normalización a [0, 1] | División por 255.0 |
| 4 | Sustracción de media ImageNet | `[0.485, 0.456, 0.406]` por canal RGB |
| 5 | División por std ImageNet | `[0.229, 0.224, 0.225]` por canal RGB |
| 6 | Transposición HWC → CHW | De `(224, 224, 3)` a `(3, 224, 224)` |
| 7 | Añadir dimensión batch | De `(3, 224, 224)` a `(1, 3, 224, 224)` |

**Tensor final:** `float32`, shape `[1, 3, 224, 224]`

---

## Modelo ONNX

| Propiedad | Valor |
|-----------|-------|
| Archivo | Configurable con `MODEL_PATH`, por ejemplo `backend/models/resnet50_oral.onnx` |
| Arquitectura | Configurable con `MODEL_ARCHITECTURE`, por ejemplo `ResNet50` |
| Input shape | `[1, 3, 224, 224]` |
| Output shape | `[1, 1]` (sigmoid binario) ó `[1, 2]` (softmax 2 clases) |
| Clases | `["benign", "malignant"]` |
| Runtime | ONNX Runtime, CPUExecutionProvider |

Las clases mostradas al usuario en la app son **Benigna** y **Maligna**. No se consideran clases adicionales para esta version del proyecto.

Las metricas de validacion del modelo se documentan en `docs/model_validation.md`.

---

## Persistencia

Al completar la inferencia, el backend guarda un registro en `analyses` con:

El guardado solo se realiza si `consent_to_store=true` fue enviado en el formulario.

| Campo | Descripción |
|-------|-------------|
| `user_id` | Usuario autenticado extraído del JWT |
| `prediction` | Clase predicha |
| `confidence` | Confianza de la clase predicha |
| `image_path` | URL de Cloudinary si está configurado, o ruta local en `uploads/` |
| `patient_id` | Metadata opcional enviada por el frontend |
| `patient_name` | Metadata opcional enviada por el frontend |
| `model_version` | Version configurada con `MODEL_VERSION` |
| `processing_time_ms` | Tiempo de inferencia medido por el backend |

---

*Última actualización: 2026-06-11*
