import io
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
import crud
from database import get_db
from models import models
from models.inference import OralLesionClassifier
from schemas import PredictionResponse
from services.cloudinary_storage import upload_image

router = APIRouter(prefix="/api/v1", tags=["predict"])
classifier = OralLesionClassifier()

_ACCEPTED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
_UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"


def _build_recommendation(prediction: str) -> str:
    if prediction == "malignant":
        return "Consult a specialist immediately for further evaluation."
    return "No immediate concern. Regular check-ups recommended."


@router.post("/predict", response_model=PredictionResponse)
async def predict(
    file: UploadFile = File(...),
    patient_id: Optional[str] = Form(None),
    patient_name: Optional[str] = Form(None),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if file.content_type not in _ACCEPTED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid file type '{file.content_type}'. "
                f"Accepted: {', '.join(sorted(_ACCEPTED_CONTENT_TYPES))}."
            ),
        )

    contents = await file.read()

    try:
        image = Image.open(io.BytesIO(contents)).convert("RGB")
    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=400, detail="Cannot decode image file.") from exc

    try:
        result = classifier.predict(image)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=f"Model inference failed: {exc}") from exc

    ext = Path(file.filename or "image.jpg").suffix or ".jpg"
    stored_filename = f"{uuid.uuid4().hex}{ext}"
    image_path = upload_image(
        contents,
        filename=stored_filename,
        content_type=file.content_type or "image/jpeg",
    )

    if image_path is None:
        _UPLOADS_DIR.mkdir(exist_ok=True)
        image_path = str(_UPLOADS_DIR / stored_filename)
        Path(image_path).write_bytes(contents)

    crud.create_analysis(
        db,
        user_id=current_user.id,
        prediction=result["prediction"],
        confidence=result["confidence"],
        image_path=image_path,
        patient_id=patient_id or None,
        patient_name=patient_name or None,
    )

    return PredictionResponse(
        prediction=result["prediction"],
        confidence=result["confidence"],
        recommendation=_build_recommendation(result["prediction"]),
        probabilities=result.get("probabilities"),
    )
