## Context

BucalScan AI is a Flutter/Riverpod client backed by FastAPI, SQLAlchemy, Alembic, Neon/PostgreSQL, and Cloudinary. Existing unarchived changes established role/workspace lifecycles, tenant-scoped patient and lesion records, a standalone platform-admin root, immutable predictions, and an unchanged ResNet50 inference contract. The current implementation still has multiple widgets performing logout navigation, a five-item professional bar plus drawer, admin lists capped and filtered in memory, weak nested-route ownership, legacy clinical fields, and history presentation that can classify unknown model labels as benign.

The current schema already separates `OralLesion.observed_at` from `estimated_duration`, evaluation observations from lesion notes, and each evaluation from its single image/prediction. It also has approval actor/time fields for workspaces and memberships, but no general decision-reason/audit-event table. The implementation must use those facts rather than create misleading UI. Product, security, clinical, accessibility, and release stakeholders all need explicit evidence boundaries: automated checks do not prove production behavior, physical-device behavior, or clinical validity.

## Goals / Non-Goals

**Goals:**

- Give authentication, role/root routing, logout, workspace switching, and draft cleanup one authoritative coordinator.
- Provide distinct persistent mobile shells for platform administration and professional work, with nested patient/lesion routes retaining the professional shell.
- Make admin and history lists scalable through server-owned search, filters, deterministic sort, and cursor- or page-based pagination.
- Improve clinical data semantics, analysis state, account/help flows, responsive behavior, accessibility, and non-diagnostic wording.
- Add a versioned deterministic clinical-priority subsystem with structured inputs, emergency override, immutable provenance, stable reason codes, governance, and controlled rollout.
- Preserve tenant isolation, async race protection, legal lifecycle transitions, release traceability, and the immutable ResNet50 contract.

**Non-Goals:**

- Retraining, replacing, recalibrating, or changing ResNet50 preprocessing, labels, thresholds, probabilities, artifacts, or response semantics.
- Diagnosing disease, estimating cancer probability, replacing professional judgment, or claiming clinically validated triage before governance evidence exists.
- Documentary verification of titles, licenses, specialties, identity, or institutional claims; administration approves access only.
- Adding patient accounts, referrals, notifications, billing, a general audit-event platform, or an admin web application.
- Deleting historical data solely because legacy fields disappear from active forms and DTOs.
- Treating automated tests or a successful build as proof of production deployment, physical-device acceptance, or clinical validation.

## Decisions

### 1. A session/root coordinator is the only navigation authority

Authentication state drives a top-level state machine: startup -> unauthenticated -> authenticated role resolution -> admin root or professional workspace gate -> professional root. Views request logout or workspace change but never push a login/root page themselves. Logout first invalidates the session generation, clears token/header and all user/workspace/draft providers, and then lets the root coordinator render login. Role and account status are revalidated rather than inferred from a stale route.

Workspace switching is a root transition, not a detail-view navigation action. A confirmed switch invalidates request generations, clears active workspace headers, selected patient/lesion, unsaved analysis/form drafts, image, attestation, current result, and workspace caches, pops nested routes, and returns to the gate. Persisted patients, lesions, evaluations, images, and predictions remain untouched, and confirmation text states that saved records remain. The switch action is hidden when the user has only one active workspace.

Alternative considered: retain `Navigator.pushAndRemoveUntil` in every root view. Rejected because concurrent widgets can race session mutation and navigation, producing duplicate routes or a black screen.

### 2. Separate shells own stable bottom navigation and nested stacks

The professional shell has exactly four destinations in this order: Inicio, Pacientes, Analizar, Historial. Profile, account actions, workspace controls, help, model information, and logout live in an accessible top account menu. Patient and lesion details are pushed inside the Pacientes branch (or equivalent shell-owned router), so bottom navigation and account access remain present. Repeat analysis selects the existing patient and lesion, resets only the new-attempt state, and selects Analizar through the shell controller.

The admin shell has exactly Centers, Access, and Users in a bottom `NavigationBar`. Each destination retains its query and scroll state while details open as draggable, safe-area-aware, near-full-height bottom sheets. Root guards prevent platform admins from entering clinical routes without an explicit active clinical membership; the global platform role alone never implies clinical access.

Alternative considered: drawers and top tabs. Rejected because primary destinations are hidden or crowded on mobile and nested pages currently reconstruct or lose the root shell.

### 3. Server-owned list queries use one deterministic contract

Admin and history endpoints accept normalized search, allow-listed filters, inclusive date boundaries expressed in UTC, allow-listed sort key/direction, and bounded page size. Responses include items plus pagination metadata (`page`, `page_size`, `total`, `has_next`) and a stable tie-breaker by identifier. Default ordering prioritizes pending admin work then newest creation time; history defaults to evaluation time descending then identifier descending.

Every query carries auth session generation and, for clinical history, workspace identity. Changing query criteria or refreshing supersedes earlier generations; late responses and page appends are discarded if context or query key changed. Refresh replaces pages atomically and an action refreshes the affected item/list/count without clearing another destination's current data.

