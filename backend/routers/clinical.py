from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, get_workspace_access, require_clinical_professional
from database import get_db
from models import models
from routers.workspaces import normalize
from schemas import LesionCreate, LesionResponse, LesionStatusUpdate, PatientCreate, PatientResponse

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


@router.get("/lesions/{lesion_id}")
def lesion_detail(lesion_id: int, access: WorkspaceAccess = Depends(get_workspace_access), db: Session = Depends(get_db)):
    lesion = db.query(models.OralLesion).filter_by(id=lesion_id, workspace_id=access.workspace.id).first()
    if lesion is None:
        raise HTTPException(status_code=404, detail="Lesion not found.")
    return {"lesion": LesionResponse.model_validate(lesion), "evaluations": [
        {"id": item.id, "evaluated_at": item.evaluated_at, "professional_id": item.professional_id,
         "prediction": item.prediction.predicted_label if item.prediction else None}
        for item in lesion.evaluations
    ]}


@router.patch("/lesions/{lesion_id}/status", response_model=LesionResponse)
def update_lesion_status(lesion_id: int, payload: LesionStatusUpdate, access: WorkspaceAccess = Depends(require_clinical_professional), db: Session = Depends(get_db)):
    lesion = db.query(models.OralLesion).filter_by(id=lesion_id, workspace_id=access.workspace.id).first()
    if lesion is None:
        raise HTTPException(status_code=404, detail="Lesion not found.")
    lesion.status = payload.status
    db.commit()
    db.refresh(lesion)
    return lesion
