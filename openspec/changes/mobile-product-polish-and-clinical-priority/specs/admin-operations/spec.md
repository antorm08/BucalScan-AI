## ADDED Requirements

### Requirement: Administrative mobile shell
The standalone platform-admin root SHALL expose a bottom `NavigationBar` with exactly `Centers`, `Access`, and `Users`, preserve independent destination state, and provide account/logout actions without requiring a clinical workspace.

#### Scenario: Admin root loads
- **WHEN** a revalidated active platform administrator enters the app
- **THEN** the admin shell SHALL select one destination, show all three bottom destinations, and SHALL NOT render the professional shell

#### Scenario: Destination switch
- **WHEN** the administrator switches destinations and returns
- **THEN** the prior query, filter, loaded page, and scroll position SHALL be retained unless explicitly refreshed or invalidated

### Requirement: Server-backed admin queries
Centers, access requests, and users SHALL support backend normalized search, allow-listed status/type/role filters, deterministic sort, bounded pagination, totals, refresh, and sanitized validation errors.

#### Scenario: Query a resolved center
- **WHEN** an administrator filters Centers by rejected status and searches by center/requester data
- **THEN** the backend SHALL return matching authorized records plus page metadata in deterministic order

#### Scenario: Unsupported sort or filter
- **WHEN** a request uses a non-allow-listed sort key, direction, filter, or excessive page size
- **THEN** the backend SHALL reject or normalize it according to the documented contract without executing arbitrary query input

#### Scenario: Superseded admin query
- **WHEN** an older search or page request completes after the destination query or authenticated session changes
- **THEN** the client SHALL discard that response and preserve the newer state

### Requirement: Detailed admin resource sheets
Selecting a center, access request, or user SHALL open a safe-area-aware, keyboard-aware, draggable near-full-height bottom sheet with complete available resource, requester, lifecycle, and audit context.

#### Scenario: Open access details
- **WHEN** an administrator selects an access request
- **THEN** the sheet SHALL display requester identity/contact claims, declared profession/specialty, workspace/type, requested role/status, creation/update times, and available resolution actor/time/reason without truncating the only access to any field

#### Scenario: Metadata is unavailable
- **WHEN** a field or audit value is not persisted by the deployed schema/API
- **THEN** the sheet SHALL label it unavailable or omit it and SHALL NOT fabricate an actor, timestamp, verification, or reason

### Requirement: Access-only verification disclaimer
Every pending administrative decision surface SHALL state that approval verifies application access only and does not verify identity, documents, title, license, profession, specialty, credentials, or clinical competence.

#### Scenario: Administrator reviews approval
- **WHEN** an approval confirmation or detail sheet is displayed
- **THEN** the access-only disclaimer SHALL be visible before confirmation and SHALL not use documentary-verification wording

### Requirement: Clear action hierarchy and resolved states
Pending records SHALL expose context-valid actions with approval primary and rejection as an outlined red destructive action; resolved records SHALL remain searchable and render outcome/read-only metadata without pending actions.

#### Scenario: Reject pending access
- **WHEN** an administrator selects Rechazar on a pending request
- **THEN** an outlined red action SHALL open a request-specific confirmation, prevent duplicate submission, and show the authoritative outcome or sanitized conflict

#### Scenario: View resolved request
- **WHEN** an administrator opens an active, rejected, inactive, or suspended record
- **THEN** the sheet SHALL show translated resolved status and available audit context and SHALL hide actions illegal for that state

### Requirement: Transactional center and access decisions
The backend SHALL re-read and lock or otherwise transactionally protect decision state, apply all related lifecycle changes atomically, populate supported actor/time audit fields, and return conflict for stale or already-resolved decisions.

#### Scenario: Concurrent decision
- **WHEN** two administrators attempt to resolve the same pending record
- **THEN** exactly one legal transition SHALL commit and the other SHALL receive a sanitized conflict with no partial state

