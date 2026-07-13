## Why

BucalScan AI has the clinical and administrative foundation, but navigation ownership, mobile information architecture, scalable administration, and clinical wording still expose black-screen, stale-state, and unsafe-interpretation risks. This change makes the product coherent and accessible while adding a governed, deterministic clinical-priority layer that remains explicitly separate from the immutable ResNet50 classifier.

## What Changes

- Establish one authority for logout, role/root routing, workspace transitions, and draft cleanup so auth and workspace boundaries cannot leave a black screen, stale clinical state, or an unguarded root; hide workspace switching when only one active workspace exists and explain that saved records remain.
- Replace the professional shell with four persistent destinations: Inicio, Pacientes, Analizar, and Historial; move profile/account/help to the top account menu and preserve the shell while navigating patient and lesion details.
- Polish the professional home, compact active-workspace presentation, patient/lesion forms, analysis/retry lifecycle, translated statuses, neutral unknown predictions, account/profile, functional help center, and safe non-diagnostic wording.
- Remove dead legacy patient fields from active product contracts, represent lesion observed date separately from estimated duration, distinguish longitudinal lesion notes from current evaluation findings, and enforce one lesion per image/evaluation.
- Expand history with backend search, filters, date range, deterministic sorting, pagination, refresh, and guarded patient/lesion links.
- Replace the admin tabs with a bottom NavigationBar for Centers, Access, and Users; provide backend search/filter/sort/pagination and detailed full-height bottom sheets for each resource.
- Improve admin data, resolved-state visibility, access-only verification disclaimers, outlined red rejection, confirmations, and audit actor/time/reason fields where the current schema can safely support them.
- Preserve and test admin invariants: suspended requesters cannot be approved, independent memberships receive `professional`, the last active clinic admin is protected, platform admins receive no implicit clinical access, and stale/racing responses cannot overwrite current state.
- Add versioned structured clinical assessment inputs for signs, symptoms, and risk factors, with emergency override and deterministic `incomplete`, `standard`, `prompt`, `urgent`, or `emergency` priority output.
- Persist an immutable assessment snapshot and priority result with stable codes, reasons, and ruleset version; do not produce a diagnosis or cancer probability and do not alter ResNet50 artifacts, preprocessing, thresholds, classes, or model output.
- Gate clinical-priority availability and claims behind clinical governance/validation, using a feature flag or explicit academic decision-support wording until approved.
- Add responsive and accessibility coverage and produce a versioned release APK, while keeping production, physical-device, and clinical-validation evidence as explicit open gates.

## Capabilities

### New Capabilities

- `mobile-product-experience`: Auth/root/workspace navigation safety, professional shell and nested navigation, clinical forms and analysis lifecycle, history, account/help, responsive accessibility, and release evidence.
- `admin-operations`: Scalable admin navigation and queries, detailed resource review and decisions, audit context, lifecycle presentation, authorization invariants, and race-safe state handling.
- `clinical-priority-support`: Versioned structured assessment, deterministic priority rules and emergency override, immutable snapshots/results, non-diagnostic presentation, governance, validation, and rollout controls.

### Modified Capabilities

None. There are no capability specifications under `openspec/specs/`; related unarchived changes are context rather than main specs to modify.

## Impact

- Flutter: startup/auth/root coordination, professional and admin shells, nested navigation, Riverpod state boundaries, patients/lesions, capture/results/history, profile/help, responsive layouts, accessibility semantics, and APK packaging.
- Backend: paginated admin/history query contracts, guarded lifecycle actions, available audit metadata/reasons, structured assessment and priority APIs, authorization, validation, and deterministic rules execution.
- Persistence: additive Alembic evolution for immutable clinical assessment snapshots and priority results; existing user/workspace/membership audit columns are reused where sufficient and new audit fields are added only where required by the approved design.
- Security and safety: tenant isolation, role/root separation, last-admin protection, stale-response suppression, no implicit platform-admin clinical access, non-diagnostic claims, and feature-gated clinical-priority rollout.
- Model: the current ResNet50 model and inference contract remain unchanged and independently persisted from the clinical-priority result.
- Verification: backend and Flutter automated tests, responsive/accessibility checks, migration checks, and APK build records; production, real-device, and clinical-governance validation remain unclaimed until completed.
