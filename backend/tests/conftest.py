"""
Shared pytest fixtures for backend tests.
Run from backend/ directory: pytest tests/ -v
"""
import os
import sys
from pathlib import Path

# Ensure test env vars are set BEFORE any backend modules import config
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-12345"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_EXPIRATION_MINUTES"] = "60"
os.environ["MODEL_PATH"] = str(
    Path(__file__).resolve().parent.parent / "models" / "mobilenetv2_oral.onnx"
)

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from database import Base, get_db
from main import app

# Replace the global engine with a StaticPool in-memory engine so that
# all sessions share the same SQLite :memory: database.
_test_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

# Create all tables on the test engine
Base.metadata.create_all(bind=_test_engine)

TestingSessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=_test_engine
)


def _override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(scope="function")
def db_session():
    """Yield a fresh SQLAlchemy session for a test; rollback on teardown."""
    connection = _test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(db_session):
    """Yield a FastAPI TestClient with DB session override."""
    def _get_db_override():
        yield db_session

    app.dependency_overrides[get_db] = _get_db_override
    yield TestClient(app)
    app.dependency_overrides.clear()
