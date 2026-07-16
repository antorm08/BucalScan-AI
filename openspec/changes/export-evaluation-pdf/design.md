## Context

BucalScan AI persists evaluation, lesion image, CAM, prediction provenance, professional, findings, and optional academic priority data. Flutter can display that data but currently has no binary-download or share path. Reports contain sensitive clinical data, so generation must reuse bearer authentication and active-workspace authorization and must not create permanent server-side files.

## Goals / Non-Goals

**Goals:**
- Generate a deterministic Spanish PDF from persisted canonical evaluation records.
- Preserve safe semantics: confidence is technical classifier confidence, CAM is explanatory only, and the report is not a diagnosis or cancer probability.
- Include source image and CAM opportunistically without making either remote asset a report availability dependency.
- Export from each evaluation card through the platform share sheet with isolated progress and safe failures.
- Keep the endpoint tenant-scoped and return `404` for mismatched lesion/evaluation/workspace resources.

**Non-Goals:**
- Persisting generated PDFs or adding database tables.
- Producing comparison, batch, signed, or legally certified reports.
- Replacing clinical records, adding a professional override, or introducing new recommendations inferred from confidence.
- Supporting arbitrary PDF customization or user-authored templates.

## Decisions

### Generate the PDF in FastAPI with ReportLab

The backend owns the canonical data, authorization, report wording, and layout. ReportLab adds modest runtime weight and can write directly to memory. Client-side PDF generation was rejected because it would duplicate report semantics and remote-image handling across platforms.

### Scope the endpoint beneath lesion and evaluation

`GET /api/v1/lesions/{lesion_id}/evaluations/{evaluation_id}/report.pdf` will use the existing workspace-access dependency and query all identifiers together. This makes the resource relationship explicit and prevents an evaluation from another lesion or workspace being exported.

### Compose reports in memory and treat images as optional

The service will return PDF bytes from a `BytesIO` buffer. Local upload paths will be read from the configured upload directory by basename; HTTPS assets will be accepted only from the configured Cloudinary delivery host, without redirects, and fetched with a short timeout and bounded size. Failures will omit the affected image and add a neutral unavailable note rather than fail the entire report. No generated file will be retained on the server.

### Use persisted priority guidance as the recommendation section

When an academic priority result exists, its code and rendered reasons will be included as orientative guidance with provenance. Otherwise the report will state that no academic orientation was recorded. The implementation will not reconstruct or persist a medical recommendation from the model label.

### Download bytes through the existing authenticated API service

Flutter will add a `getBytes` method using Dio `ResponseType.bytes` and workspace options. The clinical repository and a small use case will expose this without leaking Dio into presentation code.

### Share bytes through an injectable service

An injectable service around `share_plus` will write the bytes to an application-owned temporary report directory, export a file named only with the evaluation ID, and delete the current temporary file when the share action returns while purging stale report files. It will receive the originating button bounds required by iPad popovers. Each evaluation card will track its own in-flight export and discard completion after a workspace change so unrelated actions remain available and sensitive bytes do not cross context boundaries. Widget tests replace the platform adapter through Riverpod.

## Risks / Trade-offs

- [Remote image latency or failure] -> Use short timeouts, bounded reads, image preprocessing, and graceful omission.
- [Sensitive report shared outside the application] -> Require authenticated workspace access for generation, avoid identity-document fields and patient names in filenames, and rely on an explicit user-initiated platform share action.
- [Confidence mistaken for diagnosis] -> Label it as technical classifier confidence and include prominent non-diagnostic wording.
- [ReportLab increases the Render artifact] -> Pin the dependency and keep generation synchronous and bounded; the package is substantially smaller than model dependencies already deployed.
- [Platform share behavior varies] -> Isolate the plugin behind a service and treat dismissal as neither an application error nor a guaranteed save.
- [Large source images increase memory] -> Cap downloaded bytes and resize images before embedding.

## Migration Plan

1. Deploy the backend dependency, service, route, and tests; no database migration is required.
2. Deploy Flutter byte transport and export action after the endpoint is available.
3. Roll back by removing the client action and endpoint; no persisted data needs cleanup.

## Open Questions

None. The first version exports only from the lesion timeline and only one evaluation per report.
