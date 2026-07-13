## ADDED Requirements

### Requirement: Authoritative session and root routing
The system SHALL use one authoritative coordinator to render unauthenticated, platform-admin, workspace-gate, and professional roots from revalidated session, role, account, and membership state; leaf views MUST NOT independently push replacement roots.

#### Scenario: Professional login reaches the correct root
- **WHEN** an active professional authenticates and active memberships are revalidated
- **THEN** the coordinator SHALL render the workspace gate or professional root according to the number of active workspaces without an intermediate black screen

#### Scenario: Platform administrator has a distinct root
- **WHEN** a current active user has the `platform_admin` role
- **THEN** the coordinator SHALL render the standalone admin root and SHALL NOT infer clinical workspace access

#### Scenario: Failed validation cannot use cached privilege
- **WHEN** role, account, or membership revalidation fails
- **THEN** the coordinator SHALL render the applicable safe unauthenticated, suspended, access-denied, or retry state and SHALL NOT route from cached privilege

### Requirement: Atomic logout and draft cleanup
Logout SHALL invalidate the current session/request generation, clear credentials, workspace headers, user/workspace providers, selections, unsaved forms, images, attestation, transient prediction/priority results, and nested routes before the coordinator renders login; persisted clinical records SHALL remain unchanged.

#### Scenario: Logout from any root
- **WHEN** a user confirms logout from the admin root, professional root, workspace gate, or account menu
- **THEN** one logout operation SHALL clear sensitive transient state and render login exactly once

#### Scenario: Late response after logout
- **WHEN** an auth-, admin-, history-, patient-, lesion-, or analysis-related request completes after logout
- **THEN** its response SHALL be discarded and SHALL NOT navigate or repopulate cleared state

### Requirement: Safe workspace switching
The professional root SHALL offer workspace switching only when more than one active workspace exists and SHALL use an explicit confirmation that unsaved drafts are removed while saved records remain.

#### Scenario: Only one active workspace
- **WHEN** a professional has exactly one active workspace
- **THEN** the system SHALL show its compact identity and SHALL hide the workspace-switch action

#### Scenario: Confirmed switch
- **WHEN** a professional with multiple active workspaces confirms a switch
- **THEN** the system SHALL clear workspace-scoped requests, caches, selections, drafts, headers, and nested routes, preserve persisted records, and return to the guarded workspace selector

#### Scenario: Cancelled switch
- **WHEN** a professional cancels workspace switching
- **THEN** the active workspace, current route, draft, and saved records SHALL remain unchanged

### Requirement: Professional navigation shell
The professional shell SHALL expose exactly four persistent bottom destinations in this order: `Inicio`, `Pacientes`, `Analizar`, and `Historial`; profile/account/help actions SHALL be available from a top account menu.

#### Scenario: Primary navigation is visible
- **WHEN** a professional is at any top-level professional destination
- **THEN** all four destinations SHALL be visible with one selected state and Profile SHALL NOT consume a fifth bottom destination

#### Scenario: Patient and lesion detail preserve the shell
- **WHEN** a professional opens a patient or lesion from Patients or History
- **THEN** the detail SHALL remain inside the professional shell with guarded back navigation and persistent access to primary navigation

#### Scenario: Repeat analysis uses the shell
- **WHEN** a professional chooses repeat analysis from a lesion
- **THEN** the existing patient and lesion SHALL be selected, prior transient attempt state SHALL be cleared, and the shell SHALL select `Analizar` without constructing an unguarded home root

### Requirement: Professional home and active workspace presentation
Inicio SHALL prioritize current-workspace context, frequent clinical actions, useful summary information, and actionable empty/error states without duplicating the full account or navigation menu.

#### Scenario: Compact workspace context
- **WHEN** an active workspace is selected
- **THEN** Inicio SHALL identify it in a compact, truncation-safe control and SHALL expose switching only when eligible

#### Scenario: Summary failure
- **WHEN** home summary data cannot load
- **THEN** Inicio SHALL retain primary navigation and actions, show sanitized error/retry content, and SHALL NOT display stale data as current

### Requirement: Unambiguous patient and lesion data
Active patient contracts SHALL omit dead legacy-only fields, lesion observed date and estimated duration SHALL be separate values, and product copy SHALL distinguish longitudinal lesion notes from findings recorded for a current evaluation.

#### Scenario: Lesion temporal fields
- **WHEN** a professional creates or edits a lesion
- **THEN** observed date and estimated duration SHALL be independently editable, validated, serialized, and displayed

#### Scenario: Notes and findings
- **WHEN** a professional enters lesion notes or current evaluation findings
- **THEN** each field SHALL explain its temporal scope and the backend SHALL persist them in their separate lesion and evaluation fields

#### Scenario: Compatibility data
- **WHEN** a migrated record contains retired legacy patient values
- **THEN** the system MAY read them for compatibility but SHALL NOT require or write them through the active patient form

### Requirement: One lesion per image and evaluation
Each analysis attempt SHALL associate exactly one active-workspace patient, one lesion belonging to that patient, one image, and one evaluation; additional lesions or images MUST create separate attempts.

