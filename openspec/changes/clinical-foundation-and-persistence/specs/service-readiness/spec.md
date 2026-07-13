## ADDED Requirements

### Requirement: Liveness reporting
The backend SHALL provide dependency-free liveness that reports whether the FastAPI process is accepting requests.

#### Scenario: Dependency is starting
- **WHEN** the process runs while database or model is unavailable
- **THEN** `/live` reports process liveness without claiming analysis readiness

### Requirement: Analysis readiness reporting
The backend SHALL report ready only after bounded checks confirm database connectivity and the unchanged ResNet50 contract, and SHALL sanitize failure details.

#### Scenario: Dependencies are ready
- **WHEN** database and model-contract checks succeed
- **THEN** `/ready` reports analysis available

#### Scenario: Dependency is unavailable
- **WHEN** database or model validation fails or times out
- **THEN** `/ready` reports unavailable without credentials, internal paths, stack traces, or provider details

### Requirement: Reverted cold-start startup behavior
The Flutter application SHALL retain the current reverted cold-start behavior that polls `/ready`, offers provider-neutral progress/retry/unavailable states, and proceeds to validated session routing when ready.

#### Scenario: Service wakes
- **WHEN** readiness becomes available during configured retries
- **THEN** startup continues to session restoration and the correct validated root or gate

#### Scenario: Service remains unavailable
- **WHEN** readiness does not become available
- **THEN** startup offers retry and a clear connection state without misreporting credentials or prediction failure

### Requirement: Login transition and validated routing
Every login attempt SHALL leave the login-in-progress route through an explicit success or failure transition, and privileged routing SHALL use newly validated identity rather than cached state.

#### Scenario: Login succeeds
- **WHEN** credentials and current identity validate
- **THEN** navigation transitions to the admin root or professional workspace gate as appropriate

#### Scenario: Login or validation fails
- **WHEN** authentication or post-login identity validation fails
- **THEN** navigation returns to an actionable sanitized login error and does not use cached privileged routing

### Requirement: Authentication and authorization distinction
The client SHALL expire authentication only for a `401` matching the currently installed token, SHALL preserve authentication for ordinary permission `403`, and SHALL apply machine-identifiable suspension and workspace-revocation outcomes at the correct boundary.

#### Scenario: Current token receives 401
- **WHEN** a request made with the current token receives HTTP `401`
- **THEN** authentication and user-sensitive state are cleared

#### Scenario: Old token receives late 401
- **WHEN** a request made with an earlier token returns `401` after another user or token is installed
- **THEN** the response cannot expire or alter the current session

#### Scenario: Ordinary permission is denied
- **WHEN** an authenticated action receives a non-revocation permission `403`
- **THEN** the session is preserved and access denial is displayed

#### Scenario: Workspace access is revoked
- **WHEN** a machine-identifiable response reports inactive or revoked workspace membership
- **THEN** active workspace and workspace-scoped state are cleared while authentication remains

#### Scenario: Account is suspended
- **WHEN** a machine-identifiable response reports that the current account is suspended
- **THEN** authentication is cleared and protected roots are no longer reachable

### Requirement: Safe error normalization
The backend and Flutter client SHALL support FastAPI `detail` represented as a string, map, or list and SHALL present only sanitized user-facing errors.

#### Scenario: Structured detail is returned
- **WHEN** FastAPI returns string, map, or list validation/error detail
- **THEN** the client derives an actionable safe message without rendering raw Dio output

#### Scenario: Internal failure occurs
- **WHEN** an unexpected backend or client error reaches presentation
- **THEN** UI omits stack traces, internal paths, provider names, credentials, and implementation details and offers retry where safe
