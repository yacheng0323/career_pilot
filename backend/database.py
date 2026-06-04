import os
from sqlmodel import SQLModel, Session, create_engine
from backend.models.job import Job  # noqa: F401 — needed for SQLModel.metadata

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./career_pilot.db")

# check_same_thread=False required for SQLite + FastAPI
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)


def init_db():
    """Create all tables. Call once at startup."""
    SQLModel.metadata.create_all(engine)


def get_session():
    """FastAPI dependency — yields a DB session."""
    with Session(engine) as session:
        yield session


# Initialize tables on module import so tests work without explicit init_db() call
init_db()
