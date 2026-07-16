## 1. Baselines and Contract Inventory

- [x] 1.1 Record the current backend and Flutter test/analyzer baselines, database revision, app version/build, and SHA-256 values for the approved ResNet50 ONNX and external-data artifacts before implementation.
- [x] 1.2 Inventory every current logout, login completion, role/root redirect, workspace selection/switch, nested patient/lesion navigation, and request-generation invalidation path; identify the single coordinator entry points that will replace direct root pushes.
- [x] 1.3 Inventory active versus compatibility-only patient fields and map `observed_at`, `estimated_duration`, lesion notes, evaluation findings, image, prediction, and history identifiers through backend schemas and Flutter models.
- [x] 1.4 Define shared paginated response metadata and allow-listed query contracts for Centers, Access, Users, and History, including normalized search, filters, UTC date boundaries, sort direction, page bounds, totals, `has_next`, and stable identifier tie-breakers.
- [x] 1.5 Create the supported responsive/accessibility test matrix for narrow phone, standard phone, tablet, large text, keyboard/insets, focus traversal, screen reader semantics, touch targets, contrast, and non-color status cues.

## 2. Authoritative Session, Root, and Workspace Transitions

- [x] 2.1 Implement a top-level session/root state coordinator that revalidates account/role/membership state and exclusively renders startup, login, admin, workspace-gate, and professional roots.
- [x] 2.2 Replace direct `LoginView`, `HomeView`, and admin-root pushes from leaf widgets with intent callbacks/state transitions handled by the coordinator, including login completion and validation failure paths.
- [x] 2.3 Make logout atomically invalidate the session generation, clear credentials and API workspace headers, invalidate all user/workspace/admin/history/clinical/prediction/priority providers and drafts, remove nested routes, and let the coordinator render login once.
- [ ] 2.4 Add controller and widget tests for logout from admin, professional, workspace-gate, detail, and account-menu contexts, including in-flight late responses and the black-screen regression.
- [x] 2.5 Implement confirmed workspace switching as a coordinator transition that clears request generations, workspace caches, patient/lesion selection, unsaved forms, image, attestation, analysis/priority state, and nested routes while preserving persisted records.
- [ ] 2.6 Update workspace-switch confirmation wording to state that unsaved work is cleared and saved records remain; hide switching when only one active workspace exists and test one/multiple/revoked membership cases.
- [x] 2.7 Add routing tests proving `platform_admin` reaches only the admin root by role, professionals cannot bypass the workspace gate, cached privilege is rejected after failed revalidation, and platform-admin role alone grants no clinical root/access.

## 3. Professional Shell and Nested Navigation

- [x] 3.1 Replace the five-item professional bar/drawer primary navigation with a shell-owned four-item `NavigationBar` ordered Inicio, Pacientes, Analizar, Historial.
- [x] 3.2 Add an accessible top account menu for profile/account, Help, model/decision-support information, eligible workspace switching, and logout; remove Profile as a primary bottom destination.
- [x] 3.3 Implement shell-owned nested stacks or equivalent guarded routing so patient and lesion detail opened from Patients or History retains the shell and predictable Back behavior.
- [x] 3.4 Route repeat analysis through the shell controller to select the existing patient/lesion, clear only prior transient attempt state, and activate Analizar without constructing a new root.
- [x] 3.5 Redesign Inicio around compact active-workspace identity, frequent patient/analysis/history actions, useful workspace summary, and explicit loading/empty/error/retry states.
- [ ] 3.6 Add professional-shell widget/navigation tests for destination order/selection, state retention, account menu, nested patient/lesion routes, Back behavior, repeat analysis, and compact workspace overflow.

## 4. Clinical Forms and Analysis State Polish

