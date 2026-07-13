from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from auth.workspace import WorkspaceAccess, get_workspace_access, require_clinical_professional
from database import get_db
from models import models
from routers.workspaces import normalize
from schemas import (
    LesionCreate,
    LesionDetailResponse,
    LesionResponse,
    LesionStatusUpdate,
    LesionUpdate,
    PatientCreate,
    PatientResponse,
)

router = APIRouter(prefix="/api/v1", tags=["clinical"])


@router.get("/patients", response_model=list[PatientResponse])
def search_patients(q: str = Query("", max_length=100), access: WorkspaceAccess = Depends(get_workspace_access), db: Session = Depends(get_db)):
    query = db.query(models.Patient).filter(models.Patient.workspace_id == access.workspace.id)
    if q.strip():
        normalized = normalize(q)
        query = query.filter(or_(
            models.Patient.clinical_code.ilike(f"%{q.strip()}%"),
            models.Patient.identity_document.ilike(f"%{q.strip()}%"),
            models.Patient.normalized_name.contains(normalized),
        ))
    return query.order_by(models.Patient.full_name).limit(50).all()


@router.post("/patients", response_model=PatientResponse, status_code=201)
def create_patient(payload: PatientCreate, access: WorkspaceAccess = Depends(require_clinical_professional), db: Session = Depends(get_db)):
    exact = db.query(models.Patient).filter(
        models.Patient.workspace_id == access.workspace.id,
        or_(
            models.Patient.clinical_code == payload.clinical_code,
            models.Patient.identity_document == payload.identity_document if payload.identity_document else False,
        ),
    ).first()
    if exact:
        raise HTTPException(status_code=409, detail={"message": "Patient identifier already exists.", "patient_id": exact.id})
    potential = db.query(models.Patient).filter_by(
        workspace_id=access.workspace.id, normalized_name=normalize(payload.full_name)
    ).all()
    if potential and not payload.allow_potential_duplicate:
        raise HTTPException(status_code=409, detail={"message": "Potential duplicate patient.", "patient_ids": [p.id for p in potential]})
    data = payload.model_dump(exclude={"allow_potential_duplicate"})
    patient = models.Patient(**data, workspace_id=access.workspace.id, normalized_name=normalize(payload.full_name), created_by_id=access.user.id)
    db.add(patient)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Patient identifier already exists.") from exc
    db.refresh(patient)
    return patient


def _patient(db: Session, workspace_id: int, patient_id: int) -> models.Patient:
    patient = db.query(models.Patient).filter_by(id=patient_id, workspace_id=workspace_id).first()
    if patient is None:
        raise HTTPException(status_code=404, detail="Patient not found.")
    return patient


@router.get("/patients/{patient_id}", response_model=PatientResponse)
def get_patient(patient_id: int, access: WorkspaceAccess = Depends(get_workspace_access), db: Session = Depends(get_db)):
    return _patient(db, access.workspace.id, patient_id)


@router.post("/patients/{patient_id}/lesions", response_model=LesionResponse, status_code=201)
def create_lesion(patient_id: int, payload: LesionCreate, access: WorkspaceAccess = Depends(require_clinical_professional), db: Session = Depends(get_db)):
    _patient(db, access.workspace.id, patient_id)
    if payload.observed_at is None and not payload.estimated_duration:
        raise HTTPException(status_code=422, detail="observed_at or estimated_duration is required.")
    lesion = models.OralLesion(**payload.model_dump(), workspace_id=access.workspace.id, patient_id=patient_id, created_by_id=access.user.id)
    db.add(lesion)
    db.commit()
    db.refresh(lesion)
    return lesion


@router.get("/patients/{patient_id}/lesions", response_model=list[LesionResponse])
def list_lesions(patient_id: int, access: WorkspaceAccess = Depends(get_workspace_access), db: Session = Depends(get_db)):
    _patient(db, access.workspace.id, patient_id)
    return db.query(models.OralLesion).filter_by(patient_id=patient_id, workspace_id=access.workspace.id).order_by(models.OralLesion.created_at).all()


