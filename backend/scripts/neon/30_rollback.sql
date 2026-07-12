-- Destructive to normalized records. Use only before application cutover and after backup.
BEGIN;
ALTER TABLE analyses DROP CONSTRAINT IF EXISTS uq_analyses_evaluation;
ALTER TABLE analyses DROP CONSTRAINT IF EXISTS fk_analyses_evaluation;
ALTER TABLE analyses DROP COLUMN IF EXISTS evaluation_id;
ALTER TABLE users DROP COLUMN IF EXISTS specialty;
ALTER TABLE users DROP COLUMN IF EXISTS profession;
DROP TABLE IF EXISTS consent_attestations, model_predictions, lesion_images,
  clinical_evaluations, oral_lesions, patients, workspace_memberships,
  clinical_workspaces CASCADE;
DELETE FROM alembic_version;
INSERT INTO alembic_version(version_num) VALUES ('0001_legacy_baseline');
COMMIT;
