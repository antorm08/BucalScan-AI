## 1. Backend Report

- [x] 1.1 Add the pinned ReportLab dependency and an in-memory PDF service with bounded optional image and CAM loading.
- [x] 1.2 Add the workspace-scoped lesion/evaluation report endpoint with safe content disposition and canonical clinical data.
- [x] 1.3 Add backend tests for PDF output, report text, optional image failures, authentication, workspace isolation, and lesion/evaluation mismatch.

## 2. Flutter Export

- [x] 2.1 Add authenticated workspace-scoped byte transport and clinical repository/use-case contracts for evaluation reports.
- [x] 2.2 Add an injectable platform PDF share service with a non-identifying filename.
- [x] 2.3 Add a responsive per-evaluation export action with isolated progress, duplicate-tap prevention, and controlled Spanish errors.
- [x] 2.4 Add Flutter unit, contract, and widget tests for byte transport, export interaction, failure recovery, and accessible narrow layout.

## 3. Verification

- [x] 3.1 Run strict OpenSpec validation, backend tests, Flutter analysis, and the complete Flutter test suite; resolve all regressions.
