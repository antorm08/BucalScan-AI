from unittest.mock import patch


def test_live_has_no_dependency_checks(client):
    with patch("main._check_readiness", side_effect=RuntimeError):
        assert client.get("/live").json() == {"status": "alive"}


def test_ready_sanitizes_dependency_failure(client):
    with patch("main._check_readiness", side_effect=RuntimeError("secret database URL")):
        response = client.get("/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}


def test_ready_recovers(client):
    with patch("main._check_readiness", side_effect=RuntimeError):
        assert client.get("/ready").status_code == 503
    with patch("main._check_readiness", return_value=None):
        assert client.get("/ready").json() == {"status": "ready"}
