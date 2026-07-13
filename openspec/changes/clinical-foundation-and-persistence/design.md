## Context

BucalScan AI is a Flutter/Riverpod client backed by FastAPI, SQLAlchemy, Neon PostgreSQL, Cloudinary, and a CPU-hosted ResNet50 ONNX classifier on Render. SQLite remains useful for local development and tests. The foundation spans registration, authentication, workspace authorization, longitudinal records, inference persistence, cold-start readiness, mobile permissions, error safety, and release evidence.

Existing users and analyses must survive schema evolution. The approved model is immutable: no retraining, replacement, preprocessing, class-order, threshold, or output-semantic change belongs in this work. The current reverted Flutter startup behavior polls `/ready` on cold start and then restores or requests authentication; that behavior is retained rather than redesigned.

## Goals / Non-Goals

**Goals:**

- Evolve Neon safely with Alembic and deterministic compatibility records.
- Make user, workspace, and membership lifecycles explicit and enforce them server-side.
- Preserve a strict Flutter flow of view -> controller -> use case -> repository contract -> implementation -> datasource -> `ApiService`.
- Prevent stale requests, old tokens, and cached providers from crossing auth or workspace boundaries.
- Isolate every clinical query by active `X-Workspace-ID` and current membership.
- Support reusable patient profiles, multiple lesions, repeated evaluations/images, immutable predictions, and separate clinical observations.
- Keep capture and prediction non-diagnostic, context-bound, permission-aware, and safely retryable.
- Produce sanitized user errors and auditable deployment/release checkpoints.

**Non-Goals:**

- Retraining, replacing, recalibrating, changing preprocessing/class order, or changing the threshold of ResNet50.
- Documentary verification of profession, title, license, or declared specialty.
- Patient accounts, legal-document workflows, digital signatures, referrals, reports, notifications, billing, or advanced Cloudinary privacy/retention.
- A new startup/navigation design beyond preserving the current reverted `/ready` cold-start flow.
- Claiming production, migration, real-device, or APK evidence that has not actually been collected.

## Decisions

### 1. Alembic and environment authority

Alembic is the schema-evolution mechanism. Production resolves `DATABASE_URL` to Neon PostgreSQL; SQLite is limited to local development and automated tests. Production requires Cloudinary for durable images and explicit environment configuration for database, storage, model artifacts, CORS/host behavior, and secrets. `create_all` may remain only for isolated tests.

Migration remains additive: legacy users and analyses are mapped deterministically, legacy columns remain during the compatibility release, and approved ResNet50/model-data SHA-256 checksums are verified. Reviewable migration, verification, and rollback SQL contains no credentials.

### 2. Explicit domain lifecycles

The server owns legal transitions:

```text
User:       pending -> active; active <-> suspended
Workspace:  pending -> active | rejected (terminal)
Membership: pending -> active | rejected; active -> inactive; inactive -> active; rejected terminal
```

`pending -> active` for a user occurs only through access approval. “Pendiente de verificación” means verification/approval of access, never documentary validation of titles or credentials. A suspended requester cannot be approved. Deactivation preserves history, and last-`clinic_admin` protections prevent an active clinic from becoming unmanaged.

### 3. Registration and center discovery

Registration requires profession and accepts optional declared specialty. Password and confirmation fields have independent accessible show/hide controls with conventional semantics: the action describes the resulting visibility. Work mode uses Center and Independent cards. Center supports clinic, consultorio, hospital, university, and campaign; Independent creates a private independent workspace.

The user-facing term is “centro de atención.” Discovery searches all institutional types by normalized name regardless of type. Active centers are selectable; pending centers are visible but disabled to prevent duplicate requests; rejected and independent workspaces are not public. Creating a missing center requires selecting its institutional type.

### 4. Workspace is the tenant boundary

All summary, history, patient, lesion, evaluation, image, and prediction operations require an active `X-Workspace-ID`. A central dependency validates current membership and resource ownership; identifiers alone never cross tenant boundaries. Registration/discovery and platform administration are the only intentional exceptions and use separate authorization.

Patients have a workspace-unique clinical code and optional workspace-unique document. A patient can own multiple lesions; a lesion records anatomical site, onset/estimated duration, status, and notes and owns a chronological sequence of evaluations and images. Model predictions are immutable provenance records; professional observations are separate.

### 5. Clean Architecture and asynchronous ownership

Flutter features follow view -> controller -> use case -> repository contract -> implementation -> datasource -> `ApiService`; views do not invoke HTTP directly. Controllers capture the auth token/session generation and workspace identity that started an operation. Completion is accepted only if that context is still current. This rule applies to workspace gates, clinical pickers, prediction, history, and administration.

Auth transitions invalidate user-sensitive providers. Workspace transitions invalidate workspace caches plus patient, lesion, evaluation, history, and prediction state. Changing patient keeps the workspace but clears lesion and downstream state. Late responses are discarded rather than repopulating invalidated state.

