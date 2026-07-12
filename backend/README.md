# Backend De BucalScan AI

API REST construida con FastAPI para autenticacion, historial e inferencia de lesiones orales mediante un modelo ONNX.

Backend publicado: `https://bucalscan-ai.onrender.com`.

## Requisitos

- Python 3.12 o compatible.
- Modelo ONNX en la ruta configurada con `MODEL_PATH`; para el modelo ResNet50 ganador se recomienda `models/resnet50_oral.onnx`.
- SQLite para desarrollo local o PostgreSQL mediante `DATABASE_URL`.

## Instalacion

```bash
python -m venv venv
```

```bash
# Windows
venv\Scripts\activate

# Linux/macOS
source venv/bin/activate
```

```bash
pip install -r requirements.txt
```

Crear `.env`:

```bash
copy .env.example .env
```

En Linux/macOS:

```bash
cp .env.example .env
```

## Variables De Entorno

Usa `.env.example` como referencia para crear tu `.env` local.

No publiques credenciales, secretos JWT ni claves de servicios externos en el README o en el repositorio.
El archivo `.env` esta ignorado por Git y debe mantenerse solo en el entorno local o en las variables privadas de Render.
Genera un `JWT_SECRET` largo y aleatorio para produccion; no uses valores de ejemplo.

## Ejecucion Local

```bash
uvicorn main:app --reload
```

- API local: `http://localhost:8000`
- Swagger UI local: `http://localhost:8000/docs`
- ReDoc local: `http://localhost:8000/redoc`
- API publica: `https://bucalscan-ai.onrender.com`
- Swagger UI publica: `https://bucalscan-ai.onrender.com/docs`

## Endpoints

| Metodo | Endpoint | Autenticacion | Descripcion |
|--------|----------|---------------|-------------|
| `GET` | `/` | No | Informacion de la API |
| `GET` | `/health` | No | Estado del servicio |
| `GET` | `/live` | No | Proceso activo, sin revisar dependencias |
| `GET` | `/ready` | No | Base de datos y contrato ResNet50 disponibles |
| `POST` | `/api/v1/auth/register` | No | Registro de usuario |
| `POST` | `/api/v1/auth/login` | No | Inicio de sesion |
| `GET` | `/api/v1/auth/me` | Si | Perfil del usuario autenticado |
| `POST` | `/api/v1/predict` | Si | Clasificacion de imagen oral |
| `GET` | `/api/v1/history` | Si | Historial de analisis |
| `GET` | `/api/v1/summary/today` | Si | Resumen diario |

Los endpoints clinicos requieren `X-Workspace-ID`. El contrato del endpoint de prediccion esta documentado en `docs/predict_contract.md`.
La politica simple de privacidad y retencion esta documentada en `docs/privacy_retention.md`.

## Inferencia

- Arquitectura configurable con `MODEL_ARCHITECTURE`; para el nuevo modelo ganador usar `ResNet50`.
- Runtime: ONNX Runtime.
- Entrada: imagen JPEG, PNG o WEBP.
- Preprocesamiento: RGB, resize a `224x224`, normalizacion ImageNet y tensor `float32` con forma `[1, 3, 224, 224]`.
- Salida: clase `benign` o `malignant`, confianza, probabilidades y recomendacion.

## Pruebas

Instala primero las dependencias del backend:

```bash
pip install -r requirements.txt
```

Verifica que el modelo ONNX cargue correctamente:

```bash
python scripts/verify_model.py
```

```bash
python -m pytest
```

Las migraciones se ejecutan explicitamente, nunca durante el arranque:

```bash
alembic upgrade head
```

El flujo seguro de Neon, verificacion, rollback y limitaciones se documenta en `docs/migration_and_deployment.md`.

Pruebas especificas:

```bash
python -m pytest tests/test_auth.py -v
python -m pytest tests/test_inference.py -v
```

Antes de una demo en Render, consulta `/ready` para despertar el servicio y confirmar disponibilidad:

```text
https://bucalscan-ai.onrender.com/ready
```

## Validacion Del Modelo

El modelo configurado clasifica solo entre lesion benigna y lesion maligna. Sus metricas de validacion estan documentadas en `docs/model_validation.md`.

| Modelo | Accuracy | Precision | Recall | F1-Score | AUC-ROC | ClinicalScore |
|--------|---------:|----------:|-------:|---------:|--------:|--------------:|
| MobileNetV2 anterior | 0.8776 | 0.8462 | 0.9167 | 0.8800 | 0.8983 | 0.9020 |
| ResNet50 ganador | 0.8980 | 0.8519 | 0.9583 | 0.9020 | 0.9367 | 0.9379 |

El ResNet50 ganador fue seleccionado con `ClinicalScore = 0.50 * Recall + 0.30 * F1 + 0.20 * AUC`, priorizando sensibilidad clinica. Su F1-Score, `0.9020`, supera el minimo requerido de `0.80`.

## Despliegue En Render

| Campo | Valor |
|-------|-------|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

Configura las variables de produccion directamente en el panel de Render. No las documentes con valores reales dentro del repositorio.
