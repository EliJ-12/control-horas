-- =====================================================
-- DIAGNÓSTICO COMPLETO: Verificar estado actual del sistema
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- PASO 1: Verificar configuraciones activas
SELECT
    '=== CONFIGURACIONES ACTIVAS ===' as info,
    COUNT(*) as total_configs
FROM auto_time_settings
WHERE enabled = true;

-- PASO 2: Verificar usuarios empleados con configuración
SELECT
    u.id,
    u.name,
    u.role,
    ats.enabled,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') as auto_time,
    ats.monday, ats.tuesday, ats.wednesday, ats.thursday, ats.friday, ats.saturday, ats.sunday
FROM users u
LEFT JOIN auto_time_settings ats ON u.id::text = ats.user_id::text
WHERE u.role = 'employee'
ORDER BY u.id;

-- PASO 3: Verificar tiempo actual en España
SELECT
    '=== TIEMPO ACTUAL ===' as info,
    NOW() AT TIME ZONE 'Europe/Madrid' as spain_now,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as spain_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD') as spain_date,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as spain_dow;

-- PASO 4: Verificar registros de hoy
SELECT
    '=== REGISTROS DE HOY ===' as info,
    wl.user_id,
    u.name,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD'))::date
ORDER BY wl.created_at DESC;

-- PASO 5: Simular lógica del scheduler
SELECT
    '=== SIMULACIÓN SCHEDULER ===' as info,
    ats.user_id,
    u.name,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') as config_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as current_time,
    CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
        WHEN 0 THEN ats.sunday
        WHEN 1 THEN ats.monday
        WHEN 2 THEN ats.tuesday
        WHEN 3 THEN ats.wednesday
        WHEN 4 THEN ats.thursday
        WHEN 5 THEN ats.friday
        WHEN 6 THEN ats.saturday
        ELSE false
    END as day_matches,
    TO_CHAR(ats.auto_register_time, 'HH24:MI') = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as time_matches,
    EXISTS (
        SELECT 1 FROM work_logs wl
        WHERE wl.user_id = ats.user_id
        AND wl.date = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD'))::date
    ) as has_today_record,
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
            AND wl.date = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD'))::date
        )
    THEN '✅ SE CREARÁ REGISTRO' ELSE '❌ NO SE CREARÁ' END as status
FROM auto_time_settings ats
JOIN users u ON ats.user_id::text = u.id::text
WHERE ats.enabled = true
AND u.role = 'employee'
ORDER BY ats.user_id;

-- PASO 6: Verificar RLS status
SELECT
    '=== ESTADO RLS ===' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('auto_time_settings', 'work_logs', 'users');

-- PASO 7: Verificar políticas RLS
SELECT
    '=== POLÍTICAS RLS ===' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('auto_time_settings', 'work_logs', 'users')
ORDER BY tablename, policyname;
