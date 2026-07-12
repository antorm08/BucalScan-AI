import io

from PIL import Image

from auth.jwt import create_access_token
from auth.security import get_password_hash
from models import models


def _user(db, suffix, *, role="professional", status="active"):
    user = models.User(
        full_name=f"User {suffix}", doctor_id=f"DOC-{suffix}",
        email=f"{suffix}@example.test", hashed_password=get_password_hash("secret123"),
        role=role, status=status,
    )
    db.add(user)
    db.flush()
    return user


def _workspace(db, user, suffix, *, member_role="professional", member_status="active", status="active"):
    workspace = models.ClinicalWorkspace(
        name=f"Clinic {suffix}", normalized_name=f"clinic {suffix}".lower(),
        workspace_type="clinic", status=status, initial_requester_id=user.id,
    )
    db.add(workspace)
    db.flush()
    membership = models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=user.id, role=member_role, status=member_status,
    )
    db.add(membership)
    db.flush()
    return workspace, membership


def _headers(user, workspace=None):
    headers = {"Authorization": f"Bearer {create_access_token({'sub': str(user.id), 'email': user.email})}"}
    if workspace:
        headers["X-Workspace-ID"] = str(workspace.id)
    return headers


def _patient_payload(code="P-001", name="Maria Patient", identity="ID-001", **extra):
    return {"clinical_code": code, "identity_document": identity, "full_name": name, **extra}


def _png_bytes():
    output = io.BytesIO()
    Image.new("RGB", (8, 8), "white").save(output, format="PNG")
    return output.getvalue()


def test_new_workspace_registration_and_platform_approval(client, db_session):
    admin = _user(db_session, "platform", role="platform_admin")
    response = client.post("/api/v1/auth/register", json={
        "full_name": "Dr New", "doctor_id": "NEW-1", "email": "new@example.test",
        "password": "secret123", "workspace_choice": "new", "workspace_name": "Nueva Clinica",
    })
    assert response.status_code == 200
    membership = response.json()["data"]["user"]["memberships"][0]
    assert membership["status"] == "pending"
    assert membership["workspace"]["name"] == "Nueva Clinica"
    assert membership["workspace"]["status"] == "pending"

    approval = client.post(
        f"/api/v1/workspaces/{membership['workspace_id']}/approve",
        headers=_headers(admin),
    )
    assert approval.status_code == 200
    stored = db_session.query(models.WorkspaceMembership).filter_by(id=membership["id"]).one()
    assert stored.status == "active"
    assert stored.role == "clinic_admin"


def test_existing_workspace_registration_and_admin_membership_management(client, db_session):
    clinic_admin = _user(db_session, "clinic-admin")
    workspace, _ = _workspace(db_session, clinic_admin, "managed", member_role="clinic_admin")
    response = client.post("/api/v1/auth/register", json={
        "full_name": "Dr Join", "doctor_id": "JOIN-1", "email": "join@example.test",
        "password": "secret123", "workspace_choice": "existing", "workspace_id": workspace.id,
    })
    assert response.status_code == 200
    membership = response.json()["data"]["user"]["memberships"][0]
    assert membership["workspace"]["id"] == workspace.id
    assert membership["status"] == "pending"

    updated = client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{membership['id']}",
        headers=_headers(clinic_admin, workspace), json={"status": "active", "role": "professional"},
    )
    assert updated.status_code == 200
    assert updated.json()["status"] == "active"


def test_registration_workspace_choice_validation_and_independent_creation(client, db_session):
    missing = client.post("/api/v1/auth/register", json={
        "full_name": "Missing", "doctor_id": "MISSING-1", "email": "missing@example.test",
        "password": "secret123", "workspace_choice": "existing", "workspace_id": 999999,
    })
    assert missing.status_code == 400
    unnamed = client.post("/api/v1/auth/register", json={
        "full_name": "Unnamed", "doctor_id": "UNNAMED-1", "email": "unnamed@example.test",
        "password": "secret123", "workspace_choice": "new",
    })
    assert unnamed.status_code == 400
    independent = client.post("/api/v1/auth/register", json={
        "full_name": "Solo Doctor", "doctor_id": "SOLO-1", "email": "solo@example.test",
        "password": "secret123", "workspace_choice": "independent",
    })
    assert independent.status_code == 200
    membership = independent.json()["data"]["user"]["memberships"][0]
    assert membership["workspace"]["workspace_type"] == "independent"
    assert membership["workspace"]["status"] == "pending"


