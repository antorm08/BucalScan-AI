import json
import itertools
from types import SimpleNamespace

from auth.jwt import create_access_token
from models import models
from schemas import ClinicalAssessmentInput
from services.clinical_priority import canonicalize, evaluate_priority


FIELDS = tuple(ClinicalAssessmentInput.model_fields)


def _answers(**overrides):
    values = {field: "false" for field in FIELDS}
    values.update(overrides)
    return values


def _user(db, suffix, role="professional"):
    user = models.User(
        full_name=f"Priority {suffix}", doctor_id=f"PRI-{suffix}",
        email=f"priority-{suffix}@example.test", hashed_password="hash", role=role,
    )
    db.add(user)
    db.flush()
    return user


def _clinical_records(db, user, suffix):
    workspace = models.ClinicalWorkspace(
        name=f"Priority {suffix}", normalized_name=f"priority {suffix}", workspace_type="clinic", status="active",
    )
    db.add(workspace)
    db.flush()
    db.add(models.WorkspaceMembership(workspace_id=workspace.id, user_id=user.id, role="professional", status="active"))
    patient = models.Patient(
        workspace_id=workspace.id, clinical_code=f"P-{suffix}", full_name="Priority Patient",
        normalized_name="priority patient", created_by_id=user.id,
    )
    db.add(patient)
    db.flush()
    lesion = models.OralLesion(
        workspace_id=workspace.id, patient_id=patient.id, anatomical_site="tongue",
        estimated_duration="two weeks", created_by_id=user.id,
    )
    db.add(lesion)
    db.flush()
    evaluation = models.ClinicalEvaluation(
        workspace_id=workspace.id, patient_id=patient.id, lesion_id=lesion.id, professional_id=user.id,
    )
    db.add(evaluation)
    db.flush()
    return workspace, evaluation


def _headers(user, workspace):
    return {
        "Authorization": f"Bearer {create_access_token({'sub': str(user.id)})}",
        "X-Workspace-ID": str(workspace.id),
    }


def test_scoring_boundaries_determinism_and_monotonic_behavior():
    standard = evaluate_priority(_answers(pain="true"))
    below_prompt = evaluate_priority(_answers(ulceration="true", pain="true"))
    prompt = evaluate_priority(_answers(ulceration="true", unexplained_bleeding="true"))
    below_urgent = evaluate_priority(_answers(
        ulceration="true", unexplained_bleeding="true", red_or_white_change="true", pain="true"
    ))
    urgent = evaluate_priority(_answers(
        ulceration="true", unexplained_bleeding="true", red_or_white_change="true", tobacco_exposure="true"
    ))
    assert [standard.priority_code, below_prompt.priority_code, prompt.priority_code] == ["standard", "standard", "prompt"]
    assert below_urgent.priority_code == "prompt"
    assert urgent.priority_code == "urgent"
    assert evaluate_priority(_answers(**{field: "true" for field in FIELDS})).priority_code == "emergency"
    assert evaluate_priority(_answers(ulceration="true", unexplained_bleeding="true")) == prompt


def test_every_priority_category_combinations_and_reason_order_are_deterministic():
    cases = [
        (_answers(), "standard", ("priority.standard.complete",)),
        (_answers(ulceration="true", unexplained_bleeding="true"), "prompt", ("priority.prompt.score",)),
        (_answers(persistence_over_two_weeks="true", ulceration="true"), "prompt", ("priority.prompt.score", "priority.prompt.persistence_sign")),
        (_answers(induration_or_fixation="true", rapid_growth="true"), "urgent", ("priority.urgent.high_concern_combination",)),
        (_answers(ulceration="true", induration_or_fixation="true", rapid_growth="true"), "urgent", ("priority.urgent.score", "priority.urgent.high_concern_combination")),
        (_answers(uncontrolled_bleeding="true"), "emergency", ("emergency.uncontrolled_bleeding",)),
    ]
    for answers, expected_code, expected_reasons in cases:
        first = evaluate_priority(answers)
        assert first.priority_code == expected_code
        assert first.reason_codes == expected_reasons
        for _ in range(20):
            assert evaluate_priority(dict(reversed(tuple(answers.items())))) == first

    incomplete = _answers()
    incomplete["ulceration"] = "unknown"
    assert evaluate_priority(incomplete).priority_code == "incomplete"


