## ADDED Requirements

### Requirement: Normalized prediction persistence
The system SHALL persist each successful prediction in the normalized clinical evaluation, lesion image, model prediction, and consent records without requiring or creating a legacy `analyses` record.

#### Scenario: Successful prediction
- **WHEN** an authorized professional submits a valid prediction for a patient lesion
- **THEN** the system commits the normalized evaluation aggregate and returns its evaluation identifier
- **AND** no new row is inserted into `analyses`

### Requirement: Normalized history
The system SHALL build workspace-scoped history from normalized clinical records while preserving the existing history response fields, filtering, sorting, pagination, and priority behavior.

#### Scenario: Evaluation without legacy duplicate
- **WHEN** a normalized evaluation has an image and model prediction but no `analyses` row
- **THEN** the evaluation appears in the authorized workspace history with canonical patient, lesion, professional, prediction, image, and priority data

#### Scenario: Workspace isolation
- **WHEN** a professional requests history for an active workspace
- **THEN** the system returns only normalized evaluations belonging to that workspace

### Requirement: Normalized daily summary
The system SHALL calculate daily total, benign, malignant, and latest-analysis values from normalized model predictions scoped to the active workspace.

#### Scenario: Workspace daily counts
- **WHEN** normalized predictions exist today in multiple workspaces
- **THEN** the summary includes only predictions connected to the active workspace

### Requirement: Safe legacy retention
The system SHALL preserve existing `analyses` rows during the runtime cutover and SHALL NOT depend on those rows for current prediction, history, or summary behavior.

#### Scenario: Legacy table remains unchanged
- **WHEN** new normalized predictions are created after the cutover
- **THEN** existing legacy rows remain available for rollback or audit
- **AND** their row count does not increase
