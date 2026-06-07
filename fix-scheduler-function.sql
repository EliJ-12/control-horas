-- CORRECCIÓN FINAL: Recrear función execute_auto_time_scheduler para procesar ambas configuraciones
DROP FUNCTION IF EXISTS execute_auto_time_scheduler();

-- Eliminar constraint único antiguo para permitir múltiples registros por día
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_user_date_auto'
    ) THEN
        ALTER TABLE work_logs DROP CONSTRAINT unique_user_date_auto;
    END IF;
    
    -- No creamos constraint único ya que permitimos múltiples registros por día
    -- La lógica del scheduler controla que no haya más de 2 registros
END $$;

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

    -- Insertar registros automáticos desde CONFIGURACIÓN 1
    INSERT INTO work_logs (
        user_id, date, start_time, end_time, total_hours, type, is_auto_generated, created_at, updated_at
    )
    SELECT DISTINCT
        ats.user_id,
        spain_date,
        ats.start_time,
        ats.end_time,
        EXTRACT(EPOCH FROM (ats.end_time::time - ats.start_time::time)) / 60, -- minutos
        'work',
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
    -- Solo si no existe registro para hoy (verificación manual)
    AND NOT EXISTS (
        SELECT 1 FROM work_logs wl
        WHERE wl.user_id = ats.user_id
        AND wl.date = spain_date
    );

    -- Insertar registros automáticos desde CONFIGURACIÓN 2
    INSERT INTO work_logs (
        user_id, date, start_time, end_time, total_hours, type, is_auto_generated, created_at, updated_at
    )
    SELECT DISTINCT
        ats2.user_id,
        spain_date,
        ats2.start_time,
        ats2.end_time,
        EXTRACT(EPOCH FROM (ats2.end_time::time - ats2.start_time::time)) / 60, -- minutos
        'work',
        true,
        NOW(),
        NOW()
    FROM auto_time_settings_2 ats2
    JOIN users u ON ats2.user_id = u.id
    WHERE ats2.enabled = true
    AND u.role = 'employee'
    -- Verificar día de la semana
    AND CASE spain_dow
        WHEN 0 THEN ats2.sunday
        WHEN 1 THEN ats2.monday
        WHEN 2 THEN ats2.tuesday
        WHEN 3 THEN ats2.wednesday
        WHEN 4 THEN ats2.thursday
        WHEN 5 THEN ats2.friday
        WHEN 6 THEN ats2.saturday
        ELSE false
    END = true
    -- Verificar hora exacta
    AND TO_CHAR(ats2.auto_register_time, 'HH24:MI') = spain_time_str
    -- Solo si no existe registro para hoy (verificación manual)
    AND NOT EXISTS (
        SELECT 1 FROM work_logs wl
        WHERE wl.user_id = ats2.user_id
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

-- Probar la función corregida
SELECT execute_auto_time_scheduler();
