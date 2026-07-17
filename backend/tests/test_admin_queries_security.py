from auth.jwt import create_access_token
from models import models


def _user(db, suffix, *, role="professional", status="active"):
    user = models.User(
        full_name=f"Admin Query {suffix}", doctor_id=f"AQ-{suffix}", email=f"aq-{suffix}@example.test",
        hashed_password="hash", role=role, status=status, profession="Dentist", specialty="Oral medicine",
    )
    db.add(user)
    db.flush()
    return user


def _headers(user, workspace=None):
    headers = {"Authorization": f"Bearer {create_access_token({'sub': str(user.id)})}"}
    if workspace:
        headers["X-Workspace-ID"] = str(workspace.id)
    return headers


def _workspace(db, owner, suffix, *, workspace_type="clinic", status="active", role="clinic_admin", member_status="active"):
    workspace = models.ClinicalWorkspace(
        name=f"Center {suffix}", normalized_name=f"center {suffix}", workspace_type=workspace_type,
        status=status, city="Quito", address="Av. Central 123", initial_requester_id=owner.id,
    )
    db.add(workspace)
    db.flush()
    membership = models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=owner.id, role=role, status=member_status,
    )
    db.add(membership)
    db.flush()
    return workspace, membership


def test_paginated_admin_centers_access_and_users_contracts(client, db_session):
    admin = _user(db_session, "admin", role="platform_admin")
    owner = _user(db_session, "owner")
    center, membership = _workspace(db_session, owner, "needle", status="pending", member_status="pending")
    centers = client.get(
        "/api/v1/admin/centers?search=Needle&status=pending&page=1&page_size=1&sort_by=name&sort_direction=asc",
        headers=_headers(admin),
    )
    assert centers.status_code == 200
    assert centers.json()["total"] == 1
    assert centers.json()["has_next"] is False
    assert centers.json()["items"][0]["requester"]["specialty"] == "Oral medicine"

    center.status = "active"
    db_session.flush()
    access = client.get(
        "/api/v1/admin/access?search=needle&status=pending&role=clinic_admin&page_size=10",
        headers=_headers(admin),
    )
    assert access.status_code == 200
    assert access.json()["items"][0]["workspace"]["id"] == center.id
    users = client.get("/api/v1/admin/users?search=owner&status=active&page_size=10", headers=_headers(admin))
    assert users.status_code == 200
    assert users.json()["total"] == 1
    assert users.json()["items"][0]["memberships"][0]["workspace_id"] == center.id
    assert client.get("/api/v1/admin/users?page_size=101", headers=_headers(admin)).status_code == 422
    assert client.get("/api/v1/admin/centers?sort_by=hashed_password", headers=_headers(admin)).status_code == 422


def test_suspended_requester_cannot_receive_workspace_approval(client, db_session):
    admin = _user(db_session, "suspension-admin", role="platform_admin")
    requester = _user(db_session, "suspended", status="suspended")
    workspace, membership = _workspace(db_session, requester, "suspended", status="pending", member_status="pending")
    response = client.post(f"/api/v1/admin/workspaces/{workspace.id}/approve", headers=_headers(admin))
    assert response.status_code == 409
    assert workspace.status == membership.status == "pending"


def test_independent_approval_forces_professional_role(client, db_session):
    admin = _user(db_session, "independent-admin", role="platform_admin")
    requester = _user(db_session, "independent-owner")
    workspace, membership = _workspace(
        db_session, requester, "independent", workspace_type="independent", status="pending",
        role="clinic_admin", member_status="pending",
    )
    response = client.post(
        f"/api/v1/admin/memberships/{membership.id}/approve", headers=_headers(admin), json={"role": "clinic_admin"},
    )
    assert response.status_code == 200
    assert response.json()["role"] == "professional"


def test_global_suspension_protects_last_active_clinic_admin(client, db_session):
    admin = _user(db_session, "global-admin", role="platform_admin")
    clinic_admin = _user(db_session, "sole-clinic-admin")
    workspace, _ = _workspace(db_session, clinic_admin, "protected")
    response = client.patch(
        f"/api/v1/admin/users/{clinic_admin.id}/status", headers=_headers(admin), json={"status": "suspended"},
    )
    assert response.status_code == 409
    assert clinic_admin.status == "active"
    replacement = _user(db_session, "replacement")
    db_session.add(models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=replacement.id, role="clinic_admin", status="active",
    ))
    db_session.flush()
    assert client.patch(
        f"/api/v1/admin/users/{clinic_admin.id}/status", headers=_headers(admin), json={"status": "suspended"},
    ).status_code == 200


def test_platform_admin_needs_explicit_membership_for_active_clinical_workspace(client, db_session):
    admin = _user(db_session, "clinical-admin", role="platform_admin")
    owner = _user(db_session, "clinical-owner")
    workspace, _ = _workspace(db_session, owner, "clinical")
    assert client.get("/api/v1/patients", headers=_headers(admin, workspace)).status_code == 403
