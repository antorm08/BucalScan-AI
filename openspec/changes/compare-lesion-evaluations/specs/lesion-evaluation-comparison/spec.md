## ADDED Requirements

### Requirement: Same-lesion pair selection
The application SHALL allow selection of exactly two distinct complete evaluations from the currently authorized lesion and MUST NOT combine records from different lesions.

#### Scenario: Lesion has two comparable evaluations
- **WHEN** lesion detail contains at least two evaluations with image and prediction data
- **THEN** the comparison action SHALL be enabled and default to the two most recent comparable evaluations

#### Scenario: Lesion lacks comparable evaluations
- **WHEN** fewer than two evaluations contain both image and prediction data
- **THEN** comparison SHALL remain unavailable with an explanatory state and SHALL NOT issue another backend request

#### Scenario: User changes one selection
- **WHEN** the professional selects an evaluation already used on the opposite side
- **THEN** the application SHALL preserve two distinct selections rather than comparing an evaluation with itself

### Requirement: Responsive side-by-side comparison
The comparison view SHALL show both source images, evaluation dates, model labels, classifier confidence, malignant-output percentages, model versions, and findings in a responsive presentation that remains usable on supported phone widths and large text.

#### Scenario: Comparison opens
- **WHEN** two eligible evaluations are selected
- **THEN** their images and compact model metrics SHALL appear in labeled left/right columns and their detailed findings SHALL remain reachable without horizontal page scrolling

#### Scenario: Historical image cannot load
- **WHEN** one selected image fails to load
- **THEN** that side SHALL show a safe image-unavailable state while preserving the other evaluation and its stored data

### Requirement: Neutral classifier deltas
The application SHALL calculate signed differences from stored confidence and malignant-output values in Flutter and SHALL describe them only as numerical classifier-output changes, not diagnosis, cancer probability, urgency, improvement, deterioration, or clinical progression.

#### Scenario: Selected evaluations have the same model version
- **WHEN** both evaluations use the same model version
- **THEN** the view SHALL display confidence and malignant-output deltas with neutral signed percentage-point wording

#### Scenario: Selected evaluations use different model versions
- **WHEN** model versions differ
- **THEN** the view SHALL identify both versions and warn that the numerical outputs have reduced direct comparability

#### Scenario: Predicted labels differ
- **WHEN** the two stored predicted labels are different
- **THEN** each confidence SHALL remain associated with its own label and the view SHALL NOT describe the confidence delta as lesion evolution