- [x] 4.1 Remove dead legacy-only patient fields from active request/response models and Flutter forms while retaining read compatibility for migrated rows and adding regression tests that active writes do not require or repopulate them.
- [x] 4.2 Expose and validate lesion observed date independently from estimated duration in backend schemas, Flutter entities/models/forms, creation/editing, and detail presentation.
- [x] 4.3 Add concise form and detail guidance distinguishing longitudinal/current lesion notes from findings for the current clinical evaluation, and verify each value persists to its existing separate field.
- [x] 4.4 Enforce one workspace patient, one owned lesion, one image, and one evaluation per analysis attempt in request schemas/service transactions; reject multiple/mismatched resources without partial persistence.
- [x] 4.5 Replace ad hoc prediction state with explicit idle, context-ready, image-ready, submitting, succeeded, and failed transitions that block duplicate submission and clear stale result/error/progress on start over.
- [x] 4.6 Preserve the failed attempt's immutable workspace/patient/lesion/image/assessment/attestation snapshot for Retry while creating a new attempt and allowing an explicit Start over path.
- [x] 4.7 Centralize exhaustive localized mappings for user/workspace/membership/lesion/model/priority states and render unsupported prediction/status values with neutral text, iconography, and colors.
- [x] 4.8 Audit result, history, capture, and Help wording so classifier confidence is never called cancer probability and no output claims diagnosis, certainty, or replacement of professional judgment.
- [x] 4.9 Add backend and Flutter tests for separate temporal/note fields, legacy compatibility, one-lesion-per-image rejection, clean new/retry state, duplicate-submit prevention, known translations, neutral unknown prediction, and non-diagnostic copy.

## 5. Scalable History and Guarded Record Links

- [x] 5.1 Implement workspace-authorized History backend search across allowed patient/code fields, model and optional priority filters, inclusive UTC date range, allow-listed deterministic sorting, and bounded pagination metadata.
- [x] 5.2 Add backend History tests for tenant isolation, normalized search, each filter, date boundaries, stable tie ordering, invalid criteria, pagination totals, empty pages, and priority-disabled behavior.
- [x] 5.3 Extend Flutter History data/domain contracts, datasource, repository, use case, and controller for paginated query criteria, debounced search, refresh replacement, append, clear filters, and generation/query-key stale-response rejection.
- [x] 5.4 Redesign History controls and states for search, model/priority filters, date-range selection, sort, active-filter summary, clear, loading/append, refresh, empty/no-match, sanitized error, and retry.
- [x] 5.5 Update History cards/details with translated neutral-safe wording, evaluation/model/priority provenance, and shell-preserving links to the owning patient and lesion.
- [x] 5.6 Guard patient/lesion History links against missing, revoked, stale, or cross-workspace resources and show a safe unavailable/access-denied state without exposing identifiers from another tenant.
- [x] 5.7 Add Flutter unit/widget/navigation tests for History query replacement, stale page responses, refresh, pagination, filters/date/sort, unknown labels, and valid/stale patient/lesion links.

## 6. Administrative Query APIs and Security Invariants

- [x] 6.1 Replace capped admin list responses with shared paginated envelopes and server-backed normalized search, status/type/role filters, allow-listed sorting, totals, and stable identifiers for Centers, Access, and Users.
- [x] 6.2 Extend admin response schemas with complete currently available center/requester/user fields and persisted creation/update/approval actor/time metadata; expose reason only if a durable field exists and never synthesize missing audit data.
- [x] 6.3 Make center/access decisions transactionally re-read and protect current state so concurrent decisions produce exactly one commit and one sanitized conflict with no partial related transitions.
- [x] 6.4 Enforce suspended-requester denial for both center and membership approval at commit time, including a requester suspended after the list was loaded.
- [x] 6.5 Enforce independent approval role `professional` server-side regardless of client role and allow only documented institutional roles without altering unrelated memberships.
- [x] 6.6 Enforce last-active-`clinic_admin` protection across user suspension and membership deactivation in every affected active institutional workspace, while preserving self-suspension denial and pending-user lifecycle rules.
- [x] 6.7 Verify clinical authorization never grants access from `platform_admin` alone and no admin list/decision path creates or selects an implicit clinical membership.
- [ ] 6.8 Add backend tests for all admin query combinations and bounds, resolved records, metadata absence, concurrent decisions, suspended requester race, independent role, last clinic admin, self-suspension, terminal rejection, and no implicit clinical access.

## 7. Administrative Mobile Experience

- [x] 7.1 Replace admin top tabs with a root bottom `NavigationBar` ordered Centers, Access, Users and preserve each destination's query, pages, loading/action state, and scroll position.
- [x] 7.2 Extend Flutter admin entities/models/data/domain layers for paginated queries, detailed records, resolved states, available audit metadata, and safe absent fields without bypassing Clean Architecture.
- [x] 7.3 Implement independent generation-guarded controllers for Centers, Access, and Users with search/filter/sort/pagination, atomic refresh, per-resource action state, conflict reconciliation, and auth/query stale-response suppression.
- [x] 7.4 Build responsive compact list cards and near-full-height draggable bottom sheets for center, access, and user details, including safe areas, keyboard insets, long-field access, loading/error states, and translated lifecycle/audit context.
- [x] 7.5 Add the prominent access-only disclaimer to details and confirmations, explicitly excluding identity, documents, titles, licenses, profession, specialty, credentials, and clinical competence verification.
- [x] 7.6 Present Approve as primary and Reject as an outlined red destructive action, require context-specific confirmation, disable repeat submission, and remove illegal actions from resolved/pending states.
- [x] 7.7 Keep resolved center/access/user records searchable and read-only with authoritative outcome and only persisted actor/time/reason values; label or omit unavailable audit data.
- [ ] 7.8 Add admin controller/widget/navigation/accessibility tests for bottom navigation state retention, all list states, full-height sheets, filters/pagination, disclaimers, outlined rejection, resolved records, conflict refresh, late responses, and logout during requests.

