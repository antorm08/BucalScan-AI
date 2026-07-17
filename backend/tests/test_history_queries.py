from datetime import datetime
from types import SimpleNamespace

from auth.jwt import create_access_token
from crud import get_daily_summary
from models import models


def _headers(user, workspace):
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"Authorization": f"Bearer {token}", "X-Workspace-ID": str(workspace.id)}


def _workspace(db, suffix):
    user = models.User(
        full_name=f"Dra. Ángela {suffix}", doctor_id=f"DOC-{suffix}",
        email=f"{suffix}@history.test", hashed_password="unused", role="professional",
        status="active", profession="Odontóloga", specialty="Patología oral",
    )
    db.add(user)
    db.flush()
    workspace = models.ClinicalWorkspace(
        name=f"History {suffix}", normalized_name=f"history {suffix}",
        workspace_type="clinic", status="active", initial_requester_id=user.id,
    )
    db.add(workspace)
    db.flush()
    db.add(models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=user.id, role="professional", status="active",
    ))
    db.flush()
    return user, workspace


def _analysis(db, user, workspace, suffix, *, when, label="benign", confidence=0.8,
              site="Lengua lateral", priority=None):
    patient = models.Patient(
        workspace_id=workspace.id, clinical_code=f"CÓD-{suffix}",
        full_name=f"José Paciente {suffix}", normalized_name=f"jose paciente {suffix.lower()}",
        created_by_id=user.id,
    )
    db.add(patient)
    db.flush()
    lesion = models.OralLesion(
        workspace_id=workspace.id, patient_id=patient.id, anatomical_site=site,
        created_by_id=user.id,
    )
    db.add(lesion)
    db.flush()
    evaluation = models.ClinicalEvaluation(
        workspace_id=workspace.id, patient_id=patient.id, lesion_id=lesion.id,
        professional_id=user.id, clinical_observations=f"Hallazgo {suffix}", evaluated_at=when,
    )
    db.add(evaluation)
    db.flush()
    image = models.LesionImage(
        evaluation_id=evaluation.id,
        storage_url=f"https://images.test/{suffix}.png",
        content_type="image/png",
    )
    db.add(image)
    db.flush()
    db.add(models.ModelPrediction(
        evaluation_id=evaluation.id, image_id=image.id, model_version="resnet-v1",
        predicted_label=label, confidence=confidence,
        benign_probability=confidence if label == "benign" else 1 - confidence,
        malignant_probability=confidence if label == "malignant" else 1 - confidence,
        created_at=when,
    ))
    if priority:
        snapshot = models.ClinicalAssessmentSnapshot(
            workspace_id=workspace.id, patient_id=patient.id, lesion_id=lesion.id,
            evaluation_id=evaluation.id, assessor_id=user.id, schema_version="1",
            ruleset_version="v1", canonical_payload={}, completion_status="complete",
            assessed_at=when,
        )
        db.add(snapshot)
        db.flush()
        db.add(models.ClinicalPriorityResult(
            assessment_id=snapshot.id, workspace_id=workspace.id,
            evaluation_id=evaluation.id, priority_code=priority,
            reason_codes=["reason"], rendered_reasons=["Reason"],
            ruleset_id="clinical", ruleset_version="v1", engine_version="1",
            evaluated_at=when,
        ))
    db.flush()
    return evaluation


