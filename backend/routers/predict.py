import io
import logging
import time
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, require_clinical_professional
from config import settings
from database import get_db
from models import models
from models.inference import OralLesionClassifier
from schemas import PredictionResponse
from services.cloudinary_storage import upload_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["predict"])
classifier = OralLesionClassifier()

_ACCEPTED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
_UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"
_MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
_MODEL_VERSION = settings.model_version


def _build_recommendation(prediction: str) -> str:
    if prediction == "malignant":
        return "Consult a specialist immediately for further evaluation."
    return "No immediate concern. Regular check-ups recommended."


@router.post("/predict", response_model=PredictionResponse)
async def predict(
    file: UploadFile = File(...),
    consent_to_store: bool = Form(False),
    patient_id: int = Form(...),
    lesion_id: int = Form(...),
    patient_name: Optional[str] = Form(None),
    clinical_observations: Optional[str] = Form(None),
    access: WorkspaceAccess = Depends(require_clinical_professional),
    db: Session = Depends(get_db),
):
    if not consent_to_store:
        raise HTTPException(
            status_code=400,
            detail="Professional attestation that patient authorization was obtained is required.",
        )

    patient = db.query(models.Patient).filter_by(
        id=patient_id, workspace_id=access.workspace.id
    ).first()
    lesion = db.query(models.OralLesion).filter_by(
        id=lesion_id, patient_id=patient_id, workspace_id=access.workspace.id
    ).first()
    if patient is None or lesion is None:
        raise HTTPException(status_code=404, detail="Patient or lesion not found in active workspace.")

    if file.content_type not in _ACCEPTED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid file type '{file.content_type}'. "
                f"Accepted: {', '.join(sorted(_ACCEPTED_CONTENT_TYPES))}."
            ),
        )

    contents = await file.read()

    if len(contents) > _MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail="File too large. Maximum allowed size is 10 MB.",
        )

    try:
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        image.load()
    except Image.DecompressionBombError:
        raise HTTPException(status_code=400, detail="Image rejected: potential decompression bomb.")
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status_code=400, detail="Cannot decode image file.")
    except Exception:
        raise HTTPException(status_code=400, detail="Cannot decode image file.")

    try:
        _t0 = time.perf_counter()
        result = classifier.predict(image)
        processing_time_ms = round((time.perf_counter() - _t0) * 1000, 1)
    except Exception as exc:
        logger.exception("Inference error for user_id=%s", access.user.id)
        raise HTTPException(
            status_code=500, detail="Model inference failed. Please try again later."
        ) from exc

    ext = Path(file.filename or "image.jpg").suffix or ".jpg"
    stored_filename = f"{uuid.uuid4().hex}{ext}"
    image_path = upload_image(
        contents,
        filename=stored_filename,
        content_type=file.content_type or "image/jpeg",
    )

    if image_path is None:
        if settings.environment == "production":
            raise HTTPException(status_code=503, detail="Durable image storage is unavailable.")
        _UPLOADS_DIR.mkdir(exist_ok=True)
        image_path = str(_UPLOADS_DIR / stored_filename)
        Path(image_path).write_bytes(contents)

    evaluation = models.ClinicalEvaluation(
        workspace_id=access.workspace.id,
        patient_id=patient.id,
        lesion_id=lesion.id,
        professional_id=access.user.id,
        clinical_observations=clinical_observations,
    )
    db.add(evaluation)
    db.flush()
    image_record = models.LesionImage(
        evaluation_id=evaluation.id,
        storage_url=image_path,
        content_type=file.content_type,
        original_filename=file.filename,
    )
    db.add(image_record)
    db.flush()
    probabilities = result["probabilities"]
    db.add(models.ModelPrediction(
        evaluation_id=evaluation.id,
        image_id=image_record.id,
        model_version=_MODEL_VERSION,
        predicted_label=result["prediction"],
        confidence=result["confidence"],
        benign_probability=probabilities["benign"],
        malignant_probability=probabilities["malignant"],
        processing_time_ms=processing_time_ms,
    ))
    db.add(models.ConsentAttestation(
        evaluation_id=evaluation.id,
        professional_id=access.user.id,
        authorization_obtained=True,
    ))
    db.add(models.Analysis(
        user_id=access.user.id,
        prediction=result["prediction"],
        confidence=result["confidence"],
        image_path=image_path,
        patient_id=patient.clinical_code,
        patient_name=patient.full_name,
        model_version=_MODEL_VERSION,
        processing_time_ms=processing_time_ms,
        evaluation_id=evaluation.id,
    ))
    db.commit()

    return PredictionResponse(
        prediction=result["prediction"],
        confidence=result["confidence"],
        recommendation=_build_recommendation(result["prediction"]),
        probabilities=result.get("probabilities"),
        processing_time_ms=processing_time_ms,
        model_version=_MODEL_VERSION,
        evaluation_id=evaluation.id,
    )
