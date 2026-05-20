from pathlib import Path
from typing import List

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from crud import get_user_analyses
from database import get_db
from schemas import AnalysisHistory

router = APIRouter(prefix="/api/v1/history", tags=["history"])


@router.get("/{user_id}", response_model=List[AnalysisHistory])
async def get_history(
    request: Request,
    user_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    analyses = get_user_analyses(db, user_id=user_id, skip=skip, limit=limit)

    serialized = []
    for analysis in analyses:
        image_url = None
        if analysis.image_path:
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
            }
        )

    return serialized
