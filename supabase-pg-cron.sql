-- ALTERNATIVA: Configuración de pg_cron en Supabase
-- Si prefieres usar pg_cron en lugar de Vercel cron jobs

-- PASO 1: Habilitar pg_cron extension (en SQL Editor de Supabase)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- PASO 2: Crear función que ejecuta el scheduler
CREATE OR REPLACE FUNCTION execute_auto_time_scheduler()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Simular la lógica del scheduler en SQL puro
  -- (Esta es una versión simplificada - usa la lógica completa del scheduler)

  INSERT INTO work_logs (
    user_id, date, start_time, end_time, total_hours, type, is_auto_generated
  )
  SELECT DISTINCT
    ats.user_id,
    (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD'))::date,
    ats.start_time,
    ats.end_time,
    (EXTRACT(HOUR FROM ats.end_time) * 60 + EXTRACT(MINUTE FROM ats.end_time)) -
    (EXTRACT(HOUR FROM ats.start_time) * 60 + EXTRACT(MINUTE FROM ats.start_time)),
    'work',
    true
  FROM auto_time_settings ats
  JOIN users u ON ats.user_id = u.id
  WHERE ats.enabled = true
  AND u.role = 'employee'
  -- Condiciones del scheduler
  AND CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
    WHEN 0 THEN ats.sunday
    WHEN 1 THEN ats.monday
    WHEN 2 THEN ats.tuesday
    WHEN 3 THEN ats.wednesday
    WHEN 4 THEN ats.thursday
    WHEN 5 THEN ats.friday
    WHEN 6 THEN ats.saturday
  END = true
  AND SUBSTRING(ats.auto_register_time::text, 1, 5) = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
  -- Solo si no existe registro para hoy
  AND NOT EXISTS (
    SELECT 1 FROM work_logs wl
    WHERE wl.user_id = ats.user_id
    AND wl.date = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD'))::date
  );

  -- Log de ejecución
  RAISE NOTICE 'pg_cron: Auto time scheduler ejecutado a las %', NOW() AT TIME ZONE 'Europe/Madrid';
END;
$$;

-- PASO 3: Configurar el cron job (cada 5 minutos)
-- SELECT cron.schedule('auto-time-scheduler', '*/5 * * * *', 'SELECT execute_auto_time_scheduler();');

-- PASO 4: Para ver jobs activos
-- SELECT * FROM cron.job;

-- PASO 5: Para eliminar el job si es necesario
-- SELECT cron.unschedule('auto-time-scheduler');
