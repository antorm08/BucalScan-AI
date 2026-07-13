from datetime import UTC, datetime
from typing import List, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from auth.jwt import require_admin
import crud
from database import get_db
from models import models
from schemas import (
    AdminMembershipDecision,
    AdminMembershipRequestResponse,
    AdminRequesterResponse,
    AdminSummaryResponse,
    AdminWorkspaceRequestResponse,
    MembershipResponse,
    UserAdminResponse,
    UserStatusUpdate,
    WorkspaceResponse,
)

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def _requester(user: models.User) -> AdminRequesterResponse:
    return AdminRequesterResponse.model_validate(user, from_attributes=True)


def _workspace_request(workspace: models.ClinicalWorkspace, user: models.User | None):
    return AdminWorkspaceRequestResponse(
        id=workspace.id,
        name=workspace.name,
        workspace_type=workspace.workspace_type,
        status=workspace.status,
        city=workspace.city,
        address=workspace.address,
        created_at=workspace.created_at,
        requester=_requester(user) if user else None,
    )


def _membership_request(
    membership: models.WorkspaceMembership,
    user: models.User,
    workspace: models.ClinicalWorkspace,
):
    return AdminMembershipRequestResponse(
        id=membership.id,
        status=membership.status,
        role=membership.role,
        created_at=membership.created_at,
        requester=_requester(user),
        workspace=WorkspaceResponse.model_validate(workspace),
    )


def _pending_membership(workspace_id: int, requester_id: int | None, db: Session):
    if requester_id is None:
        return None
    return db.query(models.WorkspaceMembership).filter_by(
        workspace_id=workspace_id, user_id=requester_id, status="pending"
    ).first()


@router.get("/summary", response_model=AdminSummaryResponse)
def get_admin_summary(
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    user_counts = dict(db.query(models.User.status, func.count(models.User.id)).group_by(models.User.status).all())
    return AdminSummaryResponse(
        pending_workspaces=db.query(models.ClinicalWorkspace).filter(
            models.ClinicalWorkspace.status == "pending",
            models.ClinicalWorkspace.workspace_type != "independent",
        ).count(),
        pending_memberships=db.query(models.WorkspaceMembership)
        .join(models.ClinicalWorkspace)
        .join(models.User, models.User.id == models.WorkspaceMembership.user_id)
        .filter(
            models.WorkspaceMembership.status == "pending",
            models.User.role != "platform_admin",
            or_(
                models.ClinicalWorkspace.status == "active",
                models.ClinicalWorkspace.workspace_type == "independent",
            ),
        ).count(),
        total_users=sum(user_counts.values()),
        active_users=user_counts.get("active", 0),
        suspended_users=user_counts.get("suspended", 0),
    )


@router.get("/workspaces", response_model=list[AdminWorkspaceRequestResponse])
def list_workspace_requests(
    status: Literal["pending", "active", "rejected"] = "pending",
    limit: int = Query(100, ge=1, le=500),
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.ClinicalWorkspace, models.User)
        .outerjoin(models.User, models.User.id == models.ClinicalWorkspace.initial_requester_id)
        .filter(models.ClinicalWorkspace.status == status)
        .filter(models.ClinicalWorkspace.workspace_type != "independent")
        .order_by(models.ClinicalWorkspace.created_at)
        .limit(limit)
        .all()
    )
    return [_workspace_request(workspace, user) for workspace, user in rows]


@router.get("/memberships", response_model=list[AdminMembershipRequestResponse])
def list_membership_requests(
    status: Literal["pending", "active", "rejected", "inactive"] = "pending",
    limit: int = Query(100, ge=1, le=500),
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.WorkspaceMembership, models.User, models.ClinicalWorkspace)
        .join(models.User, models.User.id == models.WorkspaceMembership.user_id)
        .join(models.ClinicalWorkspace, models.ClinicalWorkspace.id == models.WorkspaceMembership.workspace_id)
        .filter(models.WorkspaceMembership.status == status)
        .filter(models.User.role != "platform_admin")
        .filter(or_(
            models.ClinicalWorkspace.status == "active",
            models.ClinicalWorkspace.workspace_type == "independent",
        ))
        .order_by(models.WorkspaceMembership.created_at)
        .limit(limit)
        .all()
    )
    return [_membership_request(membership, user, workspace) for membership, user, workspace in rows]


