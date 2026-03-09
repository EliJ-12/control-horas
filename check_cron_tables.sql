-- Verificar estructura de tablas pg_cron
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'cron' AND table_name LIKE '%';

-- Verificar columnas de job_run_details si existe
SELECT column_name FROM information_schema.columns 
WHERE table_schema = 'cron' AND table_name = 'job_run_details';

-- Verificar columnas de job
SELECT column_name FROM information_schema.columns 
WHERE table_schema = 'cron' AND table_name = 'job';
