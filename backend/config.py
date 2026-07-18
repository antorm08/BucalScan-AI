import os
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - dependency may be missing locally
    def load_dotenv(*_args, **_kwargs):
        return False

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


def _resolve_model_path(model_path: str) -> str:
    path = Path(model_path)
    if not path.is_absolute():
        path = BASE_DIR / path
    return str(path.resolve())


def _resolve_database_url(database_url: str) -> str:
    sqlite_prefix = "sqlite:///"
    if not database_url.startswith(sqlite_prefix):
        return database_url

    sqlite_path = database_url[len(sqlite_prefix):]
    if not sqlite_path or sqlite_path == ":memory:":
        return database_url

    path = Path(sqlite_path)
    if path.is_absolute():
        return database_url

    return f"{sqlite_prefix}{(BASE_DIR / path).resolve().as_posix()}"


def _parse_cors_origins(value: str) -> list[str]:
    origins = [origin.strip() for origin in value.split(",") if origin.strip()]
    return origins or ["*"]


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "BucalScan AI")
    jwt_secret: str = os.environ.get("JWT_SECRET") or os.getenv("JWT_SECRET", "")
    if not jwt_secret:
        raise EnvironmentError(
            "JWT_SECRET environment variable is not set. "
            "Add JWT_SECRET=<your-secret-key> to the .env file."
        )
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    jwt_expiration_minutes: int = int(os.getenv("JWT_EXPIRATION_MINUTES", "1440"))
    database_url: str = _resolve_database_url(
        os.getenv(
            "DATABASE_URL",
            f"sqlite:///{(BASE_DIR / 'bucalscan_ai.db').as_posix()}",
        )
    )
    model_path: str = _resolve_model_path(
        os.getenv(
            "MODEL_PATH",
            str(BASE_DIR / "models" / "resnet50_oral.onnx"),
        )
    )
    cam_model_path: str = _resolve_model_path(
        os.getenv(
            "CAM_MODEL_PATH",
            str(BASE_DIR / "models" / "resnet50_oral_cam.onnx"),
        )
    )
    model_architecture: str = os.getenv("MODEL_ARCHITECTURE", "ResNet50")
    model_version: str = os.getenv("MODEL_VERSION", Path(model_path).stem)
    image_min_width: int = int(os.getenv("IMAGE_MIN_WIDTH", "224"))
    image_min_height: int = int(os.getenv("IMAGE_MIN_HEIGHT", "224"))
    image_blur_threshold: float = float(os.getenv("IMAGE_BLUR_THRESHOLD", "10"))
    image_dark_luminance: int = int(os.getenv("IMAGE_DARK_LUMINANCE", "20"))
    image_bright_luminance: int = int(os.getenv("IMAGE_BRIGHT_LUMINANCE", "235"))
    image_max_dark_ratio: float = float(os.getenv("IMAGE_MAX_DARK_RATIO", "0.40"))
    image_max_bright_ratio: float = float(os.getenv("IMAGE_MAX_BRIGHT_RATIO", "0.40"))
    cloudinary_cloud_name: Optional[str] = os.getenv("CLOUDINARY_CLOUD_NAME")
    cloudinary_api_key: Optional[str] = os.getenv("CLOUDINARY_API_KEY")
    cloudinary_api_secret: Optional[str] = os.getenv("CLOUDINARY_API_SECRET")
    cloudinary_folder: str = os.getenv("CLOUDINARY_FOLDER", "bucalscan/analyses")
    environment: str = os.getenv("ENVIRONMENT", "development").lower()
    readiness_timeout_seconds: float = float(os.getenv("READINESS_TIMEOUT_SECONDS", "10"))
    clinical_priority_mode: str = os.getenv("CLINICAL_PRIORITY_MODE", "disabled").lower()
    clinical_priority_ruleset: str = os.getenv("CLINICAL_PRIORITY_RULESET", "clinical-priority-v1-draft")
    cors_origins: list[str] = None

    def __post_init__(self):
        if self.image_min_width <= 0 or self.image_min_height <= 0:
            raise ValueError("Image minimum dimensions must be positive.")
        if self.image_blur_threshold < 0:
            raise ValueError("IMAGE_BLUR_THRESHOLD must be non-negative.")
        if not 0 <= self.image_dark_luminance < self.image_bright_luminance <= 255:
            raise ValueError("Image luminance thresholds must satisfy 0 <= dark < bright <= 255.")
        if not 0 <= self.image_max_dark_ratio <= 1 or not 0 <= self.image_max_bright_ratio <= 1:
            raise ValueError("Image illumination ratios must be between 0 and 1.")

        object.__setattr__(
            self,
            "cors_origins",
            _parse_cors_origins(os.getenv("CORS_ORIGINS", "*")),
        )

        if self.environment == "production":
            if self.database_url.startswith("sqlite"):
                raise EnvironmentError("Production requires PostgreSQL DATABASE_URL.")
            if not all((self.cloudinary_cloud_name, self.cloudinary_api_key, self.cloudinary_api_secret)):
                raise EnvironmentError("Production requires complete Cloudinary configuration.")


settings = Settings()
