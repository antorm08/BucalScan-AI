from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from auth.workspace import WorkspaceAccess, get_workspace_access, require_clinical_professional
from config import settings
from database import get_db
from models import models
from schemas import AssessmentCreate, ClinicalPriorityCapability, ClinicalPriorityResponse
from services.clinical_priority import (
    ASSESSMENT_SCHEMA_VERSION,
    ENGINE_VERSION,
    RULESET_ID,
    RULESET_VERSION,
    canonicalize,
    evaluate_priority,
    result_dict,
)

router = APIRouter(prefix="/api/v1/clinical-priority", tags=["clinical-priority"])


def priority_mode() -> str:
    mode = settings.clinical_priority_mode
    if mode not in {"disabled", "academic", "enabled"}:
        return "disabled"
    if settings.clinical_priority_ruleset != RULESET_VERSION:
        return "disabled"
    return mode


def require_priority_available() -> None:
    if priority_mode() == "disabled":
        raise HTTPException(status_code=503, detail="Clinical priority support is unavailable.")


def persist_priority(db: Session, evaluation: models.ClinicalEvaluation, assessor_id: int, assessment):
    require_priority_available()
    canonical = canonicalize(assessment)
    evaluated = evaluate_priority(canonical)
    now = datetime.now(UTC).replace(tzinfo=None)
    snapshot = models.ClinicalAssessmentSnapshot(
        workspace_id=evaluation.workspace_id,
        patient_id=evaluation.patient_id,
        lesion_id=evaluation.lesion_id,
        evaluation_id=evaluation.id,
        assessor_id=assessor_id,
        schema_version=ASSESSMENT_SCHEMA_VERSION,
        ruleset_version=RULESET_VERSION,
        canonical_payload=canonical,
        completion_status=evaluated.completion_status,
        assessed_at=now,
    )
    db.add(snapshot)
    db.flush()
    result = models.ClinicalPriorityResult(
        assessment_id=snapshot.id,
        workspace_id=evaluation.workspace_id,
        evaluation_id=evaluation.id,
        priority_code=evaluated.priority_code,
        reason_codes=list(evaluated.reason_codes),
        rendered_reasons=list(evaluated.rendered_reasons),
        ruleset_id=RULESET_ID,
        ruleset_version=RULESET_VERSION,
        engine_version=ENGINE_VERSION,
        evaluated_at=now,
    )
    db.add(result)
    db.flush()
    return result, snapshot


@router.get("/capabilities", response_model=ClinicalPriorityCapability)
def capabilities():
    mode = priority_mode()
    return {
        "mode": mode,
        "available": mode != "disabled",
        "active_ruleset": RULESET_VERSION if mode != "disabled" else None,
        "assessment_schema_version": ASSESSMENT_SCHEMA_VERSION,
        "engine_version": ENGINE_VERSION,
        "notice": "Separate non-diagnostic academic decision support; not a cancer probability or replacement for professional judgment.",
    }


@router.post("/assessments", response_model=ClinicalPriorityResponse, status_code=201)
def create_assessment(
    payload: AssessmentCreate,
    access: WorkspaceAccess = Depends(require_clinical_professional),
    db: Session = Depends(get_db),
):
    evaluation = db.query(models.ClinicalEvaluation).filter_by(
        id=payload.evaluation_id, workspace_id=access.workspace.id
    ).with_for_update().first()
    if evaluation is None:
        raise HTTPException(status_code=404, detail="Evaluation not found in active workspace.")
    if db.query(models.ClinicalAssessmentSnapshot.id).filter_by(evaluation_id=evaluation.id).first():
        raise HTTPException(status_code=409, detail="This evaluation already has an assessment.")
    try:
        result, snapshot = persist_priority(db, evaluation, access.user.id, payload.assessment)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="This evaluation already has an assessment.") from exc
    db.refresh(result)
    return result_dict(result, snapshot.completion_status)


@router.get("/evaluations/{evaluation_id}", response_model=ClinicalPriorityResponse)
def get_evaluation_priority(
    evaluation_id: int,
    access: WorkspaceAccess = Depends(get_workspace_access),
    db: Session = Depends(get_db),
):
    result = db.query(models.ClinicalPriorityResult).options(
        joinedload(models.ClinicalPriorityResult.assessment)
    ).filter_by(evaluation_id=evaluation_id, workspace_id=access.workspace.id).first()
    if result is None:
        raise HTTPException(status_code=404, detail="Priority result not found.")
    return result_dict(result)
