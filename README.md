# BucalScan AI

AI-powered mobile application for binary oral lesion screening using Deep Learning.

## Project Structure

```
mobile-app-g6/
├── backend/                 # FastAPI backend
│   ├── main.py             # API entry point
│   ├── models/             # ML model and database models
│   ├── schemas.py          # Pydantic schemas
│   ├── crud.py             # Database operations
│   ├── database.py         # DB configuration
│   └── requirements.txt    # Python dependencies
├── frontend/               # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API services
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   ├── widgets/        # Reusable widgets
│   │   └── utils/          # Constants and helpers
│   └── pubspec.yaml        # Flutter dependencies
└── PROJECT_ESPECIFICATIONS.md
```

## Backend Setup (FastAPI)

Production backend deployed at `https://bucalscan-ai.onrender.com`.

1. Navigate to backend directory:
```bash
cd backend
```

2. Activate virtual environment:
```bash
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the server:
```bash
uvicorn main:app --reload
```

Local API available at `http://localhost:8000` | Local docs at `http://localhost:8000/docs`
Public API available at `https://bucalscan-ai.onrender.com` | Public docs at `https://bucalscan-ai.onrender.com/docs`

## Frontend Setup (Flutter)

1. Navigate to frontend directory:
```bash
cd frontend
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

By default, the app uses the deployed backend at `https://bucalscan-ai.onrender.com`.

4. Optional: override backend URL without editing code:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

For a different deployed backend, replace the value with your public URL, for example:
```bash
flutter run --dart-define=API_BASE_URL=https://your-backend.onrender.com
```

## Features

- **RF-001**: Real-time camera capture
- **RF-002**: Gallery image upload
- **RF-003**: AI classification (benign, malignant)
- **RF-004**: Results with confidence levels
- **RF-005**: Analysis history
- **RF-006**: Medical recommendations
- **RF-007**: User authentication

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **ML**: PyTorch (CNN models: EfficientNet, MobileNet, ResNet)
- **Database**: SQLite
