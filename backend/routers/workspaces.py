import re
import unicodedata
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from auth.jwt import get_current_user, require_admin
from auth.workspace import WorkspaceAccess, get_workspace_access, require_workspace_admin
from database import get_db
from models import models
from schemas import MembershipResponse, MembershipUpdate, WorkspaceCreate, WorkspaceResponse

router = APIRouter(prefix="/api/v1/workspaces", tags=["workspaces"])


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()


@router.get("", response_model=list[WorkspaceResponse])
def discover_workspaces(q: str = Query("", max_length=100), db: Session = Depends(get_db)):
    query = db.query(models.ClinicalWorkspace)
    if q.strip():
        query = query.filter(models.ClinicalWorkspace.normalized_name.contains(normalize(q)))
    return query.order_by(models.ClinicalWorkspace.name).limit(50).all()


@router.get("/mine", response_model=list[MembershipResponse])
def my_memberships(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.WorkspaceMembership).filter(models.WorkspaceMembership.user_id == current_user.id).all()


@router.post("", response_model=WorkspaceResponse, status_code=201)
def create_workspace(payload: WorkspaceCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    normalized = normalize(payload.name)
    duplicate = db.query(models.ClinicalWorkspace).filter(
        models.ClinicalWorkspace.normalized_name == normalized
    ).first()
    if duplicate:
        raise HTTPException(status_code=409, detail={"message": "Potential workspace duplicate.", "workspace_id": duplicate.id})
    independent = payload.workspace_type == "independent"
    workspace = models.ClinicalWorkspace(
        **payload.model_dump(), normalized_name=normalized,
        status="pending", initial_requester_id=current_user.id,
    )
    db.add(workspace)
    db.flush()
    db.add(models.WorkspaceMembership(
        workspace_id=workspace.id, user_id=current_user.id,
        role="professional", status="pending",
    ))
    db.commit()
    db.refresh(workspace)
    return workspace


@router.post("/{workspace_id}/memberships", response_model=MembershipResponse, status_code=201)
def request_membership(workspace_id: int, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    workspace = db.query(models.ClinicalWorkspace).filter(models.ClinicalWorkspace.id == workspace_id).first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "active":
        raise HTTPException(status_code=409, detail="Membership can only be requested for an active workspace.")
    existing = db.query(models.WorkspaceMembership).filter_by(workspace_id=workspace_id, user_id=current_user.id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Membership already exists.")
    membership = models.WorkspaceMembership(workspace_id=workspace_id, user_id=current_user.id)
    db.add(membership)
    db.commit()
    db.refresh(membership)
    return membership


@router.post("/{workspace_id}/approve", response_model=WorkspaceResponse)
def approve_workspace(workspace_id: int, admin: models.User = Depends(require_admin), db: Session = Depends(get_db)):
    workspace = db.query(models.ClinicalWorkspace).filter_by(id=workspace_id).first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    workspace.status = "active"
    workspace.approved_by_id = admin.id
    workspace.approved_at = datetime.now(UTC).replace(tzinfo=None)
    initial = db.query(models.WorkspaceMembership).filter_by(
        workspace_id=workspace.id, user_id=workspace.initial_requester_id
    ).first()
    if initial:
        initial.status = "active"
        initial.role = "clinic_admin"
        initial.approved_by_id = admin.id
        initial.approved_at = workspace.approved_at
    db.commit()
    db.refresh(workspace)
    return workspace


@router.get("/{workspace_id}/memberships", response_model=list[MembershipResponse])
def list_memberships(access: WorkspaceAccess = Depends(require_workspace_admin), db: Session = Depends(get_db)):
    return db.query(models.WorkspaceMembership).filter_by(workspace_id=access.workspace.id).all()


@router.patch("/{workspace_id}/memberships/{membership_id}", response_model=MembershipResponse)
def manage_membership(membership_id: int, payload: MembershipUpdate, access: WorkspaceAccess = Depends(require_workspace_admin), db: Session = Depends(get_db)):
    membership = db.query(models.WorkspaceMembership).filter_by(id=membership_id, workspace_id=access.workspace.id).first()
    if membership is None:
        raise HTTPException(status_code=404, detail="Membership not found.")
    membership.status = payload.status
    if payload.role:
        membership.role = payload.role
    membership.approved_by_id = access.user.id
    membership.approved_at = datetime.now(UTC).replace(tzinfo=None)
    db.commit()
    db.refresh(membership)
    return membership
