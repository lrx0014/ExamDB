-- ============================================================
-- Create LOGIN users and grant container roles (from 01-roles.sql)
--  - Do NOT commit real passwords; set via secrets/CI at deploy
-- ============================================================

-- ---------- For Application ----------
-- Read-only app user
CREATE ROLE app_user_r LOGIN INHERIT;
-- (set password out-of-band)
ALTER ROLE app_user_r PASSWORD 'appuserrpw';
GRANT app_user_r_role TO app_user_r;

-- Read-write (NO DELETE) app user
CREATE ROLE app_user_rw LOGIN INHERIT;
ALTER ROLE app_user_rw PASSWORD 'appuserrwpw';
GRANT app_user_rw_role TO app_user_rw;

-- If a specific service really needs DELETE, grant the delete container separately
CREATE ROLE app_user_rw_del LOGIN INHERIT;
ALTER ROLE app_user_rw_del PASSWORD 'appuserrwdelpw';
GRANT app_user_rw_role, app_user_del_role TO app_user_rw_del;

-- ---------- Operations personas ----------
-- Backup (logical dump)
CREATE ROLE backup_user LOGIN INHERIT;
ALTER ROLE backup_user PASSWORD 'backupuserpw';
GRANT backup_role TO backup_user;

-- Monitoring/metrics (no business data)
CREATE ROLE monitor_user LOGIN INHERIT;
ALTER ROLE monitor_user PASSWORD 'monitoruserpw';
GRANT monitor_role TO monitor_user;

-- Auditing (logs/metadata only)
CREATE ROLE auditor_user LOGIN INHERIT;
ALTER ROLE auditor_user PASSWORD 'auditoruserpw';
GRANT auditor_role TO auditor_user;

-- Logs-only reader (separate from auditor)
CREATE ROLE logs_reader_user LOGIN INHERIT;
ALTER ROLE logs_reader_user PASSWORD 'logsreaderuserpw';
GRANT logs_reader_role TO logs_reader_user;

-- Catalog viewer (definitions only, no data rows)
CREATE ROLE catalog_viewer_user LOGIN INHERIT;
ALTER ROLE catalog_viewer_user PASSWORD 'catalogvieweruserpw';
GRANT catalog_viewer_role TO catalog_viewer_user;

-- Blind DBA (DDL via controlled funcs + catalog, no data read)
CREATE ROLE dba_blind_user LOGIN INHERIT;
ALTER ROLE dba_blind_user PASSWORD 'dbablinduserpw';
GRANT dba_blind_role TO dba_blind_user;

-- ======================
-- Additional safeguards
-- ======================
-- App roles
ALTER ROLE app_user_r  SET statement_timeout = '15s';
ALTER ROLE app_user_rw SET statement_timeout = '15s';
ALTER ROLE app_user_r  SET search_path = 'exam,auth,grading,public';
ALTER ROLE app_user_rw SET search_path = 'exam,auth,grading,public';

-- Ops roles
ALTER ROLE backup_user   SET statement_timeout = '5min';
ALTER ROLE monitor_user  SET search_path = 'pg_catalog,public';
ALTER ROLE auditor_user  SET search_path = 'audit,information_schema,pg_catalog,public';
ALTER ROLE dba_blind_user SET statement_timeout = '60s';
