# BucalScan AI

BucalScan AI es una aplicacion movil para apoyo al tamizaje de lesiones orales. Permite registrar profesionales de salud, iniciar sesion, capturar o cargar imagenes de lesiones, enviarlas a una API y obtener una clasificacion binaria asistida por inteligencia artificial: `benign` o `malignant`.

> Esta herramienta es de apoyo y no reemplaza el diagnostico clinico de un profesional de salud.

## Estado Del Proyecto

- Frontend movil desarrollado con Flutter.
- Backend REST desarrollado con FastAPI.
- Inferencia local en el backend con modelo ONNX configurable; el nuevo modelo ganador puede usarse como `ResNet50` mediante `MODEL_PATH`.
- Autenticacion con JWT.
- Persistencia de usuarios e historial de analisis en base de datos SQL.
- Almacenamiento de imagenes en Cloudinary si esta configurado; en caso contrario, almacenamiento local en `backend/uploads`.
- Backend publicado en Render: `https://bucalscan-ai.onrender.com`.

## Tecnologias

| Capa | Tecnologia |
|------|------------|
| Aplicacion movil | Flutter, Dart, Riverpod, Dio |
| API | FastAPI, Uvicorn, Pydantic |
| Autenticacion | JWT, bcrypt |
| Base de datos | SQLite local; compatible con PostgreSQL mediante `DATABASE_URL` |
| IA | ONNX Runtime, ResNet50/ONNX configurable |
| Imagenes | Pillow, Cloudinary opcional |
| Pruebas | pytest, flutter test |

## Estructura

```text
DeepOral-Dx/
├── backend/
│   ├── auth/                  # JWT y seguridad de contrasenas
│   ├── docs/                  # Contratos tecnicos de API
│   ├── models/                # Modelos SQLAlchemy e inferencia ONNX
│   ├── routers/               # Endpoints FastAPI
│   ├── services/              # Servicios externos, como Cloudinary
│   ├── tests/                 # Pruebas automatizadas del backend
│   ├── main.py                # Entrada de la API
│   ├── config.py              # Configuracion por variables de entorno
│   ├── database.py            # Conexion y esquema de base de datos
│   ├── requirements.txt       # Dependencias de ejecucion
│   └── requirements-train.txt # Dependencias para entrenamiento
├── frontend/
│   ├── lib/
│   │   ├── core/              # Constantes, tema y configuracion base
│   │   ├── data/              # Servicios compartidos, como cliente API y auth
│   │   ├── features/          # Modulos por feature con data, domain y presentation
│   │   └── main.dart          # Entrada de la app Flutter
│   ├── test/                  # Pruebas Flutter
│   └── pubspec.yaml           # Dependencias Flutter
└── README.md
```

## Requisitos

- Python 3.12 o compatible con las dependencias del backend.
- Flutter SDK con Dart `^3.11.5`.
- Un emulador, dispositivo fisico o plataforma de escritorio habilitada para Flutter.
- Git.

## Configuracion Del Backend

1. Entrar al directorio del backend:

```bash
cd backend
```

2. Crear y activar un entorno virtual:

```bash
python -m venv venv
```

```bash
# Windows
venv\Scripts\activate

# Linux/macOS
source venv/bin/activate
```

3. Instalar dependencias:

```bash
pip install -r requirements.txt
```

4. Crear el archivo `.env` desde el ejemplo:

```bash
copy .env.example .env
```

En Linux/macOS:

```bash
cp .env.example .env
```

5. Ajustar el archivo `.env` con los valores del entorno local.

No publiques credenciales, secretos JWT ni claves de servicios externos en el README o en el repositorio.

6. Ejecutar la API:

```bash
uvicorn main:app --reload
```

La API local queda disponible en `http://localhost:8000`.

Documentacion interactiva:

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Configuracion Del Frontend

1. Entrar al directorio del frontend:

```bash
cd frontend
```

2. Instalar dependencias:

```bash
flutter pub get
```

3. Ejecutar la aplicacion usando el backend desplegado:

```bash
flutter run
```

Por defecto, la app usa `https://bucalscan-ai.onrender.com`.

Para usar un backend local:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Para usar otro backend desplegado:

```bash
flutter run --dart-define=API_BASE_URL=https://tu-backend.onrender.com
```

## Ambientes De Ejecucion

El proyecto cuenta con dos ambientes principales: prueba/local y produccion. Esta separacion permite validar el funcionamiento del sistema antes de usar la version estable conectada al backend desplegado.

### Ambiente De Prueba

