## 1. Baseline and Migration Safety

- [x] 1.1 Calculate and document SHA-256 checksums for the approved ResNet50 ONNX and external data files, and capture baseline counts and schema expectations for existing users and analyses.
- [x] 1.2 Add Alembic to backend dependencies and configure it to use the application's resolved `DATABASE_URL` and SQLAlchemy metadata.
- [x] 1.3 Create and verify a baseline migration representing the currently deployed users and analyses schema without recreating or deleting existing data.
- [x] 1.4 Replace production startup schema mutation with an explicit migration workflow while retaining isolated test database setup.
- [x] 1.5 Add automated migration tests for an empty SQLite database and a database containing representative legacy users and analyses.
- [x] 1.6 Generate ordered PostgreSQL migration, verification, and rollback SQL scripts for manual execution by the project owner in Neon, and document the process without storing credentials.

## 2. Clinical Domain Schema

- [x] 2.1 Add SQLAlchemy models and constraints for clinical workspaces and workspace memberships, including workspace type, member role, approval status, and audit timestamps.
- [x] 2.2 Extend user profile data for profession and specialty while mapping legacy `admin` and `doctor` behavior to the new role model.
- [x] 2.3 Add patient models scoped to a workspace with required clinic-unique clinical code, optional clinic-unique identity document, profile fields, and normalized search/duplicate data.
- [x] 2.4 Add oral-lesion models with patient relationship, anatomical site, temporal information, status, and clinical notes.
- [x] 2.5 Add clinical-evaluation, lesion-image, model-prediction, and professional consent-attestation persistence with immutable prediction provenance.
- [x] 2.6 Create forward and downgrade Alembic revisions for the normalized clinical schema and all required indexes, foreign keys, and uniqueness rules.

## 3. Legacy Data Migration

- [x] 3.1 Implement deterministic migration of existing medical-center text into compatibility workspaces and active memberships, using independent workspaces when no center exists.
- [x] 3.2 Mark migrated accounts active and map existing roles to `platform_admin` or `professional` without locking out current users.
- [x] 3.3 Migrate analyses with patient metadata into reusable patient records and create explicit legacy anonymous patients for analyses without metadata.
- [x] 3.4 Create a legacy lesion, evaluation, image reference, consent compatibility state, and immutable model-prediction record for every existing analysis.
- [x] 3.5 Add post-migration verification for row counts, orphaned records, image references, prediction values, timestamps, and model versions.
- [x] 3.6 Keep legacy analysis columns readable during the compatibility release and verify downgrade behavior before application cutover.

## 4. Workspace Identity and Authorization

- [x] 4.1 Implement workspace creation and discovery with pending-clinic visibility, normalized duplicate warnings, independent-practice creation, and membership requests limited to active clinics.
- [x] 4.2 Implement central active-workspace resolution and membership authorization for `platform_admin`, `clinic_admin`, `professional`, and `assistant`.
- [x] 4.3 Add platform approval of clinics that promotes the initial requester to `clinic_admin`, plus clinic-administrator endpoints to manage later memberships.
- [x] 4.4 Change self-registration so new professionals require approval, while supporting administrator-provisioned pre-approved demonstration accounts.
- [x] 4.5 Enforce workspace boundaries in every new clinical query and add tests proving cross-workspace identifiers cannot expose records.
- [x] 4.6 Update JWT/session profile responses as needed while continuing to resolve current role, status, and membership permissions from the database.
- [x] 4.7 Provide and test an idempotent SQL script that promotes exactly one registered user to active `platform_admin` by unique email without changing credentials.

## 5. Patients, Lesions, and Prediction Persistence

- [x] 5.1 Implement workspace-scoped patient search by clinical code, identity document, or name, plus creation, detail, uniqueness enforcement, and potential-duplicate detection endpoints.
- [x] 5.2 Implement lesion creation, detail, status, and chronological history endpoints under an authorized patient.
- [x] 5.3 Extend the analysis request flow to require workspace, patient, lesion, and professional authorization attestation references.
- [x] 5.4 Persist each successful inference as an immutable model prediction attached to a clinical evaluation while preserving existing `/api/v1/predict` response fields.
- [x] 5.5 Keep clinical observations separate from model probabilities and add decision-support, non-diagnostic wording to API and mobile result presentation.
- [x] 5.6 Restrict filesystem image fallback to local development and validate that production configuration expects Cloudinary without implementing advanced URL privacy.
- [x] 5.7 Add backend tests for patient reuse, duplicate warnings, multiple lesions, repeated lesion evaluations, missing attestation, and assistant permission denial.

## 6. Readiness and Model Integrity

- [x] 6.1 Add a dependency-free liveness endpoint and a sanitized readiness endpoint with bounded database and model checks.
- [x] 6.2 Validate the ResNet50 ONNX input/output contract during readiness without changing model files, preprocessing, class order, or threshold.
- [x] 6.3 Replace MobileNetV2-only production-contract coverage with ResNet50 regression tests for SHA-256 integrity, loading, preprocessing, probabilities, class ordering, and endpoint compatibility.
- [x] 6.4 Add failure-path tests for unavailable database, missing or incompatible model, and readiness recovery.

## 7. Flutter Clinical Foundation

- [x] 7.1 Add Flutter data/domain layers for post-login active-workspace selection, membership status, patient search/creation, and lesion selection/creation.
- [x] 7.2 Add registration choices for an active workspace, a new clinic or consultorio, and independent practice, including discoverable pending-clinic and professional-approval states.
- [x] 7.3 Update the primary analysis flow to select or create a patient and lesion while keeping image capture and AI analysis as the central action.
- [x] 7.4 Reword and persist the consent control as professional attestation that patient authorization was obtained.
- [x] 7.5 Update startup polling to use readiness and display provider-neutral preparation, retry, and unavailable states for Render cold starts.
- [x] 7.6 Change the HTTP interceptor so `401` clears an invalid session and `403` preserves the session and produces an access-denied state.
- [x] 7.7 Add the required iOS and Android camera/gallery declarations, handle permission denial, and align platform display names to BucalScan AI.
- [x] 7.8 Add Flutter unit and widget tests for workspace approval, patient/lesion selection, consent attestation, readiness retry, and `401` versus `403` behavior.

## 8. End-to-End Verification and Documentation

- [x] 8.1 Run backend formatting/static checks and the complete backend test suite against the migrated schema and retained ResNet50 model.
- [x] 8.2 Run Flutter analysis, unit tests, widget tests, and available mobile integration tests.
- [x] 8.3 Validate generated PostgreSQL scripts against an available non-production PostgreSQL environment when possible, then present the reviewed production scripts and verification queries for the project owner's manual Neon execution.
- [ ] 8.4 Verify an end-to-end flow from Render cold start through login, workspace selection, existing/new patient, lesion, Cloudinary image upload, ResNet50 prediction, and Neon persistence.
- [x] 8.5 Update environment-variable examples and deployment documentation for Render backend, Neon PostgreSQL, Cloudinary, migrations, readiness endpoints, and local SQLite use.
- [x] 8.6 Confirm existing users can sign in and existing analyses remain visible after migration, then document known academic-phase limitations and deferred capabilities.
