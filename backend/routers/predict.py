import io
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from sqlalchemy.orm import Session

import crud
from database import get_db
from models.inference import OralLesionClassifier
from schemas import PredictionResponse

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
    user_id: int = Form(...),
    patient_id: Optional[str] = Form(None),
    patient_name: Optional[str] = Form(None),
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

    _UPLOADS_DIR.mkdir(exist_ok=True)
    ext = Path(file.filename or "image.jpg").suffix or ".jpg"
    image_path = str(_UPLOADS_DIR / f"{uuid.uuid4().hex}{ext}")
    Path(image_path).write_bytes(contents)

    crud.create_analysis(
        db,
        user_id=user_id,
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
