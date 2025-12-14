--                        +--------------------+
--                        |   app_reader_base  |  (NOLOGIN: USAGE+SELECT)
--                        +--------------------+
--                                 ^
--                                 |
-- +--------------------+          |         +--------------------+
-- |   app_writer_base  |----------+-------->|   app_exec_base    | (USAGE on schema; EXECUTE on funcs)
-- +--------------------+                    +--------------------+
--         ^
--         | inherits
--         |
-- +---------------------------+     +--------------------+     +------------------+
-- |   app_user_r   (LOGIN)    |     | app_user_rw (LOGIN)|     | report_user (...)|
-- +---------------------------+     +--------------------+     +------------------+

-- +--------------------+      +--------------------+      +-----------------------+
-- |   ddl_base         |      | monitor_base       |      | backup_base           |
-- |  (NOLOGIN: DDL*)   |      |  (NOLOGIN)         |      | (NOLOGIN)             |
-- +--------------------+      +--------------------+      +-----------------------+
--         ^                              ^                           ^
--         |                              |                           |
-- +--------------------+      +--------------------+      +-----------------------+
-- |   dba_blind (LOGIN)|      | monitor_user(LOGIN)|      | backup_user  (LOGIN)  |
-- +--------------------+      +--------------------+      +-----------------------+

-- +--------------------+
-- | auditor_base       |  (NOLOGIN: read catalogs, pg_stat_statements, etc.)
-- +--------------------+
--         ^
--         |
-- +--------------------+
-- | auditor_user(LOGIN)|
-- +--------------------+


-- ============================================================
-- Safety first
-- ============================================================
REVOKE ALL ON SCHEMA public FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;

-- Schemas in this project
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA auth FROM PUBLIC';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'exam') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA exam FROM PUBLIC';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'grading') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA grading FROM PUBLIC';
  END IF;
END$$;

-- ============================================================
-- Atomic NOLOGIN roles (capabilities)
-- ============================================================

-- Read-only across our schemas
CREATE ROLE app_reader_base NOLOGIN;
GRANT USAGE ON SCHEMA auth, exam, grading TO app_reader_base;
GRANT SELECT ON ALL TABLES    IN SCHEMA auth, exam, grading TO app_reader_base;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA auth, exam, grading TO app_reader_base;
-- Future-proof: new objects also readable
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT SELECT ON TABLES    TO app_reader_base;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT SELECT ON SEQUENCES TO app_reader_base;

-- Write (CRUD) on business tables (no DDL)
CREATE ROLE app_writer_base NOLOGIN IN ROLE app_reader_base;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA exam, grading TO app_writer_base;
ALTER DEFAULT PRIVILEGES IN SCHEMA exam, grading
  GRANT INSERT, UPDATE, DELETE ON TABLES TO app_writer_base;

-- Execute functions/procedures (e.g., soft delete helpers)
CREATE ROLE app_exec_base NOLOGIN;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth, exam, grading TO app_exec_base;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT EXECUTE ON FUNCTIONS TO app_exec_base;

-- Monitoring (catalog + pg_stat_statements)
CREATE ROLE monitor_base NOLOGIN;
GRANT CONNECT ON DATABASE exam_sys TO monitor_base;
GRANT USAGE ON SCHEMA pg_catalog, information_schema TO monitor_base;
GRANT SELECT ON pg_catalog.pg_stat_activity      TO monitor_base;
GRANT SELECT ON pg_catalog.pg_stat_database      TO monitor_base;
GRANT SELECT ON pg_catalog.pg_locks              TO monitor_base;
-- For pg_stat_statements, rely on built-in read-all-stats role instead of extension privileges
GRANT pg_read_all_stats TO monitor_base;

-- Backup (logical + replication if needed)
CREATE ROLE backup_base NOLOGIN;
GRANT CONNECT ON DATABASE exam_sys TO backup_base;
GRANT SELECT ON ALL TABLES IN SCHEMA auth, exam, grading TO backup_base;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth, exam, grading
  GRANT SELECT ON TABLES TO backup_base;
