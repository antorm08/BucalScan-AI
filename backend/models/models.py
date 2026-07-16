from datetime import UTC, datetime

from sqlalchemy import (
    Boolean, Column, Date, DateTime, Float, ForeignKey, Index, Integer,
    JSON, String, Text, UniqueConstraint,
)
from sqlalchemy.orm import relationship

from database import Base


def _utcnow_naive():
    return datetime.now(UTC).replace(tzinfo=None)

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    doctor_id = Column(String, unique=True, index=True, nullable=False)
    medical_center = Column(String, nullable=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=_utcnow_naive)
    status = Column(String, default="active", nullable=False)
    role = Column(String, default="doctor", nullable=False)
    profession = Column(String, nullable=True)
    specialty = Column(String, nullable=True)

    analyses = relationship("Analysis", back_populates="owner")
    memberships = relationship("WorkspaceMembership", foreign_keys="WorkspaceMembership.user_id", back_populates="user")

class Analysis(Base):
    __tablename__ = "analyses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    prediction = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    image_path = Column(String, nullable=True)
    patient_id = Column(String, nullable=True)
    patient_name = Column(String, nullable=True)
    timestamp = Column(DateTime, default=_utcnow_naive)
    model_version = Column(String, nullable=True)
    processing_time_ms = Column(Float, nullable=True)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id"), nullable=True, unique=True)
    
    owner = relationship("User", back_populates="analyses")


class ClinicalWorkspace(Base):
    __tablename__ = "clinical_workspaces"
    __table_args__ = (
        Index("ix_workspaces_normalized_name", "normalized_name"),
        UniqueConstraint("tax_identifier", name="uq_workspace_tax_identifier"),
    )

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    normalized_name = Column(String, nullable=False)
    workspace_type = Column(String, nullable=False)
    status = Column(String, nullable=False, default="pending")
    city = Column(String, nullable=True)
    address = Column(String, nullable=True)
    tax_identifier = Column(String, nullable=True)
    telephone = Column(String, nullable=True)
    institutional_email = Column(String, nullable=True)
    initial_requester_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    updated_at = Column(DateTime, nullable=False, default=_utcnow_naive, onupdate=_utcnow_naive)

    memberships = relationship("WorkspaceMembership", back_populates="workspace", cascade="all, delete-orphan")
    patients = relationship("Patient", back_populates="workspace")


class WorkspaceMembership(Base):
    __tablename__ = "workspace_memberships"
    __table_args__ = (UniqueConstraint("workspace_id", "user_id", name="uq_workspace_member"),)

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    role = Column(String, nullable=False, default="professional")
    status = Column(String, nullable=False, default="pending")
    approved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    updated_at = Column(DateTime, nullable=False, default=_utcnow_naive, onupdate=_utcnow_naive)

    workspace = relationship("ClinicalWorkspace", back_populates="memberships", foreign_keys=[workspace_id])
    user = relationship("User", back_populates="memberships", foreign_keys=[user_id])


class Patient(Base):
    __tablename__ = "patients"
    __table_args__ = (
        UniqueConstraint("workspace_id", "clinical_code", name="uq_patient_workspace_code"),
        UniqueConstraint("workspace_id", "identity_document", name="uq_patient_workspace_identity"),
        Index("ix_patients_workspace_normalized_name", "workspace_id", "normalized_name"),
    )

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id"), nullable=False, index=True)
    clinical_code = Column(String, nullable=False)
    identity_document = Column(String, nullable=True)
    full_name = Column(String, nullable=False)
    normalized_name = Column(String, nullable=False)
    birth_date = Column(Date, nullable=True)
    sex = Column(String, nullable=True)
    telephone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    is_legacy_anonymous = Column(Boolean, nullable=False, default=False)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    updated_at = Column(DateTime, nullable=False, default=_utcnow_naive, onupdate=_utcnow_naive)

    workspace = relationship("ClinicalWorkspace", back_populates="patients")
    lesions = relationship("OralLesion", back_populates="patient")
    created_by = relationship("User", foreign_keys=[created_by_id])


