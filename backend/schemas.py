from pydantic import BaseModel, ConfigDict
from typing import Literal, Optional
from datetime import datetime

class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    recommendation: str
    probabilities: Optional[dict[str, float]] = None
    processing_time_ms: Optional[float] = None

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
    role: Literal["admin", "doctor"]

class UserProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    doctor_id: str
    medical_center: Optional[str] = None
    email: str
    role: Literal["admin", "doctor"]
    created_at: Optional[datetime] = None

class AnalysisHistory(BaseModel):
    model_config = ConfigDict(from_attributes=True, protected_namespaces=())

    id: int
    prediction: str
    confidence: float
    timestamp: datetime
    image_url: Optional[str] = None
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    model_version: Optional[str] = None
    processing_time_ms: Optional[float] = None


class DailySummary(BaseModel):
    total: int
    benign: int
    malignant: int
    latest_analysis_at: Optional[datetime] = None


class UserAdminResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    doctor_id: str
    email: str
    medical_center: Optional[str] = None
    created_at: Optional[datetime] = None
    status: str
    role: Literal["admin", "doctor"]


class UserStatusUpdate(BaseModel):
    status: Literal["active", "suspended"]


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    medical_center: Optional[str] = None
    email: Optional[str] = None

    @property
    def has_any_update(self) -> bool:
        return any(v is not None for v in [self.full_name, self.medical_center, self.email])

    @property
    def is_valid(self) -> bool:
        if self.full_name is not None and self.full_name.strip() == '':
            return False
        if self.email is not None and self.email.strip() == '':
            return False
        return True
