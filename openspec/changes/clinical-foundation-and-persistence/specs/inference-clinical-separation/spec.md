## ADDED Requirements

### Requirement: Retained model contract
The system SHALL continue using the approved ResNet50 ONNX artifact and external data, 224 by 224 RGB ImageNet-normalized preprocessing, benign/malignant class order, current threshold, and current prediction semantics without retraining, replacement, or recalibration.

#### Scenario: Supported image is analyzed
- **WHEN** a valid supported image is submitted with complete clinical context
- **THEN** the service returns the existing probability, label, confidence, model-version, and processing-time contract

#### Scenario: Foundation is released
- **WHEN** persistence, access, admin, or mobile hardening changes are deployed
- **THEN** the approved model bytes, preprocessing, class order, threshold, and inference semantics remain unchanged

### Requirement: Immutable prediction provenance
Each prediction SHALL be an immutable record containing workspace, patient, lesion, evaluation, source image, model version, probabilities, predicted label, confidence, processing time, creation timestamp, and attempt provenance.

#### Scenario: Clinical observations change
- **WHEN** a professional adds or updates clinical observations
- **THEN** the original model prediction remains unchanged and independently auditable

#### Scenario: Analysis is retried
- **WHEN** a failed or interrupted analysis is retried
- **THEN** a new attempt uses the original context and never overwrites an existing prediction

### Requirement: Clinical interpretation separation
The system SHALL store professional observations separately from model output and SHALL describe predictions as decision support rather than definitive diagnosis.

#### Scenario: Result is displayed
- **WHEN** an authorized user opens a current result
- **THEN** model probability is visually distinct from clinical information and accompanied by non-diagnostic wording

### Requirement: ResNet50 regression verification
Automated checks SHALL verify approved SHA-256 checksums and the configured production ResNet50 input/output contract without training or modifying the model.

#### Scenario: Model regression tests run
- **WHEN** the inference suite executes
- **THEN** it verifies checksums, loading, tensor shape, preprocessing, class order, bounded probabilities, threshold semantics, and endpoint compatibility

#### Scenario: Model is incompatible or changed
- **WHEN** an artifact checksum or expected inference contract does not match
- **THEN** integrity/readiness verification fails and identifies the affected artifact without exposing internal paths to end users