class OralLesion(Base):
    __tablename__ = "oral_lesions"

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id"), nullable=False, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True)
    anatomical_site = Column(String, nullable=False)
    observed_at = Column(Date, nullable=True)
    estimated_duration = Column(String, nullable=True)
    status = Column(String, nullable=False, default="active")
    clinical_notes = Column(Text, nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    updated_at = Column(DateTime, nullable=False, default=_utcnow_naive, onupdate=_utcnow_naive)

    patient = relationship("Patient", back_populates="lesions")
    evaluations = relationship("ClinicalEvaluation", back_populates="lesion", order_by="ClinicalEvaluation.evaluated_at")
    created_by = relationship("User", foreign_keys=[created_by_id])


class ClinicalEvaluation(Base):
    __tablename__ = "clinical_evaluations"

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id"), nullable=False, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    lesion_id = Column(Integer, ForeignKey("oral_lesions.id"), nullable=False, index=True)
    professional_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    clinical_observations = Column(Text, nullable=True)
    evaluated_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    lesion = relationship("OralLesion", back_populates="evaluations")
    image = relationship("LesionImage", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    prediction = relationship("ModelPrediction", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    consent_attestation = relationship("ConsentAttestation", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    assessment_snapshot = relationship("ClinicalAssessmentSnapshot", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")


class LesionImage(Base):
    __tablename__ = "lesion_images"

    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False, unique=True)
    storage_url = Column(String, nullable=False)
    content_type = Column(String, nullable=True)
    original_filename = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    evaluation = relationship("ClinicalEvaluation", back_populates="image")


class ModelPrediction(Base):
    __tablename__ = "model_predictions"

    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False, unique=True)
    image_id = Column(Integer, ForeignKey("lesion_images.id"), nullable=False)
    model_version = Column(String, nullable=False)
    predicted_label = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    benign_probability = Column(Float, nullable=False)
    malignant_probability = Column(Float, nullable=False)
    processing_time_ms = Column(Float, nullable=True)
    heatmap_url = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    evaluation = relationship("ClinicalEvaluation", back_populates="prediction")


class ConsentAttestation(Base):
    __tablename__ = "consent_attestations"

    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False, unique=True)
    professional_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    authorization_obtained = Column(Boolean, nullable=False)
    attested_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    evaluation = relationship("ClinicalEvaluation", back_populates="consent_attestation")


class ClinicalAssessmentSnapshot(Base):
    __tablename__ = "clinical_assessment_snapshots"
    __table_args__ = (
        UniqueConstraint("evaluation_id", name="uq_assessment_evaluation"),
        Index("ix_assessments_workspace_assessed", "workspace_id", "assessed_at"),
        Index("ix_assessments_lesion", "lesion_id"),
    )

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id"), nullable=False)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    lesion_id = Column(Integer, ForeignKey("oral_lesions.id"), nullable=False)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False)
    assessor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    schema_version = Column(String, nullable=False)
    ruleset_version = Column(String, nullable=False)
    canonical_payload = Column(JSON, nullable=False)
    completion_status = Column(String, nullable=False)
    assessed_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    evaluation = relationship("ClinicalEvaluation", back_populates="assessment_snapshot")
    priority_result = relationship("ClinicalPriorityResult", back_populates="assessment", uselist=False, cascade="all, delete-orphan")


class ClinicalPriorityResult(Base):
    __tablename__ = "clinical_priority_results"
    __table_args__ = (
        UniqueConstraint("assessment_id", name="uq_priority_assessment"),
        UniqueConstraint("evaluation_id", name="uq_priority_evaluation"),
        Index("ix_priority_workspace_evaluated", "workspace_id", "evaluated_at"),
        Index("ix_priority_code", "priority_code"),
    )

    id = Column(Integer, primary_key=True)
    assessment_id = Column(Integer, ForeignKey("clinical_assessment_snapshots.id", ondelete="CASCADE"), nullable=False)
    workspace_id = Column(Integer, ForeignKey("clinical_workspaces.id"), nullable=False)
    evaluation_id = Column(Integer, ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False)
    priority_code = Column(String, nullable=False)
    reason_codes = Column(JSON, nullable=False)
    rendered_reasons = Column(JSON, nullable=False)
    ruleset_id = Column(String, nullable=False)
    ruleset_version = Column(String, nullable=False)
    engine_version = Column(String, nullable=False)
    evaluated_at = Column(DateTime, nullable=False, default=_utcnow_naive)
    created_at = Column(DateTime, nullable=False, default=_utcnow_naive)

    assessment = relationship("ClinicalAssessmentSnapshot", back_populates="priority_result")
