-- PASO 2 DE 5: VERIFICACIÓN DE DATOS EXISTENTES
-- Ejecutar este script DESPUÉS del PASO 1 (solo si PASO 1 fue exitoso)

SELECT '=== PASO 2: VERIFICACIÓN DE DATOS EXISTENTES ===' as paso;

-- 2.1 Verificar usuarios empleados
SELECT '2.1 USUARIOS EMPLEADOS EXISTENTES' as subpaso;

SELECT
    COUNT(*) as total_empleados,
    CASE
        WHEN COUNT(*) > 0 THEN '✅ HAY EMPLEADOS - CONTINUAR'
        ELSE '❌ NO HAY EMPLEADOS - CREAR AL MENOS UNO'
    END as estado
FROM users
WHERE role = 'employee';

-- Mostrar detalles de empleados
SELECT
    'DETALLES DE EMPLEADOS' as tipo,
    u.id,
    u.username,
    u.role,
    u.created_at,
    CASE
        WHEN u.role = 'employee' THEN '✅ EMPLEADO VÁLIDO'
        ELSE '❌ NO ES EMPLEADO'
    END as estado_rol
FROM users u
WHERE u.role = 'employee'
ORDER BY u.id;

-- 2.2 Verificar configuraciones de auto-time
SELECT '2.2 CONFIGURACIONES AUTO-TIME EXISTENTES' as subpaso;

SELECT
    COUNT(*) as total_configuraciones,
    COUNT(CASE WHEN enabled = true THEN 1 END) as configuraciones_activas,
    CASE
        WHEN COUNT(CASE WHEN enabled = true THEN 1 END) > 0 THEN '✅ HAY CONFIGURACIONES ACTIVAS - CONTINUAR'
        ELSE '❌ NO HAY CONFIGURACIONES ACTIVAS - CREAR AL MENOS UNA'
    END as estado
FROM auto_time_settings;

-- Mostrar detalles de configuraciones
SELECT
    'DETALLES DE CONFIGURACIONES' as tipo,
    u.username,
    ats.enabled,
    ats.auto_register_time::text as hora_registro,
    ats.start_time,
    ats.end_time,
    ats.monday, ats.tuesday, ats.wednesday, ats.thursday, ats.friday,
    CASE
        WHEN ats.enabled = true THEN '✅ CONFIGURACIÓN ACTIVA'
        ELSE '❌ CONFIGURACIÓN INACTIVA'
    END as estado_config
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
ORDER BY ats.user_id;

-- 2.3 Verificar registros de hoy
SELECT '2.3 REGISTROS DE TRABAJO DE HOY' as subpaso;

SELECT
    COUNT(*) as total_registros_hoy,
    COUNT(CASE WHEN is_auto_generated = true THEN 1 END) as registros_automaticos,
    COUNT(CASE WHEN is_auto_generated = false THEN 1 END) as registros_manuales,
    CASE
        WHEN COUNT(CASE WHEN is_auto_generated = true THEN 1 END) > 0 THEN '⚠️ YA HAY REGISTROS AUTOMÁTICOS HOY - LIMPIAR PARA PRUEBA'
        ELSE '✅ NO HAY REGISTROS AUTOMÁTICOS HOY - LISTO PARA PRUEBA'
    END as estado_registros
FROM work_logs
WHERE date = CURRENT_DATE;

-- Mostrar registros de hoy detallados
SELECT
    'REGISTROS DETALLADOS DE HOY' as tipo,
    wl.id,
    u.username,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at,
    CASE
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as tipo_registro
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE
ORDER BY wl.created_at DESC;

-- 2.4 RESULTADO DEL PASO 2
SELECT '2.4 RESULTADO PASO 2' as subpaso;

SELECT
    'RESULTADO GENERAL PASO 2' as tipo,
    CASE
        WHEN EXISTS (SELECT 1 FROM users WHERE role = 'employee' LIMIT 1) AND
             EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true LIMIT 1) THEN
            '✅ DATOS BÁSICOS EXISTEN - CONTINUAR CON PASO 3'
        WHEN NOT EXISTS (SELECT 1 FROM users WHERE role = 'employee' LIMIT 1) THEN
            '❌ FALTAN USUARIOS EMPLEADOS - CREAR UN USUARIO CON role=''employee'''
        WHEN NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true LIMIT 1) THEN
            '❌ FALTAN CONFIGURACIONES ACTIVAS - ACTIVAR UNA CONFIGURACIÓN'
        ELSE '❌ PROBLEMA DESCONOCIDO - REVISAR DETALLES ARRIBA'
    END as estado_datos;

-- 2.5 ACCIONES RECOMENDADAS
SELECT '2.5 ACCIONES RECOMENDADAS' as subpaso;

SELECT
    'ACCIONES PARA CONTINUAR' as tipo,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM users WHERE role = 'employee' LIMIT 1) THEN
            'INSERT INTO users (username, password, full_name, role) VALUES (''testuser'', ''password'', ''Test User'', ''employee'');'
        WHEN NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true LIMIT 1) THEN
            'UPDATE auto_time_settings SET enabled = true WHERE user_id IN (SELECT id FROM users WHERE role=''employee'' LIMIT 1);'
        WHEN EXISTS (SELECT 1 FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true) THEN
            'DELETE FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true; -- Limpiar para prueba'
        ELSE '✅ TODO LISTO - CONTINUAR CON PASO 3'
    END as accion_sql,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM users WHERE role = 'employee' LIMIT 1) THEN 'Crear usuario empleado'
        WHEN NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE enabled = true LIMIT 1) THEN 'Activar configuración'
        WHEN EXISTS (SELECT 1 FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true) THEN 'Limpiar registros automáticos de hoy'
        ELSE 'Todo listo para continuar'
    END as descripcion_accion;
