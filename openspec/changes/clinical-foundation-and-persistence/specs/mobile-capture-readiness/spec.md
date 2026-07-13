## ADDED Requirements

### Requirement: Camera and gallery readiness
The mobile application SHALL declare required camera/gallery permissions and purpose descriptions and SHALL represent request, denial, cancellation, retry/settings guidance, and image-ready states without blocking unrelated actions.

#### Scenario: Camera permission is requested
- **WHEN** a user first selects camera capture
- **THEN** the operating system presents the BucalScan AI purpose description before grant or denial

#### Scenario: Gallery permission is requested
- **WHEN** a user first selects gallery input
- **THEN** the operating system presents the BucalScan AI photo-library purpose description where required

#### Scenario: Permission is denied
- **WHEN** camera or gallery access is denied
- **THEN** the application explains the selected action cannot continue, offers appropriate retry/settings guidance, and remains usable elsewhere

#### Scenario: Image selection is cancelled
- **WHEN** the user cancels camera or gallery selection
- **THEN** no analysis begins and existing valid clinical selections remain intact

### Requirement: Complete prediction prerequisites
The mobile application SHALL prevent analysis unless an active workspace, patient, lesion, supported image, and professional authorization attestation are present and current.

#### Scenario: A prerequisite is missing
- **WHEN** the user attempts analysis without any required prerequisite
- **THEN** no prediction request is sent and the UI identifies the missing action in safe product language

#### Scenario: Context is complete
- **WHEN** every prerequisite is current and the user submits
- **THEN** the request snapshots workspace, patient, lesion, image, and attestation for that attempt

#### Scenario: Professional records observations
- **WHEN** optional clinical observations are entered before submission
- **THEN** they pass through the prediction clean layers to the existing backend form field and remain separate from model output

### Requirement: Context-preserving prediction retry
Retry SHALL preserve the original attempt's workspace, patient, lesion, image, and attestation, SHALL reject completion after auth/workspace context changes, and SHALL never overwrite an existing immutable prediction.

#### Scenario: Failed attempt is retried
- **WHEN** an eligible failed attempt is retried
- **THEN** the new attempt uses the original snapshot even if visible selections have since changed

#### Scenario: Context changes while request is running
- **WHEN** authentication or workspace changes before prediction completes
- **THEN** the stale completion is ignored and cannot navigate, display, or persist into the new context

#### Scenario: Prior prediction exists
- **WHEN** another attempt is made for an evaluation context with a persisted prediction
- **THEN** the prior prediction remains unchanged and any permitted new attempt has separate provenance

#### Scenario: Repeat analysis starts from lesion follow-up
- **WHEN** a professional chooses a new analysis for an existing lesion
- **THEN** the current patient and lesion are selected, prior prediction attempt state is cleared, and the authenticated root selects capture without pushing a bare home route

### Requirement: Guarded clinical navigation and wording
Result and history navigation SHALL require current workspace/patient/lesion ownership and all prediction presentation SHALL use non-diagnostic decision-support language.

#### Scenario: Current result opens
- **WHEN** a prediction belongs to the current validated context
- **THEN** the result can open with probabilities and a non-diagnostic notice

#### Scenario: Stale result navigation is attempted
- **WHEN** result context is absent, stale, or belongs to another workspace
- **THEN** navigation is blocked or redirected without displaying the stale result

### Requirement: Consistent mobile product identity
Supported platform metadata SHALL identify the application as BucalScan AI rather than a legacy name.

#### Scenario: Application is installed
- **WHEN** the app appears in a launcher, system dialog, or permission prompt
- **THEN** the displayed product name is BucalScan AI

### Requirement: Verifiable mobile release artifact
Each candidate APK SHALL have version/build identity, filename, SHA-256 hash, build timestamp, and source revision when available recorded with clean-install guidance, and SHALL not be marked device-verified until installed and exercised on an actual device.

#### Scenario: Release APK is produced
- **WHEN** a candidate APK is generated
- **THEN** its identity, hash, time, and clean-install instructions are recorded without claiming device evidence

#### Scenario: Device release is verified
- **WHEN** the recorded APK is clean-installed and required flows are exercised on a physical device
- **THEN** device verification references that exact APK identity and observed results
