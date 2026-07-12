"""Non-destructive users and analyses baseline."""
from alembic import context, op
import sqlalchemy as sa

revision = "0001_legacy_baseline"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    if context.is_offline_mode():
        op.execute("""
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY, full_name VARCHAR NOT NULL,
          doctor_id VARCHAR NOT NULL UNIQUE, medical_center VARCHAR,
          email VARCHAR NOT NULL UNIQUE, hashed_password VARCHAR NOT NULL,
          created_at TIMESTAMP WITHOUT TIME ZONE,
          status VARCHAR NOT NULL DEFAULT 'active',
          role VARCHAR NOT NULL DEFAULT 'doctor'
        );
        CREATE TABLE IF NOT EXISTS analyses (
          id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id),
          prediction VARCHAR NOT NULL, confidence DOUBLE PRECISION NOT NULL,
          image_path VARCHAR, patient_id VARCHAR, patient_name VARCHAR,
          timestamp TIMESTAMP WITHOUT TIME ZONE, model_version VARCHAR,
          processing_time_ms DOUBLE PRECISION
        );
        ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR;
        ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR;
        UPDATE users SET status='active' WHERE status IS NULL;
        UPDATE users SET role='doctor' WHERE role IS NULL;
        ALTER TABLE users ALTER COLUMN status SET DEFAULT 'active';
        ALTER TABLE users ALTER COLUMN status SET NOT NULL;
        ALTER TABLE users ALTER COLUMN role SET DEFAULT 'doctor';
        ALTER TABLE users ALTER COLUMN role SET NOT NULL;
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS patient_id VARCHAR;
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS patient_name VARCHAR;
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS model_version VARCHAR;
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS processing_time_ms DOUBLE PRECISION;
        """)
        return
    bind = op.get_bind()
    tables = set(sa.inspect(bind).get_table_names())
    if "users" not in tables:
        op.create_table(
            "users", sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("full_name", sa.String(), nullable=False),
            sa.Column("doctor_id", sa.String(), nullable=False, unique=True),
            sa.Column("medical_center", sa.String()), sa.Column("email", sa.String(), nullable=False, unique=True),
            sa.Column("hashed_password", sa.String(), nullable=False), sa.Column("created_at", sa.DateTime()),
            sa.Column("status", sa.String(), nullable=False, server_default="active"),
            sa.Column("role", sa.String(), nullable=False, server_default="doctor"),
        )
    if "analyses" not in tables:
        op.create_table(
            "analyses", sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("prediction", sa.String(), nullable=False), sa.Column("confidence", sa.Float(), nullable=False),
            sa.Column("image_path", sa.String()), sa.Column("patient_id", sa.String()),
            sa.Column("patient_name", sa.String()), sa.Column("timestamp", sa.DateTime()),
            sa.Column("model_version", sa.String()), sa.Column("processing_time_ms", sa.Float()),
        )
    inspector = sa.inspect(bind)
    for table, additions in {
        "users": [("status", sa.String(), "active"), ("role", sa.String(), "doctor")],
        "analyses": [("patient_id", sa.String(), None), ("patient_name", sa.String(), None), ("model_version", sa.String(), None), ("processing_time_ms", sa.Float(), None)],
    }.items():
        columns = {item["name"] for item in inspector.get_columns(table)}
        for name, type_, default in additions:
            if name not in columns:
                op.add_column(table, sa.Column(name, type_, nullable=True))
                if default:
                    op.execute(sa.text(f"UPDATE {table} SET {name} = :value WHERE {name} IS NULL").bindparams(value=default))


def downgrade():
    # Baseline downgrade intentionally preserves the deployed legacy schema and data.
    pass
