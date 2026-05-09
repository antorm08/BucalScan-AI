from sqlalchemy.orm import Session
from models import models
from schemas import UserCreate
from auth.security import get_password_hash

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        full_name=user.full_name,
        doctor_id=user.doctor_id,
        medical_center=user.medical_center,
        email=user.email,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user_analyses(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(models.Analysis).filter(
        models.Analysis.user_id == user_id
    ).order_by(models.Analysis.timestamp.desc()).offset(skip).limit(limit).all()

def create_analysis(db: Session, user_id: int, prediction: str, confidence: float, image_path: str = None):
    db_analysis = models.Analysis(
        user_id=user_id,
        prediction=prediction,
        confidence=confidence,
        image_path=image_path
    )
    db.add(db_analysis)
    db.commit()
    db.refresh(db_analysis)
    return db_analysis
