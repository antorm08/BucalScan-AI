from pathlib import Path
from typing import List

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
from crud import get_all_analyses, get_user_analyses
from database import get_db
from models import models
from schemas import AnalysisHistory

router = APIRouter(prefix="/api/v1/history", tags=["history"])


@router.get("", response_model=List[AnalysisHistory])
async def get_history(
    request: Request,
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role == "admin":
        analyses = get_all_analyses(db, skip=skip, limit=limit)
    else:
        analyses = get_user_analyses(db, user_id=current_user.id, skip=skip, limit=limit)

    serialized = []
    for analysis in analyses:
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
            }
        )

    return serialized
