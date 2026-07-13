## Why

BucalScan AI needs a production-safe clinical foundation that supports approved workspace access, longitudinal patient and lesion records, tenant isolation, and durable persistence without changing the validated ResNet50 inference contract. The mobile flow must also remain safe across Render cold starts, authentication changes, workspace changes, asynchronous responses, and release verification.

## What Changes

- Establish Neon PostgreSQL as the production source of truth with Alembic migrations, legacy-data compatibility, reviewable SQL, Cloudinary image persistence, Render readiness, model checksums, and environment-specific configuration.
- Replace free-text center association with `centro de atención` discovery across clinics, consultorios, hospitals, universities, and campaigns, plus private independent workspaces and explicit user, workspace, and membership lifecycles.
- Require profession and allow an optional declared specialty during registration; this is access approval, not documentary verification of credentials.
- Provide accessible registration controls: independent password and confirmation visibility actions, Center versus Independent work-mode cards, institutional type selection, and active/pending discovery semantics that prevent duplicates.
- Route authenticated users by validated role and workspace state: `platform_admin` enters the admin root, professionals enter an unavoidable workspace gate, one active workspace auto-selects, and multiple active workspaces remain selectable.
- Enforce session and tenant safety across auth/workspace boundaries, including stale-response suppression, token-matched `401` handling, permission-preserving `403`, machine-identifiable revocation handling, resume revalidation, and provider invalidation.
- Introduce reusable workspace-scoped patients, multiple lesions per patient, chronological lesion evaluations, repeated images, immutable predictions and provenance, and clinical observations separate from model output.
- Require active `X-Workspace-ID`, patient, lesion, image, and professional authorization attestation before analysis; preserve the original context on retry and use non-diagnostic wording.
- Preserve the current ResNet50 ONNX files, preprocessing, class order, thresholds, and response semantics without retraining or replacement.
- Define camera/gallery permissions and denial states, sanitized FastAPI/Dio error presentation, and guarded result/history navigation.
- Define a versioned APK release checkpoint with identity, hash, build-time, and clean-install guidance, while leaving real-device, deployment, and production end-to-end evidence explicitly open until performed.

## Capabilities

### New Capabilities

- `production-persistence`: Neon/Alembic authority, legacy compatibility, Cloudinary durability, environment configuration, model checksums, and deployment/release verification.
- `clinical-organization-access`: Registration, centers and independent workspaces, explicit lifecycles, navigation gates, roles, approval semantics, session safety, and tenant authorization.
- `patient-lesion-records`: Workspace-scoped reusable patients, multiple lesions, typed selection flows, chronological evaluations, immutable history, and context transitions.
- `inference-clinical-separation`: Unchanged ResNet50 behavior, immutable prediction provenance, and separation of model output from clinical observations.
- `service-readiness`: `/live` and `/ready`, reverted cold-start behavior, authentication/authorization distinction, stale-session defense, and sanitized errors.
- `mobile-capture-readiness`: Camera/gallery readiness, complete analysis prerequisites, context-preserving retry, guarded navigation, branding, and APK identity.

### Modified Capabilities

None. The repository had no pre-existing OpenSpec capability specifications when this change was created.

## Impact

- Backend: FastAPI health and clinical APIs, workspace authorization, lifecycle enforcement, SQLAlchemy models, migrations, image and prediction persistence, error contracts, configuration, and tests.
- Mobile: Flutter Clean Architecture and Riverpod registration, startup, auth routing, workspace gate, patient/lesion picker, capture/result/history, boundary invalidation, error states, and release packaging.
- Data and services: Neon PostgreSQL, Alembic, Cloudinary, Render, local SQLite, and deterministic migration of existing users and analyses.
- Security: every clinical summary, history, patient, lesion, and prediction operation is isolated by validated active workspace membership.
- Model: the approved ResNet50 ONNX artifact, external data, preprocessing, benign/malignant class order, threshold, and semantics remain unchanged.
