import pytest
from sqlmodel import SQLModel, Session, create_engine, StaticPool
from backend.database import get_session
from backend.models.job import Job  # noqa: F401 — needed for table creation


TEST_DATABASE_URL = "sqlite://"   # in-memory


@pytest.fixture(name="session")
def session_fixture():
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session: Session):
    from fastapi.testclient import TestClient
    from backend.main import app

    def override_get_session():
        yield session

    app.dependency_overrides[get_session] = override_get_session
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
