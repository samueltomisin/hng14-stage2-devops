import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ── Mock Redis before importing app ──────────────────────────
@pytest.fixture(autouse=True)
def mock_redis():
    with patch('redis.Redis') as mock:
        instance = MagicMock()
        mock.return_value = instance
        yield instance


from main import app  # noqa: E402 — must import after mock

client = TestClient(app)


# ── Test 1: Health endpoint returns 200 ──────────────────────
def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


# ── Test 2: Create job returns a job_id ──────────────────────
def test_create_job(mock_redis):
    mock_redis.lpush.return_value = 1
    mock_redis.hset.return_value = True

    response = client.post("/jobs")

    assert response.status_code == 200
    data = response.json()
    assert "job_id" in data
    assert len(data["job_id"]) == 36  # valid UUID length
    mock_redis.lpush.assert_called_once()
    mock_redis.hset.assert_called_once()


# ── Test 3: Get job status returns correct status ─────────────
def test_get_job_status(mock_redis):
    mock_redis.hget.return_value = b"queued"

    response = client.get("/jobs/test-job-123")

    assert response.status_code == 200
    data = response.json()
    assert data["job_id"] == "test-job-123"
    assert data["status"] == "queued"


# ── Test 4: Get job returns 404 when not found ────────────────
def test_get_job_not_found(mock_redis):
    mock_redis.hget.return_value = None

    response = client.get("/jobs/nonexistent-job")

    assert response.status_code == 404


# ── Test 5: Job ID is unique per request ─────────────────────
def test_job_ids_are_unique(mock_redis):
    mock_redis.lpush.return_value = 1
    mock_redis.hset.return_value = True

    response1 = client.post("/jobs")
    response2 = client.post("/jobs")

    assert response1.json()["job_id"] != response2.json()["job_id"]
