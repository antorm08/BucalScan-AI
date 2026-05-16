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

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
