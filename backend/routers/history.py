from pathlib import Path
from typing import List

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, get_workspace_access
from crud import get_workspace_analyses
from database import get_db
from models import models
from schemas import AnalysisHistory

router = APIRouter(prefix="/api/v1/history", tags=["history"])


@router.get("", response_model=List[AnalysisHistory])
async def get_history(
    request: Request,
    skip: int = 0,
    limit: int = 100,
    access: WorkspaceAccess = Depends(get_workspace_access),
    db: Session = Depends(get_db),
):
    analyses = get_workspace_analyses(db, access.workspace.id, skip=skip, limit=limit)
    evaluation_ids = [item.evaluation_id for item in analyses if item.evaluation_id is not None]
    evaluations = {
        item.id: item
        for item in db.query(models.ClinicalEvaluation).filter(
            models.ClinicalEvaluation.workspace_id == access.workspace.id,
            models.ClinicalEvaluation.id.in_(evaluation_ids),
        ).all()
    } if evaluation_ids else {}

    serialized = []
    for analysis in analyses:
        evaluation = evaluations.get(analysis.evaluation_id)
        image_url = None
        if analysis.image_path:
            if analysis.image_path.startswith(("http://", "https://")):
                image_url = analysis.image_path
            else:
                filename = Path(analysis.image_path).name
                image_url = str(request.url_for("uploads", path=filename))

        serialized.append(
            {
                "id": analysis.id,
                "prediction": analysis.prediction,
                "confidence": analysis.confidence,
                "timestamp": analysis.timestamp,
                "image_url": image_url,
                "patient_id": analysis.patient_id,
                "patient_name": analysis.patient_name,
                "model_version": analysis.model_version,
                "processing_time_ms": analysis.processing_time_ms,
                "created_by_id": analysis.owner.id if analysis.owner else None,
                "created_by_name": analysis.owner.full_name if analysis.owner else None,
                "created_by_email": analysis.owner.email if analysis.owner else None,
                "created_by_doctor_id": analysis.owner.doctor_id if analysis.owner else None,
                "evaluation_id": analysis.evaluation_id,
                "patient_record_id": evaluation.patient_id if evaluation else None,
                "lesion_id": evaluation.lesion_id if evaluation else None,
            }
        )

    return serialized
