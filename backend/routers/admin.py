from datetime import UTC, datetime
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import asc, case, desc, func, or_
from sqlalchemy.orm import Session, joinedload

from auth.jwt import require_admin
import crud
from database import get_db
from models import models
from schemas import (
    AdminMembershipDecision,
    AdminMembershipDetailResponse,
    AdminMembershipRequestResponse,
    AdminRequesterResponse,
    AdminSummaryResponse,
    AdminWorkspaceRequestResponse,
    MembershipResponse,
    PaginatedResponse,
    UserAdminResponse,
    UserStatusUpdate,
    WorkspaceResponse,
)
from routers.workspaces import normalize

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def _requester(user: models.User) -> AdminRequesterResponse:
    return AdminRequesterResponse.model_validate(user, from_attributes=True)


def _workspace_request(workspace: models.ClinicalWorkspace, user: models.User | None):
    approver = getattr(workspace, "_approver", None)
    return AdminWorkspaceRequestResponse(
        id=workspace.id,
        name=workspace.name,
        workspace_type=workspace.workspace_type,
        status=workspace.status,
        city=workspace.city,
        address=workspace.address,
        tax_identifier=workspace.tax_identifier,
        telephone=workspace.telephone,
        institutional_email=workspace.institutional_email,
        created_at=workspace.created_at,
        updated_at=workspace.updated_at,
        approved_at=workspace.approved_at,
        approved_by=_requester(approver) if approver else None,
        requester=_requester(user) if user else None,
    )


def _membership_request(
    membership: models.WorkspaceMembership,
    user: models.User,
    workspace: models.ClinicalWorkspace,
):
    approver = getattr(membership, "_approver", None)
    return AdminMembershipRequestResponse(
        id=membership.id,
        status=membership.status,
        role=membership.role,
        created_at=membership.created_at,
        updated_at=membership.updated_at,
        approved_at=membership.approved_at,
        approved_by=_requester(approver) if approver else None,
        requester=_requester(user),
        workspace=WorkspaceResponse.model_validate(workspace),
    )


def _pending_membership(workspace_id: int, requester_id: int | None, db: Session):
    if requester_id is None:
        return None
    return db.query(models.WorkspaceMembership).filter_by(
        workspace_id=workspace_id, user_id=requester_id, status="pending"
    ).first()


def _page(query, page: int, page_size: int):
    total = query.order_by(None).count()
    items = query.offset((page - 1) * page_size).limit(page_size).all()
    return {"items": items, "page": page, "page_size": page_size, "total": total, "has_next": page * page_size < total}


def _attach_approvers(db: Session, rows):
    ids = {row.approved_by_id for row in rows if row.approved_by_id}
    users = {user.id: user for user in db.query(models.User).filter(models.User.id.in_(ids)).all()} if ids else {}
    for row in rows:
        row._approver = users.get(row.approved_by_id)


