# Validacion Del Modelo

## Resumen

El sistema utiliza un modelo MobileNetV2 exportado a ONNX para clasificacion binaria de lesiones orales.

## Alcance De Clasificacion

| Clase | Interpretacion |
|-------|----------------|
| Benigna | Lesion compatible con patron benigno segun el modelo |
| Maligna | Lesion sospechosa o compatible con patron maligno segun el modelo |

El resultado es una herramienta de apoyo clinico y no reemplaza el diagnostico profesional.

## Entrada Y Salida

| Elemento | Detalle |
|----------|---------|
| Arquitectura | MobileNetV2 |
| Formato | ONNX |
| Entrada | Imagen RGB redimensionada a 224x224 pixeles |
| Salida | Clase predicha, confianza, probabilidades y recomendacion |
| Clases internas | `benign`, `malignant` |
| Clases mostradas en app | Benigna, Maligna |

## Metricas De Validacion

| Modelo | Accuracy | Precision | Recall | F1-Score | AUC-ROC |
|--------|---------:|----------:|-------:|---------:|--------:|
| MobileNetV2 | 0.8776 | 0.8462 | 0.9167 | 0.8800 | 0.8983 |

## Cumplimiento RNF-005

El informe exige un F1-score mayor o igual a 0.80 en el conjunto de prueba.

```text
F1-score obtenido = 0.8800
F1-score requerido >= 0.80
Resultado: cumple
```

## Interpretacion

El F1-score de 0.8800 indica buen equilibrio entre precision y recall. El recall de 0.9167 es especialmente relevante para deteccion temprana porque refleja una alta capacidad para identificar casos positivos o sospechosos dentro del conjunto evaluado.
