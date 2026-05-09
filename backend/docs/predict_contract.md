# Contrato Técnico: POST /api/v1/predict

## Descripción

Recibe una imagen de una lesión oral y devuelve la clasificación del modelo MobileNetV2.

---

## Request

```
POST /api/v1/predict
Content-Type: multipart/form-data
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `file` | imagen (JPEG, PNG, WEBP) | Sí | Imagen de la lesión oral |

**Tipos MIME aceptados:** `image/jpeg`, `image/png`, `image/webp`

**Tamaño máximo recomendado:** 10 MB

---

## Response 200 — OK

```json
{
  "prediction": "benign",
  "confidence": 0.9312,
  "recommendation": "No immediate concern. Regular check-ups recommended.",
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

---

## Response 500 — Error interno del modelo

```json
{
  "detail": "Model inference failed: <mensaje de error>"
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
| Archivo | `backend/models/mobilenetv2_oral.onnx` |
| Arquitectura | MobileNetV2 |
| Input shape | `[1, 3, 224, 224]` |
| Output shape | `[1, 1]` (sigmoid binario) ó `[1, 2]` (softmax 2 clases) |
| Clases | `["benign", "malignant"]` |
| Runtime | ONNX Runtime 1.20.1, CPUExecutionProvider |

---

## Deuda técnica documentada

| # | Brecha | Impacto | Prioridad |
|---|--------|---------|-----------|
| 1 | Sin autenticación JWT | Endpoint público, inconsistente con modelo de datos | Alta |
| 2 | Sin límite de tamaño de archivo | Vector de abuso (imágenes de varios GB) | Alta |
| 3 | Sin persistencia en DB | `crud.create_analysis()` existe pero no se llama — historial nunca se guarda | Alta |
| 4 | Error handling demasiado amplio | Errores de imagen inválida → 500 en vez de 400 | Media |

---

*Última actualización: 2026-05-09*
