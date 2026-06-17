"""
Auth endpoint and JWT utility tests.
Run from backend/ directory: pytest tests/test_auth.py -v
"""
from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt

from auth.jwt import create_access_token, decode_access_token, get_current_user
from auth.security import get_password_hash, verify_password
from config import settings
from models import models
from schemas import UserProfile


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _register_user(client, payload):
    return client.post("/api/v1/auth/register", json=payload)


def _login_user(client, email, password):
    return client.post("/api/v1/auth/login", json={"email": email, "password": password})


def _create_db_user(db_session, **kwargs):
    defaults = {
        "full_name": "Dr. Test",
        "doctor_id": "MD-TEST-001",
        "medical_center": "Test Hospital",
        "email": "test@hospital.org",
        "hashed_password": get_password_hash("testpass123"),
    }
    defaults.update(kwargs)
    user = models.User(**defaults)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


# ---------------------------------------------------------------------------
# Password hashing / verification
# ---------------------------------------------------------------------------

class TestPasswordSecurity:
    def test_hash_is_different_from_plain(self):
        plain = "mysecretpassword"
        hashed = get_password_hash(plain)
        assert hashed != plain
        assert hashed.startswith("$2")

    def test_verify_correct_password(self):
        plain = "mysecretpassword"
        hashed = get_password_hash(plain)
        assert verify_password(plain, hashed) is True

    def test_verify_wrong_password(self):
        plain = "mysecretpassword"
        hashed = get_password_hash(plain)
        assert verify_password("wrongpassword", hashed) is False

    def test_hashing_is_consistent_but_salted(self):
        plain = "mysecretpassword"
        hashed1 = get_password_hash(plain)
        hashed2 = get_password_hash(plain)
        # bcrypt salts automatically, so hashes should differ
        assert hashed1 != hashed2
        # but both should verify against the original plain text
        assert verify_password(plain, hashed1) is True
        assert verify_password(plain, hashed2) is True


# ---------------------------------------------------------------------------
# JWT utilities
# ---------------------------------------------------------------------------

class TestJwtUtilities:
    def test_create_token_returns_string(self):
        token = create_access_token({"sub": "1", "email": "a@b.com"})
        assert isinstance(token, str)
        assert len(token) > 0

    def test_decode_valid_token(self):
        token = create_access_token({"sub": "1", "email": "a@b.com"})
        payload = decode_access_token(token)
        assert payload is not None
        assert payload["sub"] == "1"
        assert payload["email"] == "a@b.com"
        assert "exp" in payload

    def test_decode_invalid_token_returns_none(self):
        payload = decode_access_token("totally.invalid.token")
        assert payload is None

    def test_decode_tampered_token_returns_none(self):
        token = create_access_token({"sub": "1", "email": "a@b.com"})
        tampered = token[:-5] + "XXXXX"
        payload = decode_access_token(tampered)
        assert payload is None

    def test_token_expiration_is_set(self):
        token = create_access_token({"sub": "1"})
        payload = decode_access_token(token)
        exp_timestamp = payload["exp"]
        expected_exp = datetime.now(timezone.utc) + timedelta(
            minutes=settings.jwt_expiration_minutes
        )
        # Allow 5 seconds of skew
        assert abs(exp_timestamp - expected_exp.timestamp()) < 5

    def test_expired_token_is_rejected(self):
        # Create a token that expired 1 hour ago
        expired_token = create_access_token(
            {"sub": "1"},
            expires_delta=timedelta(minutes=-60),
        )
        payload = decode_access_token(expired_token)
        assert payload is None

    def test_token_uses_configured_secret(self):
        token = create_access_token({"sub": "42"})
        # Verify it can be decoded with our settings secret
        raw = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        assert raw["sub"] == "42"


# ---------------------------------------------------------------------------
# Registration endpoint
# ---------------------------------------------------------------------------

