## ADDED Requirements

### Requirement: Registration profile and work mode
The system SHALL require profession, SHALL accept specialty as optional declared profile information without documentary verification, and SHALL offer Center and Independent work-mode choices.

#### Scenario: Professional declares profile
- **WHEN** a registrant supplies a profession and optionally a specialty
- **THEN** the system records the declarations for access review without representing them as verified credentials

#### Scenario: Registrant selects center mode
- **WHEN** the registrant chooses the Center card
- **THEN** the system offers center discovery and, for a new center, requires clinic, consultorio, hospital, university, or campaign type

#### Scenario: Registrant selects independent mode
- **WHEN** the registrant chooses the Independent card
- **THEN** the system creates or requests a private independent workspace that is not publicly discoverable

#### Scenario: Password visibility is controlled
- **WHEN** the registrant uses the visibility action for password or confirmation
- **THEN** only that field changes visibility, its accessible action describes the conventional resulting action, and the other field remains unchanged

### Requirement: Center discovery
The system SHALL describe institutional workspaces as “centro de atención” and SHALL search all institutional types by normalized name regardless of selected or stored type.

#### Scenario: Active center is found
- **WHEN** a registrant searches a name matching an active clinic, consultorio, hospital, university, or campaign
- **THEN** the system displays the center as selectable and permits a pending membership request

#### Scenario: Pending center is found
- **WHEN** a registrant searches a name matching a pending institutional workspace
- **THEN** the system displays it with pending access-verification wording but disables selection and duplicate creation

#### Scenario: Non-public workspace exists
- **WHEN** a workspace is rejected or is an independent practice
- **THEN** public center discovery does not return it

#### Scenario: New center is requested
- **WHEN** no active or pending center matches and the registrant submits the required data and institutional type
- **THEN** the system creates one pending workspace and records the registrant as initial requester

### Requirement: Explicit access lifecycles
The system SHALL enforce user `pending -> active` only through access approval and `active <-> suspended`; workspace `pending -> active | rejected` with rejection terminal; and membership `pending -> active | rejected`, `active -> inactive`, `inactive -> active`, with rejection terminal.

#### Scenario: Pending access is displayed
- **WHEN** an account, workspace, or membership awaits action
- **THEN** the UI states that access is pending verification or approval and does not imply title or document verification

#### Scenario: Suspended requester is considered
- **WHEN** an administrator attempts to approve access for a suspended user
- **THEN** the system rejects the transition and leaves related access inactive or pending

#### Scenario: Rejected resource is reconsidered
- **WHEN** an administrator attempts to activate a rejected workspace or membership
- **THEN** the system rejects the transition because rejection is terminal

#### Scenario: Active membership is deactivated and restored
- **WHEN** an authorized administrator deactivates and later reactivates a non-terminal membership
- **THEN** history remains intact while workspace access follows inactive then active state

#### Scenario: Last clinic administrator is targeted
- **WHEN** an action would remove, suspend, or deactivate the last active `clinic_admin` of an active institutional workspace
- **THEN** the system denies the action until another active clinic administrator exists

### Requirement: Initial role model
The system SHALL support `platform_admin`, `clinic_admin`, `professional`, and `assistant`, and SHALL represent specialty as profile metadata rather than a separate role.

#### Scenario: Specialist profile is represented
- **WHEN** a professional declares a specialty
- **THEN** the account retains the `professional` role and exposes specialty as unverified profile information

#### Scenario: Assistant attempts a restricted action
- **WHEN** an assistant attempts clinical interpretation or another professional-only action
- **THEN** the system denies permission without invalidating authentication

### Requirement: Access approval
The system SHALL prevent newly self-registered professionals from clinical access until authorized approval and SHALL activate a pending user only as part of an eligible access approval.

#### Scenario: Institutional access is approved
- **WHEN** an eligible pending institutional workspace is approved
- **THEN** the workspace and requester become active and the initial membership becomes active `clinic_admin`

#### Scenario: Independent access is approved
- **WHEN** an eligible pending independent request is approved
- **THEN** the user, private workspace, and membership become active with membership role `professional`

#### Scenario: Active-center membership is approved
- **WHEN** an eligible pending membership to an active center is approved with an allowed role
- **THEN** the user and membership receive the access permitted in that center without changing other workspaces

#### Scenario: Demonstration account is provisioned
- **WHEN** an authorized administrator provisions pre-approved academic demonstration access
- **THEN** the account and required access records are active through the same valid lifecycle invariants

### Requirement: Initial platform administrator provisioning
The system SHALL provide a versioned, idempotent SQL script that promotes exactly one existing registered user to active `platform_admin` without inserting or modifying password credentials.