@router.get("/centers", response_model=PaginatedResponse[AdminWorkspaceRequestResponse])
def list_centers(
    search: str = Query("", max_length=100),
    status: Literal["pending", "active", "rejected"] | None = None,
    workspace_type: Literal["clinic", "consultorio", "hospital", "university", "campaign"] | None = None,
    sort_by: Literal["created_at", "updated_at", "name", "status"] = "created_at",
    sort_direction: Literal["asc", "desc"] = "desc",
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    query = db.query(models.ClinicalWorkspace, models.User).outerjoin(
        models.User, models.User.id == models.ClinicalWorkspace.initial_requester_id
    ).filter(models.ClinicalWorkspace.workspace_type != "independent")
    if status:
        query = query.filter(models.ClinicalWorkspace.status == status)
    if workspace_type:
        query = query.filter(models.ClinicalWorkspace.workspace_type == workspace_type)
    if search.strip():
        term = f"%{search.strip()}%"
        normalized = f"%{normalize(search)}%"
        query = query.filter(or_(
            models.ClinicalWorkspace.normalized_name.ilike(normalized),
            models.ClinicalWorkspace.city.ilike(term),
            models.ClinicalWorkspace.tax_identifier.ilike(term),
            models.User.full_name.ilike(term),
            models.User.email.ilike(term),
            models.User.doctor_id.ilike(term),
        ))
    column = getattr(models.ClinicalWorkspace, sort_by)
    direction = desc if sort_direction == "desc" else asc
    pending_first = case((models.ClinicalWorkspace.status == "pending", 0), else_=1)
    ordering = [pending_first] if status is None and sort_by == "created_at" else []
    ordering.extend((direction(column), direction(models.ClinicalWorkspace.id)))
    result = _page(query.order_by(*ordering), page, page_size)
    workspaces = [workspace for workspace, _ in result["items"]]
    _attach_approvers(db, workspaces)
    result["items"] = [_workspace_request(workspace, requester) for workspace, requester in result["items"]]
    return result


@router.get("/access", response_model=PaginatedResponse[AdminMembershipRequestResponse])
def list_access(
    search: str = Query("", max_length=100),
    status: Literal["pending", "active", "rejected", "inactive"] | None = None,
    role: Literal["clinic_admin", "professional", "assistant"] | None = None,
    workspace_type: Literal["clinic", "consultorio", "hospital", "university", "campaign", "independent"] | None = None,
    sort_by: Literal["created_at", "updated_at", "status", "role"] = "created_at",
    sort_direction: Literal["asc", "desc"] = "desc",
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    query = db.query(models.WorkspaceMembership, models.User, models.ClinicalWorkspace).join(
        models.User, models.User.id == models.WorkspaceMembership.user_id
    ).join(models.ClinicalWorkspace, models.ClinicalWorkspace.id == models.WorkspaceMembership.workspace_id).filter(
        models.User.role != "platform_admin",
        or_(models.ClinicalWorkspace.status == "active", models.ClinicalWorkspace.workspace_type == "independent"),
    )
    if status:
        query = query.filter(models.WorkspaceMembership.status == status)
    if role:
        query = query.filter(models.WorkspaceMembership.role == role)
    if workspace_type:
        query = query.filter(models.ClinicalWorkspace.workspace_type == workspace_type)
    if search.strip():
        term = f"%{search.strip()}%"
        normalized = f"%{normalize(search)}%"
        query = query.filter(or_(
            models.User.full_name.ilike(term), models.User.email.ilike(term), models.User.doctor_id.ilike(term),
            models.User.profession.ilike(term), models.User.specialty.ilike(term),
            models.ClinicalWorkspace.normalized_name.ilike(normalized),
        ))
    column = getattr(models.WorkspaceMembership, sort_by)
    direction = desc if sort_direction == "desc" else asc
    pending_first = case((models.WorkspaceMembership.status == "pending", 0), else_=1)
    ordering = [pending_first] if status is None and sort_by == "created_at" else []
    ordering.extend((direction(column), direction(models.WorkspaceMembership.id)))
    result = _page(query.order_by(*ordering), page, page_size)
    memberships = [membership for membership, _, _ in result["items"]]
    _attach_approvers(db, memberships)
    result["items"] = [_membership_request(*row) for row in result["items"]]
    return result


@router.get("/centers/{workspace_id}", response_model=AdminWorkspaceRequestResponse)
def get_center_detail(
    workspace_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    row = db.query(models.ClinicalWorkspace, models.User).outerjoin(
        models.User, models.User.id == models.ClinicalWorkspace.initial_requester_id
    ).filter(
        models.ClinicalWorkspace.id == workspace_id,
        models.ClinicalWorkspace.workspace_type != "independent",
    ).first()
    if row is None:
        raise HTTPException(status_code=404, detail="Center not found.")
    _attach_approvers(db, [row[0]])
    return _workspace_request(*row)


@router.get("/access/{membership_id}", response_model=AdminMembershipRequestResponse)
def get_access_detail(
    membership_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    row = db.query(models.WorkspaceMembership, models.User, models.ClinicalWorkspace).join(
        models.User, models.User.id == models.WorkspaceMembership.user_id
    ).join(models.ClinicalWorkspace).filter(
        models.WorkspaceMembership.id == membership_id,
        models.User.role != "platform_admin",
    ).first()
    if row is None:
        raise HTTPException(status_code=404, detail="Access request not found.")
    _attach_approvers(db, [row[0]])
    return _membership_request(*row)


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
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=workspace_id).with_for_update().first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "pending":
        raise HTTPException(status_code=409, detail="Workspace request has already been resolved.")
    initial = _pending_membership(workspace.id, workspace.initial_requester_id, db)
    requester = db.query(models.User).filter_by(id=workspace.initial_requester_id).with_for_update().first()
    if requester is None or requester.status == "suspended":
        raise HTTPException(status_code=409, detail="Suspended requesters cannot have workspace access approved.")
    now = datetime.now(UTC).replace(tzinfo=None)
    workspace.status = "active"
    workspace.approved_by_id = current_user.id
    workspace.approved_at = now
    if initial:
        initial.status = "active"
        initial.role = "clinic_admin"
        initial.approved_by_id = current_user.id
        initial.approved_at = now
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
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=workspace_id).with_for_update().first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "pending":
        raise HTTPException(status_code=409, detail="Workspace request has already been resolved.")
    initial = _pending_membership(workspace.id, workspace.initial_requester_id, db)
    workspace.status = "rejected"
    workspace.approved_by_id = current_user.id
    workspace.approved_at = datetime.now(UTC).replace(tzinfo=None)
    if initial:
        initial.status = "rejected"
        initial.approved_by_id = current_user.id
        initial.approved_at = workspace.approved_at
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
    membership = db.query(models.WorkspaceMembership).filter_by(id=membership_id).with_for_update().first()
    if membership is None:
        raise HTTPException(status_code=404, detail="Membership not found.")
    if membership.status != "pending":
        raise HTTPException(status_code=409, detail="Membership request has already been resolved.")
    member = db.query(models.User).filter_by(id=membership.user_id).with_for_update().first()
    if member is None:
        raise HTTPException(status_code=404, detail="User not found.")
    if member.status == "suspended":
        raise HTTPException(status_code=409, detail="Suspended users cannot have memberships approved.")
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=membership.workspace_id).with_for_update().first()
    if workspace.status == "pending":
        if workspace.workspace_type != "independent" or workspace.initial_requester_id != membership.user_id:
            raise HTTPException(status_code=409, detail="The workspace must be approved first.")
        workspace.status = "active"
        workspace.approved_by_id = current_user.id
        workspace.approved_at = datetime.now(UTC).replace(tzinfo=None)
    elif workspace.status != "active":
        raise HTTPException(status_code=409, detail="The workspace is not active.")
    membership.status = "active"
    membership.role = "professional" if workspace.workspace_type == "independent" else payload.role
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
    membership = db.query(models.WorkspaceMembership).filter_by(id=membership_id).with_for_update().first()
    if membership is None:
        raise HTTPException(status_code=404, detail="Membership not found.")
    if membership.status != "pending":
        raise HTTPException(status_code=409, detail="Membership request has already been resolved.")
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=membership.workspace_id).first()
    membership.status = "rejected"
    membership.approved_by_id = current_user.id
    membership.approved_at = datetime.now(UTC).replace(tzinfo=None)
    if workspace.status == "pending" and workspace.initial_requester_id == membership.user_id:
        workspace.status = "rejected"
        workspace.approved_by_id = current_user.id
        workspace.approved_at = membership.approved_at
    db.commit()
    db.refresh(membership)
    return membership