@router.post("/workspaces/{workspace_id}/approve", response_model=AdminWorkspaceRequestResponse)
def approve_workspace_request(
    workspace_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=workspace_id).first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "pending":
        raise HTTPException(status_code=409, detail="Workspace request has already been resolved.")
    initial = _pending_membership(workspace.id, workspace.initial_requester_id, db)
    now = datetime.now(UTC).replace(tzinfo=None)
    workspace.status = "active"
    workspace.approved_by_id = current_user.id
    workspace.approved_at = now
    if initial:
        initial.status = "active"
        initial.role = "clinic_admin"
        initial.approved_by_id = current_user.id
        initial.approved_at = now
        requester = db.query(models.User).filter_by(id=initial.user_id).first()
        if requester and requester.status == "pending":
            requester.status = "active"
    db.commit()
    db.refresh(workspace)
    requester = db.query(models.User).filter_by(id=workspace.initial_requester_id).first()
    return _workspace_request(workspace, requester)


@router.post("/workspaces/{workspace_id}/reject", response_model=AdminWorkspaceRequestResponse)
def reject_workspace_request(
    workspace_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=workspace_id).first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "pending":
        raise HTTPException(status_code=409, detail="Workspace request has already been resolved.")
    initial = _pending_membership(workspace.id, workspace.initial_requester_id, db)
    workspace.status = "rejected"
    if initial:
        initial.status = "rejected"
    db.commit()
    db.refresh(workspace)
    requester = db.query(models.User).filter_by(id=workspace.initial_requester_id).first()
    return _workspace_request(workspace, requester)


@router.post("/memberships/{membership_id}/approve", response_model=MembershipResponse)
def approve_membership_request(
    membership_id: int,
    payload: AdminMembershipDecision,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    membership = db.query(models.WorkspaceMembership).filter_by(id=membership_id).first()
    if membership is None:
        raise HTTPException(status_code=404, detail="Membership not found.")
    if membership.status != "pending":
        raise HTTPException(status_code=409, detail="Membership request has already been resolved.")
    member = db.query(models.User).filter_by(id=membership.user_id).first()
    if member is None:
        raise HTTPException(status_code=404, detail="User not found.")
    if member.status == "suspended":
        raise HTTPException(status_code=409, detail="Suspended users cannot have memberships approved.")
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=membership.workspace_id).first()
    if workspace.status == "pending":
        if workspace.workspace_type != "independent" or workspace.initial_requester_id != membership.user_id:
            raise HTTPException(status_code=409, detail="The workspace must be approved first.")
        workspace.status = "active"
        workspace.approved_by_id = current_user.id
        workspace.approved_at = datetime.now(UTC).replace(tzinfo=None)
    elif workspace.status != "active":
        raise HTTPException(status_code=409, detail="The workspace is not active.")
    membership.status = "active"
    membership.role = payload.role
    membership.approved_by_id = current_user.id
    membership.approved_at = datetime.now(UTC).replace(tzinfo=None)
    if member.status == "pending":
        member.status = "active"
    db.commit()
    db.refresh(membership)
    return membership


@router.post("/memberships/{membership_id}/reject", response_model=MembershipResponse)
def reject_membership_request(
    membership_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    membership = db.query(models.WorkspaceMembership).filter_by(id=membership_id).first()
    if membership is None:
        raise HTTPException(status_code=404, detail="Membership not found.")
    if membership.status != "pending":
        raise HTTPException(status_code=409, detail="Membership request has already been resolved.")
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=membership.workspace_id).first()
    membership.status = "rejected"
    if workspace.status == "pending" and workspace.initial_requester_id == membership.user_id:
        workspace.status = "rejected"
    db.commit()
    db.refresh(membership)
    return membership


@router.get("/users", response_model=List[UserAdminResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return crud.get_all_users(db, skip=skip, limit=limit)


@router.get("/users/{user_id}", response_model=UserAdminResponse)
async def get_user(
    user_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    user = crud.get_user(db, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


@router.patch("/users/{user_id}/status", response_model=UserAdminResponse)
async def update_user_status(
    user_id: int,
    payload: UserStatusUpdate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if user_id == current_user.id and payload.status == "suspended":
        raise HTTPException(status_code=409, detail="Administrators cannot suspend their own account.")
    user = crud.get_user(db, user_id=user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    allowed = {("active", "suspended"), ("suspended", "active")}
    if (user.status, payload.status) not in allowed:
        raise HTTPException(status_code=409, detail="Invalid user status transition.")
    user = crud.update_user_status(db, user_id=user_id, status=payload.status)
    return user
