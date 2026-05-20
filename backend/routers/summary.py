from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from crud import get_today_summary
from database import get_db
from schemas import DailySummary

router = APIRouter(prefix="/api/v1/summary", tags=["summary"])


@router.get("/today/{user_id}", response_model=DailySummary)
async def get_today_dashboard_summary(
    user_id: int,
    db: Session = Depends(get_db),
):
    return get_today_summary(db, user_id=user_id)
