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
    assert {"users", "analyses", "patients", "model_predictions", "clinical_assessment_snapshots", "clinical_priority_results"} <= tables
    inspector = inspect(create_engine(url))
    assert "heatmap_url" in {
        column["name"] for column in inspector.get_columns("model_predictions")
    }
    assert {index["name"] for index in inspector.get_indexes("clinical_priority_results")} >= {
        "ix_priority_code", "ix_priority_workspace_evaluated"
    }
    assert {constraint["name"] for constraint in inspector.get_unique_constraints("clinical_priority_results")} >= {
        "uq_priority_assessment", "uq_priority_evaluation"
    }


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
        assert connection.execute(text("SELECT COUNT(*) FROM clinical_assessment_snapshots")).scalar_one() == 0
        assert connection.execute(text("SELECT COUNT(*) FROM clinical_priority_results")).scalar_one() == 0
        assert connection.execute(text("SELECT prediction, confidence FROM analyses WHERE id=1")).one() == ("benign", 0.9)
        assert connection.execute(
            text("SELECT heatmap_url FROM model_predictions WHERE id=1")
        ).scalar_one() is None


def test_empty_priority_revision_can_downgrade_and_upgrade(tmp_path):
    url = f"sqlite:///{(tmp_path / 'rollback.db').as_posix()}"
    config = _config(url)
    command.upgrade(config, "head")
    command.downgrade(config, "0003_legacy_backfill")
    assert "clinical_priority_results" not in inspect(create_engine(url)).get_table_names()
    command.upgrade(config, "head")
    assert "clinical_priority_results" in inspect(create_engine(url)).get_table_names()


def test_heatmap_revision_can_downgrade_and_upgrade(tmp_path):
    url = f"sqlite:///{(tmp_path / 'heatmap-rollback.db').as_posix()}"
    config = _config(url)
    command.upgrade(config, "head")
    command.downgrade(config, "0004_clinical_priority")
    assert "heatmap_url" not in {
        column["name"]
        for column in inspect(create_engine(url)).get_columns("model_predictions")
    }
    command.upgrade(config, "head")
    assert "heatmap_url" in {
        column["name"]
        for column in inspect(create_engine(url)).get_columns("model_predictions")
    }
