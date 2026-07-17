## Why

The active prediction flow stores the same result in both the legacy `analyses` table and the normalized clinical schema. History and summary queries still depend on the duplicate row, creating two sources of truth and making normalized evaluations incomplete without legacy data.

## What Changes

- Make `clinical_evaluations`, `lesion_images`, and `model_predictions` the source of truth for new predictions.
- Read history, filters, sorting, and daily summaries exclusively from the normalized clinical schema.
- Preserve current API response contracts while replacing their persistence source.
- Stop writing new rows to `analyses` after normalized consumers are in place.
- Retain existing legacy rows for rollback and define production verification as the gate for a later destructive migration.
- Cover normalized writes, history, summaries, legacy backfill, and authorization with regression tests.

## Capabilities

### New Capabilities
- `normalized-analysis-persistence`: Persist and query analysis results through the normalized clinical schema without an active dependency on `analyses`.

### Modified Capabilities

None.

## Impact

- Backend prediction, history, and dashboard summary queries.
- SQLAlchemy runtime consumers and existing Alembic backfill verification.
- Existing history API contracts and migration verification.
- PostgreSQL/Neon and SQLite test databases.
