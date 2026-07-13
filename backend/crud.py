from datetime import UTC, date as date_type, datetime, timedelta
from typing import Optional

from sqlalchemy import case, func
from sqlalchemy.orm import Session, joinedload
from models import models
from schemas import UserCreate, UserUpdate
from auth.security import get_password_hash

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: UserCreate, *, commit: bool = True):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        full_name=user.full_name,
        doctor_id=user.doctor_id,
        medical_center=user.medical_center,
        email=user.email,
        hashed_password=hashed_password,
        role="professional",
        status="pending",
        profession=user.profession,
        specialty=user.specialty,
    )
    db.add(db_user)
    if commit:
        db.commit()
        db.refresh(db_user)
    else:
        db.flush()
    return db_user

def get_user_analyses(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(models.Analysis).options(joinedload(models.Analysis.owner)).filter(
        models.Analysis.user_id == user_id
    ).order_by(models.Analysis.timestamp.desc()).offset(skip).limit(limit).all()


def get_all_analyses(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Analysis).options(joinedload(models.Analysis.owner)).order_by(
        models.Analysis.timestamp.desc()
    ).offset(skip).limit(limit).all()


def get_daily_summary(
    db: Session,
    user_id: Optional[int] = None,
    date_target: Optional[date_type] = None,
) -> dict:
    today = date_target if date_target is not None else datetime.now(UTC).date()
    start_of_day = datetime(today.year, today.month, today.day)
    end_of_day = start_of_day + timedelta(days=1)

    query = db.query(
        func.count(models.Analysis.id).label("total"),
        func.sum(case((models.Analysis.prediction == "benign", 1), else_=0)).label("benign"),
        func.sum(case((models.Analysis.prediction == "malignant", 1), else_=0)).label("malignant"),
        func.max(models.Analysis.timestamp).label("latest_analysis_at"),
    ).filter(
        models.Analysis.timestamp >= start_of_day,
        models.Analysis.timestamp < end_of_day,
    )

    if user_id is not None:
        query = query.filter(models.Analysis.user_id == user_id)

    row = query.one()

    return {
        "total": int(row.total or 0),
        "benign": int(row.benign or 0),
        "malignant": int(row.malignant or 0),
        "latest_analysis_at": row.latest_analysis_at,
    }

def get_all_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()


def update_user(db: Session, user_id: int, user_update: "UserUpdate"):  # type: ignore[name-defined]
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if db_user is None:
        return None

    update_data = user_update.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(db_user, field, value)

    db.commit()
    db.refresh(db_user)
    return db_user


def update_user_status(db: Session, user_id: int, status: str):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        return None
    user.status = status
    db.commit()
    db.refresh(user)
    return user


def create_analysis(db: Session, user_id: int, prediction: str, confidence: float, image_path: str = None, patient_id: str = None, patient_name: str = None, model_version: str = None, processing_time_ms: float = None):
    db_analysis = models.Analysis(
        user_id=user_id,
        prediction=prediction,
        confidence=confidence,
        image_path=image_path,
        patient_id=patient_id,
        patient_name=patient_name,
        model_version=model_version,
        processing_time_ms=processing_time_ms,
    )
    db.add(db_analysis)
    db.commit()
    db.refresh(db_analysis)
    return db_analysis
