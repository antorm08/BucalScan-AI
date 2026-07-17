import io
from datetime import datetime

from PIL import Image

from auth.jwt import create_access_token
from auth.security import get_password_hash
from models import models
from services.evaluation_pdf_report import _asset_bytes, build_evaluation_pdf


def _user(db, suffix):
    user = models.User(
        full_name=f"Dra. {suffix}",
        doctor_id=f"DOC-{suffix}",
        email=f"{suffix}@example.test",
        hashed_password=get_password_hash("secret123"),
        role="professional",
        status="active",
        profession="Odontologa",
    )
    db.add(user)
    db.flush()
    return user


def _workspace(db, user, suffix):
    workspace = models.ClinicalWorkspace(
        name=f"Clinica {suffix}",
        normalized_name=f"clinica {suffix}".lower(),
        workspace_type="clinic",
        status="active",
        initial_requester_id=user.id,
    )
    db.add(workspace)
    db.flush()
    db.add(
        models.WorkspaceMembership(
            workspace_id=workspace.id,
            user_id=user.id,
            role="professional",
            status="active",
        )
    )
    db.flush()
    return workspace


def _headers(user, workspace):
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {
        "Authorization": f"Bearer {token}",
        "X-Workspace-ID": str(workspace.id),
    }


def _records(db, suffix="report", *, with_priority=False):
    professional = _user(db, suffix)
    workspace = _workspace(db, professional, suffix)
    patient = models.Patient(
        workspace_id=workspace.id,
        clinical_code=f"P-{suffix}",
        identity_document=f"SECRET-{suffix}",
        full_name="Paciente Privado",
        normalized_name="paciente privado",
        telephone="555-0101",
        created_by_id=professional.id,
    )
    db.add(patient)
    db.flush()
    lesion = models.OralLesion(
        workspace_id=workspace.id,
        patient_id=patient.id,
        anatomical_site="Borde lateral de lengua",
        status="monitoring",
        created_by_id=professional.id,
    )
    db.add(lesion)
    db.flush()
    evaluation = models.ClinicalEvaluation(
        workspace_id=workspace.id,
        patient_id=patient.id,
        lesion_id=lesion.id,
        professional_id=professional.id,
        clinical_observations="Borde regular sin ulceracion",
        evaluated_at=datetime(2026, 7, 16, 14, 30),
    )
    db.add(evaluation)
    db.flush()
    image = models.LesionImage(
        evaluation_id=evaluation.id,
        storage_url="missing-source.png",
        content_type="image/png",
        original_filename="lesion.png",
    )
    db.add(image)
    db.flush()
    prediction = models.ModelPrediction(
        evaluation_id=evaluation.id,
        image_id=image.id,
        model_version="resnet50-test",
        predicted_label="benign",
        confidence=0.81,
        benign_probability=0.81,
        malignant_probability=0.19,
        heatmap_url="missing-cam.png",
    )
    db.add(prediction)
    if with_priority:
        snapshot = models.ClinicalAssessmentSnapshot(
            workspace_id=workspace.id,
            patient_id=patient.id,
            lesion_id=lesion.id,
            evaluation_id=evaluation.id,
            assessor_id=professional.id,
            schema_version="1",
            ruleset_version="draft",
            canonical_payload={},
            completion_status="complete",
        )
        db.add(snapshot)
        db.flush()
        db.add(
            models.ClinicalPriorityResult(
                assessment_id=snapshot.id,
                workspace_id=workspace.id,
                evaluation_id=evaluation.id,
                priority_code="prompt",
                reason_codes=["persistent"],
                rendered_reasons=["Persistencia registrada"],
                ruleset_id="clinical-priority-v1-draft",
                ruleset_version="draft",
                engine_version="1",
            )
        )
    db.flush()
    return professional, workspace, patient, lesion, evaluation


def _png_bytes(width=32, height=24):
    output = io.BytesIO()
    Image.new("RGB", (width, height), "#5b8f96").save(output, format="PNG")
    return output.getvalue()


