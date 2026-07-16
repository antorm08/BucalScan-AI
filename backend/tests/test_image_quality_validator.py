import io

import numpy as np
import pytest
from PIL import Image

from auth.jwt import create_access_token
from auth.security import get_password_hash
from models import models
from services.image_quality_validator import validate_image_quality


def _textured_image(width=256, height=256):
    grid = np.indices((height, width)).sum(axis=0) % 2
    pixels = np.where(grid[:, :, None] == 0, 80, 180).astype(np.uint8)
    return Image.fromarray(np.repeat(pixels, 3, axis=2), mode="RGB")


def _png_bytes(image):
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


@pytest.mark.parametrize(
    ("image", "reason"),
    [
        (Image.new("RGB", (100, 256), (128, 128, 128)), "low_resolution"),
        (Image.new("RGB", (256, 256), (128, 128, 128)), "blurry"),
        (Image.new("RGB", (256, 256), (0, 0, 0)), "too_dark"),
        (Image.new("RGB", (256, 256), (255, 255, 255)), "overexposed"),
    ],
)
def test_rejects_each_quality_problem(image, reason):
    result = validate_image_quality(image)

    assert result.is_valid is False
    assert reason in result.reasons


def test_accepts_sharp_evenly_lit_image():
    result = validate_image_quality(_textured_image())

    assert result.is_valid is True
    assert result.reasons == ()
    assert result.blur_score >= 100
    assert result.dark_ratio == 0
    assert result.bright_ratio == 0


def test_predict_rejects_quality_before_inference_or_persistence(client, db_session, monkeypatch, caplog):
    user = models.User(
        full_name="Quality Professional",
        doctor_id="QUALITY-1",
        email="quality@example.test",
        hashed_password=get_password_hash("secret123"),
        role="professional",
        status="active",
    )
    db_session.add(user)
    db_session.flush()
    workspace = models.ClinicalWorkspace(
        name="Quality Clinic",
        normalized_name="quality clinic",
        workspace_type="clinic",
        status="active",
        initial_requester_id=user.id,
    )
    db_session.add(workspace)
    db_session.flush()
    db_session.add(models.WorkspaceMembership(
        workspace_id=workspace.id,
        user_id=user.id,
        role="professional",
        status="active",
    ))
    patient = models.Patient(
        workspace_id=workspace.id,
        clinical_code="QUALITY-PATIENT",
        full_name="Quality Patient",
        normalized_name="quality patient",
        created_by_id=user.id,
    )
    db_session.add(patient)
    db_session.flush()
    lesion = models.OralLesion(
        workspace_id=workspace.id,
        patient_id=patient.id,
        anatomical_site="tongue",
        estimated_duration="one week",
        created_by_id=user.id,
    )
    db_session.add(lesion)
    db_session.commit()

    def unexpected(*_args, **_kwargs):
        pytest.fail("Rejected image must not reach inference or storage")

    monkeypatch.setattr("routers.predict.classifier.predict", unexpected)
    monkeypatch.setattr("routers.predict.upload_image", unexpected)
    token = create_access_token({"sub": str(user.id), "email": user.email})
    response = client.post(
        "/api/v1/predict",
        headers={
            "Authorization": f"Bearer {token}",
            "X-Workspace-ID": str(workspace.id),
        },
        data={
            "consent_to_store": "true",
            "patient_id": patient.id,
            "lesion_id": lesion.id,
        },
        files={
            "file": (
                "blurry.png",
                _png_bytes(Image.new("RGB", (256, 256), (128, 128, 128))),
                "image/png",
            )
        },
    )

    assert response.status_code == 422
    assert "too blurry" in response.json()["detail"]
    assert "Image quality rejected" in caplog.text
    assert db_session.query(models.ClinicalEvaluation).count() == 0
    assert db_session.query(models.ModelPrediction).count() == 0
