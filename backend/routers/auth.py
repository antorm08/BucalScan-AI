from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.jwt import create_access_token, get_current_user
from auth.security import verify_password
import crud
from database import get_db
from models import models
from schemas import UserCreate, UserLogin, UserProfile, UserUpdate
from routers.workspaces import normalize

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    existing_doctor = db.query(models.User).filter(models.User.doctor_id == user.doctor_id).first()
    if existing_doctor:
        raise HTTPException(status_code=400, detail="Doctor ID already registered")

    if user.workspace_choice == "existing":
        workspace = db.query(models.ClinicalWorkspace).filter_by(
            id=user.workspace_id, status="active"
        ).first()
        if workspace is None:
            raise HTTPException(status_code=400, detail="Active workspace not found")
    elif user.workspace_choice == "new" and not (user.workspace_name or "").strip():
        raise HTTPException(status_code=400, detail="Workspace name is required")

    created_user = crud.create_user(db=db, user=user, commit=False)

    if user.workspace_choice == "existing":
        db.add(models.WorkspaceMembership(
            workspace_id=workspace.id,
            user_id=created_user.id,
            role="professional",
            status="pending",
        ))
    elif user.workspace_choice in {"new", "independent"}:
        workspace_name = (
            user.workspace_name.strip()
            if user.workspace_choice == "new"
            else f"Practica independiente de {user.full_name.strip()}"
        )
        normalized_name = normalize(workspace_name)
        duplicate = db.query(models.ClinicalWorkspace).filter_by(
            normalized_name=normalized_name
        ).first()
        if duplicate:
            db.rollback()
            raise HTTPException(
                status_code=409,
                detail={"message": "Potential workspace duplicate.", "workspace_id": duplicate.id},
            )
        workspace = models.ClinicalWorkspace(
            name=workspace_name,
            normalized_name=normalized_name,
            workspace_type=(user.workspace_type or "clinic")
            if user.workspace_choice == "new"
            else "independent",
            status="pending",
            initial_requester_id=created_user.id,
        )
        db.add(workspace)
        db.flush()
        db.add(models.WorkspaceMembership(
            workspace_id=workspace.id,
            user_id=created_user.id,
            role="professional",
            status="pending",
        ))

    db.commit()
    db.refresh(created_user)
    return {
        "success": True,
        "message": "User registered successfully",
        "data": {
            "user": UserProfile.model_validate(created_user).model_dump()
        }
    }


@router.post("/login")
async def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if db_user.status == "suspended":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account suspended",
        )

    if not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    token = create_access_token(
        data={"sub": str(db_user.id), "email": db_user.email, "role": db_user.role}
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


@router.put("/me")
async def update_me(
    user_update: UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not user_update.has_any_update:
        raise HTTPException(status_code=400, detail="No fields to update")

    if not user_update.is_valid:
        raise HTTPException(status_code=400, detail="Invalid field value")

    if user_update.email:
        existing = db.query(models.User).filter(
            models.User.email == user_update.email,
            models.User.id != current_user.id,
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")

    updated_user = crud.update_user(db, user_id=current_user.id, user_update=user_update)
    return {
        "success": True,
        "message": "Profile updated successfully",
        "data": {
            "user": UserProfile.model_validate(updated_user).model_dump()
        }
    }