-- (Optional) physical/WAL: requires superuser or REPLICATION attribute granted to LOGIN role via pg_hba.

-- Auditor (read metadata + views/materialized views; avoid raw data if required)
CREATE ROLE auditor_base NOLOGIN;
GRANT USAGE ON SCHEMA pg_catalog, information_schema TO auditor_base;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO auditor_base;
-- If you expose de-identified views for auditors, grant SELECT on those views here.

-- DDL base: use SECURITY DEFINER wrappers instead of raw table ownership
CREATE ROLE ddl_base NOLOGIN;
-- Grant CREATE on target schemas, but *not* ownership of tables with data
GRANT CREATE, USAGE ON SCHEMA auth, exam, grading TO ddl_base;

-- Controlled DDL entry point(s)
CREATE OR REPLACE FUNCTION admin.safe_alter(q text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Optional: guardrails/audit here (whitelist statements, log who/when)
  EXECUTE q;
END;
$$;
REVOKE ALL ON FUNCTION admin.safe_alter(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin.safe_alter(text) TO ddl_base;

-- ============================================================
-- Persona LOGIN roles (inherit capabilities)
-- ============================================================

-- Application read-only
CREATE ROLE app_user_r LOGIN PASSWORD 'change_me_r' INHERIT;
GRANT app_reader_base, app_exec_base TO app_user_r;

-- Application read-write
CREATE ROLE app_user_rw LOGIN PASSWORD 'change_me_rw' INHERIT;
GRANT app_writer_base, app_exec_base TO app_user_rw;

-- Blind DBA: can run controlled DDL, see metadata, but no table data
CREATE ROLE dba_blind LOGIN PASSWORD 'change_me_dba' INHERIT;
GRANT ddl_base, auditor_base TO dba_blind;

-- Monitor
CREATE ROLE monitor_user LOGIN PASSWORD 'change_me_mon' INHERIT;
GRANT monitor_base TO monitor_user;

-- Backup
CREATE ROLE backup_user LOGIN PASSWORD 'change_me_bak' INHERIT;
GRANT backup_base TO backup_user;

-- Auditor (login)
CREATE ROLE auditor_user LOGIN PASSWORD 'change_me_aud' INHERIT;
GRANT auditor_base TO auditor_user;

-- (Optionally) split tenants or teams by subnet with pg_hba.conf, not by roles

-- ============================================================
-- Tighten table data for dba_blind (no data visibility)
-- ============================================================

-- Ensure no implicit table privileges are inherited
REVOKE ALL ON ALL TABLES IN SCHEMA auth, exam, grading FROM dba_blind;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA auth, exam, grading FROM dba_blind;

-- If you use RLS, create a deny-all policy for dba_blind on sensitive tables:
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, t.relname
    FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname IN ('exam','grading','auth') AND t.relkind = 'r'
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.nspname, r.relname);
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = r.nspname AND tablename = r.relname AND policyname = 'no_data_for_dba'
    ) THEN
      EXECUTE format(
        'CREATE POLICY no_data_for_dba ON %I.%I FOR ALL TO dba_blind USING (false) WITH CHECK (false)',
        r.nspname, r.relname
      );
    END IF;
  END LOOP;
END
$$;

-- ============================================================
-- Nice-to-have safety rails on LOGIN roles
-- ============================================================
ALTER ROLE app_user_r  SET statement_timeout = '15s';
ALTER ROLE app_user_rw SET statement_timeout = '15s';
ALTER ROLE dba_blind   SET statement_timeout = '60s';
ALTER ROLE app_user_r  SET search_path = 'exam,auth,grading,public';
ALTER ROLE app_user_rw SET search_path = 'exam,auth,grading,public';

-- Enforce SCRAM passwords (server-side): password_encryption = 'scram-sha-256'
