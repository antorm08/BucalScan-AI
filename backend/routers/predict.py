import io
import json
import logging
import time
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from pydantic import ValidationError
from sqlalchemy.orm import Session

from auth.workspace import WorkspaceAccess, require_clinical_professional
from config import settings
from database import get_db
from models import models
from models.inference import OralLesionClassifier
from schemas import ClinicalAssessmentInput, PredictionResponse
from routers.priority import persist_priority, require_priority_available
from services.clinical_priority import result_dict
from services.cloudinary_storage import upload_image
from services.image_quality_validator import ImageQualityResult, validate_image_quality

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["predict"])
classifier = OralLesionClassifier()

_ACCEPTED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
_UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"
_MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
_MODEL_VERSION = settings.model_version


def _build_recommendation(prediction: str) -> str:
    if prediction == "malignant":
        return "This model output supports timely professional review and does not establish a diagnosis."
    return "Continue professional evaluation; this model output cannot rule out clinical concern."


def _quality_rejection_message(result: ImageQualityResult) -> str:
    messages = {
        "low_resolution": "the resolution is too low",
        "blurry": "the image is too blurry",
        "too_dark": "the image is too dark",
        "overexposed": "the image is overexposed",
    }
    details = ", ".join(messages[reason] for reason in result.reasons)
    return (
        f"Image quality is insufficient: {details}. "
        "Please recapture the oral image with steady focus and even lighting."
    )


@router.post("/predict", response_model=PredictionResponse)
async def predict(
    file: UploadFile = File(...),
    consent_to_store: bool = Form(False),
    patient_id: int = Form(...),
    lesion_id: int = Form(...),
    clinical_observations: Optional[str] = Form(None),
    assessment: Optional[str] = Form(None),
    access: WorkspaceAccess = Depends(require_clinical_professional),
    db: Session = Depends(get_db),
):
    if not consent_to_store:
        raise HTTPException(
            status_code=400,
            detail="Professional attestation that patient authorization was obtained is required.",
        )

    assessment_input = None
    if assessment is not None:
        try:
            assessment_input = ClinicalAssessmentInput.model_validate(json.loads(assessment))
        except (json.JSONDecodeError, ValidationError) as exc:
            raise HTTPException(status_code=422, detail="Invalid structured clinical assessment.") from exc
        require_priority_available()

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
        quality_result = validate_image_quality(image)
    except Exception as exc:
        logger.exception("Image quality validation error for user_id=%s", access.user.id)
        raise HTTPException(
            status_code=500,
            detail="Image quality validation failed. Please try again later.",
        ) from exc

    if not quality_result.is_valid:
        logger.warning(
            "Image quality rejected user_id=%s workspace_id=%s resolution=%sx%s "
            "blur_score=%.2f dark_ratio=%.4f bright_ratio=%.4f reasons=%s",
            access.user.id,
            access.workspace.id,
            quality_result.width,
            quality_result.height,
            quality_result.blur_score,
            quality_result.dark_ratio,
            quality_result.bright_ratio,
            ",".join(quality_result.reasons),
        )
        raise HTTPException(status_code=422, detail=_quality_rejection_message(quality_result))

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
    priority_result = None
    priority_snapshot = None
    if assessment_input is not None:
        priority_result, priority_snapshot = persist_priority(
            db, evaluation, access.user.id, assessment_input
        )
    db.commit()

    return PredictionResponse(
        prediction=result["prediction"],
        confidence=result["confidence"],
        recommendation=_build_recommendation(result["prediction"]),
        probabilities=result.get("probabilities"),
        processing_time_ms=processing_time_ms,
        model_version=_MODEL_VERSION,
        evaluation_id=evaluation.id,
        priority=(
            result_dict(priority_result, priority_snapshot.completion_status)
            if priority_result is not None else None
        ),
    )
