from backend.database import get_session, init_db
from backend.models.job import Job
from sqlmodel import Session, select


def test_init_db_creates_table():
    session_gen = get_session()
    session = next(session_gen)
    # If table doesn't exist this will raise
    results = session.exec(select(Job)).all()
    assert isinstance(results, list)


def test_get_session_yields_session():
    session_gen = get_session()
    session = next(session_gen)
    assert isinstance(session, Session)
