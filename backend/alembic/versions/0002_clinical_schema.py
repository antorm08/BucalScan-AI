"""Normalized clinical schema."""
from alembic import context, op
import sqlalchemy as sa

from database import Base
from models import models  # noqa: F401

revision = "0002_clinical_schema"
down_revision = "0001_legacy_baseline"
branch_labels = None
depends_on = None

NEW_TABLES = [
    "clinical_workspaces", "workspace_memberships", "patients", "oral_lesions",
    "clinical_evaluations", "lesion_images", "model_predictions", "consent_attestations",
]


def upgrade():
    if context.is_offline_mode():
        op.execute("""
        ALTER TABLE users ADD COLUMN IF NOT EXISTS profession VARCHAR;
        ALTER TABLE users ADD COLUMN IF NOT EXISTS specialty VARCHAR;
        CREATE TABLE IF NOT EXISTS clinical_workspaces (
          id SERIAL PRIMARY KEY, name VARCHAR NOT NULL, normalized_name VARCHAR NOT NULL,
          workspace_type VARCHAR NOT NULL, status VARCHAR NOT NULL DEFAULT 'pending',
          city VARCHAR, address VARCHAR, tax_identifier VARCHAR,
          telephone VARCHAR, institutional_email VARCHAR,
          initial_requester_id INTEGER REFERENCES users(id), approved_by_id INTEGER REFERENCES users(id),
          approved_at TIMESTAMP WITHOUT TIME ZONE, created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_workspace_tax_identifier UNIQUE (tax_identifier)
        );
        CREATE INDEX IF NOT EXISTS ix_workspaces_normalized_name ON clinical_workspaces(normalized_name);
        CREATE TABLE IF NOT EXISTS workspace_memberships (
          id SERIAL PRIMARY KEY, workspace_id INTEGER NOT NULL REFERENCES clinical_workspaces(id) ON DELETE CASCADE,
          user_id INTEGER NOT NULL REFERENCES users(id), role VARCHAR NOT NULL DEFAULT 'professional',
          status VARCHAR NOT NULL DEFAULT 'pending', approved_by_id INTEGER REFERENCES users(id),
          approved_at TIMESTAMP WITHOUT TIME ZONE, created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_workspace_member UNIQUE(workspace_id, user_id)
        );
        CREATE INDEX IF NOT EXISTS ix_workspace_memberships_workspace_id ON workspace_memberships(workspace_id);
        CREATE INDEX IF NOT EXISTS ix_workspace_memberships_user_id ON workspace_memberships(user_id);
        CREATE TABLE IF NOT EXISTS patients (
          id SERIAL PRIMARY KEY, workspace_id INTEGER NOT NULL REFERENCES clinical_workspaces(id),
          clinical_code VARCHAR NOT NULL, identity_document VARCHAR, full_name VARCHAR NOT NULL,
          normalized_name VARCHAR NOT NULL, birth_date DATE, sex VARCHAR, telephone VARCHAR,
          email VARCHAR, notes TEXT, is_legacy_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
          created_by_id INTEGER NOT NULL REFERENCES users(id),
          created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_patient_workspace_code UNIQUE(workspace_id, clinical_code),
          CONSTRAINT uq_patient_workspace_identity UNIQUE(workspace_id, identity_document)
        );
        CREATE INDEX IF NOT EXISTS ix_patients_workspace_id ON patients(workspace_id);
        CREATE INDEX IF NOT EXISTS ix_patients_workspace_normalized_name ON patients(workspace_id, normalized_name);
        CREATE TABLE IF NOT EXISTS oral_lesions (
          id SERIAL PRIMARY KEY, workspace_id INTEGER NOT NULL REFERENCES clinical_workspaces(id),
          patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
          anatomical_site VARCHAR NOT NULL, observed_at DATE, estimated_duration VARCHAR,
          status VARCHAR NOT NULL DEFAULT 'active', clinical_notes TEXT,
          created_by_id INTEGER NOT NULL REFERENCES users(id),
          created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS ix_oral_lesions_workspace_id ON oral_lesions(workspace_id);
        CREATE INDEX IF NOT EXISTS ix_oral_lesions_patient_id ON oral_lesions(patient_id);
        CREATE TABLE IF NOT EXISTS clinical_evaluations (
          id SERIAL PRIMARY KEY, workspace_id INTEGER NOT NULL REFERENCES clinical_workspaces(id),
          patient_id INTEGER NOT NULL REFERENCES patients(id), lesion_id INTEGER NOT NULL REFERENCES oral_lesions(id),
          professional_id INTEGER NOT NULL REFERENCES users(id), clinical_observations TEXT,
          evaluated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS ix_clinical_evaluations_workspace_id ON clinical_evaluations(workspace_id);
        CREATE INDEX IF NOT EXISTS ix_clinical_evaluations_lesion_id ON clinical_evaluations(lesion_id);
        CREATE TABLE IF NOT EXISTS lesion_images (
          id SERIAL PRIMARY KEY, evaluation_id INTEGER NOT NULL UNIQUE REFERENCES clinical_evaluations(id) ON DELETE CASCADE,
          storage_url VARCHAR NOT NULL, content_type VARCHAR, original_filename VARCHAR,
          created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS model_predictions (
          id SERIAL PRIMARY KEY, evaluation_id INTEGER NOT NULL UNIQUE REFERENCES clinical_evaluations(id) ON DELETE CASCADE,
          image_id INTEGER NOT NULL REFERENCES lesion_images(id), model_version VARCHAR NOT NULL,
          predicted_label VARCHAR NOT NULL, confidence DOUBLE PRECISION NOT NULL,
          benign_probability DOUBLE PRECISION NOT NULL, malignant_probability DOUBLE PRECISION NOT NULL,
          processing_time_ms DOUBLE PRECISION, created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS consent_attestations (
          id SERIAL PRIMARY KEY, evaluation_id INTEGER NOT NULL UNIQUE REFERENCES clinical_evaluations(id) ON DELETE CASCADE,
          professional_id INTEGER NOT NULL REFERENCES users(id), authorization_obtained BOOLEAN NOT NULL,
          attested_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS evaluation_id INTEGER;
        DO $$ BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_analyses_evaluation') THEN
            ALTER TABLE analyses ADD CONSTRAINT fk_analyses_evaluation FOREIGN KEY(evaluation_id) REFERENCES clinical_evaluations(id);
          END IF;
          IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='uq_analyses_evaluation') THEN
            ALTER TABLE analyses ADD CONSTRAINT uq_analyses_evaluation UNIQUE(evaluation_id);
          END IF;
        END $$;
        """)
        return
    bind = op.get_bind()
    for name in NEW_TABLES:
        Base.metadata.tables[name].create(bind, checkfirst=True)
    inspector = sa.inspect(bind)
    user_columns = {item["name"] for item in inspector.get_columns("users")}
    analysis_columns = {item["name"] for item in inspector.get_columns("analyses")}
    if "profession" not in user_columns:
        op.add_column("users", sa.Column("profession", sa.String(), nullable=True))
    if "specialty" not in user_columns:
        op.add_column("users", sa.Column("specialty", sa.String(), nullable=True))
    if "evaluation_id" not in analysis_columns:
        with op.batch_alter_table("analyses") as batch:
            batch.add_column(sa.Column("evaluation_id", sa.Integer(), nullable=True))
            batch.create_foreign_key("fk_analyses_evaluation", "clinical_evaluations", ["evaluation_id"], ["id"])
            batch.create_unique_constraint("uq_analyses_evaluation", ["evaluation_id"])


def downgrade():
    with op.batch_alter_table("analyses") as batch:
        batch.drop_constraint("uq_analyses_evaluation", type_="unique")
        batch.drop_constraint("fk_analyses_evaluation", type_="foreignkey")
        batch.drop_column("evaluation_id")
    with op.batch_alter_table("users") as batch:
        batch.drop_column("specialty")
        batch.drop_column("profession")
    for name in reversed(NEW_TABLES):
        op.drop_table(name)
