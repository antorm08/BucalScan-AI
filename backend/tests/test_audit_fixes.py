from auth.jwt import create_access_token
from auth.security import get_password_hash
from models import models


def _user(db, suffix, *, role="professional", status="active"):
    user = models.User(
        full_name=f"User {suffix}", doctor_id=f"AUD-{suffix}",
        email=f"{suffix}@example.test", hashed_password=get_password_hash("secret123"),
        role=role, status=status,
    )
    db.add(user)
    db.flush()
    return user


def _workspace(db, user, suffix, *, status="active", role="professional", member_status="active"):
    workspace = models.ClinicalWorkspace(
        name=f"Audit {suffix}", normalized_name=f"audit {suffix}", workspace_type="clinic",
        status=status, city="Quito", address="Av. Central 123", initial_requester_id=user.id,
    )
    db.add(workspace)
    db.flush()
    membership = models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=user.id, role=role, status=member_status,
    )
    db.add(membership)
    db.flush()
    return workspace, membership


def _headers(user, workspace=None):
    headers = {"Authorization": f"Bearer {create_access_token({'sub': str(user.id)})}"}
    if workspace:
        headers["X-Workspace-ID"] = str(workspace.id)
    return headers


def test_pending_workspace_blocks_members_and_platform_admin(client, db_session):
    member = _user(db_session, "pending-member")
    workspace, _ = _workspace(db_session, member, "pending", status="pending")
    admin = _user(db_session, "platform-audit", role="platform_admin")

    assert client.get("/api/v1/patients", headers=_headers(member, workspace)).status_code == 403
    assert client.get("/api/v1/patients", headers=_headers(admin, workspace)).status_code == 403


def test_discovery_returns_active_and_pending_workspaces(client, db_session):
    owner = _user(db_session, "discover-owner")
    active, _ = _workspace(db_session, owner, "visible")
    pending, _ = _workspace(db_session, owner, "pending", status="pending")
    hidden, _ = _workspace(db_session, owner, "hidden", status="rejected")

    response = client.get("/api/v1/workspaces")
    assert response.status_code == 200
    ids = {item["id"] for item in response.json()}
    assert ids == {active.id, pending.id}
    assert hidden.id not in ids


def test_legacy_approval_is_pending_only_and_activates_pending_requester(client, db_session):
    admin = _user(db_session, "legacy-approver", role="platform_admin")
    requester = _user(db_session, "legacy-requester", status="pending")
    workspace, membership = _workspace(
        db_session, requester, "legacy", status="pending", member_status="pending"
    )

    response = client.post(f"/api/v1/workspaces/{workspace.id}/approve", headers=_headers(admin))
    assert response.status_code == 200
    assert requester.status == membership.status == workspace.status == "active"
    assert client.post(f"/api/v1/workspaces/{workspace.id}/approve", headers=_headers(admin)).status_code == 409
    workspace.status = "rejected"
    db_session.flush()
    assert client.post(f"/api/v1/workspaces/{workspace.id}/approve", headers=_headers(admin)).status_code == 409


def test_clinic_admin_approval_activates_pending_user_but_not_suspended_user(client, db_session):
    clinic_admin = _user(db_session, "clinic-approver")
    workspace, _ = _workspace(db_session, clinic_admin, "managed", role="clinic_admin")
    pending = _user(db_session, "joining", status="pending")
    joining = models.WorkspaceMembership(workspace_id=workspace.id, user_id=pending.id, status="pending")
    db_session.add(joining)
    db_session.flush()

    response = client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{joining.id}",
        headers=_headers(clinic_admin, workspace), json={"status": "active", "role": "professional"},
    )
    assert response.status_code == 200
    assert pending.status == "active"
    pending.status = "suspended"
    joining.status = "pending"
    db_session.flush()
    assert client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{joining.id}",
        headers=_headers(clinic_admin, workspace), json={"status": "active"},
    ).status_code == 409


def test_last_clinic_admin_cannot_self_demote(client, db_session):
    clinic_admin = _user(db_session, "sole-admin")
    workspace, membership = _workspace(db_session, clinic_admin, "sole", role="clinic_admin")
    response = client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{membership.id}",
        headers=_headers(clinic_admin, workspace), json={"status": "inactive"},
    )
    assert response.status_code == 409


def test_clinic_admin_can_reactivate_inactive_but_rejected_is_terminal(client, db_session):
    clinic_admin = _user(db_session, "reactivating-admin")
    workspace, _ = _workspace(db_session, clinic_admin, "reactivation", role="clinic_admin")
    member = _user(db_session, "reactivated-member")
    membership = models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=member.id, status="inactive"
    )
    db_session.add(membership)
    db_session.flush()

    response = client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{membership.id}",
        headers=_headers(clinic_admin, workspace),
        json={"status": "active", "role": "professional"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "active"

    membership.status = "rejected"
    db_session.flush()
    response = client.patch(
        f"/api/v1/workspaces/{workspace.id}/memberships/{membership.id}",
        headers=_headers(clinic_admin, workspace), json={"status": "active"},
    )
    assert response.status_code == 409


def test_admin_user_status_does_not_activate_pending_user(client, db_session):
    admin = _user(db_session, "status-admin", role="platform_admin")
    pending = _user(db_session, "status-pending", status="pending")
    active = _user(db_session, "status-active")

    response = client.patch(
        f"/api/v1/admin/users/{pending.id}/status",
        headers=_headers(admin), json={"status": "active"},
    )
    assert response.status_code == 409
    assert pending.status == "pending"

    response = client.patch(
        f"/api/v1/admin/users/{active.id}/status",
        headers=_headers(admin), json={"status": "suspended"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "suspended"


def test_registration_and_login_normalize_email(client, db_session):
    response = client.post("/api/v1/auth/register", json={
        "full_name": "Case User", "doctor_id": "AUD-CASE", "email": "  Case@Example.Test ",
        "password": "secret123",
    })
    assert response.status_code == 200
    assert response.json()["data"]["user"]["email"] == "case@example.test"
    assert client.post("/api/v1/auth/login", json={
        "email": " CASE@EXAMPLE.TEST ", "password": "secret123",
    }).status_code == 200
    assert client.post("/api/v1/auth/register", json={
        "full_name": "Duplicate", "doctor_id": "AUD-CASE-2", "email": "CASE@example.test",
        "password": "secret123",
    }).status_code == 409
