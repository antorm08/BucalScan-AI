# BucalScan AI

BucalScan AI es una aplicacion movil academica de apoyo al tamizaje preliminar de lesiones orales. Integra una app Flutter, una API FastAPI y un clasificador ResNet50 en formato ONNX para producir una clasificacion binaria `benign` o `malignant`, probabilidades, confianza y un mapa de activacion de clase (CAM).

> BucalScan AI no realiza un diagnostico medico u odontologico, no reemplaza la evaluacion profesional y no cuenta con validacion clinica para uso asistencial.

## Estado del proyecto

La implementacion local incluye:

- Registro, inicio de sesion, restauracion de sesion y perfil profesional.
- Centros clinicos (workspaces), membresias, aprobaciones y aislamiento de datos por `X-Workspace-ID`.
- Pacientes, multiples lesiones por paciente y evaluaciones longitudinales.
- Captura desde camara o galeria y control automatico de calidad de imagen.
- Inferencia ResNet50 con ONNX Runtime y generacion de CAM.
- Historial paginado, busqueda, filtros, resumen diario y linea de tiempo por lesion.
- Comparacion de dos evaluaciones de una misma lesion.
- Exportacion individual de evaluaciones en PDF.
- Panel para administrar centros, solicitudes de acceso y usuarios.
- Persistencia clinica normalizada con SQLAlchemy y migraciones Alembic.
- Motor determinista de prioridad clinica separado del modelo de IA.

La prioridad clinica esta implementada, pero `CLINICAL_PRIORITY_MODE` permanece en `disabled` por defecto. Puede exponerse en modo `academic` para demostraciones, con un ruleset en borrador y sin validacion clinica.

La app tiene configurada por defecto la URL `https://bucalscan-ai.onrender.com`. La existencia de esa URL no demuestra que la revision actual, sus migraciones o su configuracion esten desplegadas y verificadas. La validacion de produccion, la instalacion del artefacto actual en dispositivos fisicos y los gates clinicos permanecen pendientes.

## Arquitectura

```text
Flutter / Riverpod
        |
        | HTTPS JSON o multipart/form-data
        | Authorization: Bearer <JWT>
        | X-Workspace-ID: <workspace activo>
        v
FastAPI
  |-- autenticacion y workspaces
  |-- pacientes, lesiones y evaluaciones
  |-- prediccion, historial y resumen
  |-- administracion, prioridad y PDF
  |
  |-- calidad de imagen (OpenCV)
  |-- ResNet50 ONNX + CAM
  |-- almacenamiento de imagenes
  `-- persistencia SQLAlchemy / Alembic
          |-- PostgreSQL en produccion
          `-- SQLite en desarrollo y pruebas
```

El frontend usa una organizacion feature-first inspirada en Clean Architecture:

- `presentation`: vistas, widgets, controladores y providers Riverpod.
- `domain`: entidades, casos de uso y contratos de repositorio.
- `data`: DTO, datasources, servicios HTTP y repositorios concretos.
- `di`: composicion e inyeccion de dependencias.

## Flujo clinico principal

1. El profesional se registra o inicia sesion.
2. Accede a un workspace mediante una membresia activa.
3. Selecciona o registra un paciente.
4. Selecciona o registra una lesion oral.
5. Captura una imagen o la elige desde la galeria.
6. Confirma que obtuvo autorizacion para almacenar la evaluacion.
7. El backend valida autenticacion, workspace, archivo y calidad de imagen.
8. ResNet50 procesa la imagen y genera la salida binaria y el CAM.
9. La evaluacion se persiste en el esquema clinico normalizado.
10. La app muestra el resultado preliminar y lo incorpora al historial y a la linea de tiempo de la lesion.

## Tecnologias

