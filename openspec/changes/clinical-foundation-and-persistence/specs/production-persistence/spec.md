## ADDED Requirements

### Requirement: Environment-specific persistence authority
The system SHALL use Neon PostgreSQL configured through `DATABASE_URL` as production authority, SHALL limit SQLite to local development/tests, and SHALL require explicit environment configuration for database, Cloudinary, model files, security, and service behavior.

#### Scenario: Production starts with valid configuration
- **WHEN** the latest backend starts on Render with valid production environment values
- **THEN** identity and clinical data use Neon, images use Cloudinary, and the approved ResNet50 artifacts are loaded

#### Scenario: Local development starts
- **WHEN** a developer uses the documented local environment
- **THEN** SQLite and development-only filesystem image fallback are available without production credentials

#### Scenario: Production durable storage is missing
- **WHEN** production lacks required Cloudinary or database configuration
- **THEN** readiness fails safely rather than treating Render's ephemeral filesystem as durable storage

### Requirement: Versioned schema migrations
The system SHALL manage schema evolution with versioned Alembic migrations and SHALL provide ordered, credential-free PostgreSQL migration, verification, and rollback SQL for owner-controlled Neon execution.

#### Scenario: Empty database is initialized
- **WHEN** all migrations are applied to an empty supported database
- **THEN** the complete required schema and constraints exist

#### Scenario: Existing database is upgraded
- **WHEN** approved migrations are applied to existing users and analyses
- **THEN** normalized structures are added without deleting legacy records

#### Scenario: Migration is reviewed
- **WHEN** a production change is prepared
- **THEN** ordered SQL and checks cover counts, orphans, uniqueness, lifecycle states, image references, provenance, and rollback without credentials

### Requirement: Legacy data compatibility
Migration SHALL deterministically preserve existing users, access, analyses, patient metadata, images, timestamps, and model output through compatibility workspaces, patients, lesions, evaluations, and immutable predictions.

#### Scenario: Existing user is migrated
- **WHEN** a legacy user is backfilled
- **THEN** mapped role and active compatibility access preserve sign-in while respecting current lifecycle rules

#### Scenario: Existing analysis has patient metadata
- **WHEN** a legacy analysis contains patient identifier or name
- **THEN** the data is retained in a reusable compatibility patient and associated lesion/evaluation

#### Scenario: Existing analysis has no patient metadata
- **WHEN** neither patient identifier nor name exists
- **THEN** the analysis is attached to an explicit legacy-anonymous patient without invented demographics

#### Scenario: Existing history is queried after migration
- **WHEN** the migrated user opens history in the compatibility workspace
- **THEN** original prediction, confidence, image reference, timestamp, model version, processing time, and professional remain available

### Requirement: Model artifact integrity in deployment
The deployment process SHALL verify the approved SHA-256 checksums of the ResNet50 ONNX artifact and external data file and SHALL not substitute, retrain, or modify them as part of persistence or deployment work.

#### Scenario: Deployment checks model files
- **WHEN** a backend release is prepared or validated
- **THEN** both checksums match the approved baseline before readiness is accepted

### Requirement: Production image durability
Production analysis SHALL persist image references to Cloudinary, while filesystem fallback SHALL remain development-only.

#### Scenario: Production image is accepted
- **WHEN** an authorized complete analysis succeeds in production
- **THEN** its durable image reference points to Cloudinary and its clinical/prediction records point to the same workspace context

### Requirement: Evidence-based deployment verification
The project SHALL distinguish implemented/automated evidence from manual production evidence and SHALL leave deployment, migration-history, full Render-to-Neon flow, and physical-device release gates incomplete until directly observed.

#### Scenario: Automated suites pass
- **WHEN** backend and Flutter automated checks pass
- **THEN** implementation regression evidence is recorded without claiming that Render, Neon, Cloudinary, migration, or device flows were manually verified

#### Scenario: Full production flow is verified
- **WHEN** the latest backend is deployed and an active workspace completes patient, lesion, capture, Cloudinary upload, ResNet50 inference, Neon persistence, and history retrieval after a Render cold start
- **THEN** the evidence records environment, release identity, observed records, and result without exposing secrets

#### Scenario: Migrated history is verified
- **WHEN** an existing migrated user signs in and opens retained history after the latest changes
- **THEN** the evidence identifies the compatibility access and preserved record checks actually observed
