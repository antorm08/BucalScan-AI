from auth.jwt import create_access_token
from models import models


def _user(db, suffix, role="professional"):
    user = models.User(
        full_name=f"User {suffix}", doctor_id=f"DOC-{suffix}",
        email=f"{suffix}@example.test", hashed_password="hash", role=role,
        profession="Dentist", specialty="Oral medicine",
    )
    db.add(user)
    db.flush()
    return user


def _headers(user):
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def _request(db, user, suffix, workspace_type="clinic", workspace_status="pending"):
    workspace = models.ClinicalWorkspace(
        name=f"Workspace {suffix}", normalized_name=f"workspace {suffix}",
        workspace_type=workspace_type, status=workspace_status,
        city="Quito", address="Av. Central 123", initial_requester_id=user.id,
    )
    db.add(workspace)
    db.flush()
    membership = models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=user.id, status="pending", role="professional",
    )
    db.add(membership)
    db.flush()
    return workspace, membership


def test_admin_summary_and_pending_queues_require_platform_admin(client, db_session):
    admin = _user(db_session, "admin", "platform_admin")
    requester = _user(db_session, "requester")
    workspace, _ = _request(db_session, requester, "pending")
    member = _user(db_session, "joining")
    active_workspace, membership = _request(
        db_session, member, "joining", workspace_status="active"
    )
    legacy_workspace, legacy_membership = _request(
        db_session, admin, "legacy-admin", workspace_status="active"
    )

    assert client.get("/api/v1/admin/summary", headers=_headers(requester)).status_code == 403
    summary = client.get("/api/v1/admin/summary", headers=_headers(admin))
    assert summary.status_code == 200
    assert summary.json()["pending_workspaces"] == 1
    assert summary.json()["pending_memberships"] == 1
    workspaces = client.get("/api/v1/admin/workspaces", headers=_headers(admin)).json()
    memberships = client.get("/api/v1/admin/memberships", headers=_headers(admin)).json()
    assert workspaces[0]["requester"]["profession"] == "Dentist"
    assert memberships[0]["workspace"]["id"] == active_workspace.id
    assert memberships[0]["id"] == membership.id
    assert legacy_membership.id not in {item["id"] for item in memberships}
    assert legacy_workspace.id != active_workspace.id


def test_workspace_approve_and_reject_update_initial_membership_atomically(client, db_session):
    admin = _user(db_session, "workspace-admin", "platform_admin")
    approved_user = _user(db_session, "approved")
    approved_workspace, approved_membership = _request(db_session, approved_user, "approved")
    rejected_user = _user(db_session, "rejected")
    rejected_workspace, rejected_membership = _request(db_session, rejected_user, "rejected")

    response = client.post(f"/api/v1/admin/workspaces/{approved_workspace.id}/approve", headers=_headers(admin))
    assert response.status_code == 200
    db_session.refresh(approved_membership)
    assert approved_workspace.status == "active"
    assert approved_membership.status == "active"
    assert approved_membership.role == "clinic_admin"
    assert client.post(f"/api/v1/admin/workspaces/{approved_workspace.id}/approve", headers=_headers(admin)).status_code == 409

    response = client.post(f"/api/v1/admin/workspaces/{rejected_workspace.id}/reject", headers=_headers(admin))
    assert response.status_code == 200
    db_session.refresh(rejected_membership)
    assert rejected_workspace.status == rejected_membership.status == "rejected"


def test_admin_completes_center_location_before_approval(client, db_session):
    admin = _user(db_session, "location-admin", "platform_admin")
    requester = _user(db_session, "location-requester")
    workspace, membership = _request(db_session, requester, "location")
    workspace.city = None
    workspace.address = None
    db_session.flush()

    approval_path = f"/api/v1/admin/workspaces/{workspace.id}/approve"
    assert client.post(approval_path, headers=_headers(admin)).status_code == 409
    update_path = f"/api/v1/admin/centers/{workspace.id}"
    assert client.patch(
        update_path,
        headers=_headers(requester),
        json={"city": "Cuenca", "address": "Calle Larga 10"},
    ).status_code == 403
    response = client.patch(
        update_path,
        headers=_headers(admin),
        json={"city": "  Cuenca  ", "address": "  Calle Larga 10  "},
    )
    assert response.status_code == 200
    assert response.json()["city"] == "Cuenca"
    assert response.json()["address"] == "Calle Larga 10"
    assert client.post(approval_path, headers=_headers(admin)).status_code == 200
    assert workspace.status == membership.status == "active"

    response = client.patch(
        update_path,
        headers=_headers(admin),
        json={"city": "Loja", "address": "Av. Universitaria 20"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "active"
    assert response.json()["city"] == "Loja"
    assert response.json()["address"] == "Av. Universitaria 20"
    db_session.refresh(workspace)
    assert workspace.city == "Loja"
    assert workspace.address == "Av. Universitaria 20"


def test_membership_decisions_activate_independent_and_assign_allowed_role(client, db_session):
    admin = _user(db_session, "membership-admin", "platform_admin")
    independent = _user(db_session, "independent")
    workspace, membership = _request(db_session, independent, "independent", "independent")
    response = client.post(
        f"/api/v1/admin/memberships/{membership.id}/approve",
        headers=_headers(admin), json={"role": "professional"},
    )
    assert response.status_code == 200
    assert response.json()["role"] == "professional"
    assert workspace.status == "active"
    assert client.post(
        f"/api/v1/admin/memberships/{membership.id}/approve",
        headers=_headers(admin), json={"role": "owner"},
    ).status_code == 422


def test_reject_initial_membership_rejects_pending_workspace_and_admin_cannot_self_suspend(client, db_session):
    admin = _user(db_session, "self-admin", "platform_admin")
    requester = _user(db_session, "membership-reject")
    workspace, membership = _request(db_session, requester, "membership-reject")
    response = client.post(f"/api/v1/admin/memberships/{membership.id}/reject", headers=_headers(admin))
    assert response.status_code == 200
    assert workspace.status == "rejected"
    response = client.patch(
        f"/api/v1/admin/users/{admin.id}/status",
        headers=_headers(admin), json={"status": "suspended"},
    )
    assert response.status_code == 409
    assert admin.status == "active"
