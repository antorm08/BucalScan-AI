from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, get_workspace_access
from crud import get_daily_summary
from database import get_db
from models import models
from schemas import DailySummary

router = APIRouter(prefix="/api/v1/summary", tags=["summary"])


@router.get("/today", response_model=DailySummary)
async def get_today_dashboard_summary(
    access: WorkspaceAccess = Depends(get_workspace_access),
    db: Session = Depends(get_db),
):
    return get_daily_summary(db, workspace_id=access.workspace.id)
