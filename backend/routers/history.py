from datetime import UTC, datetime
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import asc, desc, func, or_
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, get_workspace_access
from config import settings
from database import get_db
from models import models
from routers.workspaces import normalize
from schemas import HistoryPage

router = APIRouter(prefix="/api/v1/history", tags=["history"])


def _utc_naive(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        raise HTTPException(status_code=422, detail="History date boundaries must include a UTC offset.")
    return value.astimezone(UTC).replace(tzinfo=None)


def _as_utc(value: datetime | None) -> datetime | None:
    return value.replace(tzinfo=UTC) if value is not None and value.tzinfo is None else value


@router.get("", response_model=HistoryPage)
async def get_history(
    request: Request,
    search: str = Query("", max_length=100),
    model_label: Literal["benign", "malignant"] | None = None,
    priority: Literal["incomplete", "standard", "prompt", "urgent", "emergency"] | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    sort_by: Literal["evaluated_at", "confidence", "patient_name", "model_version", "lesion_site"] = "evaluated_at",
    sort_direction: Literal["asc", "desc"] = "desc",
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    access: WorkspaceAccess = Depends(get_workspace_access),
    db: Session = Depends(get_db),
):
    start = _utc_naive(date_from)
    end = _utc_naive(date_to)
    if start is not None and end is not None and start > end:
        raise HTTPException(status_code=422, detail="History date_from must not be after date_to.")
    priority_enabled = settings.clinical_priority_mode in {"academic", "enabled"}
    if priority is not None and not priority_enabled:
        raise HTTPException(status_code=422, detail="Clinical priority filtering is unavailable.")

    query = db.query(
        models.ClinicalEvaluation,
        models.Patient,
        models.OralLesion,
        models.User,
        models.ModelPrediction,
        models.LesionImage,
        models.ClinicalPriorityResult,
        models.ClinicalAssessmentSnapshot,
    ).join(
        models.Patient,
        models.Patient.id == models.ClinicalEvaluation.patient_id,
    ).join(
        models.OralLesion,
        models.OralLesion.id == models.ClinicalEvaluation.lesion_id,
    ).join(
        models.User,
        models.User.id == models.ClinicalEvaluation.professional_id,
    ).join(
        models.ModelPrediction,
        models.ModelPrediction.evaluation_id == models.ClinicalEvaluation.id,
    ).join(
        models.LesionImage,
        models.LesionImage.id == models.ModelPrediction.image_id,
    ).outerjoin(
        models.ClinicalPriorityResult,
        models.ClinicalPriorityResult.evaluation_id == models.ClinicalEvaluation.id,
    ).outerjoin(
        models.ClinicalAssessmentSnapshot,
        models.ClinicalAssessmentSnapshot.id == models.ClinicalPriorityResult.assessment_id,
    ).filter(
        models.ClinicalEvaluation.workspace_id == access.workspace.id,
        models.Patient.workspace_id == access.workspace.id,
        models.OralLesion.workspace_id == access.workspace.id,
    )

    if search.strip():
        raw_term = f"%{search.strip().lower()}%"
        normalized_search = normalize(search)
        normalized_term = f"%{normalized_search}%"
        patient_ids = [
            row.id for row in db.query(models.Patient).filter(
                models.Patient.workspace_id == access.workspace.id,
            ).all()
            if normalized_search in normalize(" ".join(filter(None, (
                row.full_name, row.clinical_code, row.identity_document,
            ))))
        ]
        lesion_ids = [
            row.id for row in db.query(models.OralLesion).filter(
                models.OralLesion.workspace_id == access.workspace.id,
            ).all()
            if normalized_search in normalize(row.anatomical_site)
        ]
        professional_ids = [
            row.id for row in db.query(models.User).join(
                models.ClinicalEvaluation,
                models.ClinicalEvaluation.professional_id == models.User.id,
            ).filter(
                models.ClinicalEvaluation.workspace_id == access.workspace.id,
            ).distinct().all()
            if normalized_search in normalize(" ".join(filter(None, (
                row.full_name, row.doctor_id, row.profession, row.specialty,
            ))))
        ]
        query = query.filter(or_(
            models.Patient.id.in_(patient_ids),
            models.OralLesion.id.in_(lesion_ids),
            models.User.id.in_(professional_ids),
            models.Patient.normalized_name.ilike(normalized_term),
            func.lower(models.Patient.clinical_code).like(raw_term),
            func.lower(models.OralLesion.anatomical_site).like(raw_term),
            func.lower(models.User.full_name).like(raw_term),
            func.lower(models.User.doctor_id).like(raw_term),
            func.lower(models.User.profession).like(raw_term),
            func.lower(models.User.specialty).like(raw_term),
        ))
    if model_label is not None:
        query = query.filter(func.lower(models.ModelPrediction.predicted_label) == model_label)
    if priority is not None:
        query = query.filter(models.ClinicalPriorityResult.priority_code == priority)
    if start is not None:
        query = query.filter(models.ClinicalEvaluation.evaluated_at >= start)
    if end is not None:
        query = query.filter(models.ClinicalEvaluation.evaluated_at <= end)

    sort_columns = {
        "evaluated_at": models.ClinicalEvaluation.evaluated_at,
        "confidence": models.ModelPrediction.confidence,
        "patient_name": models.Patient.normalized_name,
        "model_version": models.ModelPrediction.model_version,
        "lesion_site": models.OralLesion.anatomical_site,
    }
    direction = desc if sort_direction == "desc" else asc
    query = query.order_by(direction(sort_columns[sort_by]), direction(models.ClinicalEvaluation.id))
    total = query.order_by(None).count()
    rows = query.offset((page - 1) * page_size).limit(page_size).all()

    serialized = []
    for evaluation, patient, lesion, professional, prediction, image, priority_result, snapshot in rows:
        image_url = None
        if image.storage_url:
            if image.storage_url.startswith(("http://", "https://")):
                image_url = image.storage_url
            else:
                filename = Path(image.storage_url).name
                image_url = str(request.url_for("uploads", path=filename))
        heatmap_url = None
        if prediction and prediction.heatmap_url:
            if prediction.heatmap_url.startswith(("http://", "https://")):
                heatmap_url = prediction.heatmap_url
            else:
                filename = Path(prediction.heatmap_url).name
                heatmap_url = str(request.url_for("uploads", path=filename))

        serialized.append(
            {
                "id": evaluation.id,
                "prediction": prediction.predicted_label,
                "confidence": prediction.confidence,
                "timestamp": _as_utc(prediction.created_at),
                "image_url": image_url,
                "heatmap_url": heatmap_url,
                "patient_id": patient.clinical_code,
                "patient_name": patient.full_name,
                "model_version": prediction.model_version,
                "processing_time_ms": prediction.processing_time_ms,
                "created_by_id": professional.id,
                "created_by_name": professional.full_name,
                "created_by_email": professional.email,
                "created_by_doctor_id": professional.doctor_id,
                "evaluation_id": evaluation.id,
                "patient_record_id": patient.id,
                "lesion_id": lesion.id,
                "lesion_site": lesion.anatomical_site,
                "evaluated_at": _as_utc(evaluation.evaluated_at),
                "clinical_observations": evaluation.clinical_observations,
                "professional_id": professional.id,
                "professional_name": professional.full_name,
                "professional_doctor_id": professional.doctor_id,
                "professional_profession": professional.profession,
                "professional_specialty": professional.specialty,
                "priority": ({
                    "id": priority_result.id,
                    "assessment_id": snapshot.id,
                    "priority_code": priority_result.priority_code,
                    "reason_codes": priority_result.reason_codes,
                    "rendered_reasons": priority_result.rendered_reasons,
                    "ruleset_id": priority_result.ruleset_id,
                    "ruleset_version": priority_result.ruleset_version,
                    "engine_version": priority_result.engine_version,
                    "evaluated_at": _as_utc(priority_result.evaluated_at),
                    "completion_status": snapshot.completion_status,
                } if priority_result and snapshot else None),
            }
        )

    return {
        "items": serialized,
        "page": page,
        "page_size": page_size,
        "total": total,
        "has_next": page * page_size < total,
        "priority_filter_enabled": priority_enabled,
    }
