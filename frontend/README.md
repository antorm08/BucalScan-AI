# Frontend De BucalScan AI

Aplicacion Flutter de BucalScan AI para registro, inicio de sesion, captura/carga de imagenes, visualizacion de resultados e historial de analisis de lesiones orales.

## Requisitos

- Flutter SDK con Dart `^3.11.5`.
- Dispositivo fisico, emulador o plataforma de escritorio compatible.
- Backend disponible localmente o publicado.

## Instalacion

```bash
flutter pub get
```

## Ejecucion

Usar backend publicado por defecto:

```bash
flutter run
```

Usar backend local:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

En emulador Android, normalmente se debe usar la IP especial del host:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Usar otro backend desplegado:

```bash
flutter run --dart-define=API_BASE_URL=https://tu-backend.onrender.com
```

## Configuracion De API

La URL base se define en `lib/core/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://bucalscan-ai.onrender.com',
);
```

La version de API usada por la app es `/api/v1`.

## Funcionalidades

- Registro e inicio de sesion de profesionales de salud.
- Restauracion de sesion con token JWT guardado localmente.
- Captura o seleccion de imagenes.
- Envio de imagen al backend para prediccion.
- Visualizacion de clase, confianza y recomendacion.
- Historial de analisis.
- Resumen diario.
- Perfil de usuario.

## Estructura Principal

```text
lib/
├── core/
│   ├── constants/       # Constantes globales
│   ├── router/          # Configuracion de rutas si aplica
│   └── theme/           # Colores y tema visual
├── data/
│   ├── models/          # Modelos DTO
│   ├── repositories/    # Repositorios usados por viewmodels
│   └── services/        # Dio, interceptores y almacenamiento de auth
├── domain/
│   └── entities/        # Entidades de dominio
└── presentation/
    ├── viewmodels/      # Estado de UI con Provider
    ├── views/           # Pantallas
    └── widgets/         # Componentes reutilizables
```

## Dependencias Destacadas

- `provider`: gestion de estado.
- `dio`: cliente HTTP e interceptores.
- `image_picker`: seleccion/captura de imagenes.
- `shared_preferences`: persistencia local del token.
- `permission_handler`: permisos de dispositivo.
- `cached_network_image`: carga de imagenes remotas.

## Pruebas

```bash
flutter test
```

## Notas

- El backend publicado puede tardar en responder si el servicio esta en reposo.
- Para desarrollo local, asegurese de que el backend este corriendo antes de abrir la app.
- Si se prueba en dispositivo fisico, use la IP de la maquina donde corre el backend en lugar de `localhost`.
