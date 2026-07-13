from pydantic import BaseModel, ConfigDict
from typing import Literal, Optional
from datetime import date, datetime

class PredictionResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    prediction: str
    confidence: float
    recommendation: str
    probabilities: Optional[dict[str, float]] = None
    processing_time_ms: Optional[float] = None
    model_version: Optional[str] = None
    evaluation_id: Optional[int] = None
    notice: str = "AI decision support only; this result is not a diagnosis."

class UserCreate(BaseModel):
    full_name: str
    doctor_id: str
    medical_center: Optional[str] = None
    email: str
    password: str
    profession: Optional[str] = None
    specialty: Optional[str] = None
    workspace_choice: Optional[Literal["existing", "new", "independent"]] = None
    workspace_id: Optional[int] = None
    workspace_name: Optional[str] = None
    workspace_type: Optional[Literal["clinic", "consultorio", "hospital", "university", "campaign"]] = None

class UserLogin(BaseModel):
    email: str
    password: str

class TokenData(BaseModel):
    sub: str
    email: str
    role: str

class UserProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    doctor_id: str
    medical_center: Optional[str] = None
    email: str
    role: str
    status: str
    profession: Optional[str] = None
    specialty: Optional[str] = None
    memberships: list["MembershipResponse"] = []
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
    created_by_id: Optional[int] = None
    created_by_name: Optional[str] = None
    created_by_email: Optional[str] = None
    created_by_doctor_id: Optional[str] = None
    evaluation_id: Optional[int] = None
    patient_record_id: Optional[int] = None
    lesion_id: Optional[int] = None


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
    role: str
    profession: Optional[str] = None
    specialty: Optional[str] = None


class UserStatusUpdate(BaseModel):
    status: Literal["active", "suspended"]


class AdminSummaryResponse(BaseModel):
    pending_workspaces: int
    pending_memberships: int
    total_users: int
    active_users: int
    suspended_users: int


class AdminRequesterResponse(BaseModel):
    id: int
    full_name: str
    doctor_id: str
    email: str
    profession: Optional[str] = None
    specialty: Optional[str] = None
    status: str


class AdminWorkspaceRequestResponse(BaseModel):
    id: int
    name: str
    workspace_type: str
    status: str
    city: Optional[str] = None
    address: Optional[str] = None
    created_at: datetime
    requester: Optional[AdminRequesterResponse] = None


class AdminMembershipDecision(BaseModel):
    role: Literal["clinic_admin", "professional", "assistant"]


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    medical_center: Optional[str] = None
    email: Optional[str] = None
    profession: Optional[str] = None
    specialty: Optional[str] = None

    @property
    def has_any_update(self) -> bool:
        return any(v is not None for v in [self.full_name, self.medical_center, self.email, self.profession, self.specialty])

    @property
    def is_valid(self) -> bool:
        if self.full_name is not None and self.full_name.strip() == '':
            return False
        if self.email is not None and self.email.strip() == '':
            return False
        return True


class WorkspaceCreate(BaseModel):
    name: str
    workspace_type: Literal["clinic", "consultorio", "hospital", "university", "campaign", "independent"]
    city: Optional[str] = None
    address: Optional[str] = None
    tax_identifier: Optional[str] = None
    telephone: Optional[str] = None
    institutional_email: Optional[str] = None


class WorkspaceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    workspace_type: str
    status: str
    city: Optional[str] = None
    address: Optional[str] = None
    potential_duplicate: bool = False


class AdminMembershipRequestResponse(BaseModel):
    id: int
    status: str
    role: str
    created_at: datetime
    requester: AdminRequesterResponse
    workspace: WorkspaceResponse


class MembershipResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    workspace_id: int
    user_id: int
    role: str
    status: str
    workspace: Optional[WorkspaceResponse] = None


class MembershipUpdate(BaseModel):
    status: Literal["active", "rejected", "inactive"]
    role: Optional[Literal["clinic_admin", "professional", "assistant"]] = None


class PatientCreate(BaseModel):
    clinical_code: str
    identity_document: Optional[str] = None
    full_name: str
    birth_date: Optional[date] = None
    sex: Optional[str] = None
    telephone: Optional[str] = None
    email: Optional[str] = None
    notes: Optional[str] = None
    allow_potential_duplicate: bool = False


class PatientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    workspace_id: int
    clinical_code: str
    identity_document: Optional[str] = None
    full_name: str
    birth_date: Optional[date] = None
    sex: Optional[str] = None
    telephone: Optional[str] = None
    email: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime


class LesionCreate(BaseModel):
    anatomical_site: str
    observed_at: Optional[date] = None
    estimated_duration: Optional[str] = None
    status: Literal["active", "resolved", "monitoring"] = "active"
    clinical_notes: Optional[str] = None


class LesionStatusUpdate(BaseModel):
    status: Literal["active", "resolved", "monitoring"]


class LesionUpdate(BaseModel):
    status: Optional[Literal["active", "resolved", "monitoring"]] = None
    clinical_notes: Optional[str] = None


class LesionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    workspace_id: int
    patient_id: int
    anatomical_site: str
    observed_at: Optional[date] = None
    estimated_duration: Optional[str] = None
    status: str
    clinical_notes: Optional[str] = None
    created_at: datetime


class EvaluationProfessionalResponse(BaseModel):
    id: int
    full_name: str
    doctor_id: str
    profession: Optional[str] = None
    specialty: Optional[str] = None


class LesionImageResponse(BaseModel):
    id: int
    url: str
    content_type: Optional[str] = None
    original_filename: Optional[str] = None
    created_at: datetime


class EvaluationPredictionResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    id: int
    label: str
    confidence: float
    probabilities: dict[str, float]
    model_version: str
    processing_time_ms: Optional[float] = None
    created_at: datetime


class LesionEvaluationResponse(BaseModel):
    id: int
    evaluated_at: datetime
    created_at: datetime
    clinical_observations: Optional[str] = None
    professional: EvaluationProfessionalResponse
    image: Optional[LesionImageResponse] = None
    prediction: Optional[EvaluationPredictionResponse] = None
    consent_attested_at: Optional[datetime] = None


class LesionDetailResponse(BaseModel):
    lesion: LesionResponse
    evaluations: list[LesionEvaluationResponse]
