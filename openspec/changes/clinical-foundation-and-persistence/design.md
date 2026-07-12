## Context

BucalScan AI is a Flutter/Riverpod mobile client backed by FastAPI, SQLAlchemy, and a CPU-hosted ResNet50 ONNX classifier on Render. Production data is stored in PostgreSQL on Neon through `DATABASE_URL`; SQLite is used locally and in tests. Images are uploaded to Cloudinary in production, with a filesystem fallback used during local development. The Flutter startup screen already polls the backend to mitigate Render free-tier cold starts.

The current database consists primarily of users and analyses. A medical center is free text on the user, patient data is duplicated on analyses, and each prediction is treated as an isolated event. Schema creation relies on `create_all` plus SQLite-only patches, which cannot safely evolve an existing Neon schema. Current roles are `doctor` and `admin`, public registration immediately creates a doctor, and the mobile client incorrectly treats both `401` and `403` as session expiration.

This change crosses persistence, identity, API, inference, and mobile modules. Existing records and the current prediction endpoint behavior must remain usable while the data model is normalized. The trained model is an immutable input to this work.

## Goals / Non-Goals

**Goals:**

- Establish a repeatable migration path for existing SQLite and Neon PostgreSQL databases.
- Model clinical workspaces, memberships, patients, lesions, evaluations, predictions, and consent attestations with explicit relationships.
- Introduce the minimum role and approval rules needed for clinic use without creating a separate specialist role.
- Preserve current users, analyses, image references, and ResNet50 inference behavior.
- Separate model output from professional clinical information.
- Make backend readiness meaningful during Render cold starts.
- Correct mobile authorization handling, permissions, and product identity.
- Keep the primary mobile action focused on selecting a patient and analyzing an oral-lesion image.

**Non-Goals:**

- Retraining, fine-tuning, replacing, recalibrating, or changing the threshold of the current model.
- Implementing a complete clinical risk score, guided image-quality model, longitudinal comparison UI, referrals, PDF reports, or notifications.
- Creating a separate `specialist` role; specialty remains profile metadata on a professional.
- Adding patient accounts or requiring patients to operate the application.
- Implementing digital patient signatures, legal-document management, or advanced consent withdrawal workflows.
- Making Cloudinary assets private, issuing signed URLs, or implementing retention/deletion policies in this academic phase.
- Adding billing, subscriptions, multiple branches per clinic, or external professional-license verification.
- Eliminating Render free-tier cold starts.

## Decisions

### 1. Adopt Alembic as the only schema-evolution mechanism

Alembic will be added to the backend and configured from the same `DATABASE_URL` resolution used by the application. `Base.metadata.create_all()` may remain temporarily for isolated tests but will not be the production migration mechanism. The SQLite-only runtime patch will be retired once the baseline migration covers supported upgrade paths.

Alternatives considered:

- Continue `create_all`: rejected because it cannot alter existing PostgreSQL tables safely.
- Hand-written SQL scripts: rejected because they lack consistent revision ordering, downgrade support, and SQLAlchemy model integration.

### 2. Normalize around a clinical workspace boundary

A `clinical_workspaces` table will represent clinics, consultorios, hospitals, universities, campaigns, and independent practices. A `workspace_memberships` table will relate users to workspaces with role, approval status, approver, and timestamps. A user can eventually belong to multiple workspaces, while requests use an explicit active workspace context.

New clinics remain discoverable with `pending` status while awaiting `platform_admin` approval. Searches normalize names and compare available city, address, tax identifier, telephone, and institutional email data to warn about active or pending duplicates. Other professionals cannot request membership until the clinic is active. On approval, the initial requester becomes `clinic_admin`; subsequent membership requests are managed by that clinic administrator.

The initial roles are `platform_admin`, `clinic_admin`, `professional`, and `assistant`. Profession and specialty remain separate attributes. Authorization will resolve current membership state from the database rather than trusting a stale role claim alone.

Alternatives considered:

- Keep one clinic foreign key on users: rejected because it prevents future multi-clinic membership and mixes identity with authorization.
- Create `specialist` as a role: rejected because specialist describes clinical qualification, not a distinct permission set in this phase.

### 3. Migrate legacy role and medical-center data deterministically

