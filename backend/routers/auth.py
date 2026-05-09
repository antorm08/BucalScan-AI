from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import create_user, get_user_by_email
from database import get_db
from models import models
from schemas import UserCreate, UserLogin, UserProfile

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    existing_doctor = db.query(models.User).filter(models.User.doctor_id == user.doctor_id).first()
    if existing_doctor:
        raise HTTPException(status_code=400, detail="Doctor ID already registered")

    created_user = create_user(db=db, user=user)
    return {
        "success": True,
        "message": "User registered successfully",
        "data": {
            "user": UserProfile.model_validate(created_user).model_dump()
        }
    }


@router.post("/login")
async def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "user": UserProfile.model_validate(db_user).model_dump(),
            "token": None,
        }
    }
