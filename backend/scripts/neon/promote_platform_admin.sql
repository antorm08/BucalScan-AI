-- Replace the value once, then execute in a transaction. Password data is never touched.
BEGIN;
DO $$
DECLARE target_email text := 'replace-me@example.com'; matches integer;
BEGIN
  SELECT COUNT(*) INTO matches FROM users WHERE lower(email)=lower(target_email);
  IF matches <> 1 THEN RAISE EXCEPTION 'Expected exactly one user for %, found %', target_email, matches; END IF;
  UPDATE users SET role='platform_admin', status='active' WHERE lower(email)=lower(target_email);
END $$;
COMMIT;
