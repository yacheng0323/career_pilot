from unittest.mock import AsyncMock, patch


def test_sync_status_initial(client):
    resp = client.get("/api/v1/sync/status")
    assert resp.status_code == 200
    data = resp.json()
    assert "lastSync" in data
    assert "status" in data


def test_trigger_sync_returns_ok(client):
    with patch(
        "backend.routers.sync.run_all_crawlers",
        new_callable=AsyncMock,
        return_value=3,
    ):
        resp = client.post("/api/v1/sync")
    assert resp.status_code == 200
    assert resp.json()["jobsUpserted"] == 3


def test_trigger_sync_handles_crawler_error(client):
    with patch(
        "backend.routers.sync.run_all_crawlers",
        new_callable=AsyncMock,
        side_effect=Exception("network error"),
    ):
        resp = client.post("/api/v1/sync")
    assert resp.status_code == 500
    assert "error" in resp.json()["detail"].lower()
