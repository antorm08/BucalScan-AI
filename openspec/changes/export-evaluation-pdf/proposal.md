## Why

Professionals need a portable, consistent summary of a persisted lesion evaluation without manually transcribing model and clinical data. A server-generated PDF makes the report reproducible, workspace-authorized, and easy to share while preserving the distinction between technical model output and clinical diagnosis.

## What Changes

- Add an authenticated, workspace-scoped endpoint that generates a PDF for one persisted evaluation.
- Include patient clinical code, lesion site, evaluation date, source image, optional CAM, model output and provenance, recorded findings, professional, priority guidance when available, and explicit non-diagnostic wording.
- Keep PDF generation available when the CAM is absent or cannot be loaded.
- Add a Flutter action on each lesion evaluation that downloads the PDF and invokes the platform share/export sheet with local progress and controlled errors.
- Add backend and Flutter coverage for authorization, report contents, optional images, byte transport, and export interaction.

## Capabilities

### New Capabilities
- `evaluation-pdf-export`: Authorized generation and client export of a portable, non-diagnostic evaluation report.

### Modified Capabilities

None.

## Impact

- Backend: clinical routing, a PDF report service, tests, and a ReportLab runtime dependency.
- API: new binary-response endpoint under a lesion and evaluation resource.
- Flutter: byte-response support, clinical repository/use case integration, an injectable sharing service, lesion-detail UI, tests, and a sharing dependency.
- Persistence: no database schema or migration changes.
- Deployment: modest additional package size and transient memory use while composing a report; no durable PDF storage.