### 6. Authentication, routing, and workspace gate

Cold start retains the current `/ready` polling and retry flow. The login route always completes a routing transition, including validation failures; it never remains stuck on a loading route or reuses cached privileged routing.

After validated authentication, `platform_admin` enters the standalone admin root and does not enter clinical summary without a workspace. A professional enters an unavoidable workspace gate. One approved active workspace auto-selects; multiple are selectable. Pending, rejected, inactive, loading, empty, and error/retry states are explicit, with refresh and logout. Back navigation cannot bypass the gate. Logout works from root/admin even when no workspace exists.

### 7. Session failure semantics

Only a `401` associated with the currently installed token expires the current session. A stale `401` from an old token is ignored. Ordinary permission `403` preserves authentication. A machine-identifiable workspace-revoked response clears workspace and workspace-scoped state only; a suspended-account response clears authentication. Membership is revalidated on app resume, and failed validation cannot route from cached privilege.

FastAPI `detail` values may be strings, maps, or lists. The client normalizes those contracts into safe product language and never shows Dio output, stack traces, internal paths, provider names, or implementation details.

### 8. Patient and lesion interaction state

The picker is typed and explicit for loading, search/results, empty, create, error, and retry. Search and creation enforce deduplication. Selection of a patient clears any prior lesion while retaining workspace. A workspace switch clears both selections and all workspace caches. Request generation/context guards prevent a stale search or creation response from selecting an entity in a newer context.

### 9. Capture, prediction, and retry invariants

Camera and gallery paths expose platform permission request, denial, retry/settings guidance, cancellation, and image-ready states. Analysis is disabled unless active workspace, patient, lesion, image, and professional authorization attestation are all present.

An analysis attempt snapshots workspace, patient, lesion, image, and attestation. Retry uses that original snapshot even if visible selection later changes, creates a new attempt, and never overwrites the immutable prior prediction. Result/history navigation is guarded against missing or stale context. All wording describes decision support, not diagnosis.

### 10. Readiness and unchanged inference

`/live` checks only the FastAPI process. `/ready` performs bounded database and model-contract checks with sanitized responses. Flutter preserves provider-neutral cold-start polling. The inference service and approved ONNX/external-data bytes, 224x224 RGB ImageNet normalization, benign/malignant ordering, threshold, and response fields remain unchanged.

### 11. Release evidence is separate from implementation evidence

Automated backend and Flutter suites can establish regression evidence. They do not prove production deployment, migrated production data, or real-device behavior. A release APK record includes version/build identity, filename, SHA-256 hash, build timestamp, source revision when available, and clean-install guidance. Institutional and independent approval flows, root/gate routing, full Render-to-Neon clinical flow, migrated history, latest backend deployment, and APK installation remain unchecked until directly observed.

## Risks / Trade-offs

- [Cross-cutting state can leak between users or workspaces] -> Invalidate providers at boundaries and reject stale completion by token/session/workspace generation.
- [Ambiguous `403` handling can either leak access or log users out] -> Use machine-identifiable auth, suspension, and workspace-revocation contracts; preserve session for ordinary permission denial.
- [Concurrent lifecycle actions conflict] -> Validate current state transactionally and return sanitized conflicts.
- [Legacy records cannot be reliably grouped] -> Use deterministic compatibility patients/lesions and retain mappings rather than fuzzy merges.
- [Production differs from SQLite] -> Test migrations locally and keep Neon execution and post-migration checks as explicit gates.
- [Render sleeps] -> Retain bounded `/ready` polling, retry, and provider-neutral UI.
- [Retry duplicates inference] -> Preserve immutable attempts and provenance; never mutate a prior prediction.
- [Automated green status is mistaken for release evidence] -> Keep deployment/device/migration checkboxes open until evidence is recorded.

## Migration Plan

1. Back up Neon and record baseline schema and counts.
2. Apply ordered Alembic/SQL revisions that add workspace, membership, patient, lesion, evaluation, image, prediction, and attestation structures without deleting legacy records.
3. Backfill roles, active compatibility access, patients, lesions, evaluations, predictions, image references, and model provenance deterministically.
4. Verify counts, orphans, uniqueness, lifecycle values, checksums, timestamps, and legacy mappings.
5. Deploy the latest backend configuration for Neon, Cloudinary, Render readiness, and the retained model.
6. Publish a versioned APK and record identity/hash/time/source information and clean-install instructions.
7. Perform the institutional and independent approval, routing, full clinical production flow, migrated-history, and device checks listed as open tasks.
8. Retain legacy structures through this release; prefer forward-fix migrations after normalized writes begin.

Rollback before cutover uses Alembic downgrade or the verified backup. After normalized writes, rollback requires an explicit maintenance decision because restoring a backup would discard new records.

## Open Questions

No product decisions remain. Production execution, current deployment, migrated-history verification, and physical-device/APK evidence remain release gates rather than assumptions.
