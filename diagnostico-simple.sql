-- DIAGNÓSTICO SENCILLO: ¿Por qué no se crean registros?
-- Versión simplificada para evitar errores de sintaxis

SELECT '=== DIAGNÓSTICO SENCILLO ===' as titulo;

-- 1. Verificar configuraciones activas
SELECT
    'CONFIGURACIONES ACTIVAS' as tipo,
    COUNT(*) as cantidad,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAY CONFIGURACIONES' ELSE '❌ NO HAY CONFIGURACIONES ACTIVAS' END as estado
FROM auto_time_settings
WHERE enabled = true;

-- 2. Verificar empleados
SELECT
    'EMPLEADOS' as tipo,
    COUNT(*) as cantidad,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAY EMPLEADOS' ELSE '❌ NO HAY EMPLEADOS' END as estado
FROM users
WHERE role = 'employee';

-- 3. Verificar día actual
SELECT
    'DÍA ACTUAL' as tipo,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as numero_dia,
    CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
        WHEN 0 THEN 'DOMINGO - ❌ NO LABORABLE'
        WHEN 1 THEN 'LUNES - ✅ LABORABLE'
        WHEN 2 THEN 'MARTES - ✅ LABORABLE'
        WHEN 3 THEN 'MIÉRCOLES - ✅ LABORABLE'
        WHEN 4 THEN 'JUEVES - ✅ LABORABLE'
        WHEN 5 THEN 'VIERNES - ✅ LABORABLE'
        WHEN 6 THEN 'SÁBADO - ❌ NO LABORABLE'
    END as estado_dia;

-- 4. Verificar hora actual
SELECT
    'HORA ACTUAL ESPAÑA' as tipo,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    'Esta debe coincidir EXACTAMENTE con auto_register_time' as nota;

-- 5. Mostrar configuración detallada
SELECT
    'CONFIGURACIÓN DETALLADA' as tipo,
    u.username,
    u.role,
    ats.enabled,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ HORA COINCIDE'
        ELSE '❌ HORA NO COINCIDE'
    END as comparacion_hora,
    ats.monday, ats.tuesday, ats.wednesday, ats.thursday, ats.friday,
    CASE
        WHEN ats.enabled = true AND u.role = 'employee' THEN '✅ CONFIGURACIÓN VÁLIDA'
        ELSE '❌ CONFIGURACIÓN INVÁLIDA'
    END as estado_general
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id;

-- 6. Verificar registros existentes hoy
SELECT
    'REGISTROS EXISTENTES HOY' as tipo,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN is_auto_generated = true THEN 1 END) as registros_automaticos,
    COUNT(CASE WHEN is_auto_generated = false THEN 1 END) as registros_manuales,
    CASE
        WHEN COUNT(CASE WHEN is_auto_generated = true THEN 1 END) > 0
        THEN '⚠️ YA HAY REGISTROS AUTOMÁTICOS - NO SE CREARÁN MÁS'
        ELSE '✅ NO HAY REGISTROS AUTOMÁTICOS - LISTO PARA CREAR'
    END as estado_registros
FROM work_logs
WHERE date = CURRENT_DATE;

-- 7. DIAGNÓSTICO FINAL SENCILLO
SELECT
    'DIAGNÓSTICO FINAL SENCILLO' as tipo,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true) THEN
            '❌ PROBLEMA: No hay configuraciones activas'
        WHEN NOT EXISTS (SELECT 1 FROM users WHERE role = 'employee') THEN
            '❌ PROBLEMA: No hay usuarios empleados'
        WHEN EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') NOT IN (1,2,3,4,5) THEN
            '❌ PROBLEMA: Hoy no es día laborable'
        WHEN NOT EXISTS (
            SELECT 1 FROM auto_time_settings ats
            JOIN users u ON ats.user_id = u.id
            WHERE ats.enabled = true AND u.role = 'employee'
            AND ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        ) THEN '❌ PROBLEMA: La hora no coincide'
        WHEN EXISTS (
            SELECT 1 FROM work_logs
            WHERE date = CURRENT_DATE AND is_auto_generated = true
        ) THEN '❌ PROBLEMA: Ya existe registro automático hoy'
        ELSE '✅ TODAS LAS CONDICIONES CORRECTAS - DEBERÍA FUNCIONAR'
    END as resultado_diagnostico;

-- 8. ACCIONES RECOMENDADAS
SELECT
    'ACCIONES RECOMENDADAS' as tipo,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true) THEN
            'SOLUCIÓN: UPDATE auto_time_settings SET enabled = true WHERE user_id = (SELECT id FROM users WHERE role=''employee'' LIMIT 1);'
        WHEN NOT EXISTS (SELECT 1 FROM users WHERE role = 'employee') THEN
            'SOLUCIÓN: INSERT INTO users (username, password, full_name, role) VALUES (''testuser'', ''password'', ''Test User'', ''employee'');'
        WHEN EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') NOT IN (1,2,3,4,5) THEN
            'SOLUCIÓN: Cambiar día de prueba o habilitar fin de semana: UPDATE auto_time_settings SET saturday = true, sunday = true;'
        WHEN NOT EXISTS (
            SELECT 1 FROM auto_time_settings ats
            JOIN users u ON ats.user_id = u.id
            WHERE ats.enabled = true AND u.role = 'employee'
            AND ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        ) THEN 'SOLUCIÓN: UPDATE auto_time_settings SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE ''Europe/Madrid'', ''HH24:MI'')::time;'
        WHEN EXISTS (
            SELECT 1 FROM work_logs
            WHERE date = CURRENT_DATE AND is_auto_generated = true
        ) THEN 'SOLUCIÓN: DELETE FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true;'
        ELSE '✅ SISTEMA LISTO - EJECUTAR npm run dev'
    END as solucion;
