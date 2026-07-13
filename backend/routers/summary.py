from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
from crud import get_daily_summary
from database import get_db
from models import models
from schemas import DailySummary

router = APIRouter(prefix="/api/v1/summary", tags=["summary"])


@router.get("/today", response_model=DailySummary)
async def get_today_dashboard_summary(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_id = None if current_user.role == "admin" else current_user.id
    return get_daily_summary(db, user_id=user_id)