@router.get("/lesions/{lesion_id}", response_model=LesionDetailResponse)
def lesion_detail(lesion_id: int, request: Request, access: WorkspaceAccess = Depends(get_workspace_access), db: Session = Depends(get_db)):
    lesion = db.query(models.OralLesion).options(
        joinedload(models.OralLesion.evaluations).joinedload(models.ClinicalEvaluation.image),
        joinedload(models.OralLesion.evaluations).joinedload(models.ClinicalEvaluation.prediction),
        joinedload(models.OralLesion.evaluations).joinedload(models.ClinicalEvaluation.consent_attestation),
        joinedload(models.OralLesion.evaluations)
        .joinedload(models.ClinicalEvaluation.assessment_snapshot)
        .joinedload(models.ClinicalAssessmentSnapshot.priority_result),
    ).filter_by(id=lesion_id, workspace_id=access.workspace.id).first()
    if lesion is None:
        raise HTTPException(status_code=404, detail="Lesion not found.")

    professional_ids = {item.professional_id for item in lesion.evaluations}
    professionals = {
        user.id: user
        for user in db.query(models.User).filter(models.User.id.in_(professional_ids)).all()
    } if professional_ids else {}

    evaluations = []
    for item in sorted(lesion.evaluations, key=lambda value: (value.evaluated_at, value.id)):
        professional = professionals[item.professional_id]
        image = None
        if item.image:
            image_url = item.image.storage_url
            if not image_url.startswith(("http://", "https://")):
                image_url = str(request.url_for("uploads", path=Path(image_url).name))
            image = {
                "id": item.image.id,
                "url": image_url,
                "content_type": item.image.content_type,
                "original_filename": item.image.original_filename,
                "created_at": item.image.created_at,
            }
        prediction = None
        if item.prediction:
            prediction = {
                "id": item.prediction.id,
                "label": item.prediction.predicted_label,
                "confidence": item.prediction.confidence,
                "probabilities": {
                    "benign": item.prediction.benign_probability,
                    "malignant": item.prediction.malignant_probability,
                },
                "model_version": item.prediction.model_version,
                "processing_time_ms": item.prediction.processing_time_ms,
                "created_at": item.prediction.created_at,
            }
        evaluations.append({
            "id": item.id,
            "evaluated_at": item.evaluated_at,
            "created_at": item.created_at,
            "clinical_observations": item.clinical_observations,
            "professional": {
                "id": professional.id,
                "full_name": professional.full_name,
                "doctor_id": professional.doctor_id,
                "profession": professional.profession,
                "specialty": professional.specialty,
            },
            "image": image,
            "prediction": prediction,
            "consent_attested_at": item.consent_attestation.attested_at if item.consent_attestation else None,
            "priority": (
                {
                    "id": item.assessment_snapshot.priority_result.id,
                    "assessment_id": item.assessment_snapshot.id,
                    "priority_code": item.assessment_snapshot.priority_result.priority_code,
                    "reason_codes": item.assessment_snapshot.priority_result.reason_codes,
                    "rendered_reasons": item.assessment_snapshot.priority_result.rendered_reasons,
                    "ruleset_id": item.assessment_snapshot.priority_result.ruleset_id,
                    "ruleset_version": item.assessment_snapshot.priority_result.ruleset_version,
                    "engine_version": item.assessment_snapshot.priority_result.engine_version,
                    "evaluated_at": item.assessment_snapshot.priority_result.evaluated_at,
                    "completion_status": item.assessment_snapshot.completion_status,
                }
                if item.assessment_snapshot and item.assessment_snapshot.priority_result else None
            ),
        })
    return {"lesion": lesion, "evaluations": evaluations}


def _update_lesion(lesion_id: int, payload: LesionUpdate, access: WorkspaceAccess, db: Session):
    lesion = db.query(models.OralLesion).filter_by(id=lesion_id, workspace_id=access.workspace.id).first()
    if lesion is None:
        raise HTTPException(status_code=404, detail="Lesion not found.")
    supplied = payload.model_fields_set
    if not supplied:
        raise HTTPException(status_code=422, detail="At least one lesion field is required.")
    if "status" in supplied:
        if payload.status is None:
            raise HTTPException(status_code=422, detail="status cannot be null.")
        lesion.status = payload.status
    if "clinical_notes" in supplied:
        lesion.clinical_notes = payload.clinical_notes
    if "observed_at" in supplied:
        lesion.observed_at = payload.observed_at
    if "estimated_duration" in supplied:
        lesion.estimated_duration = payload.estimated_duration
    if lesion.observed_at is None and not lesion.estimated_duration:
        raise HTTPException(status_code=422, detail="observed_at or estimated_duration is required.")
    db.commit()
    db.refresh(lesion)
    return lesion


@router.patch("/lesions/{lesion_id}", response_model=LesionResponse)
def update_lesion(lesion_id: int, payload: LesionUpdate, access: WorkspaceAccess = Depends(require_clinical_professional), db: Session = Depends(get_db)):
    return _update_lesion(lesion_id, payload, access, db)


@router.patch("/lesions/{lesion_id}/status", response_model=LesionResponse)
def update_lesion_status(lesion_id: int, payload: LesionStatusUpdate, access: WorkspaceAccess = Depends(require_clinical_professional), db: Session = Depends(get_db)):
    return _update_lesion(lesion_id, LesionUpdate(status=payload.status), access, db)