def test_history_tenant_search_filters_details_and_totals(client, db_session, monkeypatch):
    user, workspace = _workspace(db_session, "owner")
    outsider, other = _workspace(db_session, "other")
    first = _analysis(
        db_session, user, workspace, "ALFA", when=datetime(2026, 1, 1, 10),
        label="benign", site="Mucosa yugal", priority="standard",
    )
    second = _analysis(
        db_session, user, workspace, "BETA", when=datetime(2026, 1, 2, 10),
        label="malignant", confidence=0.9, site="Paladar duro", priority="urgent",
    )
    _analysis(db_session, outsider, other, "FOREIGN", when=datetime(2026, 1, 3, 10))
    db_session.commit()
    monkeypatch.setattr("routers.history.settings", SimpleNamespace(clinical_priority_mode="academic"))
    headers = _headers(user, workspace)

    page = client.get("/api/v1/history?page_size=1", headers=headers).json()
    assert page == {**page, "page": 1, "page_size": 1, "total": 2, "has_next": True,
                    "priority_filter_enabled": True}
    assert page["items"][0]["id"] == second.id
    assert page["items"][0]["lesion_site"] == "Paladar duro"
    assert page["items"][0]["clinical_observations"] == "Hallazgo BETA"
    assert page["items"][0]["professional_profession"] == "Odontóloga"

    for search in ("jose", "CÓD-BETA", "paladar", "angela", "patologia"):
        result = client.get("/api/v1/history", params={"search": search}, headers=headers).json()
        assert result["total"] >= 1
    assert client.get("/api/v1/history?model_label=malignant", headers=headers).json()["items"][0]["id"] == second.id
    assert client.get("/api/v1/history?priority=standard", headers=headers).json()["items"][0]["id"] == first.id


def test_history_inclusive_dates_stable_sort_empty_pages_and_validation(client, db_session):
    user, workspace = _workspace(db_session, "dates")
    same = datetime(2026, 2, 2, 12, 30)
    first = _analysis(db_session, user, workspace, "ONE", when=same, confidence=0.5)
    second = _analysis(db_session, user, workspace, "TWO", when=same, confidence=0.5)
    db_session.commit()
    headers = _headers(user, workspace)

    result = client.get(
        "/api/v1/history",
        params={"date_from": "2026-02-02T12:30:00Z", "date_to": "2026-02-02T12:30:00Z"},
        headers=headers,
    ).json()
    assert [item["id"] for item in result["items"]] == [second.id, first.id]
    ascending = client.get(
        "/api/v1/history?sort_by=confidence&sort_direction=asc", headers=headers,
    ).json()
    assert [item["id"] for item in ascending["items"]] == [first.id, second.id]
    empty = client.get("/api/v1/history?page=3&page_size=1", headers=headers).json()
    assert empty["items"] == [] and empty["total"] == 2 and empty["has_next"] is False

    invalid_queries = (
        "page=0", "page_size=101", "sort_by=drop_table", "sort_direction=sideways",
        "model_label=unknown", "date_from=2026-02-03T00:00:00Z&date_to=2026-02-02T00:00:00Z",
        "date_from=2026-02-02T00:00:00",
    )
    for query in invalid_queries:
        assert client.get(f"/api/v1/history?{query}", headers=headers).status_code == 422


def test_history_priority_filter_fails_closed_when_disabled(client, db_session, monkeypatch):
    user, workspace = _workspace(db_session, "disabled")
    _analysis(db_session, user, workspace, "ROW", when=datetime(2026, 3, 1), priority="urgent")
    db_session.commit()
    monkeypatch.setattr("routers.history.settings", SimpleNamespace(clinical_priority_mode="disabled"))
    headers = _headers(user, workspace)

    ordinary = client.get("/api/v1/history", headers=headers)
    assert ordinary.status_code == 200
    assert ordinary.json()["priority_filter_enabled"] is False
    assert ordinary.json()["items"][0]["priority"]["priority_code"] == "urgent"
    assert client.get("/api/v1/history?priority=urgent", headers=headers).status_code == 422


def test_daily_summary_uses_normalized_predictions_and_workspace_scope(db_session):
    owner, workspace = _workspace(db_session, "summary-owner")
    outsider, other = _workspace(db_session, "summary-other")
    day = datetime(2026, 4, 5, 9)
    _analysis(db_session, owner, workspace, "SUMMARY-A", when=day, label="benign")
    _analysis(
        db_session, owner, workspace, "SUMMARY-B",
        when=datetime(2026, 4, 5, 11), label="malignant",
    )
    _analysis(db_session, outsider, other, "SUMMARY-C", when=day, label="malignant")
    db_session.commit()

    summary = get_daily_summary(db_session, date_target=day.date(), workspace_id=workspace.id)

    assert summary == {
        "total": 2,
        "benign": 1,
        "malignant": 1,
        "latest_analysis_at": datetime(2026, 4, 5, 11),
    }
    assert db_session.query(models.Analysis).count() == 0
