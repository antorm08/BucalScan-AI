from pydantic import BaseModel, ConfigDict, Field
from typing import Generic, Literal, Optional, TypeVar
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
    heatmap_url: Optional[str] = None
    notice: str = "AI decision support only; this result is not a diagnosis."
    priority: Optional["ClinicalPriorityResponse"] = None

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
    heatmap_url: Optional[str] = None
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
    lesion_site: Optional[str] = None
    evaluated_at: Optional[datetime] = None
    clinical_observations: Optional[str] = None
    professional_id: Optional[int] = None
    professional_name: Optional[str] = None
    professional_doctor_id: Optional[str] = None
    professional_profession: Optional[str] = None
    professional_specialty: Optional[str] = None
    priority: Optional["ClinicalPriorityResponse"] = None


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
    memberships: list["AdminMembershipDetailResponse"] = []


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
    medical_center: Optional[str] = None
    role: str
    profession: Optional[str] = None
    specialty: Optional[str] = None
    status: str
    created_at: Optional[datetime] = None


class AdminWorkspaceRequestResponse(BaseModel):
    id: int
    name: str
    workspace_type: str
    status: str
    city: Optional[str] = None
    address: Optional[str] = None
    tax_identifier: Optional[str] = None
    telephone: Optional[str] = None
    institutional_email: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by: Optional[AdminRequesterResponse] = None
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
    tax_identifier: Optional[str] = None
    telephone: Optional[str] = None
    institutional_email: Optional[str] = None


class AdminWorkspaceUpdate(BaseModel):
    city: str = Field(min_length=2, max_length=100)
    address: str = Field(min_length=3, max_length=255)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by_id: Optional[int] = None
    potential_duplicate: bool = False


class AdminMembershipRequestResponse(BaseModel):
    id: int
    status: str
    role: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by: Optional[AdminRequesterResponse] = None
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


class AdminMembershipDetailResponse(MembershipResponse):
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by_id: Optional[int] = None


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


class ClinicalCreatorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    full_name: str
    doctor_id: str
    profession: Optional[str] = None
    specialty: Optional[str] = None


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
    created_by: Optional[ClinicalCreatorResponse] = None


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
    observed_at: Optional[date] = None
    estimated_duration: Optional[str] = None


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
    created_by: Optional[ClinicalCreatorResponse] = None


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
    heatmap_url: Optional[str] = None
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
    priority: Optional["ClinicalPriorityResponse"] = None


class LesionDetailResponse(BaseModel):
    lesion: LesionResponse
    evaluations: list[LesionEvaluationResponse]


T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    page: int
    page_size: int
    total: int
    has_next: bool


class HistoryPage(PaginatedResponse[AnalysisHistory]):
    priority_filter_enabled: bool


TriState = Literal["true", "false", "unknown"]


class ClinicalAssessmentInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ulceration: Optional[TriState] = None
    induration_or_fixation: Optional[TriState] = None
    unexplained_bleeding: Optional[TriState] = None
    red_or_white_change: Optional[TriState] = None
    rapid_growth: Optional[TriState] = None
    pain: Optional[TriState] = None
    dysphagia: Optional[TriState] = None
    altered_sensation: Optional[TriState] = None
    functional_limitation: Optional[TriState] = None
    persistence_over_two_weeks: Optional[TriState] = None
    tobacco_exposure: Optional[TriState] = None
    heavy_alcohol_exposure: Optional[TriState] = None
    prior_oral_malignancy: Optional[TriState] = None
    immunosuppression: Optional[TriState] = None
    airway_compromise: Optional[TriState] = None
    uncontrolled_bleeding: Optional[TriState] = None
    inability_to_swallow: Optional[TriState] = None
    rapidly_progressing_face_neck_swelling: Optional[TriState] = None


class ClinicalPriorityResponse(BaseModel):
    id: Optional[int] = None
    assessment_id: Optional[int] = None
    status: Literal["available", "unavailable"] = "available"
    priority_code: Literal["incomplete", "standard", "prompt", "urgent", "emergency"]
    reason_codes: list[str]
    rendered_reasons: list[str]
    ruleset_id: str
    ruleset_version: str
    engine_version: str
    evaluated_at: Optional[datetime] = None
    completion_status: Literal["complete", "incomplete"]


class ClinicalPriorityCapability(BaseModel):
    mode: Literal["disabled", "academic", "enabled"]
    available: bool
    active_ruleset: Optional[str] = None
    assessment_schema_version: str
    engine_version: str
    notice: str


class AssessmentCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    evaluation_id: int
    assessment: ClinicalAssessmentInput