class TestRegistration:
    def test_register_new_user_success(self, client, db_session):
        response = _register_user(
            client,
            {
                "full_name": "Dra. Jane Doe",
                "doctor_id": "MD-123456",
                "medical_center": "Hospital Central",
                "email": "jane.doe@hospital.org",
                "password": "secret123",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["message"] == "User registered successfully"
        user = data["data"]["user"]
        assert user["email"] == "jane.doe@hospital.org"
        assert user["doctor_id"] == "MD-123456"
        assert user["medical_center"] == "Hospital Central"
        assert user["id"] is not None

    def test_register_without_medical_center_is_allowed(self, client, db_session):
        response = _register_user(
            client,
            {
                "full_name": "Dr. No Center",
                "doctor_id": "MD-NOCENTER",
                "email": "nocenter@hospital.org",
                "password": "secret123",
            },
        )
        assert response.status_code == 200
        user = response.json()["data"]["user"]
        assert user["medical_center"] is None

    def test_register_duplicate_email(self, client, db_session):
        _create_db_user(db_session, email="dup@hospital.org", doctor_id="MD-DUP-1")

        response = _register_user(
            client,
            {
                "full_name": "Dr. Duplicate",
                "doctor_id": "MD-DUP-2",
                "email": "dup@hospital.org",
                "password": "secret123",
            },
        )
        assert response.status_code == 400
        assert "Email already registered" in response.json()["detail"]

    def test_register_duplicate_doctor_id(self, client, db_session):
        _create_db_user(db_session, email="doc1@hospital.org", doctor_id="MD-DOCDUP")

        response = _register_user(
            client,
            {
                "full_name": "Dr. Duplicate",
                "doctor_id": "MD-DOCDUP",
                "email": "doc2@hospital.org",
                "password": "secret123",
            },
        )
        assert response.status_code == 400
        assert "Doctor ID already registered" in response.json()["detail"]

    def test_register_password_is_hashed_not_stored_plain(self, client, db_session):
        _register_user(
            client,
            {
                "full_name": "Dr. Hash",
                "doctor_id": "MD-HASH",
                "email": "hash@hospital.org",
                "password": "myplainpassword",
            },
        )
        db_user = db_session.query(models.User).filter(
            models.User.email == "hash@hospital.org"
        ).first()
        assert db_user is not None
        assert db_user.hashed_password != "myplainpassword"
        assert verify_password("myplainpassword", db_user.hashed_password)

    def test_register_missing_required_field(self, client, db_session):
        response = client.post(
            "/api/v1/auth/register",
            json={"email": "incomplete@hospital.org", "password": "secret123"},
        )
        assert response.status_code == 422


# ---------------------------------------------------------------------------
# Login endpoint
# ---------------------------------------------------------------------------

class TestLogin:
    def test_login_success_returns_token(self, client, db_session):
        _create_db_user(db_session, email="login@hospital.org", doctor_id="MD-LOGIN-1")

        response = _login_user(client, "login@hospital.org", "testpass123")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["message"] == "Login successful"
        assert "token" in data["data"]
        assert data["data"]["token"] is not None
        assert isinstance(data["data"]["token"], str)
        user = data["data"]["user"]
        assert user["email"] == "login@hospital.org"

    def test_login_wrong_password_returns_401(self, client, db_session):
        _create_db_user(db_session, email="wrongpass@hospital.org", doctor_id="MD-WP-1")

        response = _login_user(client, "wrongpass@hospital.org", "badpassword")
        assert response.status_code == 401
        assert "Invalid credentials" in response.json()["detail"]

    def test_login_nonexistent_user_returns_401(self, client, db_session):
        response = _login_user(client, "nobody@hospital.org", "anypassword")
        assert response.status_code == 401
        assert "Invalid credentials" in response.json()["detail"]

    def test_login_token_contains_expected_claims(self, client, db_session):
        user = _create_db_user(
            db_session, email="claims@hospital.org", doctor_id="MD-CLAIMS-1", id=99
        )

        response = _login_user(client, "claims@hospital.org", "testpass123")
        token = response.json()["data"]["token"]
        payload = decode_access_token(token)
        assert payload["sub"] == str(user.id)
        assert payload["email"] == user.email


# ---------------------------------------------------------------------------
# /auth/me endpoint
# ---------------------------------------------------------------------------

class TestAuthMe:
    def test_me_with_valid_token(self, client, db_session):
        user = _create_db_user(
            db_session, email="me@hospital.org", doctor_id="MD-ME-1"
        )
        token = create_access_token({"sub": str(user.id), "email": user.email})

        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["user"]["email"] == "me@hospital.org"

    def test_me_without_token_returns_401(self, client, db_session):
        response = client.get("/api/v1/auth/me")
        assert response.status_code == 401
        assert "Not authenticated" in response.json()["detail"]

    def test_me_with_invalid_token_returns_401(self, client, db_session):
        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401
        assert "Invalid or expired token" in response.json()["detail"]

    def test_me_with_expired_token_returns_401(self, client, db_session):
        user = _create_db_user(db_session, email="expired@hospital.org", doctor_id="MD-EXP-1")
        expired_token = create_access_token(
            {"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=-10),
        )

        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert response.status_code == 401
        assert "Invalid or expired token" in response.json()["detail"]

    def test_me_with_token_for_deleted_user_returns_401(self, client, db_session):
        # Create user, generate token, then delete user from DB
        user = _create_db_user(
            db_session, email="deleted@hospital.org", doctor_id="MD-DEL-1"
        )
        token = create_access_token({"sub": str(user.id), "email": user.email})
        db_session.delete(user)
        db_session.commit()

        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 401
        assert "User not found" in response.json()["detail"]

    def test_me_response_includes_created_at(self, client, db_session):
        user = _create_db_user(
            db_session, email="mecreated@hospital.org", doctor_id="MD-MECREATED-1"
        )
        token = create_access_token({"sub": str(user.id), "email": user.email})

        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        user_data = response.json()["data"]["user"]
        assert "created_at" in user_data
        assert user_data["created_at"] is not None


# ---------------------------------------------------------------------------
# get_current_user dependency (direct unit test)
# ---------------------------------------------------------------------------

class TestGetCurrentUserDependency:
    def test_returns_user_for_valid_token(self, db_session):
        user = _create_db_user(db_session, email="dep@hospital.org", doctor_id="MD-DEP-1")
        token = create_access_token({"sub": str(user.id), "email": user.email})

        from fastapi.security import HTTPAuthorizationCredentials
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        result = get_current_user(credentials=creds, db=db_session)
        assert result.id == user.id
        assert result.email == user.email

    def test_raises_when_credentials_are_none(self, db_session):
        with pytest.raises(Exception) as exc_info:
            get_current_user(credentials=None, db=db_session)
        assert exc_info.value.status_code == 401

    def test_raises_for_malformed_token(self, db_session):
        from fastapi.security import HTTPAuthorizationCredentials
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="bad")
        with pytest.raises(Exception) as exc_info:
            get_current_user(credentials=creds, db=db_session)
        assert exc_info.value.status_code == 401


# ---------------------------------------------------------------------------
# Protected route access
# ---------------------------------------------------------------------------

class TestProtectedRoutes:
    def test_history_without_token_returns_401(self, client, db_session):
        response = client.get("/api/v1/history")
        assert response.status_code == 401

    def test_history_with_valid_token_returns_200(self, client, db_session):
        user = _create_db_user(db_session, email="hist@hospital.org", doctor_id="MD-HIST-1")
        token = create_access_token({"sub": str(user.id), "email": user.email})
        response = client.get(
            "/api/v1/history",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200

    def test_history_doctor_only_sees_own_analyses(self, client, db_session):
        doctor = _create_db_user(
            db_session, email="doctorhist@hospital.org", doctor_id="MD-HIST-DOCTOR"
        )
        other = _create_db_user(
            db_session, email="otherhist@hospital.org", doctor_id="MD-HIST-OTHER"
        )
        own_analysis = models.Analysis(
            user_id=doctor.id,
            prediction="benign",
            confidence=0.91,
        )
        other_analysis = models.Analysis(
            user_id=other.id,
            prediction="malignant",
            confidence=0.88,
        )
        db_session.add_all([own_analysis, other_analysis])
        db_session.commit()

        token = create_access_token({"sub": str(doctor.id), "email": doctor.email})
        response = client.get(
            "/api/v1/history",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        items = response.json()
        ids = {item["id"] for item in items}
        assert ids == {own_analysis.id}
        assert items[0]["created_by_id"] == doctor.id
        assert items[0]["created_by_name"] == doctor.full_name
        assert items[0]["created_by_email"] == doctor.email
        assert items[0]["created_by_doctor_id"] == doctor.doctor_id

    def test_history_admin_sees_all_analyses(self, client, db_session):
        admin = _create_db_user(
            db_session,
            email="adminhist@hospital.org",
            doctor_id="MD-HIST-ADMIN",
            role="admin",
        )
        doctor = _create_db_user(
            db_session, email="doctorallhist@hospital.org", doctor_id="MD-HIST-ALL"
        )
        admin_analysis = models.Analysis(
            user_id=admin.id,
            prediction="benign",
            confidence=0.93,
        )
        doctor_analysis = models.Analysis(
            user_id=doctor.id,
            prediction="malignant",
            confidence=0.87,
        )
        db_session.add_all([admin_analysis, doctor_analysis])
        db_session.commit()

        token = create_access_token({"sub": str(admin.id), "email": admin.email})
        response = client.get(
            "/api/v1/history",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        ids = {item["id"] for item in response.json()}
        assert {admin_analysis.id, doctor_analysis.id}.issubset(ids)

    def test_history_with_invalid_token_returns_401(self, client, db_session):
        response = client.get(
            "/api/v1/history",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401

    def test_predict_without_token_returns_401(self, client, db_session):
        # Send an empty multipart request — should fail at auth before file validation
        response = client.post("/api/v1/predict")
        assert response.status_code == 401

    def test_predict_with_valid_token_returns_400_not_401(self, client, db_session):
        # Valid token but no file — should get 422 (missing file), not 401
        user = _create_db_user(db_session, email="pred@hospital.org", doctor_id="MD-PRED-1")
        token = create_access_token({"sub": str(user.id), "email": user.email})
        response = client.post(
            "/api/v1/predict",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 422  # Missing required file field

    def test_summary_without_token_returns_401(self, client, db_session):
        response = client.get("/api/v1/summary/today")
        assert response.status_code == 401

    def test_summary_with_valid_token_returns_200(self, client, db_session):
        user = _create_db_user(db_session, email="summ@hospital.org", doctor_id="MD-SUMM-1")
        token = create_access_token({"sub": str(user.id), "email": user.email})
        response = client.get(
            "/api/v1/summary/today",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200

    def test_summary_doctor_only_counts_own_analyses(self, client, db_session):
        doctor = _create_db_user(
            db_session, email="doctorsummary@hospital.org", doctor_id="MD-SUMMARY-DOCTOR"
        )
        other = _create_db_user(
            db_session, email="othersummary@hospital.org", doctor_id="MD-SUMMARY-OTHER"
        )
        db_session.add_all([
            models.Analysis(user_id=doctor.id, prediction="benign", confidence=0.91),
            models.Analysis(user_id=other.id, prediction="malignant", confidence=0.88),
        ])
        db_session.commit()

        token = create_access_token({"sub": str(doctor.id), "email": doctor.email})
        response = client.get(
            "/api/v1/summary/today",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["benign"] == 1
        assert data["malignant"] == 0

    def test_summary_admin_counts_all_analyses(self, client, db_session):
        admin = _create_db_user(
            db_session,
            email="adminsummary@hospital.org",
            doctor_id="MD-SUMMARY-ADMIN",
            role="admin",
        )
        doctor = _create_db_user(
            db_session, email="doctorglobalsummary@hospital.org", doctor_id="MD-SUMMARY-ALL"
        )
        db_session.add_all([
            models.Analysis(user_id=admin.id, prediction="benign", confidence=0.93),
            models.Analysis(user_id=doctor.id, prediction="malignant", confidence=0.87),
        ])
        db_session.commit()

        token = create_access_token({"sub": str(admin.id), "email": admin.email})
        response = client.get(
            "/api/v1/summary/today",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert data["benign"] == 1
        assert data["malignant"] == 1

    def test_register_is_public_no_token_required(self, client, db_session):
        response = client.post(
            "/api/v1/auth/register",
            json={
                "full_name": "Dr. Public",
                "doctor_id": "MD-PUBLIC-1",
                "email": "public@hospital.org",
                "password": "secret123",
            },
        )
        assert response.status_code == 200

    def test_login_is_public_no_token_required(self, client, db_session):
        _create_db_user(db_session, email="loginpub@hospital.org", doctor_id="MD-LPUB-1")
        response = client.post(
            "/api/v1/auth/login",
            json={"email": "loginpub@hospital.org", "password": "testpass123"},
        )
        assert response.status_code == 200
        assert "token" in response.json()["data"]
