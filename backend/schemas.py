from pydantic import BaseModel
from typing import Optional

class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    recommendation: str
    probabilities: Optional[dict] = None

class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class AnalysisHistory(BaseModel):
    id: int
    prediction: str
    confidence: float
    timestamp: str
    image_url: Optional[str] = None
