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
- [x] 8.5 Update environment-variable examples and deployment documentation for Render backend, Neon PostgreSQL, Cloudinary, migrations, readiness endpoints, and local SQLite use.

## 9. Recent Hardening and Release Verification

- [x] 9.1 Harden registration with required profession, optional declared specialty, independent accessible password/confirmation visibility actions, Center/Independent cards, all institutional center types, and access-verification wording; covered by the confirmed Flutter suite (`167 passed`) and clean `flutter analyze`.
- [x] 9.2 Harden center discovery and lifecycle enforcement so name search spans all institutional types, active centers are selectable, pending centers are visible/disabled, rejected and independent workspaces are private, legal user/workspace/membership transitions are enforced, suspended requesters cannot be approved, and last-`clinic_admin` invariants hold; covered by the confirmed backend suite (`83 passed`) and Flutter suite (`167 passed`).
- [x] 9.3 Harden startup/login routing and the workspace gate so `/ready` retains current cold-start behavior, login always transitions, `platform_admin` reaches the standalone admin root, professionals cannot bypass active-workspace selection, typed pending/rejected/inactive/error states support refresh/logout, approval status refreshes automatically without overlapping requests, and one versus multiple active memberships route correctly; covered by the confirmed Flutter suite (`168 passed`) and clean analysis.
- [x] 9.4 Harden auth/workspace boundaries so sensitive Riverpod providers are cleared, stale workspace completion and old-token `401` cannot affect a new session, token-matched `401` expires auth, ordinary `403` preserves auth, machine-identifiable revocation clears workspace only, suspension clears auth, resume revalidates membership, and failed validation cannot use cached privileged routing; covered by the confirmed backend suite (`83 passed`) and Flutter suite (`167 passed`).
- [x] 9.5 Harden workspace-scoped patient/lesion/history/prediction state, typed picker states, stale response rejection, patient/workspace selection clearing rules, prediction prerequisites, original-context retry, immutable prediction handling, guarded navigation, non-diagnostic text, and string/map/list FastAPI error normalization without technical UI leakage; covered by the confirmed backend suite (`83 passed`), Flutter suite (`167 passed`), and clean analysis.
- [x] 9.6 Confirm through automated contracts that the ResNet50 ONNX artifact, external data, preprocessing, class order, threshold, and inference semantics remain unchanged and checksum-protected; covered by the confirmed backend suite (`83 passed`).
- [ ] 9.7 On an actual device, verify both institutional-center and independent registration/approval flows, including pending access wording, suspended-requester denial, role assignment, and resulting active access.
- [ ] 9.8 On actual devices, verify an administrator can approve while the professional remains on the pending screen, the gate detects approval automatically and routes to the correct auto-selected or selectable workspace, including pending/rejected/inactive/error, manual refresh, back-block, and root logout behavior.
- [ ] 9.9 Deploy the latest backend revision and production environment configuration to Render, including Neon, Cloudinary, Alembic revision, readiness, and approved ResNet50 checksum configuration; record deployment identity without secrets.
- [ ] 9.10 Execute and document the full production flow after a Render cold start: active workspace -> patient search/create -> lesion select/create -> camera/gallery capture -> attestation -> Cloudinary upload -> ResNet50 prediction -> Neon persistence -> chronological history.
- [ ] 9.11 Verify a migrated existing user and retained history in the latest deployed environment, including compatibility workspace, patient/lesion relationships, image reference, prediction provenance, and tenant isolation.
- [ ] 9.12 Produce the release APK, record version/build identity, filename, SHA-256 hash, build timestamp and source revision when available, document clean-install guidance, then install that exact artifact on a physical device and record observed results.
- [x] 9.13 Implement the production-quality longitudinal patient chart vertical slice with typed complete lesion timelines, controlled status/notes patching, normalized history identifiers, Clean Architecture follow-up layers/controller/views, clinical-observation propagation, repeat-analysis root callback, robust picker states, and confirmed safe workspace switching; covered by backend (`84 passed`), Flutter (`174 passed`), and clean `flutter analyze`.
