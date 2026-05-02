from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import os
from PIL import Image

from database import engine, get_db, Base
from models import models
from schemas import PredictionResponse, UserCreate, UserLogin, AnalysisHistory
from crud import get_user_by_email, create_user, get_user_analyses, create_analysis
from models.inference import OralLesionClassifier

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Oral Lesion Detection API",
    description="AI-powered oral lesion classification system for early detection of oral cancer",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

classifier = OralLesionClassifier()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.get("/")
async def root():
    return {"message": "Oral Lesion Detection API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/api/v1/auth/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return create_user(db=db, user=user)

@app.post("/api/v1/auth/login")
async def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid credentials")
    return {"message": "Login successful", "user_id": db_user.id, "full_name": db_user.full_name}

@app.post("/api/v1/predict", response_model=PredictionResponse)
async def predict(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    try:
        image = Image.open(file.file).convert("RGB")
        result = classifier.predict(image)
        
        recommendation = "Consult a specialist immediately for further evaluation." if result["prediction"] in ["opmd", "malignant"] else "No immediate concern. Regular check-ups recommended."
        
        return PredictionResponse(
            prediction=result["prediction"],
            confidence=result["confidence"],
            recommendation=recommendation,
            probabilities=result.get("probabilities")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/history/{user_id}", response_model=List[AnalysisHistory])
async def get_history(user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    analyses = get_user_analyses(db, user_id=user_id, skip=skip, limit=limit)
    return analyses