def test_report_service_embeds_safe_text_and_survives_missing_assets(db_session):
    professional, _, patient, lesion, evaluation = _records(
        db_session, with_priority=True
    )

    pdf = build_evaluation_pdf(
        patient=patient,
        lesion=lesion,
        evaluation=evaluation,
        professional=professional,
    )
    decoded = pdf.decode("latin-1")

    assert pdf.startswith(b"%PDF-")
    assert "Borde regular sin ulceracion" in decoded
    assert "resnet50-test" in decoded
    assert "Persistencia registrada" in decoded
    assert "Imagen no disponible" in decoded
    assert "Mapa CAM no disponible" in decoded
    assert "SECRET-report" not in decoded
    assert "555-0101" not in decoded


def test_report_service_embeds_available_source_and_cam(db_session, monkeypatch):
    professional, _, patient, lesion, evaluation = _records(db_session, "images")
    monkeypatch.setattr(
        "services.evaluation_pdf_report._asset_bytes", lambda _: _png_bytes()
    )

    pdf = build_evaluation_pdf(
        patient=patient,
        lesion=lesion,
        evaluation=evaluation,
        professional=professional,
    )

    assert pdf.startswith(b"%PDF-")
    assert b"Imagen no disponible" not in pdf
    assert b"Mapa CAM no disponible" not in pdf


def test_report_service_bounds_tall_images(db_session, monkeypatch):
    professional, _, patient, lesion, evaluation = _records(db_session, "tall")
    monkeypatch.setattr(
        "services.evaluation_pdf_report._asset_bytes",
        lambda _: _png_bytes(120, 1600),
    )

    pdf = build_evaluation_pdf(
        patient=patient,
        lesion=lesion,
        evaluation=evaluation,
        professional=professional,
    )

    assert pdf.startswith(b"%PDF-")


def test_report_service_rejects_untrusted_remote_assets():
    assert _asset_bytes("https://127.0.0.1/private.png") is None
    assert _asset_bytes("https://images.example.test/lesion.png") is None
    assert _asset_bytes("http://res.cloudinary.com/insecure.png") is None


def test_report_service_wraps_long_dynamic_values(db_session):
    professional, _, patient, lesion, evaluation = _records(db_session, "long")
    patient.clinical_code = "P-" + "1234567890" * 30
    lesion.anatomical_site = "Borde lateral " * 50
    professional.full_name = "Profesional " * 40
    evaluation.prediction.model_version = "modelo-" * 50

    pdf = build_evaluation_pdf(
        patient=patient,
        lesion=lesion,
        evaluation=evaluation,
        professional=professional,
    )

    assert pdf.startswith(b"%PDF-")


def test_report_endpoint_returns_pdf_and_enforces_resource_scope(client, db_session):
    professional, workspace, _, lesion, evaluation = _records(db_session, "endpoint")
    headers = _headers(professional, workspace)
    other_lesion = models.OralLesion(
        workspace_id=workspace.id,
        patient_id=evaluation.patient_id,
        anatomical_site="Encia",
        status="active",
        created_by_id=professional.id,
    )
    db_session.add(other_lesion)
    other_user, other_workspace, _, _, _ = _records(db_session, "other")
    db_session.flush()

    response = client.get(
        f"/api/v1/lesions/{lesion.id}/evaluations/{evaluation.id}/report.pdf",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.headers["cache-control"] == "private, no-store"
    assert response.headers["content-disposition"] == (
        f'attachment; filename="bucalscan-evaluacion-{evaluation.id}.pdf"'
    )
    assert response.content.startswith(b"%PDF-")
    mismatch = client.get(
        f"/api/v1/lesions/{other_lesion.id}/evaluations/{evaluation.id}/report.pdf",
        headers=headers,
    )
    assert mismatch.status_code == 404
    cross_workspace = client.get(
        f"/api/v1/lesions/{lesion.id}/evaluations/{evaluation.id}/report.pdf",
        headers=_headers(other_user, other_workspace),
    )
    assert cross_workspace.status_code == 404


def test_report_endpoint_requires_authentication(client, db_session):
    _, _, _, lesion, evaluation = _records(db_session, "auth")

    response = client.get(
        f"/api/v1/lesions/{lesion.id}/evaluations/{evaluation.id}/report.pdf"
    )

    assert response.status_code in {401, 403}
