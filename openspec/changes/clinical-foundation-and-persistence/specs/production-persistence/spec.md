## ADDED Requirements

### Requirement: Environment-specific database authority
The system SHALL use the PostgreSQL database configured through `DATABASE_URL` as the production source of truth, while SQLite SHALL be limited to local development and automated tests.

#### Scenario: Production starts with Neon PostgreSQL
- **WHEN** the backend starts in the production environment with a valid PostgreSQL `DATABASE_URL`
- **THEN** all persistent clinical and identity data is read from and written to that PostgreSQL database

#### Scenario: Local development uses SQLite
- **WHEN** a developer runs the backend with the local SQLite configuration
- **THEN** the same application data model is available without connecting to the production database

### Requirement: Versioned schema migrations
The system SHALL manage database schema creation and evolution with versioned Alembic migrations that support both PostgreSQL and SQLite where required by development and tests, and SHALL provide reviewable PostgreSQL SQL scripts for manual execution in Neon.

#### Scenario: Empty database is initialized
- **WHEN** all committed migrations are applied to an empty supported database
- **THEN** the database contains the complete schema required by the application

#### Scenario: Existing production database is upgraded
- **WHEN** the project owner executes the approved versioned SQL in Neon against a database containing the current users and analyses tables
- **THEN** the new schema is created without deleting existing user or analysis records

#### Scenario: Production migration is prepared
- **WHEN** a schema change is ready for deployment
- **THEN** the project owner receives ordered migration, verification, and rollback SQL scripts that contain no database credentials

### Requirement: Existing record compatibility
The migration process SHALL deterministically associate existing users and analyses with compatibility records required by the new organization, patient, lesion, and prediction model.

#### Scenario: Existing analysis is migrated
- **WHEN** an existing analysis is migrated
- **THEN** its prediction, confidence, image reference, timestamp, model version, processing time, and owning professional remain available

#### Scenario: Existing patient metadata is migrated
- **WHEN** an existing analysis contains patient identifier or patient name data
- **THEN** the migration preserves that data in a reusable patient record and associates the analysis with a lesion record

#### Scenario: Existing analysis has no patient metadata
- **WHEN** an existing analysis has neither patient identifier nor patient name
- **THEN** the migration associates it with an explicitly identified legacy anonymous patient record without inventing clinical demographics

### Requirement: Production image storage expectation
The system SHALL treat Cloudinary as the durable image store in production and SHALL treat filesystem image storage as a development-only fallback.

#### Scenario: Production image is stored
- **WHEN** an authenticated professional submits an analysis in production
- **THEN** the persisted image reference points to Cloudinary rather than Render's local filesystem

#### Scenario: Developer runs without Cloudinary
- **WHEN** the backend runs in a local development environment without Cloudinary credentials
- **THEN** local filesystem storage remains available for development