## 8. Profile, Account, and Help Center

- [x] 8.1 Complete profile/account data and UI flows with validation, loading, sanitized error, success feedback, session-safe refresh, and responsive/accessible field controls.
- [x] 8.2 Build a functional Help center with navigable/searchable sections for access/workspaces, patients/lesions, observed date versus duration, notes versus findings, one lesion per image, analysis/retry, History, authorization/privacy, disclaimers, common errors, and support/app version.
- [x] 8.3 Update model/decision-support information to distinguish immutable ResNet50 output from the separate feature-gated clinical-priority rules, provenance, limitations, and academic/clinical mode.
- [ ] 8.4 Add account-menu/profile/help widget tests for navigation, actual section links, validation/error/success, workspace-action eligibility, logout delegation, semantics, large text, and support/version display.

## 9. Clinical Priority Governance Inputs and Data Migration

- [ ] 9.1 Draft and review the canonical input catalog for signs, symptoms, risk factors, emergency flags, true/false/unknown semantics, required fields, stable codes, units/time windows, and prohibited diagnostic claims; record sources, owner, and unresolved clinical decisions.
- [x] 9.2 Define a machine-readable immutable ruleset schema and reason-code catalog for `incomplete`, `standard`, `prompt`, `urgent`, and `emergency`, with fixed incomplete/emergency precedence and versioned placeholders for governance-approved weights, thresholds, combinations, and copy.
- [x] 9.3 Add SQLAlchemy models for immutable clinical assessment snapshots and one-to-one priority results with workspace/patient/lesion/evaluation/assessor provenance, canonical structured payload, completion state, category, ordered reason codes/text, ruleset/engine versions, and timestamps.
- [x] 9.4 Create forward and downgrade Alembic revisions with foreign keys, uniqueness/index constraints, PostgreSQL/SQLite compatibility, no backfilled/fabricated priority rows, and a documented non-destructive rollback decision after writes.
- [x] 9.5 Add migration tests for empty and representative legacy databases, unchanged existing evaluation/prediction rows, constraints/indexes, immutable row expectations, and rollback behavior.

## 10. Deterministic Clinical Priority Backend

- [x] 10.1 Implement canonical assessment schemas and validation that distinguish false from unknown, reject unsupported codes/values/client-selected versions, and return stable missing-field codes without partial writes.
- [x] 10.2 Implement a pure server-side evaluator that loads an allow-listed immutable ruleset and deterministically applies confirmed emergency override, incomplete handling, and version-defined urgent/prompt/standard rules with ordered reason codes.
- [x] 10.3 Add a default-off backend feature mode (`disabled`, approved `academic`, or `enabled`) and capability endpoint that publishes mode and active supported ruleset while failing closed for unknown/retired versions.
- [x] 10.4 Implement workspace-authorized assessment/priority creation and retrieval that atomically persists snapshot/result, rejects cross-tenant or platform-admin-only access, and exposes no mutation endpoint for historical rows.
- [x] 10.5 Keep priority contracts and persistence separate from `ModelPrediction`; confirm the evaluator does not read classifier probabilities and `/predict`, model artifacts, preprocessing, labels, thresholds, and existing response fields remain unchanged.
- [x] 10.6 Integrate optional priority metadata into evaluation/history detail contracts without changing historical results when the active ruleset changes and without requiring priority when the feature is disabled.
- [x] 10.7 Add table-driven and property tests for canonicalization, missing/unknown inputs, every category, emergency-over-incomplete precedence where a confirmed emergency exists, threshold boundaries, combinations, determinism, ordered reasons, version immutability, atomic failures, authorization, and feature modes.
- [x] 10.8 Run checksum/inference regression tests proving the approved ResNet50 artifacts and full inference contract are byte/behavior unchanged by clinical-priority work.

