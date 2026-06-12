from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from config import settings

connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def ensure_sqlite_schema():
    if not settings.database_url.startswith("sqlite"):
        return

    with engine.begin() as connection:
        analyses_exists = connection.execute(
            text(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='analyses'"
            )
        ).scalar()

        if not analyses_exists:
            return

        table_info = connection.execute(text("PRAGMA table_info(analyses)"))
        existing_columns = {row[1] for row in table_info}

        if "patient_id" not in existing_columns:
            connection.execute(text("ALTER TABLE analyses ADD COLUMN patient_id VARCHAR"))

        if "patient_name" not in existing_columns:
            connection.execute(text("ALTER TABLE analyses ADD COLUMN patient_name VARCHAR"))

        if "model_version" not in existing_columns:
            connection.execute(text("ALTER TABLE analyses ADD COLUMN model_version VARCHAR"))

        if "processing_time_ms" not in existing_columns:
            connection.execute(text("ALTER TABLE analyses ADD COLUMN processing_time_ms FLOAT"))

        # --- Migración de la tabla users ---
        users_exists = connection.execute(
            text("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        ).scalar()

        if users_exists:
            users_info = connection.execute(text("PRAGMA table_info(users)"))
            users_columns = {row[1] for row in users_info}

            if "status" not in users_columns:
                connection.execute(text("ALTER TABLE users ADD COLUMN status VARCHAR"))
                connection.execute(
                    text("UPDATE users SET status='active' WHERE status IS NULL")
                )

            if "role" not in users_columns:
                connection.execute(text("ALTER TABLE users ADD COLUMN role VARCHAR"))
                connection.execute(
                    text("UPDATE users SET role='doctor' WHERE role IS NULL")
                )

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