#### Scenario: Valid single-image attempt
- **WHEN** patient, lesion, one image, professional authorization attestation, and required assessment context are valid
- **THEN** the system SHALL permit one analysis attempt for that lesion and image

#### Scenario: Ambiguous payload
- **WHEN** a request contains multiple lesions, multiple images, or mismatched patient/lesion ownership
- **THEN** the backend SHALL reject it with a sanitized validation or authorization error and SHALL create no partial evaluation

### Requirement: Clean analysis and retry lifecycle
Analysis state SHALL explicitly represent idle, context-ready, image-ready, submitting, succeeded, and failed states; starting over and retrying SHALL not display stale result/error state or permit duplicate submission.

#### Scenario: Start a new analysis
- **WHEN** a professional starts a new analysis after a prior result or failure
- **THEN** the system SHALL clear prior transient result, error, progress, and assessment state while retaining only context the user intentionally selected

#### Scenario: Retry a failed attempt
- **WHEN** a professional retries a failed attempt without choosing start over
- **THEN** the system SHALL reuse the original workspace, patient, lesion, image, assessment, and attestation snapshot and create a new immutable attempt

#### Scenario: Unknown prediction
- **WHEN** the backend returns an unknown, null, or unsupported prediction label
- **THEN** the UI SHALL render a neutral translated unknown state and SHALL NOT style or describe it as benign, malignant, successful, or low risk

### Requirement: Safe localized clinical wording
All known lifecycle/model/priority statuses SHALL have exhaustive user-facing translations, and model results/history SHALL use decision-support wording that does not state diagnosis, cancer probability, or guaranteed risk.

#### Scenario: Known status
- **WHEN** a known backend status is displayed
- **THEN** the UI SHALL use the approved localized label and a non-color textual indicator

#### Scenario: Confidence presentation
- **WHEN** model confidence is displayed
- **THEN** it SHALL be identified as classifier confidence for that model output and SHALL NOT be described as probability of cancer

### Requirement: Scalable clinical history
History SHALL provide server-backed debounced search, filters, inclusive date range, allow-listed deterministic sorting, bounded pagination, refresh, retry, clear-filter behavior, and current-workspace totals.

#### Scenario: Search and filter query
- **WHEN** a professional changes search, model status, priority status, date range, or sort criteria
- **THEN** the client SHALL issue a normalized workspace-scoped query, replace the current page set, and discard responses for superseded query keys

#### Scenario: Pagination remains deterministic
- **WHEN** multiple records share the selected sort value
- **THEN** the backend SHALL apply a stable identifier tie-breaker and return pagination metadata without duplicate records within the query snapshot

#### Scenario: Refresh history
- **WHEN** a professional refreshes history
- **THEN** the client SHALL replace loaded pages atomically, preserve current criteria, and show sanitized loading/error state without presenting stale results as refreshed

### Requirement: Guarded history links
History items and details SHALL link to their owning patient and lesion inside the professional shell only after current-workspace authorization.

#### Scenario: Open valid lesion link
- **WHEN** the referenced patient and lesion belong to the current active workspace
- **THEN** the app SHALL open the lesion detail inside the professional shell

#### Scenario: Stale or foreign link
- **WHEN** the referenced resource was removed, revoked, or belongs to another workspace
- **THEN** the app SHALL show a safe unavailable/access-denied state and SHALL NOT expose data or leave the guarded shell

### Requirement: Functional account and help center
The account menu SHALL provide profile/account management, eligible workspace switching, functional help, model/support information, and logout; Help SHALL contain navigable task-oriented guidance and current app/support identity.

#### Scenario: Edit profile
- **WHEN** a user submits valid editable profile fields
- **THEN** the layered profile flow SHALL persist them, refresh session-safe profile state, and show explicit loading/success/error feedback

#### Scenario: Find help for an analysis problem
- **WHEN** a user searches or selects analysis/retry help
- **THEN** Help SHALL navigate to actionable guidance covering prerequisites, one lesion per image, retry behavior, disclaimers, and common errors

### Requirement: Responsive and accessible mobile experience
Professional and account surfaces SHALL remain usable on narrow phones, standard phones, tablets, large text, screen readers, switch/keyboard traversal where supported, and safe-area/keyboard insets.

#### Scenario: Large text on narrow phone
- **WHEN** text scale and viewport constraints match the supported accessibility test matrix
- **THEN** primary controls, labels, bottom navigation, forms, and sheets SHALL remain reachable without clipped text or hidden actions

#### Scenario: Non-visual operation
- **WHEN** a screen reader traverses a status, destructive action, loading state, error, or result
- **THEN** the control/state SHALL have a meaningful semantic label, logical order, non-color meaning, and non-duplicative announcement

### Requirement: Traceable APK release
The project SHALL build a versioned release APK and record version/build identity, filename, SHA-256, build timestamp, source revision when available, and clean-install guidance; build evidence MUST remain distinct from production and physical-device evidence.

#### Scenario: APK build completes
- **WHEN** the release APK is generated
- **THEN** its identity and hash SHALL be recorded while physical-device and production verification gates remain open until directly observed
