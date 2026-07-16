## Why

The lesion timeline exposes repeated evaluations but requires professionals to compare images and model outputs mentally. A dedicated same-lesion comparison makes longitudinal differences visible without adding a second source of clinical data or implying that classifier changes prove lesion progression.

## What Changes

- Add a Flutter comparison entry point when a lesion has at least two complete evaluations.
- Let the professional select two different evaluations belonging to that lesion.
- Present both images, dates, model outputs, classifier confidence, malignant-output percentage, model version, and recorded findings side by side.
- Calculate numerical deltas locally from immutable evaluation data and label them as classifier-output differences rather than clinical progression.
- Preserve safe empty and unavailable states when fewer than two comparable evaluations exist or image/prediction data is missing.

## Capabilities

### New Capabilities
- `lesion-evaluation-comparison`: Selection and safe side-by-side presentation of two immutable evaluations from the same lesion.

### Modified Capabilities

None.

## Impact

- Flutter clinical presentation and navigation under lesion detail.
- Flutter widget/domain-level comparison tests.
- No backend endpoint, database migration, model, inference, or persistence change.
