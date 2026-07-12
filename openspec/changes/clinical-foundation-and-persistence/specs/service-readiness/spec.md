## ADDED Requirements

### Requirement: Liveness reporting
The backend SHALL provide a liveness endpoint that reports whether the FastAPI process is running without requiring database or model dependencies to be ready.

#### Scenario: API process is running during dependency startup
- **WHEN** the backend process is accepting requests while a dependency is unavailable
- **THEN** the liveness endpoint reports that the process is alive

### Requirement: Analysis readiness reporting
The backend SHALL provide a readiness endpoint that only reports ready when the configured database is reachable and the retained model has loaded with a valid inference contract.

#### Scenario: All required dependencies are available
- **WHEN** the database connection succeeds and the ResNet50 inference contract is valid
- **THEN** the readiness endpoint reports that analysis is available

#### Scenario: Database is unavailable
- **WHEN** the configured database cannot be reached
- **THEN** the readiness endpoint reports unavailable without exposing credentials or sensitive connection details

#### Scenario: Model is unavailable
- **WHEN** the configured model cannot be loaded or validated
- **THEN** the readiness endpoint reports unavailable and the client does not offer analysis as ready

### Requirement: Render cold-start experience
The Flutter application SHALL poll readiness during a Render free-tier cold start and SHALL describe the delay in user-oriented language without naming infrastructure providers.

#### Scenario: Backend wakes successfully
- **WHEN** the application starts while the backend is suspended and readiness becomes available after retries
- **THEN** the application continues to session restoration and enables the normal workflow

#### Scenario: Backend remains unavailable
- **WHEN** readiness does not become available within the configured user-facing flow
- **THEN** the application offers retry and an understandable connection state rather than reporting a model result failure

### Requirement: Authentication and authorization distinction
The Flutter client SHALL clear the local session for an invalid or expired authentication response and SHALL preserve the session for an authorization denial.

#### Scenario: Backend returns 401
- **WHEN** an authenticated request receives HTTP `401`
- **THEN** the client clears the invalid session and requests authentication

#### Scenario: Backend returns 403
- **WHEN** an authenticated request receives HTTP `403`
- **THEN** the client preserves the session and displays that the requested action is not permitted
