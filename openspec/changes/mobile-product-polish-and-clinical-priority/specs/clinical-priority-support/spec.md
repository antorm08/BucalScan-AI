## ADDED Requirements

### Requirement: Structured versioned clinical assessment
The system SHALL capture a canonical, versioned structured assessment of relevant signs, symptoms, risk factors, and emergency flags using explicit true/false/unknown or allow-listed values; unknown/not assessed MUST remain distinct from false.

#### Scenario: Complete structured assessment
- **WHEN** a professional supplies every field required by the active ruleset
- **THEN** the backend SHALL canonicalize and validate the input under that ruleset version before evaluation

#### Scenario: Missing required answers
- **WHEN** one or more required inputs are unknown, absent, or invalid
- **THEN** the result SHALL be `incomplete` with stable missing-field reason codes and SHALL NOT silently treat them as negative findings

#### Scenario: Client submits unknown field or value
- **WHEN** the payload contains an unsupported code, enum value, or client-selected ruleset
- **THEN** the backend SHALL return a sanitized validation error and SHALL NOT persist a partial assessment/result

### Requirement: Deterministic priority categories
For an accepted ruleset version, identical canonical assessment snapshots SHALL always produce the same one of `incomplete`, `standard`, `prompt`, `urgent`, or `emergency`, with the same ordered stable reason codes.

#### Scenario: Repeat deterministic evaluation
- **WHEN** the same canonical snapshot is evaluated repeatedly with the same ruleset and engine contract
- **THEN** priority code and ordered reason codes SHALL be identical

#### Scenario: Complete low-concern input
- **WHEN** all required inputs are complete and no emergency, urgent, or prompt rule matches
- **THEN** the result SHALL be `standard` with the applicable stable reason code

### Requirement: Emergency override
The priority engine SHALL evaluate governance-approved emergency flags as an override that returns `emergency` regardless of non-emergency score or classifier output.

#### Scenario: Emergency flag present
- **WHEN** any configured emergency flag is true in an otherwise valid assessment
- **THEN** the engine SHALL return `emergency`, identify every matched emergency reason code, and SHALL NOT lower the output based on other answers

#### Scenario: Emergency input unknown
- **WHEN** a required emergency flag is unknown rather than false
- **THEN** the engine SHALL return `incomplete` unless a different confirmed emergency flag already requires `emergency`

### Requirement: Version-controlled standard, prompt, and urgent rules
Required fields, concern weights, thresholds, high-concern combinations, reason catalog, and display copy SHALL reside in an immutable server-side ruleset definition; UI code MUST NOT independently calculate priority.

#### Scenario: Urgent threshold or combination matches
- **WHEN** a complete snapshot matches the active ruleset's approved urgent threshold or combination and no emergency rule matches
- **THEN** the engine SHALL return `urgent` with all governing reason codes and ruleset version

#### Scenario: Prompt threshold or combination matches
- **WHEN** a complete snapshot matches the active ruleset's approved prompt threshold or combination but no urgent/emergency rule
- **THEN** the engine SHALL return `prompt` with all governing reason codes and ruleset version

#### Scenario: Ruleset mutation attempted
- **WHEN** a published ruleset version would otherwise be edited
- **THEN** the system SHALL require a new version identifier and SHALL preserve evaluation behavior and fixtures for the prior version

### Requirement: Immutable assessment snapshot
Each accepted assessment SHALL be persisted as an immutable snapshot containing canonical structured inputs, schema/ruleset version, completion state, assessor, workspace, patient, lesion, evaluation, and assessment timestamps.

#### Scenario: Persist accepted assessment
- **WHEN** an authorized professional submits a valid assessment for an active-workspace lesion evaluation
- **THEN** the backend SHALL atomically persist the complete canonical snapshot with tenant and author provenance

#### Scenario: Attempt to edit historical assessment
- **WHEN** a client attempts to update a persisted snapshot
- **THEN** the backend SHALL reject mutation; a correction SHALL create a new assessment/result linked to a new evaluation or explicit superseding record without overwriting history

### Requirement: Immutable priority result provenance
Each assessment snapshot SHALL have an immutable priority result containing category code, ordered stable reason codes, rendered reasons, ruleset identifier/version, engine version, and evaluation timestamp.

#### Scenario: Historical result is read after rules change
- **WHEN** a later ruleset becomes active
- **THEN** an earlier result SHALL retain and display its original category, reasons, ruleset, engine, and timestamp without automatic recalculation

#### Scenario: Atomic failure
- **WHEN** assessment persistence or priority evaluation fails
- **THEN** the transaction SHALL not leave an orphan snapshot, partial result, or altered model prediction

### Requirement: Workspace and professional authorization
Clinical assessment and priority APIs SHALL require an active workspace, active authorized membership, and patient/lesion/evaluation ownership in that workspace; platform-admin status alone SHALL grant no access.

