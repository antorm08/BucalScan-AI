"""Add immutable clinical assessment snapshots and priority results."""

from alembic import op
import sqlalchemy as sa

revision = "0004_clinical_priority"
down_revision = "0003_legacy_backfill"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "clinical_assessment_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("workspace_id", sa.Integer(), sa.ForeignKey("clinical_workspaces.id"), nullable=False),
        sa.Column("patient_id", sa.Integer(), sa.ForeignKey("patients.id"), nullable=False),
        sa.Column("lesion_id", sa.Integer(), sa.ForeignKey("oral_lesions.id"), nullable=False),
        sa.Column("evaluation_id", sa.Integer(), sa.ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("assessor_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("schema_version", sa.String(), nullable=False),
        sa.Column("ruleset_version", sa.String(), nullable=False),
        sa.Column("canonical_payload", sa.JSON(), nullable=False),
        sa.Column("completion_status", sa.String(), nullable=False),
        sa.Column("assessed_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.current_timestamp()),
        sa.UniqueConstraint("evaluation_id", name="uq_assessment_evaluation"),
    )
    op.create_index("ix_assessments_workspace_assessed", "clinical_assessment_snapshots", ["workspace_id", "assessed_at"])
    op.create_index("ix_assessments_lesion", "clinical_assessment_snapshots", ["lesion_id"])
    op.create_table(
        "clinical_priority_results",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("assessment_id", sa.Integer(), sa.ForeignKey("clinical_assessment_snapshots.id", ondelete="CASCADE"), nullable=False),
        sa.Column("workspace_id", sa.Integer(), sa.ForeignKey("clinical_workspaces.id"), nullable=False),
        sa.Column("evaluation_id", sa.Integer(), sa.ForeignKey("clinical_evaluations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("priority_code", sa.String(), nullable=False),
        sa.Column("reason_codes", sa.JSON(), nullable=False),
        sa.Column("rendered_reasons", sa.JSON(), nullable=False),
        sa.Column("ruleset_id", sa.String(), nullable=False),
        sa.Column("ruleset_version", sa.String(), nullable=False),
        sa.Column("engine_version", sa.String(), nullable=False),
        sa.Column("evaluated_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.current_timestamp()),
        sa.UniqueConstraint("assessment_id", name="uq_priority_assessment"),
        sa.UniqueConstraint("evaluation_id", name="uq_priority_evaluation"),
    )
    op.create_index("ix_priority_workspace_evaluated", "clinical_priority_results", ["workspace_id", "evaluated_at"])
    op.create_index("ix_priority_code", "clinical_priority_results", ["priority_code"])


def downgrade():
    # Operational rollback must disable the feature and retain data first. This
    # explicit schema downgrade is destructive and requires an approved export.
    op.drop_index("ix_priority_code", table_name="clinical_priority_results")
    op.drop_index("ix_priority_workspace_evaluated", table_name="clinical_priority_results")
    op.drop_table("clinical_priority_results")
    op.drop_index("ix_assessments_lesion", table_name="clinical_assessment_snapshots")
    op.drop_index("ix_assessments_workspace_assessed", table_name="clinical_assessment_snapshots")
    op.drop_table("clinical_assessment_snapshots")
