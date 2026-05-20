from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
from crud import get_today_summary
from database import get_db
from models import models
from schemas import DailySummary

router = APIRouter(prefix="/api/v1/summary", tags=["summary"])


@router.get("/today", response_model=DailySummary)
async def get_today_dashboard_summary(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_today_summary(db, user_id=current_user.id)
