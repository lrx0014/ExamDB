-- Ensure supporting admin schema exists before role bootstrap
CREATE SCHEMA IF NOT EXISTS admin;

-- safe to rerun
SELECT format('CREATE DATABASE %I OWNER %I', 'exam_sys', 'app_owner')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'exam_sys') \gexec

\connect exam_sys

-- extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- CREATE EXTENSION IF NOT EXISTS pgaudit;
