-- ============================================================
--  Atomic base-permission roles (NOLOGIN)
--  - These cap_* roles are ATOMIC and NOLOGIN
--  - No users created here
--  - No superuser powers
-- ============================================================

-- For convenience, revoke PUBLIC where appropriate
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- (Optional) also lock down your business schemas
-- REVOKE ALL ON SCHEMA auth, exam, grading FROM PUBLIC;

-- ------------------------------
-- 0) Common helpers (one-time)
-- ------------------------------
-- Ensure supporting schemas exist for grants below
CREATE SCHEMA IF NOT EXISTS admin;
CREATE SCHEMA IF NOT EXISTS audit;

-- If you frequently create new tables/functions, set safe defaults for future objects.
-- We'll attach default privileges AFTER we create each cap_* role.

-- ============================================================
-- 1) Atomic Role: cap_read
--    - SELECT rows
--    - NO INSERT/UPDATE/DELETE
--    - NO_LOGIN
-- ============================================================
CREATE ROLE cap_read NOLOGIN;

GRANT USAGE ON SCHEMA auth, exam, grading TO cap_read;
GRANT SELECT ON ALL TABLES    IN SCHEMA auth, exam, grading TO cap_read;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA auth, exam, grading TO cap_read;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT SELECT ON TABLES    TO cap_read;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT SELECT ON SEQUENCES TO cap_read;

-- ============================================================
-- 2) Atomic Role: cap_write
--    - INSERT/UPDATE rows
--    - No DELETE
--    - inherits cap_read permissions
-- ============================================================
CREATE ROLE cap_write NOLOGIN IN ROLE cap_read;

GRANT INSERT, UPDATE ON ALL TABLES IN SCHEMA auth, exam, grading TO cap_write;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth, exam, grading TO cap_write;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT INSERT, UPDATE ON TABLES TO cap_write;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT USAGE ON SEQUENCES      TO cap_write;

-- ============================================================
-- 3) Atomic Role: cap_delete
--    - DELETE rows
--    - but only for business schema (exam, grading)
-- ============================================================
CREATE ROLE cap_delete NOLOGIN;

GRANT DELETE ON ALL TABLES IN SCHEMA auth, exam, grading TO cap_delete;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT DELETE ON TABLES TO cap_delete;

-- ============================================================
-- 4) Atomic Role: cap_exec
--    - EXECUTE functions
-- ============================================================
CREATE ROLE cap_exec NOLOGIN;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth, exam, grading TO cap_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT EXECUTE ON FUNCTIONS TO cap_exec;

-- ============================================================
-- 5) Atomic Role: cap_read_logs
--    - Assumes logs data saved in views/tables under `audit` schema
--    - Does NOT grant access to other business tables
-- ============================================================
CREATE ROLE cap_read_logs NOLOGIN;

GRANT USAGE ON SCHEMA audit TO cap_read_logs;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO cap_read_logs;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
  GRANT SELECT ON TABLES TO cap_read_logs;

-- ============================================================
-- 6) Atomic Role: cap_monitor
--    - Access to pg_stat_* and pg_stat_statements
--    - No SELECT on business schemas
-- ============================================================
CREATE ROLE cap_monitor NOLOGIN;

GRANT CONNECT ON DATABASE exam_sys TO cap_monitor;
GRANT pg_read_all_stats TO cap_monitor;
GRANT USAGE ON SCHEMA pg_catalog, information_schema TO cap_monitor;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') THEN
    GRANT SELECT ON pg_stat_statements TO cap_monitor;
  END IF;
END$$;

-- ensure monitor role has no rights on business schemas
REVOKE ALL ON ALL TABLES    IN SCHEMA auth, exam, grading FROM cap_monitor;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA auth, exam, grading FROM cap_monitor;

-- ============================================================
-- 7) Atomic Role: cap_connect
--    - allow CONNECT
-- ============================================================
CREATE ROLE cap_connect NOLOGIN;
GRANT CONNECT ON DATABASE exam_sys TO cap_connect;

-- ============================================================
-- 8) Atomic Role: cap_catalog_read
--    - Metadata-only / catalog-read
--    - View definitions but not data
-- ============================================================
CREATE ROLE cap_catalog_read NOLOGIN;
GRANT USAGE ON SCHEMA information_schema, pg_catalog TO cap_catalog_read;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO cap_catalog_read;

-- ============================================================
-- 9) Atomic Role: cap_ddl
--    - Controlled DDL via admin.safe_alter
-- ============================================================
CREATE ROLE cap_ddl NOLOGIN;
GRANT CREATE, USAGE ON SCHEMA auth, exam, grading TO cap_ddl;

-- Ensure admin helper exists for controlled DDL
CREATE OR REPLACE FUNCTION admin.safe_alter(q text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  EXECUTE q;
END;
$$;
REVOKE ALL ON FUNCTION admin.safe_alter(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin.safe_alter(text) TO cap_ddl;
