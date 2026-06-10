from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
import crud
from database import get_db
from models import models
from schemas import UserAdminResponse, UserStatusUpdate

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@router.get("/users", response_model=List[UserAdminResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    # TODO: Require admin role here
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return crud.get_all_users(db, skip=skip, limit=limit)


@router.get("/users/{user_id}", response_model=UserAdminResponse)
async def get_user(
    user_id: int,
    # TODO: Require admin role here
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = crud.get_user(db, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


@router.patch("/users/{user_id}/status", response_model=UserAdminResponse)
async def update_user_status(
    user_id: int,
    payload: UserStatusUpdate,
    # TODO: Require admin role here
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = crud.update_user_status(db, user_id=user_id, status=payload.status)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    return user