| Capa | Tecnologias |
|------|-------------|
| Aplicacion | Flutter, Dart, Riverpod |
| Cliente HTTP | Dio, interceptor JWT |
| Sesion local | `flutter_secure_storage`, `shared_preferences` |
| Imagenes y archivos | `image_picker`, `file_picker` |
| API | FastAPI, Uvicorn, Pydantic |
| Seguridad | JWT, Passlib, bcrypt |
| Persistencia | SQLAlchemy, Alembic, PostgreSQL, SQLite |
| IA | ONNX Runtime, ResNet50, NumPy, Pillow |
| Calidad y CAM | OpenCV, grafo ONNX con salidas CAM |
| Almacenamiento | Cloudinary en produccion; filesystem solo en desarrollo |
| PDF | ReportLab |
| Pruebas | pytest, `flutter_test`, `integration_test` |

## Modelo de datos

La fuente de verdad del flujo actual esta formada por:

- `users`
- `clinical_workspaces`
- `workspace_memberships`
- `patients`
- `oral_lesions`
- `clinical_evaluations`
- `lesion_images`
- `model_predictions`
- `consent_attestations`
- `clinical_assessment_snapshots`
- `clinical_priority_results`

La tabla `analyses` se conserva en el historial de migraciones y en el modelo heredado para compatibilidad y rollback. Las nuevas predicciones, el historial y el resumen diario no escriben ni leen esa tabla como fuente de verdad.

## Roles y acceso

- Roles globales: `platform_admin` y `professional`.
- Roles de membresia: `clinic_admin`, `professional` y `assistant`.
- Estados principales: `pending`, `active`, `rejected`, `inactive` o `suspended`, segun el recurso.
- Las operaciones clinicas requieren JWT, `X-Workspace-ID` y membresia activa.
- `clinic_admin` y `professional` pueden realizar operaciones clinicas.
- `assistant` no puede crear pacientes, lesiones ni predicciones.
- `platform_admin` no obtiene acceso clinico automatico; necesita una membresia activa explicita.

## Inferencia y calidad de imagen

El runtime carga por defecto `backend/models/resnet50_oral_cam.onnx` mediante `CAM_MODEL_PATH`.

- Entrada: JPEG, PNG o WEBP de hasta 10 MB.
- Resolucion minima predeterminada: `224x224`.
- Control de desenfoque, oscuridad y sobreexposicion.
- Preprocesamiento: RGB, `224x224`, normalizacion ImageNet y tensor `float32 [1,3,224,224]`.
- Salida: clase, confianza, probabilidades, recomendacion no diagnostica, version y tiempo de procesamiento.
- Explicabilidad: CAM calculado en la misma inferencia ONNX.

El CAM no es Grad-CAM, segmentacion, localizacion diagnostica ni evidencia autonoma de malignidad.

### Metricas academicas de ResNet50

| Accuracy | Precision | Recall | F1-score | AUC-ROC |
|---------:|----------:|-------:|---------:|--------:|
| 0.8980 | 0.8519 | 0.9583 | 0.9020 | 0.9367 |

Las metricas corresponden a un conjunto de prueba reducido dentro de un protocolo academico. No demuestran generalizacion clinica, desempeno en poblaciones externas ni equivalencia con especialistas.

## Estructura del repositorio

```text
BucalScan_AI/
|-- backend/
|   |-- alembic/             # Migraciones de base de datos
|   |-- auth/                # JWT y autorizacion por workspace
|   |-- docs/                # Contratos, validacion y operacion
|   |-- models/              # ORM, ONNX e inferencia
|   |-- routers/             # Routers FastAPI
|   |-- rulesets/            # Ruleset academico de prioridad
|   |-- scripts/             # Verificacion, CAM y migracion
|   |-- services/            # Calidad, almacenamiento, prioridad y PDF
|   |-- tests/               # Pruebas backend
|   |-- main.py
|   `-- requirements.txt
|-- frontend/
|   |-- lib/
|   |   |-- core/            # Tema, sesion, startup y widgets comunes
|   |   |-- data/            # Servicios compartidos
|   |   `-- features/        # Modulos data/domain/presentation/di
|   |-- integration_test/
|   |-- test/
|   `-- pubspec.yaml
|-- openspec/                # Propuestas, disenos, specs y tareas
`-- README.md
```

