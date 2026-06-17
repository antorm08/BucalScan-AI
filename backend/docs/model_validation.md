# Validacion Del Modelo

## Resumen

El sistema utiliza un modelo ONNX configurable para clasificacion binaria de lesiones orales. El nuevo modelo ganador puede registrarse como ResNet50 mediante `MODEL_ARCHITECTURE=ResNet50`.

## Alcance De Clasificacion

| Clase | Interpretacion |
|-------|----------------|
| Benigna | Lesion compatible con patron benigno segun el modelo |
| Maligna | Lesion sospechosa o compatible con patron maligno segun el modelo |

El resultado es una herramienta de apoyo clinico y no reemplaza el diagnostico profesional.

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

| Modelo | Accuracy | Precision | Recall | F1-Score | AUC-ROC |
|--------|---------:|----------:|-------:|---------:|--------:|
| MobileNetV2 anterior | 0.8776 | 0.8462 | 0.9167 | 0.8800 | 0.8983 |
| ResNet50 ganador | 0.8980 | 0.8519 | 0.9583 | 0.9020 | 0.9367 |

## Cumplimiento RNF-005

El informe exige un F1-score mayor o igual a 0.80 en el conjunto de prueba.

```text
F1-score obtenido = 0.9020
F1-score requerido >= 0.80
Resultado: cumple
```

## Interpretacion

El modelo ResNet50 ganador supera el criterio minimo de F1-score y mejora el desempeno global frente al modelo anterior. El recall de `0.9583` es especialmente relevante para apoyo al tamizaje, porque reduce el riesgo de no detectar casos malignos dentro del conjunto evaluado. La precision de `0.8519` indica que las predicciones malignas mantienen un nivel adecuado de confiabilidad, aunque todo resultado debe interpretarse como apoyo y no como diagnostico definitivo.
