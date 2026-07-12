## ADDED Requirements

### Requirement: Retained model contract
The system SHALL continue using the current ResNet50 ONNX artifact, 224 by 224 RGB ImageNet-normalized preprocessing, benign/malignant class order, and current prediction semantics without retraining or replacing the model.

#### Scenario: Existing supported image is analyzed
- **WHEN** a valid supported clinical image is submitted to the retained inference service
- **THEN** the service returns benign and malignant probabilities, a predicted label, confidence, model version, and processing time using the existing contract

#### Scenario: Clinical foundation is deployed
- **WHEN** the new persistence and clinical workflow changes are released
- **THEN** the approved ONNX model artifacts and learned weights remain byte-for-byte unchanged

### Requirement: Prediction provenance
Each persisted model prediction SHALL retain the model version, probabilities, predicted label, confidence, processing time, source image, and creation timestamp independently from clinical interpretation.

#### Scenario: Professional later changes clinical interpretation
- **WHEN** a professional records or updates a clinical interpretation
- **THEN** the original model prediction remains unchanged and auditable

### Requirement: Clinical interpretation separation
The system SHALL label model output as decision support rather than definitive diagnosis and SHALL store professional observations or future risk levels separately from raw model output.

#### Scenario: Result is displayed
- **WHEN** the analysis result screen opens
- **THEN** the model probability is visually distinguished from clinical information and includes a non-diagnostic support notice

### Requirement: ResNet50 regression verification
Automated tests SHALL exercise the configured production ResNet50 model, verify its input/output contract without training it, and compare SHA-256 checksums for the ONNX artifact and its external data file against the approved baseline.

#### Scenario: Model regression tests run
- **WHEN** the backend inference test suite executes
- **THEN** it verifies model loading, expected tensor shape, valid class ordering, bounded probabilities, and a successful prediction using ResNet50

#### Scenario: Model artifact is incompatible
- **WHEN** the configured artifact cannot satisfy the expected inference contract
- **THEN** readiness fails and the service does not report itself ready for analysis

#### Scenario: Model artifact bytes change
- **WHEN** either approved ResNet50 file no longer matches its recorded SHA-256 checksum
- **THEN** model-integrity verification fails and identifies the changed artifact without retraining it
