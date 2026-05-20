from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    recommendation: str
    probabilities: Optional[dict[str, float]] = None

class UserCreate(BaseModel):
    full_name: str
    doctor_id: str
    medical_center: Optional[str] = None
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class TokenData(BaseModel):
    sub: str
    email: str

class UserProfile(BaseModel):
    id: int
    full_name: str
    doctor_id: str
    medical_center: Optional[str] = None
    email: str

    class Config:
        from_attributes = True

class AnalysisHistory(BaseModel):
    id: int
    prediction: str
    confidence: float
    timestamp: datetime
    image_url: Optional[str] = None
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None

    class Config:
        from_attributes = True


class DailySummary(BaseModel):
    total: int
    benign: int
    malignant: int
    latest_analysis_at: Optional[datetime] = None
