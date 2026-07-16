"""Persist optional CAM heatmap URLs for model predictions."""

from alembic import context, op
import sqlalchemy as sa


revision = "0005_model_prediction_heatmap"
down_revision = "0004_clinical_priority"
branch_labels = None
depends_on = None


def upgrade():
    if context.is_offline_mode() or "heatmap_url" not in {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns("model_predictions")
    }:
        op.add_column(
            "model_predictions",
            sa.Column("heatmap_url", sa.String(), nullable=True),
        )


def downgrade():
    if context.is_offline_mode() or "heatmap_url" in {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns("model_predictions")
    }:
        op.drop_column("model_predictions", "heatmap_url")
