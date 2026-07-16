import asyncio
import logging
from pathlib import Path

from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings
from sqlalchemy import text

from database import SessionLocal
from routers.admin import router as admin_router
from routers.auth import router as auth_router
from routers.history import router as history_router
from routers.predict import router as predict_router
from routers.summary import router as summary_router
from routers.workspaces import router as workspaces_router
from routers.clinical import router as clinical_router
from routers.priority import router as priority_router

logger = logging.getLogger(__name__)
from routers.predict import classifier

uploads_dir = Path(__file__).resolve().parent / "uploads"
uploads_dir.mkdir(exist_ok=True)

app = FastAPI(
    title="BucalScan AI API",
    description="Backend API for BucalScan AI.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,  # We use Bearer tokens, not cookies — credentials not needed
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": settings.app_name, "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "alive"}


@app.get("/live")
async def live():
    return {"status": "alive"}


def _check_readiness() -> None:
    with SessionLocal() as db:
        db.execute(text("SELECT 1"))
        tables = {
            row[0]
            for row in db.execute(
                text(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = current_schema() "
                    "AND table_name IN "
                    "('clinical_assessment_snapshots', 'clinical_priority_results')"
                )
            )
        } if db.get_bind().dialect.name == "postgresql" else {
            row[0]
            for row in db.execute(
                text(
                    "SELECT name FROM sqlite_master WHERE type = 'table' "
                    "AND name IN "
                    "('clinical_assessment_snapshots', 'clinical_priority_results')"
                )
            )
        }
        if tables != {"clinical_assessment_snapshots", "clinical_priority_results"}:
            raise RuntimeError("Database schema is not at the required revision")
        heatmap_columns = {
            row[0]
            for row in db.execute(
                text(
                    "SELECT column_name FROM information_schema.columns "
                    "WHERE table_schema = current_schema() "
                    "AND table_name = 'model_predictions' "
                    "AND column_name = 'heatmap_url'"
                )
            )
        } if db.get_bind().dialect.name == "postgresql" else {
            row[1]
            for row in db.execute(text("PRAGMA table_info(model_predictions)"))
        }
        if "heatmap_url" not in heatmap_columns:
            raise RuntimeError("Database schema is missing model prediction heatmaps")
    classifier.validate_contract()
    if not classifier.cam_output_names:
        raise RuntimeError("The configured model does not expose CAM outputs")


@app.get("/ready")
async def ready(response: Response):
    try:
        await asyncio.wait_for(asyncio.to_thread(_check_readiness), timeout=settings.readiness_timeout_seconds)
    except Exception:
        logger.exception("Readiness check failed")
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "unavailable"}
    return {"status": "ready"}


app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

app.include_router(auth_router)
app.include_router(predict_router)
app.include_router(history_router)
app.include_router(summary_router)
app.include_router(admin_router)
app.include_router(workspaces_router)
app.include_router(clinical_router)
app.include_router(priority_router)
