from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from config import settings

connect_args = {"check_same_thread": False} if settings.database_url.startswith("sqlite") else {}
pool_args = (
    {}
    if settings.database_url.startswith("sqlite")
    else {"pool_pre_ping": True, "pool_recycle": 300}
)

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    **pool_args,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
