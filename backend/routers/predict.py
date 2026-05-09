from fastapi import APIRouter, File, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError

from models.inference import OralLesionClassifier
from schemas import PredictionResponse

router = APIRouter(prefix="/api/v1", tags=["predict"])
classifier = OralLesionClassifier()

_ACCEPTED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _build_recommendation(prediction: str) -> str:
    if prediction == "malignant":
        return "Consult a specialist immediately for further evaluation."
    return "No immediate concern. Regular check-ups recommended."


@router.post("/predict", response_model=PredictionResponse)
async def predict(file: UploadFile = File(...)):
    if file.content_type not in _ACCEPTED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid file type '{file.content_type}'. "
                f"Accepted: {', '.join(sorted(_ACCEPTED_CONTENT_TYPES))}."
            ),
        )

    try:
        image = Image.open(file.file).convert("RGB")
    except UnidentifiedImageError as exc:
        raise HTTPException(status_code=400, detail="Cannot decode image file.") from exc

    try:
        result = classifier.predict(image)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=f"Model inference failed: {exc}") from exc

    return PredictionResponse(
        prediction=result["prediction"],
        confidence=result["confidence"],
        recommendation=_build_recommendation(result["prediction"]),
        probabilities=result.get("probabilities"),
    )
