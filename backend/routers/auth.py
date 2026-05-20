from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.jwt import create_access_token, get_current_user
from auth.security import verify_password
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
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    token = create_access_token(
        data={"sub": str(db_user.id), "email": db_user.email}
    )

    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "user": UserProfile.model_validate(db_user).model_dump(),
            "token": token,
        }
    }


@router.get("/me")
async def me(current_user: models.User = Depends(get_current_user)):
    return {
        "success": True,
        "data": {
            "user": UserProfile.model_validate(current_user).model_dump()
        }
    }
