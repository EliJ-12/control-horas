-- SOLUCIÓN SIMPLE: pg_cron para registro automático diario
-- Ejecutar en Supabase SQL Editor

-- PASO 1: Habilitar pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- PASO 2: Crear función simple de registro
CREATE OR REPLACE FUNCTION registrar_jornada()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_count INTEGER;
BEGIN
    -- Verificar que hay usuarios empleados
    SELECT COUNT(*) INTO user_count 
    FROM users 
    WHERE role = 'employee';
    
    IF user_count = 0 THEN
        RAISE NOTICE 'No hay usuarios empleados para registrar jornada';
        RETURN;
    END IF;

    -- Insertar registro para el primer usuario empleado (puedes modificar esto)
    INSERT INTO work_logs (
        user_id, 
        date, 
        start_time, 
        end_time, 
        total_hours, 
        type, 
        is_auto_generated
    )
    SELECT 
        u.id,
        TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD'),
        '09:00',
        '14:00', 
        5 * 60, -- 5 horas en minutos
        'work',
        true
    FROM users u
    WHERE u.role = 'employee'
    ORDER BY u.id
    LIMIT 1; -- Solo para el primer empleado (modificar según necesites)

    RAISE NOTICE 'Jornada registrada automáticamente para usuario empleado';
END;
$$;

-- PASO 3: Programar el cron job (Lunes a Viernes a las 14:00)
SELECT cron.schedule(
    'registro-automatico-diario',
    '0 14 * * 1-5',  -- Lunes a viernes a las 14:00
    $$ SELECT registrar_jornada(); $$
);

-- PASO 4: Verificar que se creó el job
SELECT jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'registro-automatico-diario';

-- PASO 5: Probar la función manualmente (opcional)
-- SELECT registrar_jornada();

-- PASO 6: Ver logs del cron
-- SELECT * FROM cron.job_run_details 
-- WHERE jobname = 'registro-automatico-diario' 
-- ORDER BY start_time DESC;

-- LIMPIEZA (descomentar si necesitas detener):
-- SELECT cron.unschedule('registro-automatico-diario');
-- DROP FUNCTION IF EXISTS registrar_jornada();