Existing `admin` users will map to `platform_admin`; existing `doctor` users will map to `professional`. Each distinct non-empty `medical_center` value will produce a compatibility workspace after normalized matching, and the user will receive an active membership. Users without a medical center will receive an independent workspace. The migration will not attempt automatic fuzzy merging of differently spelled clinic names because an incorrect merge is harder to reverse than separate compatibility workspaces.

Existing users are treated as approved so the deployment does not lock out current accounts. Approval is required for newly self-registered professionals after the migration.

An independent workspace is created when requested, but its professional remains pending until a `platform_admin` approves the professional. The first `platform_admin` is bootstrapped by registering normally and then running a versioned, idempotent SQL promotion script keyed by unique email. The script never inserts or modifies password material and aborts unless exactly one user matches.

### 4. Introduce patient, lesion, evaluation, and prediction boundaries

The target relationship is:

```text
ClinicalWorkspace
  ├── Memberships ── Users
  └── Patients
        └── OralLesions
              └── ClinicalEvaluations
                    ├── LesionImage
                    ├── ModelPrediction
                    └── ConsentAttestation
```

`patients` stores reusable identity/demographic information scoped to a workspace. Every patient has a required clinical code unique within that workspace and may have an identity document that is also unique within that workspace. Professionals can search by clinical code, identity document, or name; patients do not receive application accounts. `oral_lesions` stores anatomical and lifecycle information. `clinical_evaluations` represents a dated professional encounter. `model_predictions` stores immutable inference output and provenance. Consent fields can be stored one-to-one with the evaluation in this phase while preserving a boundary that can later become a richer consent entity.

Alternative considered:

- Add more columns to `analyses`: rejected because it continues duplication and cannot represent multiple lesions or repeated evaluations cleanly.

### 5. Preserve compatibility through phased analysis migration

The existing `analyses` table will not be destructively rewritten in the first deployment. New normalized tables and nullable compatibility foreign keys will be introduced, then a data migration will create patients, lesions, evaluations, and model predictions from existing rows. Application reads will switch only after migration verification. Legacy columns remain during this change and can be removed in a later, separately approved cleanup.

For an analysis with patient metadata, patient matching will prioritize the legacy patient identifier within the compatibility workspace. Records without patient metadata will be attached to a clearly marked legacy anonymous patient. Each legacy analysis initially receives its own legacy lesion unless deterministic evidence links analyses; this avoids falsely grouping distinct lesions.

### 6. Keep the inference service and artifact immutable

The current model files, preprocessing, class order, and response semantics will not be edited. A model-integrity test will target the configured ResNet50 artifact rather than MobileNetV2. Readiness will validate that the ONNX session can load and exposes the expected contract. Prediction persistence will copy the returned values into `model_predictions`; clinical observations never overwrite those values.

SHA-256 checksums for the approved ResNet50 ONNX file and its external `.onnx.data` file will be recorded and verified by regression tests or deployment checks. This change will not introduce a remote model registry.

### 7. Use explicit workspace context in clinical APIs

Clinical requests will identify the active workspace through a stable API mechanism selected consistently for Flutter and backend, preferably an `X-Workspace-ID` header validated against active membership. Resource-level queries will also enforce workspace ownership to prevent identifier-based cross-workspace access.

After authentication, a user with multiple active memberships selects the active workspace before entering the normal application flow. Flutter persists the selected workspace for the session and always displays enough workspace context to change it deliberately.

Registration and workspace discovery endpoints remain outside active-workspace enforcement where necessary. Platform administration uses explicit elevated authorization rather than a synthetic workspace.

Alternative considered:

- Infer workspace from the user: rejected because it becomes ambiguous once a professional belongs to multiple clinics.

### 8. Treat consent as professional attestation

The existing consent gate will be retained but renamed and presented as the professional confirming that patient authorization was obtained. The record stores who attested and when. No patient login, signature, or legal-document upload is required.

This is intentionally an academic, lightweight workflow and must not be described as direct in-app patient consent.

### 9. Separate liveness from readiness

`/live` will perform no dependency checks. `/ready` will verify database connectivity and validated model availability with bounded execution time and sanitized failure responses. Existing `/health` can temporarily remain as a compatibility alias while Flutter moves to `/ready`.

Flutter will retain retry behavior but replace provider-specific wording with product language. Readiness failure will not be confused with invalid credentials or inference failure.

