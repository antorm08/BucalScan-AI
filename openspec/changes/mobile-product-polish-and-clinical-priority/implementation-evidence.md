# Implementation Evidence

Evidence date: 2026-07-13. Source revision at the start of the final hardening pass: `b29b29500d7d6e5e15170341ee92de32a3aa608a` with a dirty worktree. This file records automated and repository evidence only; it does not claim clinical, production, emulator, APK, or physical-device validation.

## Baseline

- Backend: Python 3.12.10, pytest 8.3.4, `pytest -q` -> 99 passed, one third-party `python_multipart` deprecation warning.
- Flutter: Flutter 3.41.9, Dart 3.11.5, baseline app `1.1.0+3`; `flutter analyze` -> no issues; baseline `flutter test --concurrency=1` -> 193 passed.
- Local database revision before applying the new migration: `0003_legacy_backfill`; repository head revision is `0004_clinical_priority`.
- Approved ResNet50 ONNX SHA-256: `F306E10A5A603788E55AF425439BEF67817ED926872E8A95F418AA7FD9D444DC`.
- Approved ResNet50 external-data SHA-256: `2EFDD0CCB3F0541A0C0B692276C5807F4342A67AF7CADB94C2A58FECBA59D25A`.
- The inference checksum and behavior contract is enforced by `backend/tests/test_inference.py`; no ResNet code or artifact was changed.

## Navigation And Invalidation Inventory

| Concern | Former/direct path | Authoritative path after change |
| --- | --- | --- |
| Startup and login completion | View-owned replacement routes | `BucalScanAiApp` root coordinator observes `authViewModelProvider` and revalidates the session |
| Role/root redirect | Cached role or leaf push | Root coordinator selects login, admin, workspace gate, or professional root |
| Logout | Admin, professional account menu, workspace gate, and profile/detail entry surfaces | `AuthViewModel.logout`, `SessionEvents`, and `resetUserSensitiveState`; coordinator renders login |
| Workspace selection | Gate selection | `ClinicalController.selectWorkspace` and API workspace header |
| Workspace switch | Shell account intent | Confirmation -> nested-stack pop -> `resetWorkspaceSensitiveState` -> guarded gate |
| Patient/lesion navigation | Patients and History links | Shell-owned destination `Navigator` stacks with current-workspace authorization |
| Repeat analysis | Lesion/history action | Shell callback selects patient/lesion, clears transient attempt state, and selects Analizar |
| Async invalidation | Auth, workspace, admin, history, clinical, prediction, and priority requests | Session/workspace generation counters and query keys reject late completions |

The coordinator entry points are authentication state changes for root transitions, `AuthViewModel.logout` for logout, `ClinicalController.selectWorkspace/leaveWorkspace` for workspace context, and shell callbacks for nested clinical navigation. Leaf views do not construct replacement login/admin/professional roots.

## Clinical Contract Inventory

| Data | Active write/read contract | Compatibility path |
| --- | --- | --- |
| Patient | `PatientCreate/PatientResponse`, `Patient`, and `PatientModel`; workspace id, clinical code, identity data, demographics/contact, and notes | `Patient.is_legacy_anonymous` remains persistence-only for migrated rows |
| Legacy analysis patient fields | Not accepted as authoritative prediction input; patient id/name are derived from the selected canonical patient | `Analysis.patient_id/patient_name` remain readable for legacy History and are populated canonically for current records |
| Lesion temporal data | `observed_at` and `estimated_duration` are independent in schemas, entities, models, forms, update, and detail | `temporal_description` is read-only Flutter rollout compatibility |
| Notes/findings | `OralLesion.clinical_notes` is longitudinal; `ClinicalEvaluation.clinical_observations` is attempt-specific | Existing values remain in their original columns |
| Image/prediction | One `LesionImage` and one `ModelPrediction` per `ClinicalEvaluation` | Legacy `Analysis.image_path/prediction/confidence` supports migrated History |
| History links | `evaluation_id`, `patient_record_id`, and `lesion_id` identify canonical records | Legacy analysis id and patient display fields remain nullable/readable |

## Query Contracts