#### Scenario: Registered user is promoted
- **WHEN** the project owner executes the script with one uniquely matching email
- **THEN** that user becomes active `platform_admin` and can administer after signing in again

#### Scenario: Promotion target is invalid
- **WHEN** the email matches zero or more than one user
- **THEN** the script aborts without promoting an account

### Requirement: Authenticated root and workspace gate
The Flutter application SHALL route only from freshly validated identity and access state, SHALL use the admin panel as the `platform_admin` root, and SHALL require professionals to complete a non-bypassable workspace gate before clinical navigation.

#### Scenario: Platform administrator signs in
- **WHEN** validated identity has role `platform_admin` and no active clinical workspace
- **THEN** login transitions to the standalone admin root rather than clinical summary

#### Scenario: Professional has one active workspace
- **WHEN** validated identity has exactly one approved active membership
- **THEN** the gate auto-selects that workspace and enters the professional flow

#### Scenario: Professional has multiple active workspaces
- **WHEN** validated identity has more than one approved active membership
- **THEN** the gate presents a selection and enters only after one is selected

#### Scenario: Professional has no usable workspace
- **WHEN** memberships are pending, rejected, inactive, empty, unavailable, or fail to load
- **THEN** the gate shows a polished typed state with refresh, error/retry where applicable, and logout

#### Scenario: Administrator approves while professional waits
- **WHEN** a professional remains on the pending gate and an administrator activates the eligible workspace and membership
- **THEN** the gate refreshes automatically without overlapping requests and enters the single active workspace without requiring logout or app restart

#### Scenario: Back navigation is attempted at gate
- **WHEN** a professional presses back before selecting an active workspace
- **THEN** navigation does not bypass the gate into cached clinical content

#### Scenario: Root user logs out
- **WHEN** a user logs out from admin or another root without a workspace
- **THEN** authentication and sensitive state are cleared and login is reachable

### Requirement: Workspace-scoped clinical access
Every clinical summary, history, patient, lesion, evaluation, image, and prediction request SHALL include an active `X-Workspace-ID` and SHALL be authorized against current active membership and resource ownership.

#### Scenario: Clinical request lacks workspace
- **WHEN** an authenticated user requests a clinical resource without an active `X-Workspace-ID`
- **THEN** the system rejects the request without exposing clinical data

#### Scenario: Cross-workspace identifier is supplied
- **WHEN** a valid identifier belongs to another workspace
- **THEN** the system denies or safely reports absence without revealing record contents

#### Scenario: Membership is inactive
- **WHEN** a request includes a workspace whose membership is no longer active
- **THEN** the system returns a machine-identifiable workspace-access failure and no clinical data

### Requirement: Session and workspace boundary safety
The Flutter application SHALL clear user-sensitive Riverpod providers at authentication boundaries, SHALL clear workspace-scoped providers at workspace boundaries, and SHALL ignore asynchronous completion whose token, session generation, or workspace no longer matches.

#### Scenario: User changes during workspace load
- **WHEN** an old user's workspace response completes after logout or a new login
- **THEN** the response is discarded and cannot select, display, or route the new user

#### Scenario: Workspace changes during clinical load
- **WHEN** a response for the previous workspace completes after selection changed
- **THEN** the response is discarded and cannot repopulate workspace caches

#### Scenario: Professional changes active workspace from home
- **WHEN** the professional confirms the visible Cambiar espacio action
- **THEN** the workspace header, patient, lesion, prediction, summary, history, follow-up, stale generations, and detail routes are cleared before the existing workspace selector is shown

#### Scenario: Application resumes
- **WHEN** the app resumes with an authenticated workspace session
- **THEN** it revalidates current membership before allowing continued privileged clinical access

#### Scenario: Validation fails
- **WHEN** identity or membership validation fails
- **THEN** cached privileged routing is not used and the appropriate auth or workspace boundary is cleared

### Requirement: Membership management
Authorized administrators SHALL review, approve, reject, deactivate, and reactivate memberships only through legal lifecycle transitions and last-administrator protections.

#### Scenario: Clinic administrator reviews requests
- **WHEN** a clinic administrator opens membership requests
- **THEN** the system lists only workspaces administered by that user

#### Scenario: Membership is deactivated
- **WHEN** an authorized administrator deactivates an eligible active membership
- **THEN** access ends without deleting historical records

#### Scenario: Rejected membership is targeted
- **WHEN** any actor attempts to approve or reactivate a rejected membership
- **THEN** the system rejects the terminal transition