#### Scenario: Center approval
- **WHEN** a valid institutional center request is approved
- **THEN** its workspace and initial membership SHALL activate atomically, the initial membership SHALL be `clinic_admin`, supported approval metadata SHALL be persisted, and eligible pending user access SHALL activate

#### Scenario: Center rejection
- **WHEN** a valid institutional center request is rejected
- **THEN** its workspace and linked pending initial membership SHALL become terminally rejected atomically and any supported resolution metadata/reason SHALL be persisted

### Requirement: Suspended requester invariant
A suspended requester MUST NOT receive approved center or membership access even if the client displayed approval before the suspension.

#### Scenario: Requester suspended during review
- **WHEN** the backend re-reads a requester as suspended at approval time
- **THEN** it SHALL reject the approval, preserve pending/resolved consistency, and return a sanitized conflict

### Requirement: Independent professional role invariant
Approval of an independent workspace/access SHALL assign membership role `professional` regardless of any client-supplied role.

#### Scenario: Client requests elevated independent role
- **WHEN** an independent membership approval includes `clinic_admin`, `assistant`, or another role
- **THEN** the backend SHALL ignore/reject the elevation and SHALL only activate the membership as `professional`

### Requirement: Last clinic administrator invariant
The backend SHALL prevent any user or membership status transition that would leave an active institutional workspace without at least one active `clinic_admin`.

#### Scenario: Suspend the last clinic admin
- **WHEN** an administrator attempts to suspend a user whose active membership is the sole active `clinic_admin` for a center
- **THEN** the transition SHALL fail atomically with a sanitized explanation and leave all states unchanged

#### Scenario: Another clinic admin remains
- **WHEN** every affected active center retains another active `clinic_admin`
- **THEN** an otherwise legal suspension/deactivation MAY proceed without altering memberships in unrelated workspaces

### Requirement: No implicit platform-admin clinical access
The `platform_admin` role SHALL authorize only platform operations unless the same user has an explicit active membership accepted by normal workspace authorization; admin APIs and UI MUST NOT create such membership implicitly.

#### Scenario: Admin requests clinical record without membership
- **WHEN** a platform administrator supplies a workspace identifier but lacks an active membership
- **THEN** the clinical API SHALL deny access without creating, inferring, or selecting a membership

### Requirement: Safe user lifecycle management
User management SHALL expose translated pending, active, and suspended states, prohibit self-suspension and illegal pending transitions, and enforce all affected-workspace invariants transactionally.

#### Scenario: Pending user detail
- **WHEN** an administrator views a pending user
- **THEN** suspend/reactivate actions SHALL not be offered and activation SHALL occur only through a valid access approval

#### Scenario: Administrator self-suspension
- **WHEN** an administrator attempts to suspend their current account
- **THEN** the backend SHALL reject the operation and the active session SHALL remain consistent

### Requirement: Race-safe administrative state
Admin controllers SHALL key requests and actions by authenticated session, destination query, generation, and resource; late responses MUST NOT overwrite newer data, resolved outcomes, or another user's session.

#### Scenario: Action completes after refresh
- **WHEN** a decision response arrives after a newer refresh already shows the resource resolved differently
- **THEN** the controller SHALL discard or reconcile the stale completion against authoritative server state and SHALL NOT restore pending state

#### Scenario: Logout during admin request
- **WHEN** logout occurs while admin queries or decisions are in flight
- **THEN** all completions SHALL be ignored and no admin data SHALL appear on the login or next user's root

### Requirement: Administrative accessibility and responsive behavior
The admin shell, filters, cards, confirmations, bottom sheets, pagination, and actions SHALL meet the supported responsive/accessibility matrix with non-color statuses and semantic destructive-action labels.

#### Scenario: Full-height sheet with keyboard and large text
- **WHEN** an admin detail sheet contains long data, large text, and an open keyboard
- **THEN** all content and final actions SHALL remain scrollable, reachable, safe-area-aware, and correctly labeled
