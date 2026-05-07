from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from crud import get_user_analyses
from database import get_db
from schemas import AnalysisHistory

router = APIRouter(prefix="/api/v1/history", tags=["history"])


@router.get("/{user_id}", response_model=List[AnalysisHistory])
async def get_history(
    user_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    return get_user_analyses(db, user_id=user_id, skip=skip, limit=limit)
