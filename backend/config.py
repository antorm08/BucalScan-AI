import os
from dataclasses import dataclass
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - dependency may be missing locally
    def load_dotenv(*_args, **_kwargs):
        return False

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "BucalScan AI")
    jwt_secret: str = os.environ["JWT_SECRET"]
    database_url: str = os.getenv(
        "DATABASE_URL",
        f"sqlite:///{(BASE_DIR / 'bucalscan_ai.db').as_posix()}",
    )
    model_path: str = os.getenv(
        "MODEL_PATH",
        str(BASE_DIR / "models" / "mobilenetv2_oral.onnx"),
    )


settings = Settings()
