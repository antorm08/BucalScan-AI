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


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "BucalScan AI")
    jwt_secret: str = os.environ["JWT_SECRET"]
    database_url: str = _resolve_database_url(
        os.getenv(
            "DATABASE_URL",
            f"sqlite:///{(BASE_DIR / 'bucalscan_ai.db').as_posix()}",
        )
    )
    model_path: str = _resolve_model_path(
        os.getenv(
            "MODEL_PATH",
            str(BASE_DIR / "models" / "mobilenetv2_oral.onnx"),
        )
    )


settings = Settings()