## Requisitos

- Python 3.12.
- Flutter con Dart compatible con `^3.11.5`.
- Git.
- Android SDK, Xcode u otro toolchain segun la plataforma objetivo.
- PostgreSQL y Cloudinary para un entorno configurado como produccion.

Los runners de Android, iOS, web y escritorio existen en el repositorio. La evidencia disponible se concentra en Android; la compatibilidad completa de todas las plataformas no esta validada. El flujo de prediccion usa `dart:io`, por lo que no debe asumirse soporte web sin adaptaciones.

## Ejecucion local

### 1. Backend

Desde la raiz del repositorio:

```bash
cd backend
python -m venv venv
```

Activar el entorno:

```powershell
# Windows PowerShell
.\venv\Scripts\Activate.ps1
```

```bash
# Linux/macOS
source venv/bin/activate
```

Instalar dependencias y crear la configuracion local:

```bash
pip install -r requirements.txt
```

```powershell
# Windows PowerShell
Copy-Item .env.example .env
```

```bash
# Linux/macOS
cp .env.example .env
```

Edita `.env` y reemplaza al menos `JWT_SECRET`. No publiques ese archivo ni credenciales reales.

Aplicar las migraciones de forma explicita:

```bash
alembic upgrade head
```

Iniciar la API:

```bash
uvicorn main:app --reload
```

Servicios locales:

- API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- Liveness: `http://localhost:8000/live`
- Readiness: `http://localhost:8000/ready`

`/ready` valida la conexion a la base de datos, la revision de esquema requerida, el modelo ONNX y sus salidas CAM. Las migraciones no se ejecutan durante el arranque.

### 2. Frontend

En otra terminal, desde la raiz:

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

En el emulador Android usa la direccion especial del host:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

En un dispositivo fisico usa la IP accesible de la maquina donde se ejecuta FastAPI.

Si no se proporciona `API_BASE_URL`, la app usa `https://bucalscan-ai.onrender.com`. Verifica `/ready` y la revision desplegada antes de tratar esa URL como un entorno operativo.

## Variables de entorno principales

| Variable | Desarrollo | Produccion |
|----------|------------|------------|
| `JWT_SECRET` | Obligatoria | Obligatoria y robusta |
| `DATABASE_URL` | SQLite permitido | PostgreSQL obligatorio |
| `MODEL_PATH` | Modelo base aprobado | Modelo base aprobado |
| `CAM_MODEL_PATH` | Grafo CAM del runtime | Grafo CAM del runtime |
| `MODEL_ARCHITECTURE` | `ResNet50` | `ResNet50` |
| `CLOUDINARY_CLOUD_NAME` | Opcional | Obligatoria |
| `CLOUDINARY_API_KEY` | Opcional | Obligatoria |
| `CLOUDINARY_API_SECRET` | Opcional | Obligatoria |
| `CLINICAL_PRIORITY_MODE` | `disabled` o `academic` | `disabled` salvo aprobacion formal |
| `CORS_ORIGINS` | Origenes permitidos | Lista explicita recomendada |

Consulta `backend/.env.example` para ver la lista completa y los umbrales de calidad de imagen.

## API

La API publica 45 operaciones HTTP. Estos son sus grupos principales:

| Grupo | Rutas principales | Requisitos |
|-------|-------------------|------------|
| Disponibilidad | `/`, `/health`, `/live`, `/ready` | Publicas |
| Autenticacion | `/api/v1/auth/register`, `/login`, `/me` | JWT salvo registro/login |
| Workspaces | `/api/v1/workspaces`, `/mine`, membresias | JWT; permisos segun operacion |
| Clinica | `/api/v1/patients`, `/lesions`, evaluaciones y PDF | JWT + `X-Workspace-ID` |
| Prediccion | `POST /api/v1/predict` | JWT + workspace + paciente + lesion + atestacion |
| Historial | `GET /api/v1/history` | JWT + `X-Workspace-ID` |
| Resumen | `GET /api/v1/summary/today` | JWT + `X-Workspace-ID` |
| Prioridad | `/api/v1/clinical-priority/*` | JWT + workspace; modo configurable |
| Administracion | `/api/v1/admin/*` | `platform_admin` |

