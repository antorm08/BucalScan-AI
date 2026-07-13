# Migration and deployment

## Safety workflow

1. Back up the target PostgreSQL database and run `scripts/neon/00_baseline.sql` read-only.
2. Install pinned dependencies and validate `alembic upgrade head` plus downgrade on disposable SQLite and PostgreSQL databases.
3. Set `DATABASE_URL` to a non-secret, dialect-only PostgreSQL URL and run `alembic upgrade head --sql > scripts/neon/10_migrate.generated.sql`. Offline mode does not connect. Review the transaction-wrapped output through the current head revision, including `0004_clinical_priority`, and store it without credentials.
4. The project owner manually executes the reviewed SQL in Neon. The application never runs migrations at startup.
5. Run `scripts/neon/20_verify.sql`. User and analysis counts must equal the recorded baseline, normalized prediction/evaluation counts must equal analysis count, and all orphan/invalid queries must return zero.
6. Deploy only after verification. Before cutover, `scripts/neon/30_rollback.sql` or Alembic downgrade can remove normalized structures while preserving legacy `users` and `analyses`. After normalized writes begin, use a forward fix rather than rollback.

The repository does not contain a Neon URL or credentials. Do not run migration tests against production.

## Compatibility and limitations

Legacy users remain able to authenticate because the migration preserves password hashes, marks them active, and maps `admin` to `platform_admin` and `doctor` to `professional`. Legacy analysis columns remain readable and each analysis is linked to one normalized evaluation and immutable prediction. Analyses without patient metadata use an explicit legacy anonymous patient.

This academic phase provides decision support, not diagnosis. It does not include patient accounts, signatures, private Cloudinary delivery, retention automation, referrals, reports, notifications, billing, license verification, or model retraining. Cloudinary URLs are not private and Render cold starts remain possible.

## Render and local use

Production requires `ENVIRONMENT=production`, a PostgreSQL `DATABASE_URL`, complete Cloudinary credentials, the approved ResNet50 files, and a strong `JWT_SECRET`. Build with `pip install -r requirements.txt`, migrate manually before deployment, and start with `uvicorn main:app --host 0.0.0.0 --port $PORT`. Configure the liveness probe as `/live` and readiness as `/ready`.

For revision `0004_clinical_priority`, run `alembic current`, then `alembic upgrade head`, and confirm that `alembic current` reports `0004_clinical_priority (head)`. Until both priority tables exist, `/ready` returns `503` and history or lesion-detail requests from the matching application release must not be served.

Local development uses `ENVIRONMENT=development` and SQLite. Initialize it with `alembic upgrade head`; tests may use isolated `Base.metadata.create_all()` databases. Filesystem image fallback is development-only.
