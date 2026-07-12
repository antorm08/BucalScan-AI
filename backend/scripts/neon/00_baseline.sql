-- Read-only preflight. Record this output before migration and compare after verification.
SELECT current_database() AS database_name, current_schema() AS schema_name;
SELECT COUNT(*) AS baseline_users FROM users;
SELECT COUNT(*) AS baseline_analyses FROM analyses;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = current_schema() AND table_name IN ('users', 'analyses')
ORDER BY table_name, ordinal_position;
