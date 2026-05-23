# Backend De BucalScan AI

API REST construida con FastAPI para autenticacion, historial e inferencia de lesiones orales mediante un modelo ONNX.

Backend publicado: `https://bucalscan-ai.onrender.com`.

## Requisitos

- Python 3.12 o compatible.
- Modelo ONNX en `models/mobilenetv2_oral.onnx` o una ruta configurada con `MODEL_PATH`.
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
| `POST` | `/api/v1/auth/register` | No | Registro de usuario |
| `POST` | `/api/v1/auth/login` | No | Inicio de sesion |
| `GET` | `/api/v1/auth/me` | Si | Perfil del usuario autenticado |
| `POST` | `/api/v1/predict` | Si | Clasificacion de imagen oral |
| `GET` | `/api/v1/history` | Si | Historial de analisis |
| `GET` | `/api/v1/summary/today` | Si | Resumen diario |

El contrato del endpoint de prediccion esta documentado en `docs/predict_contract.md`.

## Inferencia

- Arquitectura esperada: MobileNetV2.
- Runtime: ONNX Runtime.
- Entrada: imagen JPEG, PNG o WEBP.
- Preprocesamiento: RGB, resize a `224x224`, normalizacion ImageNet y tensor `float32` con forma `[1, 3, 224, 224]`.
- Salida: clase `benign` o `malignant`, confianza, probabilidades y recomendacion.

## Pruebas

```bash
pytest
```

Pruebas especificas:

```bash
pytest tests/test_auth.py -v
pytest tests/test_inference.py -v
```

## Despliegue En Render

| Campo | Valor |
|-------|-------|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

Configura las variables de produccion directamente en el panel de Render. No las documentes con valores reales dentro del repositorio.
