-- ============================================================
-- Container roles (NOLOGIN) that compose cap_* roles defined in 00-capabilities.sql
--  - No superuser, no direct privileges here
--  - Only inherit atomic capabilities
-- ============================================================

-- App read-only container
-- Can CONNECT, read business data, execute safe functions
CREATE ROLE app_user_r_container NOLOGIN INHERIT;
GRANT cap_connect, cap_read, cap_exec TO app_user_r_container;

-- App read-write (NO DELETE) container
-- Adds INSERT/UPDATE on business tables, still executes functions
CREATE ROLE app_user_rw_container NOLOGIN INHERIT;
GRANT cap_connect, cap_write, cap_exec TO app_user_rw_container;

-- App delete container (only for services that truly need DELETE)
-- Grant separately so most apps never get DELETE
CREATE ROLE app_user_del_container NOLOGIN INHERIT;
GRANT cap_delete TO app_user_del_container;

-- Backup container (logical backups / pg_dump)
-- Read-only across business data
CREATE ROLE backup_container NOLOGIN INHERIT;
GRANT cap_connect, cap_read TO backup_container;

-- Monitor container
-- Read pg_stat*/catalog metrics only. no business data
CREATE ROLE monitor_container NOLOGIN INHERIT;
GRANT cap_connect, cap_monitor TO monitor_container;

-- Auditor container
-- Read information_schema/pg_catalog and audit schema. no business rows
CREATE ROLE auditor_container NOLOGIN INHERIT;
GRANT cap_catalog_read, cap_read_logs TO auditor_container;

-- Read-logs-only container (separate from auditor)
CREATE ROLE logs_reader_container NOLOGIN INHERIT;
GRANT cap_read_logs TO logs_reader_container;

-- Catalog-only container (DBAs who see definitions but not data)
CREATE ROLE catalog_viewer_container NOLOGIN INHERIT;
GRANT cap_catalog_read TO catalog_viewer_container;

-- define a blind DBA container and grant only catalog+DDL (no data):
CREATE ROLE dba_blind_container NOLOGIN INHERIT;
GRANT cap_catalog_read, cap_ddl TO dba_blind_container;