## 11. Structured Assessment and Priority Mobile Experience

- [x] 11.1 Add Flutter clinical-assessment/priority entities, models, datasource, repository contracts/implementations, use cases, and generation-guarded controller without calculating priority in the client.
- [x] 11.2 Build a structured assessment flow with accessible grouped signs/symptoms/risk/emergency inputs, explicit unknown state, completion feedback, validation summaries, and preservation in the immutable analysis-attempt snapshot.
- [x] 11.3 Handle server capability modes explicitly: hide/disable safely when disabled, require approved academic support wording in academic mode, render enabled mode only for a supported ruleset, and fail closed on client/server version mismatch.
- [x] 11.4 Render priority separately from ResNet50 with translated category, matched reasons, ruleset/engine/timestamp provenance, neutral incomplete state, and approved non-diagnostic/emergency disclaimers that never state cancer probability.
- [x] 11.5 Extend lesion timeline and History presentation to show the immutable priority result/snapshot provenance associated with each evaluation without recalculating historical records.
- [x] 11.6 Integrate assessment into new-analysis, retry, start-over, workspace switch, patient/lesion change, logout, and stale-response cleanup so no assessment/result crosses context boundaries.
- [ ] 11.7 Add Flutter unit/widget/navigation tests for all capability modes/categories, unknown/required inputs, emergency/incomplete copy, version mismatch, strict model/priority separation, retry snapshot, historical provenance, stale responses, accessibility semantics, and large-text layouts.
- [x] 11.8 Operationalize the academic attention semaphore by aligning the supported draft ruleset, localizing stable reason codes, applying distinct non-color category presentation, and testing every category without deriving priority from ResNet50 confidence.

## 12. Automated Quality and Release Artifact

- [x] 12.1 Run the complete backend suite, migration tests, concurrency/security tests, unchanged-model contract tests, and configured backend formatting/static checks; resolve all regressions and record commands/results.
- [x] 12.2 Run `flutter analyze` plus the complete Flutter unit/widget/integration suite, including root, admin, professional shell, history, assessment, race, and wording regressions; resolve all findings and record commands/results.
- [ ] 12.3 Execute responsive golden/widget/manual-emulator checks across the documented viewport/text-scale matrix for both shells, forms, filters, details, bottom sheets, loading/error states, and keyboard/safe-area behavior.
- [ ] 12.4 Execute automated accessibility checks for semantics, labels, traversal, touch targets, contrast, non-color status/action meaning, focus visibility, and loading/error/result announcements; document remaining manual checks.
- [x] 12.5 Build the versioned release APK and record app version/build, filename, SHA-256, build timestamp, source revision when available, build command, and clean-install instructions without claiming device or production verification.

## 13. Explicit Governance and Validation Gates

- [ ] 13.1 CLINICAL GOVERNANCE GATE: accountable clinical reviewers approve the intended use, final required fields, emergency flags, weights, thresholds, combinations, reason codes/text, limitations, academic/clinical wording, monitoring, rollback criteria, and one frozen ruleset version.
- [ ] 13.2 CLINICAL VALIDATION GATE: execute the preregistered representative validation protocol for the frozen ruleset, record acceptance criteria and subgroup/error analysis, obtain accountable sign-off, and keep enabled clinical mode off if any criterion is unmet.
- [ ] 13.3 PRODUCTION MIGRATION/DEPLOYMENT GATE: back up and migrate the production database, deploy the exact reviewed backend/configuration with feature mode default-off or specifically approved, verify Neon/Cloudinary/readiness and active ruleset identity, and record deployment evidence without secrets.
- [ ] 13.4 PRODUCTION SECURITY/FUNCTIONAL GATE: verify role/root routing, no implicit platform-admin clinical access, tenant isolation, admin invariants/concurrency, history pagination, stale-response handling, feature-mode behavior, and unchanged ResNet50 contract against the deployed environment.
- [ ] 13.5 PHYSICAL DEVICE GATE: clean-install the exact recorded APK and verify institutional/independent access, admin and professional navigation, logout/workspace switching, patient/lesion/analysis/retry/history/account/help flows, camera/gallery, narrow/large-text accessibility, and cold-start behavior on supported real devices.
- [ ] 13.6 CLINICAL RELEASE DECISION GATE: after governance, clinical validation, production, and device evidence are complete, explicitly approve or reject activation of the exact ruleset/mode; never infer approval from automated tests or APK generation.