def test_engine_is_total_and_deterministic_for_representative_tristate_space():
    variable_fields = tuple(FIELDS[:6]) + tuple(FIELDS[-4:])
    for index, values in enumerate(itertools.product(("false", "true", "unknown"), repeat=len(variable_fields))):
        if index % 97 != 0:
            continue
        answers = _answers(**dict(zip(variable_fields, values)))
        first = evaluate_priority(answers)
        second = evaluate_priority(dict(answers))
        assert first == second
        assert first.priority_code in {"incomplete", "standard", "prompt", "urgent", "emergency"}
        assert len(first.reason_codes) == len(first.rendered_reasons)


def test_missing_fields_and_confirmed_emergency_override_are_ordered():
    incomplete = evaluate_priority(canonicalize(ClinicalAssessmentInput(ulceration="false")))
    assert incomplete.priority_code == "incomplete"
    assert incomplete.reason_codes[0] == "missing.induration_or_fixation"
    emergency = evaluate_priority(canonicalize(ClinicalAssessmentInput(airway_compromise="true")))
    assert emergency.priority_code == "emergency"
    assert emergency.reason_codes == ("emergency.airway_compromise",)
    assert emergency.completion_status == "incomplete"


def test_capability_defaults_off_and_unknown_version_fails_closed(client, monkeypatch):
    response = client.get("/api/v1/clinical-priority/capabilities")
    assert response.json()["mode"] == "disabled"
    monkeypatch.setattr("routers.priority.settings", SimpleNamespace(
        clinical_priority_mode="academic", clinical_priority_ruleset="retired-version"
    ))
    assert client.get("/api/v1/clinical-priority/capabilities").json()["available"] is False


def test_priority_persistence_is_tenant_scoped_immutable_and_model_separate(client, db_session, monkeypatch):
    monkeypatch.setattr("routers.priority.settings", SimpleNamespace(
        clinical_priority_mode="academic", clinical_priority_ruleset="clinical-priority-v1-draft"
    ))
    owner = _user(db_session, "owner")
    workspace, evaluation = _clinical_records(db_session, owner, "one")
    outsider = _user(db_session, "outsider")
    other_workspace, _ = _clinical_records(db_session, outsider, "two")
    payload = {"evaluation_id": evaluation.id, "assessment": _answers(ulceration="true", unexplained_bleeding="true")}
    response = client.post("/api/v1/clinical-priority/assessments", headers=_headers(owner, workspace), json=payload)
    assert response.status_code == 201
    assert response.json()["priority_code"] == "prompt"
    assert db_session.query(models.ModelPrediction).count() == 0
    assert db_session.query(models.ClinicalAssessmentSnapshot).count() == 1
    assert db_session.query(models.ClinicalPriorityResult).count() == 1
    assert client.post("/api/v1/clinical-priority/assessments", headers=_headers(owner, workspace), json=payload).status_code == 409
    assert client.get(
        f"/api/v1/clinical-priority/evaluations/{evaluation.id}", headers=_headers(outsider, other_workspace)
    ).status_code == 404
    assert client.patch(
        f"/api/v1/clinical-priority/evaluations/{evaluation.id}", headers=_headers(owner, workspace), json={}
    ).status_code == 405


def test_platform_admin_role_alone_has_no_clinical_priority_access(client, db_session, monkeypatch):
    monkeypatch.setattr("routers.priority.settings", SimpleNamespace(
        clinical_priority_mode="academic", clinical_priority_ruleset="clinical-priority-v1-draft"
    ))
    professional = _user(db_session, "member")
    workspace, evaluation = _clinical_records(db_session, professional, "admin-denied")
    admin = _user(db_session, "admin", "platform_admin")
    response = client.post(
        "/api/v1/clinical-priority/assessments",
        headers=_headers(admin, workspace),
        json={"evaluation_id": evaluation.id, "assessment": _answers()},
    )
    assert response.status_code == 403
    assert db_session.query(models.ClinicalAssessmentSnapshot).count() == 0


def test_predict_rejects_invalid_assessment_without_inference(client, db_session, monkeypatch):
    owner = _user(db_session, "predict-invalid")
    workspace, evaluation = _clinical_records(db_session, owner, "predict-invalid")
    called = False

    def inference(_image):
        nonlocal called
        called = True

    monkeypatch.setattr("routers.predict.classifier.predict", inference)
    response = client.post(
        "/api/v1/predict", headers=_headers(owner, workspace),
        data={
            "consent_to_store": "true", "patient_id": evaluation.patient_id, "lesion_id": evaluation.lesion_id,
            "assessment": json.dumps({"unsupported": "true"}),
        },
        files={"file": ("lesion.png", b"not needed", "image/png")},
    )
    assert response.status_code == 422
    assert called is False
