-- ============================================================
-- Container roles (NOLOGIN) that compose cap_* roles defined in 00-capabilities.sql
--  - No superuser, no direct privileges here
--  - Only inherit atomic capabilities
-- ============================================================

-- App read-only container
-- Can CONNECT, read business data, execute safe functions
CREATE ROLE app_user_r_role NOLOGIN INHERIT;
GRANT cap_connect, cap_read, cap_exec TO app_user_r_role;

-- App read-write (NO DELETE) container
-- Adds INSERT/UPDATE on business tables, still executes functions
CREATE ROLE app_user_rw_role NOLOGIN INHERIT;
GRANT cap_connect, cap_write, cap_exec TO app_user_rw_role;

-- App delete container (only for services that truly need DELETE)
-- Grant separately so most apps never get DELETE
CREATE ROLE app_user_del_role NOLOGIN INHERIT;
GRANT cap_delete TO app_user_del_role;

-- Backup container (logical backups / pg_dump)
-- Read-only across business data
CREATE ROLE backup_role NOLOGIN INHERIT;
GRANT cap_connect, cap_read TO backup_role;

-- Monitor container
-- Read pg_stat*/catalog metrics only. no business data
CREATE ROLE monitor_role NOLOGIN INHERIT;
GRANT cap_connect, cap_monitor TO monitor_role;

-- Auditor container
-- Read information_schema/pg_catalog and audit schema. no business rows
CREATE ROLE auditor_role NOLOGIN INHERIT;
GRANT cap_catalog_read, cap_read_logs TO auditor_role;

-- Read-logs-only container (separate from auditor)
CREATE ROLE logs_reader_role NOLOGIN INHERIT;
GRANT cap_read_logs TO logs_reader_role;

-- Catalog-only container (DBAs who see definitions but not data)
CREATE ROLE catalog_viewer_role NOLOGIN INHERIT;
GRANT cap_catalog_read TO catalog_viewer_role;

-- define a blind DBA container and grant only catalog+DDL (no data):
CREATE ROLE dba_blind_role NOLOGIN INHERIT;
GRANT cap_catalog_read, cap_ddl TO dba_blind_role;

