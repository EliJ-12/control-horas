-- =====================================================
-- SOLUCIÓN FINAL: pg_cron CONFIGURABLE COMPLETA
-- Opción B: Lee configuración de cada empleado
-- =====================================================

-- PASO 1: Habilitar pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- PASO 2: Función principal del scheduler
CREATE OR REPLACE FUNCTION execute_auto_time_scheduler()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    spain_now timestamptz;
    spain_time_str text;
    spain_date text;
    spain_dow integer;
    records_created integer := 0;
BEGIN
    -- Calcular tiempo actual en España
    spain_now := NOW() AT TIME ZONE 'Europe/Madrid';
    spain_time_str := TO_CHAR(spain_now, 'HH24:MI');
    spain_date := TO_CHAR(spain_now, 'YYYY-MM-DD');
    spain_dow := EXTRACT(DOW FROM spain_now);

    RAISE NOTICE 'pg_cron: Ejecutando scheduler - Hora España: %, Fecha: %, Día semana: %',
        spain_time_str, spain_date, spain_dow;

    -- Insertar registros automáticos basados en configuración de empleados
    INSERT INTO work_logs (
        user_id, date, start_time, end_time, total_hours, type, is_auto_generated, created_at, updated_at
    )
    SELECT DISTINCT
        ats.user_id,
        spain_date,
        ats.start_time,
        ats.end_time,
        EXTRACT(EPOCH FROM (ats.end_time::time - ats.start_time::time)) / 60, -- minutos
        'work'::work_log_type,
        true,
        NOW(),
        NOW()
    FROM auto_time_settings ats
    JOIN users u ON ats.user_id = u.id
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
    );

    GET DIAGNOSTICS records_created = ROW_COUNT;

    RAISE NOTICE 'pg_cron: Registros creados: %', records_created;

    IF records_created > 0 THEN
        RAISE NOTICE 'pg_cron: ✅ Scheduler completado - % registros automáticos creados', records_created;
    ELSE
        RAISE NOTICE 'pg_cron: ℹ️  Ningún registro creado - revisa configuraciones';
    END IF;

END;
$$;

-- PASO 3: Función de diagnóstico
CREATE OR REPLACE FUNCTION test_auto_scheduler()
RETURNS TABLE (
    user_id integer,
    user_name varchar(255),
    config_time varchar(5),
    hora_actual varchar(5),
    day_match boolean,
    time_match boolean,
    existing_record boolean,
    will_create boolean
) AS $$
DECLARE
    spain_now timestamptz;
    spain_time_str varchar(5);
    spain_date text;
    spain_dow integer;
BEGIN
    -- Calcular tiempo actual en España
    spain_now := NOW() AT TIME ZONE 'Europe/Madrid';
    spain_time_str := TO_CHAR(spain_now, 'HH24:MI');
    spain_date := TO_CHAR(spain_now, 'YYYY-MM-DD');
    spain_dow := EXTRACT(DOW FROM spain_now);

    RETURN QUERY
    SELECT
        ats.user_id,
        u.full_name::varchar(255),
        TO_CHAR(ats.auto_register_time, 'HH24:MI'),
        spain_time_str,
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
    JOIN users u ON ats.user_id = u.id
    WHERE ats.enabled = true
    AND u.role = 'employee'
    ORDER BY ats.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 4: Programar cron job cada 5 minutos
SELECT cron.schedule(
    'auto-time-scheduler',
    '*/5 * * * *',
    'SELECT execute_auto_time_scheduler();'
);

-- PASO 5: Verificar configuración
SELECT jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'auto-time-scheduler';

-- PASO 6: Probar manualmente
-- SELECT * FROM test_auto_scheduler();

-- PASO 7: Ver logs
-- SELECT * FROM cron.job_run_details
-- WHERE jobname = 'auto-time-scheduler'
-- ORDER BY start_time DESC LIMIT 10;

-- LIMPIEZA (descomentar si necesitas resetear):
-- SELECT cron.unschedule('auto-time-scheduler');
-- DROP FUNCTION IF EXISTS execute_auto_time_scheduler();
-- DROP FUNCTION IF EXISTS test_auto_scheduler();
