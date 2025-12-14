-- Create exam_sys database if missing; safe to rerun
SELECT format('CREATE DATABASE %I OWNER %I', 'exam_sys', 'app_owner')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'exam_sys') \gexec