Alternative considered: download up to 500 records and filter in Flutter. Rejected for stale totals, memory use, inconsistent ordering, and inability to scale.

### 4. Admin details expose facts, access semantics, and legal actions

Summary cards remain compact; tapping one opens a full-height sheet with all available requester/resource fields, lifecycle status, creation/update times, and existing approval actor/time metadata. The UI never invents unavailable audit values. A decision reason is collected and shown only when the deployed API/schema durably supports it; this change does not introduce a general audit table. Resolved records remain searchable/read-only and show their outcome and available metadata.

Every decision says it verifies access only, not identity, credentials, documents, title, license, profession, specialty, or clinical competence. Reject is an outlined red action separated from the primary approval action. Sensitive actions require a context-specific confirmation and disable duplicate submission.

Backend transactions re-read current rows and enforce: suspended requester denial; independent access role fixed to `professional`; allow-listed institutional roles; last active `clinic_admin` protection; no self-suspension; no implicit platform-admin membership; terminal rejection; and conflict on already-resolved state. Actor/time fields already present are populated where applicable. UI optimistic state never overrides a newer server response.

Alternative considered: optimistic local lifecycle transitions. Rejected because concurrent administrators can resolve the same request and only the database transaction is authoritative.

### 5. Active clinical contracts remove ambiguity without deleting history

Active patient forms and DTOs stop asking for dead legacy-only fields; compatibility columns remain readable for migrated records until a separately approved removal. Lesion creation/editing displays observed date and estimated duration as independent optional values with distinct help text. Lesion notes describe the longitudinal/current lesion record; evaluation findings describe what the professional observed in that specific assessment. Copy explains the distinction at entry and display.

One evaluation accepts exactly one lesion and one image. A different lesion or additional image creates a separate evaluation/analysis attempt. Backend validation rejects ambiguous multi-lesion/multi-image payloads. Lifecycle and model statuses are translated through exhaustive mappings; unknown values render a neutral “Unknown/not available” state and never inherit benign, success, or low-priority styling.

Alternative considered: combine temporal values and note fields for shorter forms. Rejected because it loses provenance and confuses changing findings with longitudinal context.

### 6. Analysis is an explicit attempt state machine

The analysis controller owns `idle`, `contextReady`, `imageReady`, `submitting`, `succeeded`, and `failed` states. Starting a new analysis or retry clears prior transient error/result/progress while preserving the intended patient/lesion context. Retry snapshots and reuses the failed attempt's workspace, patient, lesion, image, assessment, and attestation unless the user explicitly starts over. Duplicate submission is blocked.

Model labels and confidence remain model output only. Result presentation translates known labels, renders unknown neutrally, and uses decision-support wording that does not describe confidence as cancer probability or diagnosis. Clinical priority, when present, is a separate card with its own provenance and disclaimer.

Alternative considered: append priority into the prediction label/response. Rejected because it would conflate two independently versioned systems and alter the immutable inference contract.

### 7. History links records instead of becoming a second chart

History supports debounced patient/code search, known model-label filter, clinical-priority filter when enabled, date range, sort order, pagination, pull-to-refresh, retry, and clear-filter states. Each item and detail sheet uses safe wording and guarded links to the owning patient and lesion inside the professional shell. The backend authorizes all identifiers under the active workspace; stale links show a safe unavailable state rather than crossing tenants or leaving the shell.

Alternative considered: client-only filtering of the current page. Rejected because it produces incorrect empty states and totals.

### 8. Account/help are functional product surfaces

The top account menu opens profile/account, help, model/decision-support information, workspace switching when applicable, and logout. Profile edits retain layered architecture, field validation, loading/error/success states, and session-safe refresh. Help provides task-oriented guidance for access/workspaces, patients and lesions, one-lesion-per-image capture, analysis and retry, history, disclaimers, privacy/authorization, common errors, and support/version information; search or an index navigates to actual sections rather than placeholder actions.

Alternative considered: retain Profile as a fifth primary destination. Rejected because it displaces frequent clinical work and conflicts with the confirmed four-item navigation.

### 9. Clinical priority is a separate deterministic bounded context

`ClinicalAssessmentSnapshot` stores a versioned immutable copy of structured tri-state/enum inputs, free-text context only where explicitly allowed, completion status, assessor, workspace/patient/lesion/evaluation references, and assessment time. Input groups cover signs (for example ulceration, induration/fixation, unexplained bleeding, red/white change, rapid growth), symptoms (pain, dysphagia, altered sensation, functional limitation, persistence), risk factors (tobacco, alcohol, prior oral malignancy, immunosuppression), and emergency flags (airway compromise, uncontrolled bleeding, inability to swallow, or rapidly progressing face/neck swelling). “Unknown/not assessed” is distinct from false.

`ClinicalPriorityResult` is immutable and one-to-one with the snapshot. It stores priority code, stable reason codes, rendered reasons, ruleset identifier/version, evaluated time, and engine version. It does not store or expose a diagnosis, malignancy label, or cancer probability. It is related to an evaluation but not embedded in `ModelPrediction`; priority computation neither reads nor changes ResNet50 probabilities in the initial ruleset.

The draft `clinical-priority-v1` evaluates in this order:

1. Return `incomplete` with missing-field reason codes when required fields are unknown/unanswered.
2. Return `emergency` if any emergency flag is true, regardless of other answers.
3. Compute a declared concern score from version-controlled input weights; return `urgent` for the governance-approved high threshold or an approved high-concern combination.
4. Return `prompt` for the approved middle threshold, persistence-plus-concerning-sign combination, or equivalent approved rule.
5. Return `standard` when complete and no higher rule matches.

Exact weights, thresholds, required fields, combinations, copy, and reason-code catalog live in an immutable ruleset fixture reviewed by clinical governance, not in UI code. Evaluation is pure and deterministic: identical canonical snapshots plus ruleset version produce identical code/reasons. Emergency override and incomplete precedence are fixed architectural invariants; draft medical thresholds remain disabled until approved.

Alternative considered: let the neural-network confidence determine priority. Rejected because classifier confidence is not calibrated clinical risk, would imply cancer probability, and violates model separation.

### 10. Governance and rollout are enforced, not just documented

The backend owns a default-off feature flag and allow-listed active ruleset version. Before clinical validation approval, production either hides the feature or labels it explicitly as academic decision-support according to the approved deployment mode. The API rejects an unknown, retired, or client-selected ruleset version; the server records the actual active version. Governance evidence must define intended use, reviewers, source rationale, test corpus, acceptance criteria, known limitations, wording, monitoring, and rollback decision.

Automated unit/property tests prove determinism, precedence, serialization, authorization, and migration behavior but cannot mark clinical validation complete. Clinical governance/validation and production enablement remain unchecked gates.

Alternative considered: ship enabled with a disclaimer alone. Rejected because a disclaimer does not establish clinical validity or control version activation.

### 11. Accessibility, responsiveness, and release evidence are first-class

Layouts are tested at narrow phone, standard phone, large text, and tablet widths without clipped controls or inaccessible sheets. Interactive controls have semantic labels, logical focus/traversal order, minimum touch targets, visible focus, sufficient contrast, non-color status cues, keyboard support where applicable, and screen-reader announcements for loading/errors/results without duplicate chatter. Bottom sheets respect safe areas and keyboard insets.

The release task builds a versioned APK and records application version/build, filename, SHA-256, build timestamp, source revision when available, and clean-install instructions. Installing it on a physical device, checking production, and validating clinical behavior remain separate unchecked gates.

## Risks / Trade-offs

- [A root transition races an old request] -> Invalidate session/workspace generations before clearing storage or rendering the next root and reject all mismatched completions.
- [Nested navigation becomes complex] -> Keep one shell-owned stack per destination and test back/deep-link/repeat-analysis behavior rather than letting leaf views construct roots.
- [Offset pagination changes while data is updated] -> Apply stable tie-break ordering, refresh after mutations, and never append pages from a superseded query.
- [Admin details imply unavailable audit evidence] -> Display only persisted actor/time/reason fields and label unavailable metadata honestly.
- [Legacy fields are still needed by migrated rows] -> Remove them from active write contracts but retain compatibility reads and postpone destructive migration.
- [Priority rules create false reassurance or alarm] -> Default off, preserve `incomplete`, prioritize explicit emergency override, use non-diagnostic copy, and require clinical governance before activation.
- [Rules evolve after records exist] -> Persist canonical snapshots and result/ruleset versions; never recalculate historical results in place.
- [Feature flag creates divergent UI/API states] -> Server publishes capability/ruleset metadata and Flutter handles disabled, academic, enabled, and unsupported states explicitly.
- [Automated accessibility checks miss device issues] -> Keep physical-device accessibility and release checks open until observed.

## Migration Plan

1. Capture baseline schema/counts and ResNet50 hashes; add an Alembic revision for immutable assessment snapshots and priority results with foreign keys, indexes, ruleset/version fields, stable JSON serialization, and downgrade SQL that refuses destructive rollback after production writes unless explicitly approved.
2. Deploy backward-compatible admin/history pagination and capability-metadata endpoints while retaining current clients during rollout.
3. Add the server-side default-off priority engine and draft versioned fixture; run deterministic, migration, tenant, lifecycle, and unchanged-model regression suites.
4. Release Flutter root coordination and shells, then admin/history/detail/account/help and structured assessment UI behind server capability detection.
5. Complete automated backend, Flutter, responsive, accessibility, and APK-build checks and record the release artifact identity.
6. Obtain clinical governance approval for a specific ruleset/copy and execute the predefined clinical validation protocol before enabling non-academic use.
7. Deploy production backend/migration and enable only the approved mode/version; verify telemetry and rollback controls without changing historical snapshots/results.
8. On rollback, disable the feature flag first and roll back the client if needed. Retain immutable assessment/priority rows; prefer a forward fix after writes rather than destructive downgrade.

## Open Questions

No product-scope questions remain. The exact clinically approved required fields, weights, combinations, thresholds, reason text, intended-use claim, and validation acceptance criteria are governance deliverables and remain open release gates, not implementation guesses. Production deployment, physical-device verification, and clinical validation must remain unchecked until evidence is recorded.