@router.get("/users", response_model=PaginatedResponse[UserAdminResponse])
def list_users(
    search: str = Query("", max_length=100),
    status: Literal["pending", "active", "suspended"] | None = None,
    role: Literal["platform_admin", "professional", "admin", "doctor"] | None = None,
    sort_by: Literal["created_at", "full_name", "email", "status", "role"] = "created_at",
    sort_direction: Literal["asc", "desc"] = "desc",
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    query = db.query(models.User).options(joinedload(models.User.memberships).joinedload(models.WorkspaceMembership.workspace))
    if status:
        query = query.filter(models.User.status == status)
    if role:
        query = query.filter(models.User.role == role)
    if search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            models.User.full_name.ilike(term), models.User.email.ilike(term), models.User.doctor_id.ilike(term),
            models.User.medical_center.ilike(term), models.User.profession.ilike(term), models.User.specialty.ilike(term),
        ))
    column = getattr(models.User, sort_by)
    direction = desc if sort_direction == "desc" else asc
    result = _page(query.order_by(direction(column), direction(models.User.id)), page, page_size)
    result["items"] = [UserAdminResponse.model_validate(user) for user in result["items"]]
    return result


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
    user = db.query(models.User).options(
        joinedload(models.User.memberships).joinedload(models.WorkspaceMembership.workspace)
    ).filter_by(id=user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    allowed = {("active", "suspended"), ("suspended", "active")}
    if (user.status, payload.status) not in allowed:
        raise HTTPException(status_code=409, detail="Invalid user status transition.")
    if payload.status == "suspended":
        admin_memberships = db.query(models.WorkspaceMembership).join(models.ClinicalWorkspace).filter(
            models.WorkspaceMembership.user_id == user.id,
            models.WorkspaceMembership.status == "active",
            models.WorkspaceMembership.role == "clinic_admin",
            models.ClinicalWorkspace.status == "active",
            models.ClinicalWorkspace.workspace_type != "independent",
        ).with_for_update().all()
        for membership in admin_memberships:
            remaining = db.query(models.WorkspaceMembership).filter(
                models.WorkspaceMembership.workspace_id == membership.workspace_id,
                models.WorkspaceMembership.user_id != user.id,
                models.WorkspaceMembership.status == "active",
                models.WorkspaceMembership.role == "clinic_admin",
            ).count()
            if remaining == 0:
                raise HTTPException(status_code=409, detail="Each active center must retain an active clinic administrator.")
    user = crud.update_user_status(db, user_id=user_id, status=payload.status)
    return user
