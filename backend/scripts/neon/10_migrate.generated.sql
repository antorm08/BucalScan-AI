BEGIN;

CREATE TABLE alembic_version (
    version_num VARCHAR(32) NOT NULL, 
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);

-- Running upgrade  -> 0001_legacy_baseline

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
        ALTER TABLE analyses ADD COLUMN IF NOT EXISTS processing_time_ms DOUBLE PRECISION;;

INSERT INTO alembic_version (version_num) VALUES ('0001_legacy_baseline') RETURNING alembic_version.version_num;

-- Running upgrade 0001_legacy_baseline -> 0002_clinical_schema

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
        END $$;;

UPDATE alembic_version SET version_num='0002_clinical_schema' WHERE alembic_version.version_num = '0001_legacy_baseline';

-- Running upgrade 0002_clinical_schema -> 0003_legacy_backfill

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
        ) UPDATE analyses a SET evaluation_id=m.new_evaluation_id FROM mapped m WHERE a.id=m.id;;

UPDATE alembic_version SET version_num='0003_legacy_backfill' WHERE alembic_version.version_num = '0002_clinical_schema';

-- Running upgrade 0003_legacy_backfill -> 0004_clinical_priority

CREATE TABLE clinical_assessment_snapshots (
    id SERIAL NOT NULL,
    workspace_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    lesion_id INTEGER NOT NULL,
    evaluation_id INTEGER NOT NULL,
    assessor_id INTEGER NOT NULL,
    schema_version VARCHAR NOT NULL,
    ruleset_version VARCHAR NOT NULL,
    canonical_payload JSON NOT NULL,
    completion_status VARCHAR NOT NULL,
    assessed_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_assessment_evaluation UNIQUE (evaluation_id),
    FOREIGN KEY(workspace_id) REFERENCES clinical_workspaces (id),
    FOREIGN KEY(patient_id) REFERENCES patients (id),
    FOREIGN KEY(lesion_id) REFERENCES oral_lesions (id),
    FOREIGN KEY(evaluation_id) REFERENCES clinical_evaluations (id) ON DELETE CASCADE,
    FOREIGN KEY(assessor_id) REFERENCES users (id)
);

CREATE INDEX ix_assessments_workspace_assessed ON clinical_assessment_snapshots (workspace_id, assessed_at);

CREATE INDEX ix_assessments_lesion ON clinical_assessment_snapshots (lesion_id);

CREATE TABLE clinical_priority_results (
    id SERIAL NOT NULL,
    assessment_id INTEGER NOT NULL,
    workspace_id INTEGER NOT NULL,
    evaluation_id INTEGER NOT NULL,
    priority_code VARCHAR NOT NULL,
    reason_codes JSON NOT NULL,
    rendered_reasons JSON NOT NULL,
    ruleset_id VARCHAR NOT NULL,
    ruleset_version VARCHAR NOT NULL,
    engine_version VARCHAR NOT NULL,
    evaluated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_priority_assessment UNIQUE (assessment_id),
    CONSTRAINT uq_priority_evaluation UNIQUE (evaluation_id),
    FOREIGN KEY(assessment_id) REFERENCES clinical_assessment_snapshots (id) ON DELETE CASCADE,
    FOREIGN KEY(workspace_id) REFERENCES clinical_workspaces (id),
    FOREIGN KEY(evaluation_id) REFERENCES clinical_evaluations (id) ON DELETE CASCADE
);

CREATE INDEX ix_priority_workspace_evaluated ON clinical_priority_results (workspace_id, evaluated_at);

CREATE INDEX ix_priority_code ON clinical_priority_results (priority_code);

UPDATE alembic_version SET version_num='0004_clinical_priority' WHERE alembic_version.version_num = '0003_legacy_backfill';

-- Running upgrade 0004_clinical_priority -> 0005_model_prediction_heatmap

ALTER TABLE model_predictions ADD COLUMN heatmap_url VARCHAR;

UPDATE alembic_version SET version_num='0005_model_prediction_heatmap' WHERE alembic_version.version_num = '0004_clinical_priority';

COMMIT;