#### Scenario: Cross-workspace assessment
- **WHEN** an authorized professional submits identifiers from another workspace
- **THEN** the backend SHALL deny the request without revealing foreign clinical data or persisting a result

#### Scenario: Platform admin without clinical membership
- **WHEN** a platform administrator invokes a clinical-priority endpoint without an active membership
- **THEN** the backend SHALL deny clinical access exactly as for other clinical endpoints

### Requirement: Strict separation from ResNet50
Clinical priority SHALL be persisted, versioned, computed, and presented separately from `ModelPrediction`; initial priority rules MUST NOT consume classifier confidence/probabilities, and no priority operation SHALL modify the approved ResNet50 artifact or inference contract.

#### Scenario: Priority calculation executes
- **WHEN** the backend computes a priority result
- **THEN** model artifact bytes, checksums, preprocessing, class order, threshold, probabilities, prediction label, and inference response fields SHALL remain unchanged

#### Scenario: Result screen contains both outputs
- **WHEN** an evaluation has a model prediction and a priority result
- **THEN** the UI SHALL render them as separately titled/supporting outputs with independent provenance and disclaimers

### Requirement: No diagnosis or cancer probability
Priority APIs, reason text, UI, history, exports/logging, and help SHALL describe timing/attention support only and MUST NOT state or imply diagnosis, malignancy determination, cancer probability, or replacement of professional judgment/emergency services.

#### Scenario: Display urgent result
- **WHEN** the priority category is `urgent`
- **THEN** the UI SHALL explain the matched structured reasons and suggested attention category using approved non-diagnostic wording, without converting model confidence or score into cancer probability

#### Scenario: Display emergency result
- **WHEN** the priority category is `emergency`
- **THEN** the UI SHALL use approved emergency-action wording and SHALL state that the tool does not replace emergency services or professional judgment

### Requirement: Feature-gated governed rollout
The backend SHALL default clinical-priority support off, publish disabled/academic/enabled capability state and active allow-listed ruleset, and reject evaluation when the deployment mode or version is not authorized.

#### Scenario: Feature disabled
- **WHEN** the server reports clinical priority disabled
- **THEN** the client SHALL hide or disable assessment submission, explain unavailability safely, and continue the unchanged model/clinical-record flow

#### Scenario: Academic mode
- **WHEN** governance permits academic support but not clinical-use claims
- **THEN** every assessment/result/history/help surface SHALL show the approved academic decision-support wording and SHALL NOT present it as validated clinical triage

#### Scenario: Unknown active version
- **WHEN** client and server do not support the same allow-listed active ruleset
- **THEN** evaluation SHALL fail closed with a safe upgrade/unavailable state rather than calculating locally or selecting another version

### Requirement: Clinical governance package
Activation beyond hidden/approved academic mode SHALL require recorded intended use, accountable reviewers, evidence sources, finalized fields/rules/reasons/copy, representative validation corpus, predefined acceptance criteria, subgroup/error analysis, known limitations, monitoring, and rollback approval for one exact ruleset version.

#### Scenario: Governance evidence incomplete
- **WHEN** any required governance or validation artifact lacks approval/evidence
- **THEN** production clinical enablement SHALL remain blocked and its gate SHALL remain unchecked

#### Scenario: New ruleset proposed
- **WHEN** weights, thresholds, combinations, emergency flags, or clinical wording change
- **THEN** the new version SHALL undergo the defined governance and validation process independently before activation

### Requirement: Priority migration safety
Schema evolution SHALL add assessment/result storage without mutating existing evaluations or predictions, SHALL provide reviewable forward/rollback behavior, and SHALL preserve old records when rollback would otherwise destroy captured clinical data.

#### Scenario: Upgrade existing database
- **WHEN** the migration runs against existing patients, lesions, evaluations, and predictions
- **THEN** it SHALL create the new structures/indexes without fabricating priority results or changing existing model/clinical rows

#### Scenario: Downgrade after priority writes
- **WHEN** persisted assessment/priority rows exist
- **THEN** rollback guidance SHALL disable the feature and prefer forward fix; destructive downgrade SHALL require an explicit approved data-retention decision

### Requirement: Priority verification boundaries
Automated tests SHALL cover canonicalization, every category, emergency/incomplete precedence, boundary values, determinism, reason ordering, versioning, immutability, migration, authorization, feature modes, UI wording, race handling, and unchanged model checksums; clinical and device validation MUST remain separate gates.

#### Scenario: Automated suite passes
- **WHEN** all backend and Flutter tests pass
- **THEN** implementation evidence MAY be recorded but clinical validation, production enablement, and physical-device gates SHALL remain unchecked until their own evidence exists

#### Scenario: Clinical validation completes
- **WHEN** accountable reviewers execute the approved protocol against the frozen ruleset and record acceptance evidence
- **THEN** only that exact ruleset/version and approved wording MAY be considered for enabled mode through a separate explicit release decision