El ambiente de prueba se ejecuta localmente para validar funcionalidades con datos controlados. En este ambiente, el backend FastAPI puede ejecutarse en `http://localhost:8000`, la base de datos puede ser SQLite local y se utilizan usuarios, imagenes y datos de prueba para verificar el flujo de registro, inicio de sesion, prediccion e historial.

Comandos principales:

```bash
cd backend
uvicorn main:app --reload
```

```bash
cd frontend
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

En emulador Android, si el backend corre en la maquina local, puede usarse `http://10.0.2.2:8000` en lugar de `http://localhost:8000`.

### Ambiente De Produccion

El ambiente de produccion corresponde a la version estable del sistema. El backend esta publicado en Render en `https://bucalscan-ai.onrender.com` y la aplicacion movil Flutter se conecta por defecto a esa URL mediante la variable `API_BASE_URL`.

La app puede ejecutarse contra produccion con:

```bash
cd frontend
flutter run
```

Tambien puede indicarse explicitamente la URL de produccion:

```bash
flutter run --dart-define=API_BASE_URL=https://bucalscan-ai.onrender.com
```

Texto sugerido para sustentacion:

> El proyecto cuenta con dos ambientes. El ambiente de prueba se ejecuta localmente, usando el backend FastAPI en `http://localhost:8000`, base de datos SQLite local, usuarios de prueba e imagenes controladas para validar el flujo de autenticacion, prediccion e historial. El ambiente de produccion utiliza el backend desplegado en Render en `https://bucalscan-ai.onrender.com`, al cual se conecta por defecto la aplicacion movil Flutter mediante la variable `API_BASE_URL`.

## Endpoints Principales

| Metodo | Endpoint | Autenticacion | Descripcion |
|--------|----------|---------------|-------------|
| `GET` | `/` | No | Informacion basica de la API |
| `GET` | `/health` | No | Verificacion de salud del servicio |
| `POST` | `/api/v1/auth/register` | No | Registro de usuario medico |
| `POST` | `/api/v1/auth/login` | No | Inicio de sesion y emision de token JWT |
| `GET` | `/api/v1/auth/me` | Si | Perfil del usuario autenticado |
| `POST` | `/api/v1/predict` | Si | Clasificacion de imagen oral |
| `GET` | `/api/v1/history` | Si | Historial de analisis del usuario |
| `GET` | `/api/v1/summary/today` | Si | Resumen del dia para el usuario |

El contrato tecnico del endpoint de prediccion esta en `backend/docs/predict_contract.md`.

## Flujo De Uso

1. El profesional se registra o inicia sesion en la app.
2. La app guarda el token JWT de sesion.
3. El usuario captura o selecciona una imagen de lesion oral.
4. El frontend envia la imagen a `/api/v1/predict` con el token JWT.
5. El backend valida la imagen, ejecuta la inferencia ONNX y guarda el analisis.
6. La app muestra la prediccion, confianza, recomendacion e historial.

## Pruebas

Backend:

```bash
cd backend
pytest
```

Frontend:

```bash
cd frontend
flutter test
```

## Evidencias Para Sustentacion

Para demostrar el despliegue completo del sistema, se recomienda registrar las siguientes evidencias:

| Componente | Evidencia sugerida |
|------------|--------------------|
| Frontend movil | Capturas o video de la app ejecutandose en emulador o dispositivo fisico |
| Backend local | Captura de `http://localhost:8000/docs` o respuesta de `GET /health` |
| Backend produccion | Captura de `https://bucalscan-ai.onrender.com/health` o Swagger si esta habilitado |
| Base de datos | Registro de usuarios, analisis o historial guardado |
| Modelo IA | Respuesta de `/api/v1/predict` con clase, confianza y recomendacion |
| Ambiente de prueba | App conectada a `http://localhost:8000` o `http://10.0.2.2:8000` |
| Ambiente de produccion | App conectada a `https://bucalscan-ai.onrender.com` |
| Pruebas backend | Resultado de ejecucion de `pytest` |
| Pruebas frontend | Resultado de ejecucion de `flutter test` |

## Despliegue En Render

Configuracion sugerida para el backend:

| Campo | Valor |
|-------|-------|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

Configura las variables de produccion directamente en el panel de Render. No las documentes con valores reales dentro del repositorio.

## Notas

- El modelo activo se configura con `MODEL_PATH`; para ResNet50 usa, por ejemplo, `backend/models/resnet50_oral.onnx`.
- Las clases de salida son `benign` y `malignant`.
- Si `CLOUDINARY_*` no esta configurado, las imagenes se guardan localmente.
- En Android con emulador, si el backend corre en la maquina local, puede ser necesario usar `http://10.0.2.2:8000` en lugar de `http://localhost:8000`.
