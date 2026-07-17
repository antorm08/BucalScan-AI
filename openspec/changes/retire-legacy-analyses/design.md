## Context

The prediction transaction currently writes a normalized evaluation, image, model prediction, and consent record, then duplicates selected values in `analyses`. History and daily summary endpoints join from that duplicate table, so a valid normalized evaluation is not visible unless the compatibility write also succeeds. Migration `0003` already backfilled legacy rows into the normalized schema and linked each legacy row through `evaluation_id`.

The history response is consumed by Flutter and its field names and value types must remain stable. PostgreSQL/Neon is the production target, while tests also run against SQLite.

## Goals / Non-Goals

**Goals:**

- Use normalized clinical tables as the only runtime source of truth for prediction history and summaries.
- Stop creating duplicate `analyses` rows.
- Preserve history and summary HTTP contracts, workspace isolation, filtering, sorting, pagination, and image URL rendering.
- Preserve existing legacy rows until a later destructive migration is independently authorized.
- Prove that new predictions work when no matching `analyses` row exists.

**Non-Goals:**

- Delete historical data in this change.
- Change the classifier, clinical priority rules, or Flutter response models.
- Rework unrelated user administration queries.

## Decisions

### Query from the normalized aggregate

History will start from `clinical_evaluations` and join its patient, lesion, professional, image, and model prediction. Priority remains optional. This makes the complete normalized transaction independently queryable and removes the legacy join requirement.

Alternative considered: continue joining `analyses` only for old rows. This retains two read paths and is unnecessary because migration `0003` normalized old records.

### Preserve the API shape

History fields will be populated from canonical columns: patient code/name from `patients`, prediction values from `model_predictions`, image URL from `lesion_images`, and timestamps from the evaluation/prediction. The response `id` will use the evaluation identifier, which is stable, workspace-scoped, and already exposed as `evaluation_id`.

Alternative considered: expose the model prediction identifier. The evaluation is the aggregate root used by detail, PDF, and longitudinal workflows, so it is the safer public identity.

### Keep the physical legacy table temporarily

The SQLAlchemy legacy model and table remain present only to support historical migrations and a safe rollback window. Runtime routers and CRUD helpers will neither read nor write it. A later destructive migration may drop it after production verification confirms no external consumers and complete normalized coverage.

Alternative considered: drop or rename `analyses` in the same release. That can break the previous application version while a deployment is switching over and makes rollback unsafe.

### Summaries use prediction creation time

Daily counts will aggregate `model_predictions.created_at`, scoped through `clinical_evaluations.workspace_id`. This is the normalized equivalent of the old analysis creation timestamp and avoids counting evaluations without a completed model result.

## Risks / Trade-offs

- [Historical rows were not normalized correctly] -> Keep `analyses` intact and add regression coverage for the `0003` backfill before any later destructive migration.
- [History identifiers differ from legacy analysis IDs] -> Preserve the integer response contract and use the already-public evaluation aggregate identifier; Flutter uses this field only as a list identity.
- [Timestamp behavior shifts slightly] -> Use prediction creation time for `timestamp` and summary day boundaries, while retaining `evaluated_at` for clinical chronology.
- [Legacy table remains visible] -> Treat it as retained rollback data, with zero runtime consumers, and schedule physical removal separately after production verification.

## Migration Plan

1. Deploy normalized readers while the legacy table still exists.
2. Stop compatibility writes in the same application release.
3. Verify production history and summary behavior and confirm new predictions create no `analyses` rows.
4. In a later independently reviewed change, verify normalized coverage and drop the legacy table.

Rollback restores the previous application without requiring a database rollback because the legacy table is retained. Predictions created after this release will not have compatibility rows, so rollback must be accompanied by a backfill or avoided after new writes begin.

## Open Questions

None.
