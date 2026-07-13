## ADDED Requirements

### Requirement: Reusable workspace patient profiles
The system SHALL let authorized professionals search, deduplicate, select, or create a patient in the active workspace using a required workspace-unique clinical code, an optional workspace-unique identity document, and patient name/profile data.

#### Scenario: Existing patient is selected
- **WHEN** a professional finds a patient by clinical code, document, or name
- **THEN** the existing profile and longitudinal history are reused only within the active workspace

#### Scenario: New patient is created
- **WHEN** no matching patient is selected and valid minimum data and unique clinical code are submitted
- **THEN** one patient profile is created in the active workspace without a patient login

#### Scenario: Exact identifier already exists
- **WHEN** clinical code or identity document duplicates an active-workspace patient
- **THEN** creation is prevented and the existing patient is offered

#### Scenario: Demographic data is similar
- **WHEN** name or available demographics resemble another patient without an exact unique-key conflict
- **THEN** potential matches are shown without automatic merging

### Requirement: Typed patient and lesion picker
The Flutter picker SHALL expose typed loading, search/results, empty, create, error, and retry states for patients and lesions and SHALL reject stale completions.

#### Scenario: Search has no result
- **WHEN** a current patient or lesion search completes successfully without matches
- **THEN** the picker shows a distinct empty state and an eligible create action

#### Scenario: Picker request fails
- **WHEN** a current request fails
- **THEN** the picker shows a sanitized error and retry without losing valid workspace context

#### Scenario: Older search completes late
- **WHEN** an older query or prior-workspace response completes after a newer request or context change
- **THEN** the picker ignores it and preserves the current typed state

### Requirement: Distinct longitudinal lesions
The system SHALL allow multiple lesions per patient, SHALL record anatomical site, onset or estimated duration, status, and optional notes, and SHALL append repeated evaluations and images to a chronological lesion timeline.

#### Scenario: Patient has multiple lesions
- **WHEN** lesions at distinct sites are recorded for one patient
- **THEN** each has an independent lifecycle and timeline under the reusable patient

#### Scenario: Existing lesion is evaluated again
- **WHEN** a professional selects an existing lesion for another evaluation
- **THEN** the new image, observation, attestation, and immutable prediction are appended chronologically

#### Scenario: Lesion exists without prediction
- **WHEN** valid lesion details are saved before analysis
- **THEN** the lesion exists without requiring model output

### Requirement: Selection boundary behavior
Patient and lesion selections SHALL belong to the active workspace; changing patient SHALL preserve workspace and clear lesion/downstream context, while changing workspace SHALL clear patient, lesion, and every workspace-scoped cache.

#### Scenario: Patient changes
- **WHEN** a professional selects a different patient in the same workspace
- **THEN** the workspace remains active and prior lesion, evaluation, image, and pending result context are cleared

#### Scenario: Workspace changes
- **WHEN** a different active workspace is selected
- **THEN** patient, lesion, history, prediction, search, and other workspace caches are cleared before new data is accepted

### Requirement: Professional authorization attestation
Before analysis and storage, the system SHALL require the acting professional to attest that patient authorization was obtained and SHALL persist who attested, when, and for which evaluation.

#### Scenario: Authorization is confirmed
- **WHEN** a professional submits complete clinical context and attestation
- **THEN** the attestation is recorded with the evaluation and analysis may proceed

#### Scenario: Authorization is absent
- **WHEN** submission lacks attestation
- **THEN** the image is not analyzed or persisted as a clinical prediction

### Requirement: Clinical history ownership and navigation
Clinical history SHALL retain workspace, patient, lesion, professional, evaluation, image, immutable prediction, separate observations, and timestamps, and mobile navigation SHALL open history/results only for current valid context.

#### Scenario: Lesion timeline is viewed
- **WHEN** an authorized professional opens the current lesion
- **THEN** evaluations appear chronologically with responsible professional, images, observations, and unchanged prediction provenance

#### Scenario: Result context is stale or absent
- **WHEN** navigation targets a result or history that no longer belongs to the current workspace/patient/lesion context
- **THEN** navigation is blocked or redirected to a safe current selection state