Alternative considered:

- Expand `/health` only: rejected because deployment liveness probes must not restart a healthy process merely because an external dependency is temporarily unavailable.

### 10. Keep Cloudinary behavior simple but environment-aware

Advanced Cloudinary privacy is explicitly deferred. Production configuration will expect Cloudinary and will not rely on Render's ephemeral filesystem for durable clinical images. Local development can continue using filesystem fallback. This can be enforced through an environment designation or a startup/configuration check without exposing credentials.

### 11. Deliver backward-compatible API evolution

The existing `/api/v1/predict` response fields used by Flutter will remain available. Request evolution will be additive where possible, introducing patient, lesion, workspace, and attestation identifiers. During a short compatibility window, migrated legacy clients can still consume existing result fields, but new persisted analyses must satisfy normalized relationships.

If additive compatibility makes validation ambiguous, richer clinical endpoints will be introduced under `/api/v2` rather than silently changing `/api/v1` semantics.

### 12. Correct mobile platform and session behavior independently of model flow

The Dio interceptor will clear credentials only for `401`; a `403` will propagate as an authorization error. iOS camera and photo-library usage descriptions, applicable Android declarations, and product display names will be aligned to BucalScan AI. Permission denial will be represented as a recoverable UI state.

## Risks / Trade-offs

- [Large cross-cutting schema change] → Implement migrations and application cutover in phases, verify row counts and relationships, and retain legacy columns until a later cleanup.
- [Legacy clinic names produce duplicates] → Prefer separate compatibility workspaces and allow later administrator consolidation rather than risky automatic fuzzy merges.
- [Legacy analyses cannot be reliably grouped by lesion] → Create one legacy lesion per analysis unless deterministic linkage exists.
- [New approval workflow locks out existing users] → Mark migrated users and memberships active; apply pending approval only to new self-registration.
- [Multi-workspace context complicates APIs] → Use one explicit, consistently validated workspace identifier and central authorization dependencies.
- [Readiness checks increase startup traffic during Render wake-up] → Keep checks lightweight, bounded, and safe under polling.
- [ResNet50 test increases test time or repository resource use] → Use a minimal representative image and session reuse while still testing the deployed artifact.
- [Cloudinary assets remain accessible by URL] → Accept as an academic-phase limitation and retain privacy hardening as a future change.
- [Production depends on free-tier sleeping infrastructure] → Preserve clear retry/failure UX; a non-sleeping hosting plan remains a future operational decision.
- [SQLite and PostgreSQL differ] → Add migration tests for SQLite and PostgreSQL-compatible integration coverage where feasible, with Neon staging verification before production migration.

## Migration Plan

1. The project owner captures a backup of the Neon database and records baseline counts for users and analyses.
2. Add Alembic configuration and create a baseline revision representing the current deployed schema without dropping data.
3. Generate ordered PostgreSQL migration, verification, and rollback SQL scripts; the project owner reviews and executes approved production scripts manually in the Neon console.
4. Add workspace, membership, patient, lesion, evaluation, image/prediction, and consent-compatible structures through forward migrations.
5. Backfill legacy users into roles, workspaces, and active memberships using deterministic rules.
6. Backfill analyses into patient, lesion, evaluation, and prediction records while preserving every original field and identifier mapping.
7. Run migration verification for row counts, orphan checks, unique constraints, model provenance, and image references.
8. Deploy backend code capable of reading the normalized model while preserving the current prediction response contract.
9. Deploy Flutter changes for workspace context, patient/lesion selection, readiness, permission declarations, and corrected `401`/`403` behavior.
10. Monitor readiness, authentication failures, migration-related errors, and prediction persistence after deployment.
11. Retain legacy columns and tables through this release; propose destructive cleanup only after production verification.

Rollback strategy:

- Before application cutover, downgrade the latest Alembic revisions or restore the Neon backup if a data migration cannot be corrected safely.
- After normalized writes begin, prefer a forward-fix migration. Restoring a backup would discard new records and therefore requires an explicit maintenance decision.
- Flutter can temporarily continue using compatible `/api/v1` response fields while backend issues are corrected.

## Open Questions

No blocking product decisions remain for this change. Production database scripts will be supplied for manual execution by the project owner in Neon, and their actual execution will remain an explicit deployment checkpoint.