La documentacion OpenAPI generada por FastAPI en `/docs` es la referencia ejecutable de los parametros y respuestas de la revision en uso.

## Pruebas y analisis

Backend:

```bash
cd backend
python -m pytest -q
```

Frontend:

```bash
cd frontend
flutter analyze
flutter test
```

Prueba de integracion Flutter disponible:

```bash
flutter test integration_test/app_smoke_test.dart
```

La evidencia registrada mas reciente incluye 119 pruebas backend aprobadas y una ejecucion de 208 pruebas Flutter sin incidencias de `flutter analyze`. Son resultados de revisiones registradas, no una garantia sobre un entorno productivo ni sustituyen pruebas clinicas, de dispositivo o E2E contra servicios reales.

## Build Android

```bash
cd frontend
flutter build apk --release
```

No incluyas en Git ni distribuyas publicamente:

- `.env`
- `key.properties`
- keystores `.jks`
- bases `.db`
- tokens, secretos JWT o credenciales Cloudinary

La construccion exitosa de un APK no demuestra instalacion, conectividad productiva, funcionamiento de camara/galeria ni validacion clinica.

## Configuracion objetivo de produccion

El backend exige PostgreSQL y Cloudinary cuando `ENVIRONMENT=production`.

Configuracion orientativa para Render:

| Campo | Valor |
|-------|-------|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

Procedimiento minimo:

1. Configurar secretos en el proveedor, nunca en el repositorio.
2. Respaldar la base de datos.
3. Ejecutar `alembic upgrade head` de forma explicita.
4. Desplegar la revision identificada.
5. Verificar `/live` y `/ready`.
6. Probar autenticacion, aislamiento por workspace, Cloudinary, inferencia, CAM, persistencia e historial.
7. Mantener la prioridad clinica deshabilitada mientras no complete gobernanza y validacion.

La documentacion operativa esta en `backend/docs/migration_and_deployment.md`.

## Limitaciones conocidas

- Dataset y conjunto de prueba reducidos, sin validacion externa representativa.
- Sin validacion clinica, aprobacion regulatoria ni evaluacion formal con pacientes.
- Prioridad clinica con ruleset en borrador, deshabilitada por defecto.
- Sin evidencia completa de la revision actual desplegada y migrada en produccion.
- Sin prueba E2E real contra Render, Neon, Cloudinary, camara y galeria.
- Sin verificacion vigente del artefacto actual en dispositivo fisico.
- Auditorias manuales de accesibilidad, retencion, eliminacion y seguridad pendientes.
- URLs de Cloudinary publicas; no existe entrega privada avanzada ni automatizacion de retencion.
- Sin recuperacion de contrasena, MFA, OAuth o revocacion persistida de tokens.
- Sin CI/CD versionado en el repositorio.

## Documentacion relacionada

- `backend/docs/model_validation.md`: contrato y metricas del modelo.
- `backend/docs/clinical_priority_governance.md`: gates de prioridad clinica.
- `backend/docs/migration_and_deployment.md`: migracion y operacion.
- `backend/docs/privacy_retention.md`: consideraciones de privacidad y retencion.
- `openspec/changes/`: especificaciones y tareas de evolucion del producto.

Algunos documentos tecnicos historicos pueden describir contratos anteriores. Ante una discrepancia, contrasta el documento con OpenAPI, los routers, los modelos y las migraciones de la revision ejecutada.

## Aviso de uso

BucalScan AI es un artefacto academico de ingenieria de software y aprendizaje automatico. Todo resultado debe interpretarse como una salida preliminar del modelo y revisarse por profesionales cualificados dentro de procesos clinicos, eticos y legales aprobados.
