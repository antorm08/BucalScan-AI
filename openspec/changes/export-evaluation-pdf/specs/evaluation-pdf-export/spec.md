## ADDED Requirements

### Requirement: Authorized evaluation report generation
The system SHALL generate a PDF only for an evaluation that belongs to the requested lesion and active workspace, using the authenticated workspace-access policy.

#### Scenario: Authorized report request
- **WHEN** an active workspace member requests a report for an evaluation belonging to the requested lesion and workspace
- **THEN** the system returns PDF bytes with PDF content type and an attachment filename

#### Scenario: Cross-workspace or mismatched resource request
- **WHEN** the lesion or evaluation does not belong to the active workspace or the evaluation does not belong to the requested lesion
- **THEN** the system returns a not-found response without revealing the inaccessible resource

### Requirement: Safe report contents
The report SHALL identify the evaluation with its clinical code, lesion site, date, professional, findings, source image availability, model output, technical confidence, model version, and explicit non-diagnostic language, while excluding direct identity documents and contact information.

#### Scenario: Complete evaluation report
- **WHEN** a persisted evaluation has an image, prediction, professional, and findings
- **THEN** the generated PDF contains those fields and distinguishes technical model output from diagnosis and cancer probability

#### Scenario: Academic orientation exists
- **WHEN** the evaluation has a persisted academic priority result
- **THEN** the report includes its orientative code, reasons, and ruleset provenance without deriving priority from model confidence

#### Scenario: Academic orientation is absent
- **WHEN** the evaluation has no persisted academic priority result
- **THEN** the report states that no academic orientation was recorded and still generates successfully

### Requirement: Optional report imagery
The system SHALL generate the report even when the source image or CAM is missing, inaccessible, or invalid.

#### Scenario: CAM is available
- **WHEN** a valid CAM asset is associated with the prediction
- **THEN** the report embeds it separately from the source image and labels it as an explanatory visualization

#### Scenario: Image asset cannot be loaded
- **WHEN** the source image or CAM cannot be loaded within bounded retrieval rules
- **THEN** the report marks that asset as unavailable and returns a valid PDF

### Requirement: Client export interaction
Flutter SHALL download report bytes through the authenticated workspace-scoped API path and invoke the platform export/share interface from an individual evaluation card.

#### Scenario: Successful export
- **WHEN** a user requests export from an evaluation card and the backend returns PDF bytes
- **THEN** Flutter passes one PDF file with a non-identifying filename to the platform interface

#### Scenario: Export in progress
- **WHEN** one evaluation report is downloading
- **THEN** that evaluation's export action shows progress and rejects duplicate taps without disabling unrelated evaluation cards

#### Scenario: Export failure
- **WHEN** download or platform export fails
- **THEN** Flutter restores the action and displays a controlled Spanish error without exposing technical details

#### Scenario: Narrow and enlarged-text layout
- **WHEN** the lesion timeline is displayed at 320 logical pixels or enlarged text
- **THEN** the export action remains reachable without horizontal overflow
