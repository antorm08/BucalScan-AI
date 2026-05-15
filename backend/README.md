# Oral Lesion Detection Backend

FastAPI backend for the oral lesion detection system.

Production deployment: `https://bucalscan-ai.onrender.com`

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
```

2. Activate the virtual environment:
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

Local API: `http://localhost:8000`
Production API: `https://bucalscan-ai.onrender.com`

## API Documentation

- Local Swagger UI: `http://localhost:8000/docs`
- Local ReDoc: `http://localhost:8000/redoc`
- Production Swagger UI: `https://bucalscan-ai.onrender.com/docs`
- Production ReDoc: `https://bucalscan-ai.onrender.com/redoc`

## Render Deployment

- Root Directory: `backend`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Required environment variables:
  - `APP_NAME=BucalScan AI`
  - `JWT_SECRET=<your-secret>`
  - `MODEL_PATH=models/mobilenetv2_oral.onnx`

## Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/health` | Health check |
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/predict` | Classify oral lesion image |
| GET | `/api/v1/history/{user_id}` | Get user analysis history |
