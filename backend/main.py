from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings
from database import Base, engine, ensure_sqlite_schema
from routers.auth import router as auth_router
from routers.history import router as history_router
from routers.predict import router as predict_router
from routers.summary import router as summary_router

Base.metadata.create_all(bind=engine)
ensure_sqlite_schema()

uploads_dir = Path(__file__).resolve().parent / "uploads"
uploads_dir.mkdir(exist_ok=True)

app = FastAPI(
    title="BucalScan AI API",
    description="Backend API for BucalScan AI.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": settings.app_name, "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}


app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

app.include_router(auth_router)
app.include_router(predict_router)
app.include_router(history_router)
app.include_router(summary_router)