def test_patient_reuse_duplicate_enforcement_and_cross_workspace_denial(client, db_session):
    professional = _user(db_session, "patient-owner")
    workspace, _ = _workspace(db_session, professional, "one")
    other_user = _user(db_session, "other-owner")
    other_workspace, _ = _workspace(db_session, other_user, "two")
    headers = _headers(professional, workspace)

    created = client.post("/api/v1/patients", headers=headers, json=_patient_payload())
    assert created.status_code == 201
    patient_id = created.json()["id"]
    search = client.get("/api/v1/patients?q=P-001", headers=headers)
    assert [item["id"] for item in search.json()] == [patient_id]

    exact = client.post("/api/v1/patients", headers=headers, json=_patient_payload(name="Different"))
    assert exact.status_code == 409
    similar = client.post("/api/v1/patients", headers=headers, json=_patient_payload(code="P-002", identity=None))
    assert similar.status_code == 409
    allowed = client.post("/api/v1/patients", headers=headers, json=_patient_payload(
        code="P-002", identity=None, allow_potential_duplicate=True,
    ))
    assert allowed.status_code == 201

    assert client.get(f"/api/v1/patients/{patient_id}", headers=_headers(other_user, other_workspace)).status_code == 404
    assert client.get(f"/api/v1/patients/{patient_id}", headers=_headers(professional, other_workspace)).status_code == 403


def test_multiple_lesions_and_repeated_evaluations(client, db_session, monkeypatch):
    professional = _user(db_session, "evaluator")
    workspace, _ = _workspace(db_session, professional, "evaluation")
    headers = _headers(professional, workspace)
    patient = client.post("/api/v1/patients", headers=headers, json=_patient_payload(code="E-1")).json()
    lesion_one = client.post(f"/api/v1/patients/{patient['id']}/lesions", headers=headers, json={
        "anatomical_site": "tongue", "observed_at": "2026-01-01",
    })
    lesion_two = client.post(f"/api/v1/patients/{patient['id']}/lesions", headers=headers, json={
        "anatomical_site": "gingiva", "estimated_duration": "two weeks",
    })
    assert lesion_one.status_code == lesion_two.status_code == 201
    assert len(client.get(f"/api/v1/patients/{patient['id']}/lesions", headers=headers).json()) == 2

    monkeypatch.setattr("routers.predict.classifier.predict", lambda image: {
        "prediction": "benign", "confidence": 0.8,
        "probabilities": {"benign": 0.8, "malignant": 0.2},
    })
    monkeypatch.setattr("routers.predict.upload_image", lambda *args, **kwargs: "https://images.example.test/test.png")
    form = {"consent_to_store": "true", "patient_id": str(patient["id"]), "lesion_id": str(lesion_one.json()["id"])}
    files = {"file": ("lesion.png", _png_bytes(), "image/png")}
    first = client.post("/api/v1/predict", headers=headers, data=form, files=files)
    second = client.post("/api/v1/predict", headers=headers, data=form, files=files)
    assert first.status_code == second.status_code == 200
    detail = client.get(f"/api/v1/lesions/{lesion_one.json()['id']}", headers=headers).json()
    assert len(detail["evaluations"]) == 2
    assert db_session.query(models.ModelPrediction).count() == 2
    assert db_session.query(models.ConsentAttestation).count() == 2


def test_missing_attestation_does_not_infer_or_persist(client, db_session, monkeypatch):
    professional = _user(db_session, "no-consent")
    workspace, _ = _workspace(db_session, professional, "no-consent")
    patient = models.Patient(
        workspace_id=workspace.id, clinical_code="NC-1", full_name="No Consent",
        normalized_name="no consent", created_by_id=professional.id,
    )
    db_session.add(patient)
    db_session.flush()
    lesion = models.OralLesion(
        workspace_id=workspace.id, patient_id=patient.id, anatomical_site="lip",
        estimated_duration="one day", created_by_id=professional.id,
    )
    db_session.add(lesion)
    db_session.flush()
    called = False

    def unexpected(_image):
        nonlocal called
        called = True

    monkeypatch.setattr("routers.predict.classifier.predict", unexpected)
    response = client.post("/api/v1/predict", headers=_headers(professional, workspace), data={
        "consent_to_store": "false", "patient_id": patient.id, "lesion_id": lesion.id,
    }, files={"file": ("lesion.png", _png_bytes(), "image/png")})
    assert response.status_code == 400
    assert called is False
    assert db_session.query(models.ClinicalEvaluation).count() == 0


def test_assistant_cannot_create_patient_lesion_or_prediction(client, db_session):
    assistant = _user(db_session, "assistant")
    workspace, _ = _workspace(db_session, assistant, "assistant", member_role="assistant")
    headers = _headers(assistant, workspace)
    assert client.post("/api/v1/patients", headers=headers, json=_patient_payload()).status_code == 403
    patient = models.Patient(
        workspace_id=workspace.id, clinical_code="A-1", full_name="Assistant Patient",
        normalized_name="assistant patient", created_by_id=assistant.id,
    )
    db_session.add(patient)
    db_session.flush()
    assert client.post(f"/api/v1/patients/{patient.id}/lesions", headers=headers, json={
        "anatomical_site": "tongue", "estimated_duration": "one week",
    }).status_code == 403
    response = client.post("/api/v1/predict", headers=headers, data={
        "consent_to_store": "true", "patient_id": patient.id, "lesion_id": 1,
    }, files={"file": ("lesion.png", _png_bytes(), "image/png")})
    assert response.status_code == 403
