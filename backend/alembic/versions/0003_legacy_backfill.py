"""Deterministic legacy users and analyses backfill."""
import re
import unicodedata

from alembic import context, op
import sqlalchemy as sa

revision = "0003_legacy_backfill"
down_revision = "0002_clinical_schema"
branch_labels = None
depends_on = None


def _normalize(value):
    value = unicodedata.normalize("NFKD", value or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()


def upgrade():
    if context.is_offline_mode():
        op.execute("""
        CREATE TEMP TABLE migration_user_workspaces(user_id INTEGER PRIMARY KEY, workspace_id INTEGER NOT NULL) ON COMMIT DROP;
        WITH centers AS (
          SELECT lower(regexp_replace(trim(medical_center), '[^a-zA-Z0-9]+', ' ', 'g')) AS center_key,
                 min(medical_center) AS center_name, min(id) AS requester_id, min(created_at) AS created_at
          FROM users WHERE trim(coalesce(medical_center,''))<>'' GROUP BY 1
        ), inserted AS (
          INSERT INTO clinical_workspaces(name, normalized_name, workspace_type, status, initial_requester_id, created_at, updated_at)
          SELECT center_name, center_key, 'clinic', 'active', requester_id, coalesce(created_at,CURRENT_TIMESTAMP), coalesce(created_at,CURRENT_TIMESTAMP)
          FROM centers c WHERE NOT EXISTS (SELECT 1 FROM clinical_workspaces w WHERE w.normalized_name=c.center_key)
          RETURNING id
        ) SELECT count(*) FROM inserted;
        INSERT INTO clinical_workspaces(name, normalized_name, workspace_type, status, initial_requester_id, created_at, updated_at)
        SELECT 'Independent practice - '||u.full_name, 'independent-user-'||u.id, 'independent', 'active', u.id,
               coalesce(u.created_at,CURRENT_TIMESTAMP), coalesce(u.created_at,CURRENT_TIMESTAMP)
        FROM users u WHERE trim(coalesce(u.medical_center,''))=''
          AND NOT EXISTS (SELECT 1 FROM clinical_workspaces w WHERE w.normalized_name='independent-user-'||u.id);
        INSERT INTO migration_user_workspaces(user_id, workspace_id)
        SELECT u.id, w.id FROM users u JOIN clinical_workspaces w ON w.normalized_name =
          CASE WHEN trim(coalesce(u.medical_center,''))='' THEN 'independent-user-'||u.id
          ELSE lower(regexp_replace(trim(u.medical_center), '[^a-zA-Z0-9]+', ' ', 'g')) END;
        UPDATE users SET role=CASE WHEN role IN ('admin','platform_admin') THEN 'platform_admin' ELSE 'professional' END, status='active';
        INSERT INTO workspace_memberships(workspace_id,user_id,role,status,approved_at,created_at,updated_at)
        SELECT m.workspace_id,u.id,CASE WHEN u.role='platform_admin' THEN 'clinic_admin' ELSE 'professional' END,'active',
               coalesce(u.created_at,CURRENT_TIMESTAMP),coalesce(u.created_at,CURRENT_TIMESTAMP),coalesce(u.created_at,CURRENT_TIMESTAMP)
        FROM users u JOIN migration_user_workspaces m ON m.user_id=u.id
        ON CONFLICT(workspace_id,user_id) DO NOTHING;
        INSERT INTO patients(workspace_id,clinical_code,full_name,normalized_name,is_legacy_anonymous,created_by_id,created_at,updated_at)
        SELECT DISTINCT ON (m.workspace_id, coalesce(nullif(trim(a.patient_id),''),
                 CASE WHEN trim(coalesce(a.patient_name,''))<>'' THEN 'LEGACY-NAME-'||md5(lower(trim(a.patient_name))) ELSE 'LEGACY-ANON-'||m.workspace_id END))
          m.workspace_id,
          coalesce(nullif(trim(a.patient_id),''), CASE WHEN trim(coalesce(a.patient_name,''))<>'' THEN 'LEGACY-NAME-'||md5(lower(trim(a.patient_name))) ELSE 'LEGACY-ANON-'||m.workspace_id END),
          coalesce(nullif(trim(a.patient_name),''),'Legacy anonymous patient'),
          lower(regexp_replace(coalesce(nullif(trim(a.patient_name),''),'Legacy anonymous patient'),'[^a-zA-Z0-9]+',' ','g')),
          trim(coalesce(a.patient_id,''))='' AND trim(coalesce(a.patient_name,''))='', a.user_id,
          coalesce(a.timestamp,CURRENT_TIMESTAMP),coalesce(a.timestamp,CURRENT_TIMESTAMP)
        FROM analyses a JOIN migration_user_workspaces m ON m.user_id=a.user_id
        WHERE a.evaluation_id IS NULL ON CONFLICT(workspace_id,clinical_code) DO NOTHING;
        WITH source AS (
          SELECT a.*,m.workspace_id,p.id AS normalized_patient_id FROM analyses a
          JOIN migration_user_workspaces m ON m.user_id=a.user_id
          JOIN patients p ON p.workspace_id=m.workspace_id AND p.clinical_code=coalesce(nullif(trim(a.patient_id),''),
            CASE WHEN trim(coalesce(a.patient_name,''))<>'' THEN 'LEGACY-NAME-'||md5(lower(trim(a.patient_name))) ELSE 'LEGACY-ANON-'||m.workspace_id END)
          WHERE a.evaluation_id IS NULL
        ), new_lesions AS (
          INSERT INTO oral_lesions(workspace_id,patient_id,anatomical_site,estimated_duration,status,clinical_notes,created_by_id,created_at,updated_at)
          SELECT workspace_id,normalized_patient_id,'legacy-unspecified','unknown','active','Migrated from analysis '||id,user_id,
                 coalesce(timestamp,CURRENT_TIMESTAMP),coalesce(timestamp,CURRENT_TIMESTAMP) FROM source ORDER BY id RETURNING id,clinical_notes
        ), new_evaluations AS (
          INSERT INTO clinical_evaluations(workspace_id,patient_id,lesion_id,professional_id,evaluated_at,created_at)
          SELECT s.workspace_id,s.normalized_patient_id,l.id,s.user_id,coalesce(s.timestamp,CURRENT_TIMESTAMP),coalesce(s.timestamp,CURRENT_TIMESTAMP)
          FROM source s JOIN new_lesions l ON l.clinical_notes='Migrated from analysis '||s.id RETURNING id,lesion_id
        ), mapped AS (
          SELECT s.*,e.id AS new_evaluation_id FROM source s JOIN new_lesions l ON l.clinical_notes='Migrated from analysis '||s.id
          JOIN new_evaluations e ON e.lesion_id=l.id
        ), new_images AS (
          INSERT INTO lesion_images(evaluation_id,storage_url,created_at)
          SELECT new_evaluation_id,coalesce(nullif(image_path,''),'legacy://missing-image'),coalesce(timestamp,CURRENT_TIMESTAMP)
          FROM mapped RETURNING id,evaluation_id
        ), predictions AS (
          INSERT INTO model_predictions(evaluation_id,image_id,model_version,predicted_label,confidence,benign_probability,malignant_probability,processing_time_ms,created_at)
          SELECT m.new_evaluation_id,i.id,coalesce(m.model_version,'legacy-unknown'),m.prediction,m.confidence,
                 CASE WHEN m.prediction='malignant' THEN 1-m.confidence ELSE m.confidence END,
                 CASE WHEN m.prediction='malignant' THEN m.confidence ELSE 1-m.confidence END,
                 m.processing_time_ms,coalesce(m.timestamp,CURRENT_TIMESTAMP) FROM mapped m JOIN new_images i ON i.evaluation_id=m.new_evaluation_id
        ), attestations AS (
          INSERT INTO consent_attestations(evaluation_id,professional_id,authorization_obtained,attested_at)
          SELECT new_evaluation_id,user_id,TRUE,coalesce(timestamp,CURRENT_TIMESTAMP) FROM mapped
        ) UPDATE analyses a SET evaluation_id=m.new_evaluation_id FROM mapped m WHERE a.id=m.id;
        """)
        return
    bind = op.get_bind()
    metadata = sa.MetaData()
    metadata.reflect(bind=bind)
    users, analyses = metadata.tables["users"], metadata.tables["analyses"]
    workspaces, memberships = metadata.tables["clinical_workspaces"], metadata.tables["workspace_memberships"]
    patients, lesions = metadata.tables["patients"], metadata.tables["oral_lesions"]
    evaluations, images = metadata.tables["clinical_evaluations"], metadata.tables["lesion_images"]
    predictions, attestations = metadata.tables["model_predictions"], metadata.tables["consent_attestations"]

    user_rows = bind.execute(sa.select(users)).mappings().all()
    workspace_by_user = {}
    centers = {}
    for user in user_rows:
        center = (user.get("medical_center") or "").strip()
        key = _normalize(center) if center else f"independent-user-{user['id']}"
        workspace_id = centers.get(key)
        if workspace_id is None:
            name = center or f"Independent practice - {user['full_name']}"
            result = bind.execute(workspaces.insert().values(
                name=name, normalized_name=_normalize(name), workspace_type="clinic" if center else "independent",
                status="active", initial_requester_id=user["id"], created_at=user.get("created_at"), updated_at=user.get("created_at"),
            ))
            workspace_id = result.inserted_primary_key[0]
            centers[key] = workspace_id
        workspace_by_user[user["id"]] = workspace_id
        role = "platform_admin" if user.get("role") in ("admin", "platform_admin") else "professional"
        bind.execute(users.update().where(users.c.id == user["id"]).values(role=role, status="active"))
        bind.execute(memberships.insert().values(
            workspace_id=workspace_id, user_id=user["id"], role="clinic_admin" if role == "platform_admin" else role,
            status="active", approved_at=user.get("created_at"), created_at=user.get("created_at"), updated_at=user.get("created_at"),
        ))

    patient_cache = {}
    for analysis in bind.execute(sa.select(analyses).where(analyses.c.evaluation_id.is_(None))).mappings():
        workspace_id = workspace_by_user[analysis["user_id"]]
        legacy_identifier = (analysis.get("patient_id") or "").strip()
        legacy_name = (analysis.get("patient_name") or "").strip()
        key = (workspace_id, legacy_identifier or (f"name:{_normalize(legacy_name)}" if legacy_name else "anonymous"))
        patient_pk = patient_cache.get(key)
        if patient_pk is None:
            code = legacy_identifier or f"LEGACY-ANON-{workspace_id}"
            existing = bind.execute(sa.select(patients.c.id).where(
                patients.c.workspace_id == workspace_id, patients.c.clinical_code == code
            )).scalar()
            if existing:
                patient_pk = existing
            else:
                result = bind.execute(patients.insert().values(
                    workspace_id=workspace_id, clinical_code=code,
                    full_name=legacy_name or "Legacy anonymous patient", normalized_name=_normalize(legacy_name or "Legacy anonymous patient"),
                    is_legacy_anonymous=not bool(legacy_identifier or legacy_name), created_by_id=analysis["user_id"],
                    created_at=analysis.get("timestamp"), updated_at=analysis.get("timestamp"),
                ))
                patient_pk = result.inserted_primary_key[0]
            patient_cache[key] = patient_pk
        lesion_id = bind.execute(lesions.insert().values(
            workspace_id=workspace_id, patient_id=patient_pk, anatomical_site="legacy-unspecified",
            estimated_duration="unknown", status="active", clinical_notes=f"Migrated from analysis {analysis['id']}",
            created_by_id=analysis["user_id"], created_at=analysis.get("timestamp"), updated_at=analysis.get("timestamp"),
        )).inserted_primary_key[0]
        evaluation_id = bind.execute(evaluations.insert().values(
            workspace_id=workspace_id, patient_id=patient_pk, lesion_id=lesion_id,
            professional_id=analysis["user_id"], evaluated_at=analysis.get("timestamp"), created_at=analysis.get("timestamp"),
        )).inserted_primary_key[0]
        image_id = bind.execute(images.insert().values(
            evaluation_id=evaluation_id, storage_url=analysis.get("image_path") or "legacy://missing-image",
            created_at=analysis.get("timestamp"),
        )).inserted_primary_key[0]
        confidence = float(analysis["confidence"])
        malignant = confidence if analysis["prediction"] == "malignant" else 1.0 - confidence
        bind.execute(predictions.insert().values(
            evaluation_id=evaluation_id, image_id=image_id, model_version=analysis.get("model_version") or "legacy-unknown",
            predicted_label=analysis["prediction"], confidence=confidence,
            benign_probability=1.0 - malignant, malignant_probability=malignant,
            processing_time_ms=analysis.get("processing_time_ms"), created_at=analysis.get("timestamp"),
        ))
        bind.execute(attestations.insert().values(
            evaluation_id=evaluation_id, professional_id=analysis["user_id"], authorization_obtained=True,
            attested_at=analysis.get("timestamp"),
        ))
        bind.execute(analyses.update().where(analyses.c.id == analysis["id"]).values(evaluation_id=evaluation_id))


def downgrade():
    # Legacy rows remain untouched; normalized rows are removed by the schema downgrade.
    pass
