## ADDED Requirements

### Requirement: Clinical workspaces
The system SHALL represent clinics, consultorios, hospitals, universities, campaigns, and independent professional practices as clinical workspaces rather than free-text user attributes.

#### Scenario: Professional selects an existing workspace
- **WHEN** a registering professional searches for and selects a registered workspace
- **THEN** the system creates a pending membership request for that workspace

#### Scenario: Professional registers a new workspace
- **WHEN** a registering professional cannot find their clinic or consultorio and provides the required workspace information
- **THEN** the system creates a pending workspace request and records that professional as its initial requester

#### Scenario: Pending workspace remains discoverable
- **WHEN** another professional searches for a clinic whose creation request is pending
- **THEN** the system displays the clinic with its pending status and does not allow a duplicate creation or membership request until approval

#### Scenario: Similar workspace already exists
- **WHEN** a professional attempts to register a workspace whose normalized name and available identifying data resemble an existing or pending workspace
- **THEN** the system displays the potential match and requires the professional to use or review it instead of silently creating a duplicate

#### Scenario: Clinic is approved
- **WHEN** a platform administrator approves a pending clinic
- **THEN** the clinic becomes active and its initial requester receives an active `clinic_admin` membership

#### Scenario: Professional works independently
- **WHEN** a registering professional selects independent practice
- **THEN** the system creates a personal clinical workspace while keeping the professional unable to analyze until platform approval

### Requirement: Initial role model
The system SHALL support `platform_admin`, `clinic_admin`, `professional`, and `assistant` permissions, and SHALL represent a specialist as a `professional` with specialty information rather than as a separate role.

#### Scenario: Specialist profile is represented
- **WHEN** a professional records a specialty such as oral pathology or maxillofacial surgery
- **THEN** the account retains the `professional` role and exposes the specialty as profile information

#### Scenario: Assistant attempts clinical interpretation
- **WHEN** an assistant attempts to finalize a prediction interpretation or clinical assessment
- **THEN** the system denies the action without invalidating the assistant's authenticated session

### Requirement: Professional approval
The system SHALL prevent a newly self-registered professional from performing clinical analyses until an authorized administrator approves the account or membership.

#### Scenario: Pending professional attempts analysis
- **WHEN** a professional whose approval status is pending submits an analysis request
- **THEN** the system rejects the action with an authorization response and preserves the login session

#### Scenario: Administrator approves professional
- **WHEN** a platform administrator or authorized clinic administrator approves a professional membership
- **THEN** the professional can perform the actions permitted in that workspace

#### Scenario: Demonstration account is provisioned
- **WHEN** an authorized administrator creates or marks a demonstration professional as pre-approved
- **THEN** the account can be used immediately for an academic demonstration

### Requirement: Initial platform administrator provisioning
The system SHALL provide a versioned, idempotent SQL script that promotes exactly one existing registered user to active `platform_admin` without inserting or modifying password credentials.

#### Scenario: Registered user is promoted
- **WHEN** the project owner executes the script with the unique email of an existing user
- **THEN** exactly that user becomes an active `platform_admin` and can approve clinics and professionals after signing in again

#### Scenario: Promotion target is invalid
- **WHEN** the supplied email matches zero or more than one user
- **THEN** the script aborts without promoting any account

### Requirement: Workspace-scoped clinical access
The system SHALL scope patient and clinical records to a workspace and SHALL only expose them to authenticated members with the required permission.

#### Scenario: Professional searches patients in active workspace
- **WHEN** a professional searches for a patient
- **THEN** results contain only patients accessible within the professional's active workspace

#### Scenario: User requests another workspace record
- **WHEN** a user requests a clinical record outside every workspace accessible to that user
- **THEN** the system denies access without revealing the record contents

### Requirement: Membership management
An authorized clinic administrator SHALL be able to review, approve, reject, and deactivate memberships within their workspace.

#### Scenario: Clinic administrator reviews pending request
- **WHEN** a clinic administrator opens pending membership requests
- **THEN** the system lists only requests for workspaces administered by that user

#### Scenario: Membership is deactivated
- **WHEN** a clinic administrator deactivates a membership
- **THEN** the affected user loses workspace access without deleting historical records authored by that user

#### Scenario: Professional requests membership after clinic approval
- **WHEN** a professional selects an active clinic and requests access
- **THEN** the clinic administrator can approve or reject that pending membership
