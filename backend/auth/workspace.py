from dataclasses import dataclass

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from auth.jwt import get_current_user
from database import get_db
from models import models


@dataclass(frozen=True)
class WorkspaceAccess:
    workspace: models.ClinicalWorkspace
    membership: models.WorkspaceMembership | None
    user: models.User


def is_platform_admin(user: models.User) -> bool:
    return user.role in {"admin", "platform_admin"}


def get_workspace_access(
    x_workspace_id: int = Header(..., alias="X-Workspace-ID"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WorkspaceAccess:
    workspace = db.query(models.ClinicalWorkspace).filter(
        models.ClinicalWorkspace.id == x_workspace_id
    ).first()
    if workspace is None:
        raise HTTPException(status_code=404, detail="Workspace not found.")
    if workspace.status != "active":
        raise HTTPException(status_code=403, detail="Active workspace required.")
    if current_user.status != "active":
        raise HTTPException(status_code=403, detail="Active user account required.")
    membership = db.query(models.WorkspaceMembership).filter(
        models.WorkspaceMembership.workspace_id == x_workspace_id,
        models.WorkspaceMembership.user_id == current_user.id,
        models.WorkspaceMembership.status == "active",
    ).first()
    if membership is None and not is_platform_admin(current_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Active workspace membership required.")
    return WorkspaceAccess(workspace, membership, current_user)


def require_clinical_professional(
    access: WorkspaceAccess = Depends(get_workspace_access),
) -> WorkspaceAccess:
    if is_platform_admin(access.user):
        return access
    if access.membership is None or access.membership.role not in {"clinic_admin", "professional"}:
        raise HTTPException(status_code=403, detail="Professional permission required.")
    return access


def require_workspace_admin(
    access: WorkspaceAccess = Depends(get_workspace_access),
) -> WorkspaceAccess:
    if is_platform_admin(access.user):
        return access
    if access.membership is None or access.membership.role != "clinic_admin":
        raise HTTPException(status_code=403, detail="Clinic administrator permission required.")
    return access
