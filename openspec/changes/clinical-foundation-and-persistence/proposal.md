## Why

BucalScan AI already performs mobile oral-lesion analysis with a deployed ONNX model, but its prototype data model and operational safeguards do not yet support shared clinical work, longitudinal patient records, or safe schema evolution in the production Neon database. This change establishes that foundation while preserving the current trained ResNet50 model and keeping image analysis as the central mobile workflow.

## What Changes

- Establish PostgreSQL on Neon as the production source of truth, retain SQLite for local development and tests, and introduce versioned Alembic migrations before evolving the schema.
- Replace the free-text medical center association with registered clinics or independent professional workspaces, visible approval states, duplicate prevention, and managed memberships.
- Introduce the initial roles `platform_admin`, `clinic_admin`, `professional`, and `assistant`; specialists remain professionals identified by their specialty rather than a separate role.
- Require administrative approval before a newly registered professional can perform clinical analyses, while supporting pre-approved demonstration accounts.
- Promote the initial `platform_admin` through a versioned SQL script after normal account registration; the first requester of an approved clinic becomes its `clinic_admin`.
- Introduce reusable patient and oral-lesion records so professionals can select an existing patient or create one and associate repeated evaluations with the same lesion.
- Require a clinic-unique clinical code for each patient, allow an optional clinic-unique identity document, and support searches by either value or patient name.
- Separate immutable model predictions from clinical observations and future risk assessments, without retraining, replacing, or changing the current ResNet50 ONNX inference contract.
- Record a lightweight professional attestation that patient authorization was obtained before capturing, analyzing, and storing a clinical image.
- Preserve Cloudinary as the expected production image store and permit local image storage only for development; advanced private delivery, signed URLs, and retention policies remain out of scope.
- Add liveness and readiness behavior so the Flutter startup flow can distinguish a running API from a service whose database and model are ready, while retaining Render free-tier cold-start retries.
- Correct authorization handling so `401` expires a session while `403` reports insufficient permission without logging the user out.
- Add regression coverage for the deployed ResNet50 artifact and correct mobile camera/gallery permissions and product naming.
- Preserve existing analyses through an explicit migration and compatibility strategy.
- Deliver versioned Neon migration, verification, and rollback SQL for manual execution by the project owner.

## Capabilities

### New Capabilities

- `production-persistence`: Environment-specific persistence rules, Alembic migrations, Neon compatibility, and preservation of existing records.
- `clinical-organization-access`: Clinics, independent workspaces, memberships, initial roles, account approval, and tenant-scoped permissions.
- `patient-lesion-records`: Reusable patient records, distinct oral-lesion cases, evaluation association, duplicate detection, and professional consent attestation.
- `inference-clinical-separation`: Preservation and regression testing of the current ResNet50 output while storing model predictions separately from clinical interpretation.
- `service-readiness`: Liveness, database/model readiness, Render cold-start behavior, and correct client handling of authentication versus authorization failures.
- `mobile-capture-readiness`: Required camera/gallery platform permissions and consistent BucalScan AI product naming.

### Modified Capabilities

None. The repository has no existing OpenSpec capability specifications.

## Impact

- Backend: FastAPI startup and health routes, SQLAlchemy models, authentication and authorization, prediction persistence, history APIs, configuration, dependencies, and tests.
- Database: Neon PostgreSQL schema and migration process; SQLite development and test setup.
- Mobile app: registration, startup readiness, session error handling, patient selection, analysis flow, platform permissions, and displayed branding.
- External services: Render continues to host the backend, Neon hosts production PostgreSQL, and Cloudinary remains the production image store.
- Model: the existing ResNet50 ONNX artifact, preprocessing, class order, and prediction semantics remain unchanged.
- Compatibility: existing users and analyses require deterministic migration into the new organization, patient, lesion, and prediction relationships.
