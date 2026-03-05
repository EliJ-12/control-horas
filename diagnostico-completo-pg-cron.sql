-- =====================================================
-- DIAGNÓSTICO COMPLETO: ¿Por qué no se crean registros?
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- PASO 1: Verificar pg_cron extensión
SELECT
    '=== EXTENSIÓN PG_CRON ===' as check_type,
    name,
    installed_version,
    default_version,
    CASE WHEN installed_version IS NOT NULL THEN '✅ HABILITADA' ELSE '❌ NO HABILITADA' END as status
FROM pg_available_extensions
WHERE name = 'pg_cron';

-- PASO 2: Verificar cron jobs activos
SELECT
    '=== CRON JOBS ACTIVOS ===' as check_type,
    jobname,
    schedule,
    command,
    active
FROM cron.job
WHERE jobname LIKE '%scheduler%';

-- PASO 3: Verificar configuraciones de empleados
SELECT
    '=== CONFIGURACIONES AUTO_TIME_SETTINGS ===' as check_type,
    COUNT(*) as total_configs,
    COUNT(CASE WHEN enabled = true THEN 1 END) as configs_activas,
    COUNT(CASE WHEN enabled = false THEN 1 END) as configs_inactivas
FROM auto_time_settings;

SELECT
    ats.user_id,
    u.full_name,
    ats.enabled,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') as hora_registro,
    ats.monday, ats.tuesday, ats.wednesday, ats.thursday, ats.friday, ats.saturday, ats.sunday
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true
ORDER BY ats.user_id;

-- PASO 4: Verificar tiempo actual en España
SELECT
    '=== TIEMPO ACTUAL ===' as check_type,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_formateada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD') as fecha_espana,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as dia_semana;

-- PASO 5: Simular lógica del scheduler
SELECT
    '=== SIMULACIÓN SCHEDULER ===' as check_type,
    ats.user_id,
    u.full_name as nombre,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') as hora_config,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
        WHEN 0 THEN ats.sunday
        WHEN 1 THEN ats.monday
        WHEN 2 THEN ats.tuesday
        WHEN 3 THEN ats.wednesday
        WHEN 4 THEN ats.thursday
        WHEN 5 THEN ats.friday
        WHEN 6 THEN ats.saturday
        ELSE false
    END as dia_coincide,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_coincide,
    EXISTS (
        SELECT 1 FROM work_logs wl
        WHERE wl.user_id = ats.user_id
        AND wl.date::date = CURRENT_DATE
    ) as ya_existe_registro,
    CASE WHEN
        ats.enabled = true
        AND CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
            WHEN 0 THEN ats.sunday
            WHEN 1 THEN ats.monday
            WHEN 2 THEN ats.tuesday
            WHEN 3 THEN ats.wednesday
            WHEN 4 THEN ats.thursday
            WHEN 5 THEN ats.friday
            WHEN 6 THEN ats.saturday
            ELSE false
        END = true
        AND TO_CHAR(ats.auto_register_time, 'HH24:MI') = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        AND NOT EXISTS (
            SELECT 1 FROM work_logs wl
            WHERE wl.user_id = ats.user_id
            AND wl.date::date = CURRENT_DATE
        )
    THEN '✅ SE CREARÁ REGISTRO' ELSE '❌ NO SE CREARÁ' END as status
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true
AND u.role = 'employee'
ORDER BY ats.user_id;

-- PASO 6: Verificar registros de hoy
SELECT
    '=== REGISTROS DE HOY ===' as check_type,
    wl.user_id,
    u.full_name,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date::date = CURRENT_DATE
ORDER BY wl.created_at DESC;

-- PASO 7: Verificar RLS en auto_time_settings
SELECT
    '=== ESTADO RLS ===' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'auto_time_settings';

-- PASO 8: Verificar políticas RLS activas
SELECT
    '=== POLÍTICAS RLS ===' as check_type,
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies
WHERE tablename = 'auto_time_settings'
ORDER BY policyname;

-- PASO 9: Verificar logs de cron (simplificado - puede no estar disponible)
-- SELECT '=== LOGS DE CRON ===' as check_type;
-- Nota: Los logs de pg_cron pueden no estar disponibles en Supabase
-- Si el cron está ejecutándose, verás registros automáticos en work_logs

