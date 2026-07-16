# Validacion Del Modelo

## Resumen

El sistema utiliza un modelo ONNX configurable para clasificacion binaria de lesiones orales. El nuevo modelo ganador puede registrarse como ResNet50 mediante `MODEL_ARCHITECTURE=ResNet50`.

## Alcance De Clasificacion

| Clase | Interpretacion |
|-------|----------------|
| Benigna | Lesion compatible con patron benigno segun el modelo |
| Maligna | Lesion sospechosa o compatible con patron maligno segun el modelo |

El resultado es una herramienta de apoyo clinico y no reemplaza el diagnostico profesional.

## Mapa de activacion CAM

El grafo derivado `resnet50_oral_cam.onnx` conserva exactamente los logits del modelo aprobado y expone la activacion final `2048x7x7` junto con los pesos de su cabeza lineal. El backend combina ambos valores para producir un mapa CAM especifico de la clase elegida en la misma inferencia ONNX. No se carga PyTorch en produccion y no se modifica el archivo ONNX aprobado.

El mapa resalta regiones que influyeron en la salida del clasificador. No es Grad-CAM, segmentacion, localizacion diagnostica ni evidencia de malignidad por si mismo.

## Entrada Y Salida

| Elemento | Detalle |
|----------|---------|
| Arquitectura | Configurable; actual recomendado: ResNet50 |
| Formato | ONNX |
| Entrada | Imagen RGB redimensionada a 224x224 pixeles |
| Salida | Clase predicha, confianza, probabilidades y recomendacion |
| Clases internas | `benign`, `malignant` |
| Clases mostradas en app | Benigna, Maligna |

## Metricas De Validacion

| Modelo | Accuracy | Precision | Recall | F1-Score | AUC-ROC | ClinicalScore |
|--------|---------:|----------:|-------:|---------:|--------:|--------------:|
| MobileNetV2 anterior | 0.8776 | 0.8462 | 0.9167 | 0.8800 | 0.8983 | 0.9020 |
| ResNet50 ganador | 0.8980 | 0.8519 | 0.9583 | 0.9020 | 0.9367 | 0.9379 |

El modelo ganador se selecciono con el criterio clinico ponderado:

```text
ClinicalScore = 0.50 * Recall + 0.30 * F1 + 0.20 * AUC
```

Este puntaje prioriza el recall para reducir falsos negativos en casos malignos, sin descuidar F1-score ni AUC-ROC.

## Cumplimiento RNF-005

El informe exige un F1-score mayor o igual a 0.80 en el conjunto de prueba.

```text
F1-score obtenido = 0.9020
F1-score requerido >= 0.80
Resultado: cumple
```

## Interpretacion

El modelo ResNet50 ganador supera el criterio minimo de F1-score y mejora el desempeno global frente al modelo anterior. Fue elegido por su mayor ClinicalScore, no solo por F1-score. El recall de `0.9583` es especialmente relevante para apoyo al tamizaje, porque reduce el riesgo de no detectar casos malignos dentro del conjunto evaluado. La precision de `0.8519` indica que las predicciones malignas mantienen un nivel adecuado de confiabilidad, aunque todo resultado debe interpretarse como apoyo y no como diagnostico definitivo.
