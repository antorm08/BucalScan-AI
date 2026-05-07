from fastapi import APIRouter, File, HTTPException, UploadFile
from PIL import Image

from models.inference import OralLesionClassifier
from schemas import PredictionResponse

router = APIRouter(prefix="/api/v1", tags=["predict"])
classifier = OralLesionClassifier()


def _build_recommendation(prediction: str) -> str:
    if prediction == "malignant":
        return "Consult a specialist immediately for further evaluation."
    return "No immediate concern. Regular check-ups recommended."


@router.post("/predict", response_model=PredictionResponse)
async def predict(file: UploadFile = File(...)):
    try:
        image = Image.open(file.file).convert("RGB")
        result = classifier.predict(image)
        return PredictionResponse(
            prediction=result["prediction"],
            confidence=result["confidence"],
            recommendation=_build_recommendation(result["prediction"]),
            probabilities=result.get("probabilities"),
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
