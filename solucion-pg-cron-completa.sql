-- =====================================================
-- SOLUCIÓN COMPLETA: pg_cron para auto time registration
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- PASO 1: Verificar si pg_cron está habilitado
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE name = 'pg_cron';

-- PASO 2: Habilitar pg_cron si no está habilitado
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- PASO 3: Crear función completa del scheduler
CREATE OR REPLACE FUNCTION execute_auto_time_scheduler()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    spain_now timestamptz;
    spain_time_str text;
    spain_date date;
    spain_dow integer;
    records_created integer := 0;
BEGIN
    -- Calcular tiempo actual en España
    spain_now := NOW() AT TIME ZONE 'Europe/Madrid';
    spain_time_str := TO_CHAR(spain_now, 'HH24:MI');
    spain_date := spain_now::date;
    spain_dow := EXTRACT(DOW FROM spain_now);

    RAISE NOTICE 'pg_cron: Ejecutando scheduler - Hora España: %, Fecha: %, Día semana: %',
        spain_time_str, spain_date, spain_dow;

    -- Insertar registros automáticos
    INSERT INTO work_logs (
        user_id, date, start_time, end_time, total_hours, type, is_auto_generated, created_at, updated_at
    )
    SELECT DISTINCT
        ats.user_id,
        spain_date,
        ats.start_time,
        ats.end_time,
        EXTRACT(EPOCH FROM (ats.end_time - ats.start_time)) / 3600, -- horas decimales
        'work'::work_log_type,
        true,
        NOW(),
        NOW()
    FROM auto_time_settings ats
    JOIN users u ON ats.user_id::text = u.id::text
    WHERE ats.enabled = true
    AND u.role = 'employee'
    -- Verificar día de la semana
    AND CASE spain_dow
        WHEN 0 THEN ats.sunday
        WHEN 1 THEN ats.monday
        WHEN 2 THEN ats.tuesday
        WHEN 3 THEN ats.wednesday
        WHEN 4 THEN ats.thursday
        WHEN 5 THEN ats.friday
        WHEN 6 THEN ats.saturday
        ELSE false
    END = true
    -- Verificar hora exacta
    AND TO_CHAR(ats.auto_register_time, 'HH24:MI') = spain_time_str
    -- Solo si no existe registro para hoy
    AND NOT EXISTS (
        SELECT 1 FROM work_logs wl
        WHERE wl.user_id = ats.user_id
        AND wl.date = spain_date
        AND wl.is_auto_generated = true
    );

    GET DIAGNOSTICS records_created = ROW_COUNT;

    RAISE NOTICE 'pg_cron: Registros creados: %', records_created;

    -- Log adicional para debugging
    IF records_created > 0 THEN
        RAISE NOTICE 'pg_cron: ✅ Scheduler completado exitosamente - % registros automáticos creados', records_created;
    ELSE
        RAISE NOTICE 'pg_cron: ℹ️  Ningún registro creado - revisa configuraciones y condiciones';
    END IF;

END;
$$;

-- PASO 4: Programar el cron job (cada 5 minutos)
SELECT cron.schedule(
    'auto-time-scheduler',
    '*/5 * * * *',
    'SELECT execute_auto_time_scheduler();'
);

-- PASO 5: Verificar jobs activos
SELECT jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'auto-time-scheduler';

-- PASO 6: Función de prueba manual
CREATE OR REPLACE FUNCTION test_auto_scheduler()
RETURNS TABLE (
    user_id integer,
    user_name text,
    config_time text,
    hora_actual text,
    day_match boolean,
    time_match boolean,
    existing_record boolean,
    will_create boolean
) AS $$
DECLARE
    spain_now timestamptz;
    spain_time_str text;
    spain_date date;
    spain_dow integer;
BEGIN
    -- Calcular tiempo actual en España
    spain_now := NOW() AT TIME ZONE 'Europe/Madrid';
    spain_time_str := TO_CHAR(spain_now, 'HH24:MI');
    spain_date := spain_now::date;
    spain_dow := EXTRACT(DOW FROM spain_now);

    RETURN QUERY
    SELECT
        ats.user_id,
        u.full_name,
        TO_CHAR(ats.auto_register_time, 'HH24:MI') as config_time,
        spain_time_str as hora_actual,
        CASE spain_dow
            WHEN 0 THEN ats.sunday
            WHEN 1 THEN ats.monday
            WHEN 2 THEN ats.tuesday
            WHEN 3 THEN ats.wednesday
            WHEN 4 THEN ats.thursday
            WHEN 5 THEN ats.friday
            WHEN 6 THEN ats.saturday
            ELSE false
        END as day_match,
        TO_CHAR(ats.auto_register_time, 'HH24:MI') = spain_time_str as time_match,
        EXISTS (
            SELECT 1 FROM work_logs wl
            WHERE wl.user_id = ats.user_id
            AND wl.date = spain_date
        ) as existing_record,
        CASE WHEN
            CASE spain_dow
                WHEN 0 THEN ats.sunday
                WHEN 1 THEN ats.monday
                WHEN 2 THEN ats.tuesday
                WHEN 3 THEN ats.wednesday
                WHEN 4 THEN ats.thursday
                WHEN 5 THEN ats.friday
                WHEN 6 THEN ats.saturday
                ELSE false
            END = true
            AND TO_CHAR(ats.auto_register_time, 'HH24:MI') = spain_time_str
            AND NOT EXISTS (
                SELECT 1 FROM work_logs wl
                WHERE wl.user_id = ats.user_id
                AND wl.date = spain_date
            )
        THEN true ELSE false END as will_create
    FROM auto_time_settings ats
    JOIN users u ON ats.user_id::text = u.id::text
    WHERE ats.enabled = true
    AND u.role = 'employee'
    ORDER BY ats.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 7: Probar la función manualmente
-- SELECT * FROM test_auto_scheduler();

-- PASO 8: Ver logs de cron (últimas 24 horas)
-- SELECT * FROM cron.job_run_details
-- WHERE jobname = 'auto-time-scheduler'
-- AND start_time > NOW() - INTERVAL '24 hours'
-- ORDER BY start_time DESC;

-- PASO 9: LIMPIEZA (descomentar si necesitas resetear)
-- SELECT cron.unschedule('auto-time-scheduler');
-- DROP FUNCTION IF EXISTS execute_auto_time_scheduler();
-- DROP FUNCTION IF EXISTS test_auto_scheduler();
