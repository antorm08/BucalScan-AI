import io
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect, text


def _config(database_url: str) -> Config:
    root = Path(__file__).resolve().parent.parent
    config = Config(str(root / "alembic.ini"))
    config.set_main_option("script_location", str(root / "alembic"))
    config.set_main_option("sqlalchemy.url", database_url)
    return config


def test_postgresql_offline_sql_is_complete_and_transactional():
    output = io.StringIO()
    config = _config("postgresql://unused:unused@localhost/unused")
    config.output_buffer = output
    command.upgrade(config, "head", sql=True)
    sql = output.getvalue()
    assert "BEGIN;" in sql and "COMMIT;" in sql
    assert "CREATE TABLE IF NOT EXISTS clinical_workspaces" in sql
    assert "CREATE TABLE IF NOT EXISTS model_predictions" in sql
    assert "CREATE TEMP TABLE migration_user_workspaces" in sql
    assert "UPDATE analyses a SET evaluation_id" in sql
    assert "0003_legacy_backfill" in sql


def test_migrations_initialize_empty_sqlite(tmp_path):
    url = f"sqlite:///{(tmp_path / 'empty.db').as_posix()}"
    command.upgrade(_config(url), "head")
    tables = set(inspect(create_engine(url)).get_table_names())
    assert {"users", "analyses", "patients", "model_predictions"} <= tables


def test_migrations_preserve_and_backfill_legacy_rows(tmp_path):
    url = f"sqlite:///{(tmp_path / 'legacy.db').as_posix()}"
    engine = create_engine(url)
    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, full_name VARCHAR NOT NULL, doctor_id VARCHAR NOT NULL UNIQUE, medical_center VARCHAR, email VARCHAR NOT NULL UNIQUE, hashed_password VARCHAR NOT NULL, created_at DATETIME)"))
        connection.execute(text("CREATE TABLE analyses (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id), prediction VARCHAR NOT NULL, confidence FLOAT NOT NULL, image_path VARCHAR, timestamp DATETIME)"))
        connection.execute(text("INSERT INTO users VALUES (1, 'Legacy Doctor', 'L-1', 'Legacy Clinic', 'legacy@example.test', 'hash', CURRENT_TIMESTAMP)"))
        connection.execute(text("INSERT INTO analyses VALUES (1, 1, 'benign', 0.9, 'https://example.test/image.jpg', CURRENT_TIMESTAMP)"))
    command.upgrade(_config(url), "head")
    with engine.connect() as connection:
        assert connection.execute(text("SELECT COUNT(*) FROM users")).scalar_one() == 1
        assert connection.execute(text("SELECT COUNT(*) FROM analyses")).scalar_one() == 1
        assert connection.execute(text("SELECT COUNT(*) FROM model_predictions")).scalar_one() == 1
        assert connection.execute(text("SELECT evaluation_id FROM analyses WHERE id=1")).scalar_one() is not None