All four list contracts normalize trimmed search, reject non-allow-listed enum/sort input through FastAPI validation, use `page >= 1`, `1 <= page_size <= 100`, and return `items`, `page`, `page_size`, `total`, and `has_next`. Selected sort direction is `asc|desc`; the selected resource id is the stable tie-breaker.

| List | Filters | Sort keys |
| --- | --- | --- |
| Centers | status `pending|active|rejected`; documented non-independent workspace type | `created_at|updated_at|name|status` |
| Access | status `pending|active|rejected|inactive`; role `clinic_admin|professional|assistant`; workspace type including `independent` | `created_at|updated_at|status|role` |
| Users | status `pending|active|suspended`; role `platform_admin|professional|admin|doctor` | `created_at|full_name|email|status|role` |
| History | known model label; optional priority; inclusive UTC `date_from/date_to`; workspace-scoped normalized patient/code search | `evaluated_at|confidence|patient_name|model_version|lesion_site` |

History defaults to descending evaluation/id order. Admin defaults place pending work first and then use descending creation/id order.

## Responsive And Accessibility Matrix

| Matrix case | Automated coverage | Remaining manual coverage |
| --- | --- | --- |
| Narrow phone 320x640 | Home/professional shell/widget tests; large-text variant; touch-target guideline | Camera, keyboard, OS safe areas, screen reader, visible focus, contrast observation |
| Standard phone 390x844 | Home and shell/widget layout checks | Emulator gestures, keyboard/insets, TalkBack/VoiceOver |
| Tablet 768x1024 | Home responsive branch and admin sheet/widget checks | Device rotation, split screen, hardware keyboard |
| Large text 1.6x | Home, shell, Help, priority controls | Maximum OS scales and real-device font rendering |
| Keyboard/insets | Scrollable forms and draggable sheets are structurally covered | Open-keyboard emulator observation |
| Semantics/traversal | Named account, logout, assessment, filter, retry, and destructive actions; semantic widget assertions | Full screen-reader traversal and announcement cadence |
| Touch targets | Flutter Android tap-target guideline on representative Home actions | Platform/device verification |
| Contrast/non-color | Text/icon status labels are asserted for unknown, error, resolved, and destructive states | Instrumented contrast audit and visual focus verification |

Tasks 12.3 and 12.4 remain unchecked because automated widget coverage is partial and no manual emulator/device evidence was performed.

## Quality Runs

Initial final-hardening baseline:

- `cd backend; pytest -q` -> 99 passed in 19.86s.
- `cd frontend; flutter analyze` -> no issues in 10.3s.
- `cd frontend; flutter test --concurrency=1` -> 193 passed.

Final command results are recorded below after the hardening changes are verified.

Final hardening results:

- `cd backend; pytest -q` -> 102 passed in 25.21s; one third-party `python_multipart` deprecation warning. This includes migration, admin/security, tenant, priority, and unchanged-inference tests. The repository has no separately configured Python formatter/static-check command.
- `cd frontend; flutter analyze` -> no issues in 12.7s.
- `cd frontend; flutter test --concurrency=1` -> 204 passed in 81s.

## Release APK

- Build command: `flutter build apk --release`.
- Version: `1.2.0+4` (`versionName=1.2.0`, `versionCode=4`).
- File: `frontend/build/app/outputs/flutter-apk/app-release.apk`.
- Size: `56,522,548` bytes (`53.9 MB`).
- SHA-256: `229BB72B3F4C2B0D23DBFA3E10AEF1DAD87E3147037DE00E3D01CA143C887A04`.
- Build timestamp: `2026-07-13 12:42:03` local workspace time.
- Source revision at build: `b29b29500d7d6e5e15170341ee92de32a3aa608a` with the documented dirty worktree.
- Clean-install guidance: uninstall prior builds when diagnosing retained secure-storage/session state, install this exact APK, and verify version `1.2.0` before testing.

APK generation is recorded evidence only; no installation, production connectivity, camera/gallery, or physical-device behavior is claimed.

## Explicit Open Evidence

- The release APK was built and recorded, but has not been installed or verified on a physical device.
- No manual emulator responsive/accessibility run was performed; tasks 12.3 and 12.4 remain open despite their documented automated subset.
- No clinical governance, clinical validation, production deployment/security run, physical-device run, or release decision was performed; all section 13 gates remain open.