-- PASO 10: Probar función manualmente (descomentar para ejecutar)
-- SELECT execute_auto_time_scheduler();

-- Si hay error de tipo, recrear la función corregida:
-- DROP FUNCTION IF EXISTS execute_auto_time_scheduler();
-- CREATE OR REPLACE FUNCTION execute_auto_time_scheduler()
-- RETURNS void
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- DECLARE
--     spain_now timestamptz;
--     spain_time_str text;
--     spain_date text;
--     spain_dow integer;
--     records_created integer := 0;
-- BEGIN
--     -- Calcular tiempo actual en España
--     spain_now := NOW() AT TIME ZONE 'Europe/Madrid';
--     spain_time_str := TO_CHAR(spain_now, 'HH24:MI');
--     spain_date := TO_CHAR(spain_now, 'YYYY-MM-DD');
--     spain_dow := EXTRACT(DOW FROM spain_now);
--
--     RAISE NOTICE 'pg_cron: Ejecutando scheduler - Hora España: %, Fecha: %, Día semana: %',
--         spain_time_str, spain_date, spain_dow;
--
--     -- Insertar registros automáticos
--     INSERT INTO work_logs (
--         user_id, date, start_time, end_time, total_hours, type, is_auto_generated, created_at, updated_at
--     )
--     SELECT DISTINCT
--         ats.user_id,
--         spain_date,
--         ats.start_time,
--         ats.end_time,
--         EXTRACT(EPOCH FROM (ats.end_time::time - ats.start_time::time)) / 60, -- minutos
--         'work', -- Tipo como texto simple
--         true,
--         NOW(),
--         NOW()
--     FROM auto_time_settings ats
--     JOIN users u ON ats.user_id = u.id
--     WHERE ats.enabled = true
--     AND u.role = 'employee'
--     -- Verificar día de la semana
--     AND CASE spain_dow
--         WHEN 0 THEN ats.sunday
--         WHEN 1 THEN ats.monday
--         WHEN 2 THEN ats.tuesday
--         WHEN 3 THEN ats.wednesday
--         WHEN 4 THEN ats.thursday
--         WHEN 5 THEN ats.friday
--         WHEN 6 THEN ats.saturday
--         ELSE false
--     END = true
--     -- Verificar hora exacta
--     AND TO_CHAR(ats.auto_register_time, 'HH24:MI') = spain_time_str
--     -- Solo si no existe registro para hoy
--     AND NOT EXISTS (
--         SELECT 1 FROM work_logs wl
--         WHERE wl.user_id = ats.user_id
--         AND wl.date = spain_date
--     );
--
--     GET DIAGNOSTICS records_created = ROW_COUNT;
--
--     RAISE NOTICE 'pg_cron: Registros creados: %', records_created;
--
--     IF records_created > 0 THEN
--         RAISE NOTICE 'pg_cron: ✅ Scheduler completado - % registros automáticos creados', records_created;
--     ELSE
--         RAISE NOTICE 'pg_cron: ℹ️  Ningún registro creado - revisa configuraciones';
--     END IF;
--
-- END;
-- $$;

-- PASO 11: Probar función de test (descomentar para ejecutar)
-- SELECT * FROM test_auto_scheduler();

-- =====================================================
-- POSIBLES SOLUCIONES SEGÚN RESULTADOS
-- =====================================================

/*
SI pg_cron NO está habilitado:
    CREATE EXTENSION IF NOT EXISTS pg_cron;

SI no hay cron job:
    SELECT cron.schedule('auto-time-scheduler', '*/5 * * * *', 'SELECT execute_auto_time_scheduler();');

SI no hay configuraciones activas:
    - Los empleados deben configurar sus horarios en auto_time_settings
    - enabled = true
    - auto_register_time configurada
    - Días de la semana seleccionados

SI la hora no coincide:
    - Verificar zona horaria (Europe/Madrid)
    - Verificar formato HH24:MI
    - Cron ejecuta cada 5 minutos, así que debe coincidir exactamente

SI RLS está bloqueando:
    - Verificar que existe política para service_role
    - Función usa SECURITY DEFINER para bypass RLS

SI ya existe registro:
    - Solo se crea si no existe registro para hoy
    - Verificar work_logs para esa fecha
*/
