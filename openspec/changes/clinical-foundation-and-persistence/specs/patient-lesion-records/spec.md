## ADDED Requirements

### Requirement: Reusable patient records
The system SHALL allow an authorized professional to search for an existing patient in the active workspace or register a new patient before creating a clinical evaluation.

#### Scenario: Existing patient is selected
- **WHEN** a professional searches by supported patient identifier or name and selects a result
- **THEN** the new evaluation uses the existing patient record and its prior clinical history remains available

#### Scenario: New patient is registered
- **WHEN** no matching patient exists and the professional submits a clinic-unique clinical code and valid minimum patient information
- **THEN** the system creates a patient in the active workspace and makes that patient available for evaluation without creating a patient login

#### Scenario: Professional records identity document
- **WHEN** the patient's clinical record contains an identity document
- **THEN** the professional can store it as an optional value that is unique within the active workspace

#### Scenario: Professional searches patient
- **WHEN** the professional searches by clinical code, identity document, or patient name
- **THEN** the system returns matching patients from the active workspace only

### Requirement: Potential duplicate warning
The system SHALL warn the professional when a new patient resembles an existing patient in the active workspace, without automatically merging records.

#### Scenario: Matching identifier exists
- **WHEN** a professional enters a clinical code or identity document already registered in the active workspace
- **THEN** the system prevents an accidental duplicate and offers the existing patient for selection

#### Scenario: Similar demographic data exists
- **WHEN** a patient name and available demographic data resemble an existing record but the identifier is different or absent
- **THEN** the system displays potential matches and allows the professional to decide whether to select an existing record or continue

### Requirement: Distinct oral-lesion cases
The system SHALL represent each oral lesion independently so one patient can have multiple lesions and one lesion can have multiple evaluations over time.

#### Scenario: Patient has multiple lesions
- **WHEN** a professional records lesions at two distinct anatomical locations for one patient
- **THEN** the system maintains separate lesion histories under the same patient

#### Scenario: Existing lesion is evaluated again
- **WHEN** a professional selects an existing active lesion and performs another analysis
- **THEN** the new evaluation is appended to that lesion's chronological history

### Requirement: Minimum lesion description
The system SHALL record the lesion's anatomical site, initial observation date or estimated duration, status, and optional clinical notes independently from model prediction data.

#### Scenario: Lesion is created with valid minimum data
- **WHEN** a professional submits a supported anatomical site and required temporal information
- **THEN** the system creates the lesion without requiring a model prediction first

### Requirement: Professional consent attestation
Before a clinical image is captured, analyzed, and stored, the system SHALL require the acting professional to attest that patient authorization has been obtained and SHALL record the professional and timestamp with the evaluation.

#### Scenario: Professional confirms authorization
- **WHEN** the professional confirms authorization and submits the image
- **THEN** the system records the attestation with the evaluation and permits analysis

#### Scenario: Authorization is not confirmed
- **WHEN** the professional attempts to submit an image without confirming patient authorization
- **THEN** the system does not analyze or persist the image

### Requirement: Clinical history ownership
Clinical records SHALL retain the workspace, patient, lesion, creating professional, and evaluation timestamps needed to reconstruct their history.

#### Scenario: Professional views lesion history
- **WHEN** an authorized professional opens a lesion
- **THEN** the system presents its evaluations in chronological order with their responsible professionals and image-analysis results
