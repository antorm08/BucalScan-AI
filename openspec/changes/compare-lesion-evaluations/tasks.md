## 1. Comparison Domain and Navigation

- [x] 1.1 Add pure helpers for comparable-evaluation filtering, default pair selection, distinct selection updates, and signed percentage-point deltas.
- [x] 1.2 Add a guarded comparison action to lesion detail that only opens for two or more complete evaluations from that lesion.

## 2. Comparison Experience

- [x] 2.1 Build the responsive comparison view with two selectors, side-by-side source images and compact immutable evaluation/model metrics.
- [x] 2.2 Add neutral delta, differing-label/model-version warnings, detailed findings, image fallback, and explicit non-progression wording.

## 3. Verification

- [x] 3.1 Add unit and widget tests for eligibility, latest-two defaults, distinct selection, deltas, unavailable state, image fallback, differing versions/labels, narrow width, and large text.
- [x] 3.2 Run `flutter analyze` and the complete Flutter test suite, resolving all regressions without backend or migration changes.
