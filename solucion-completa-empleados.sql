-- SOLUCIÓN COMPLETA: Sistema de Registros Automáticos para Empleados
-- Ejecutar en Supabase SQL Editor paso por paso

-- =====================================================
-- PASO 1: VERIFICAR ESTRUCTURA COMPLETA DE TABLAS
-- =====================================================
SELECT '=== VERIFICANDO ESTRUCTURA DE TABLAS ===' as paso;

-- Verificar tabla users
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Verificar tabla auto_time_settings
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings' 
ORDER BY ordinal_position;

-- Verificar tabla work_logs
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'work_logs' 
ORDER BY ordinal_position;

-- =====================================================
-- PASO 2: VERIFICAR USUARIOS EMPLEADOS
-- =====================================================
SELECT '=== USUARIOS EMPLEADOS ===' as paso;
SELECT 
    u.id,
    u.username,
    u.full_name,
    u.role,
    CASE 
        WHEN u.role = 'employee' THEN '✅ EMPLEADO'
        WHEN u.role = 'admin' THEN '👑 ADMIN'
        ELSE '❌ OTRO'
    END as tipo_usuario,
    CASE 
        WHEN ats.enabled IS NOT NULL THEN '✅ TIENE CONFIGURACIÓN'
        ELSE '❌ SIN CONFIGURACIÓN'
    END as estado_configuracion
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee'
ORDER BY u.id;

-- =====================================================
-- PASO 3: VERIFICAR CONFIGURACIONES DE EMPLEADOS
-- =====================================================
SELECT '=== CONFIGURACIONES DE EMPLEADOS ===' as paso;
SELECT 
    ats.id,
    ats.user_id,
    u.username,
    u.full_name,
    u.role,
    ats.enabled,
    ats.monday,
    ats.tuesday,
    ats.wednesday,
    ats.thursday,
    ats.friday,
    ats.saturday,
    ats.sunday,
    ats.start_time::text as hora_inicio,
    ats.end_time::text as hora_fin,
    ats.auto_register_time::text as hora_registro,
    CASE 
        WHEN ats.enabled = true THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 AND 
             (
               (EXTRACT(DOW FROM CURRENT_DATE) = 1 AND ats.monday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 2 AND ats.tuesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 3 AND ats.wednesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 4 AND ats.thursday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 5 AND ats.friday = true)
             )
        THEN '✅ DÍA ACTIVO HOY'
        ELSE '❌ DÍA INACTIVO HOY'
    END as estado_dia_hoy
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE u.role = 'employee'
ORDER BY u.id;

-- =====================================================
-- PASO 4: VERIFICAR HORA ACTUAL Y EVALUACIÓN
-- =====================================================
SELECT '=== EVALUACIÓN DE EJECUCIÓN ===' as paso;
SELECT 
    NOW() as hora_utc_completa,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana_completa,
    CURRENT_TIME as hora_actual_utc,
    CURRENT_TIME AT TIME ZONE 'Europe/Madrid' as hora_actual_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_completa_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_formateada_espana,
    CURRENT_DATE as fecha_actual,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_semana_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES (1)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES (2)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES (3)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES (4)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES (5)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO (6)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO (0)'
    END as dia_semana_nombre;

-- =====================================================
-- PASO 5: EVALUAR QUÉ EMPLEADOS DEBERÍAN EJECUTARSE
-- =====================================================
SELECT '=== EMPLEADOS QUE DEBERÍAN EJECUTARSE ===' as paso;
SELECT 
    ats.user_id,
    u.username,
    u.full_name,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_espana,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ HORA COINCIDE'
        ELSE '❌ HORA NO COINCIDE'
    END as estado_hora,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 AND 
             (
               (EXTRACT(DOW FROM CURRENT_DATE) = 1 AND ats.monday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 2 AND ats.tuesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 3 AND ats.wednesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 4 AND ats.thursday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 5 AND ats.friday = true)
             )
        THEN '✅ DÍA LABORAL ACTIVO'
        ELSE '❌ DÍA NO LABORAL'
    END as estado_dia,
    CASE 
        WHEN ats.enabled = true AND
             (
               (EXTRACT(DOW FROM CURRENT_DATE) = 1 AND ats.monday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 2 AND ats.tuesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 3 AND ats.wednesday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 4 AND ats.thursday = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 5 AND ats.friday = true)
             ) AND
             ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ DEBERÍA CREAR REGISTRO AHORA'
        ELSE '❌ NO DEBERÍA CREAR'
    END as estado_final
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE u.role = 'employee' AND ats.enabled = true;

-- =====================================================
-- PASO 6: VERIFICAR REGISTROS DE TRABAJO DE HOY
-- =====================================================
SELECT '=== REGISTROS DE TRABAJO DE HOY ===' as paso;
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.full_name,
    u.role,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.total_hours,
    wl.type,
    wl.is_auto_generated,
    wl.created_at,
    wl.created_at AT TIME ZONE 'Europe/Madrid' as fecha_creacion_espana,
    CASE 
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as origen,
    CASE 
        WHEN wl.date = CURRENT_DATE THEN 'HOY'
        WHEN wl.date = CURRENT_DATE - INTERVAL '1 day' THEN 'AYER'
        ELSE 'ANTERIOR'
    END as periodo
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date >= CURRENT_DATE - INTERVAL '3 days'
ORDER BY wl.date DESC, wl.created_at DESC;

-- =====================================================
-- PASO 7: CREAR CONFIGURACIÓN PARA EMPLEADOS SI NO EXISTE
-- =====================================================
SELECT '=== CREANDO CONFIGURACIÓN PARA EMPLEADOS ===' as paso;

-- Obtener todos los empleados sin configuración
DO $$
DECLARE
    emp_record RECORD;
    emp_count INTEGER := 0;
BEGIN
    FOR emp_record IN 
        SELECT id, username FROM users WHERE role = 'employee' 
        AND id NOT IN (SELECT user_id FROM auto_time_settings)
    LOOP
        -- Insertar configuración para cada empleado
        INSERT INTO auto_time_settings (
            user_id, enabled, monday, tuesday, wednesday, thursday, friday,
            saturday, sunday, start_time, end_time, auto_register_time
        ) VALUES (
            emp_record.id, -- user_id
            true, -- enabled
            true, true, true, true, true, -- lunes a viernes
            false, false, -- sábado y domingo
            '09:00', -- start_time
            '17:00', -- end_time
            '17:05'  -- auto_register_time
        );
        
        emp_count := emp_count + 1;
        RAISE NOTICE '✅ Configuración creada para empleado % (%)', emp_record.id, emp_record.username;
    END LOOP;
    
    IF emp_count > 0 THEN
        RAISE NOTICE '✅ Se crearon configuraciones para % empleados', emp_count;
    ELSE
        RAISE NOTICE 'ℹ️ Todos los empleados ya tienen configuración';
    END IF;
END $$;

-- =====================================================
-- PASO 8: FORZAR EJECUCIÓN PARA PRÓXIMO MINUTO
-- =====================================================
SELECT '=== CONFIGURANDO EJECUCIÓN INMEDIATA ===' as paso;

-- Actualizar todos los empleados para que se ejecuten en el próximo minuto
UPDATE auto_time_settings 
SET auto_register_time = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI'))::time
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee') AND enabled = true;

-- Verificar actualización
SELECT 
    'EMPLEADOS CONFIGURADOS PARA EJECUTAR EN 1 MINUTO' as resultado,
    COUNT(*) as total_empleados,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI') as proxima_ejecucion
FROM auto_time_settings 
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee') AND enabled = true;

-- =====================================================
-- PASO 9: LIMPIAR REGISTROS DE PRUEBA DE HOY
-- =====================================================
SELECT '=== LIMPIANDO REGISTROS DE PRUEBA ===' as paso;

-- Eliminar registros automáticos de hoy para prueba
DELETE FROM work_logs 
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee') 
AND date = CURRENT_DATE 
AND is_auto_generated = true;

-- Mostrar cuántos se eliminaron
SELECT 
    'REGISTROS AUTOMÁTICOS ELIMINADOS' as resultado,
    (SELECT COUNT(*) FROM work_logs 
     WHERE user_id IN (SELECT id FROM users WHERE role = 'employee') 
     AND date = CURRENT_DATE 
     AND is_auto_generated = true) as registros_restantes,
    'Todos los registros automáticos de hoy han sido eliminados' as mensaje;

-- =====================================================
-- PASO 10: VERIFICAR ESTADO FINAL
-- =====================================================
SELECT '=== ESTADO FINAL DEL SISTEMA ===' as paso;

-- Resumen de empleados
SELECT 
    'RESUMEN EMPLEADOS' as tipo,
    COUNT(*) as total,
    COUNT(CASE WHEN ats.enabled = true THEN 1 END) as con_configuracion_activa,
    COUNT(CASE WHEN ats.enabled = false OR ats.enabled IS NULL THEN 1 END) as sin_configuracion
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee';

-- Resumen de configuraciones
SELECT 
    'RESUMEN CONFIGURACIONES' as tipo,
    COUNT(*) as total_configuraciones,
    COUNT(CASE WHEN enabled = true THEN 1 END) as activas,
    COUNT(CASE WHEN enabled = false THEN 1 END) as inactivas
FROM auto_time_settings 
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee');

-- Hora de próxima ejecución
SELECT 
    'PRÓXIMA EJECUCIÓN' as tipo,
    MIN(auto_register_time::text) as hora_minima,
    MAX(auto_register_time::text) as hora_maxima,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual
FROM auto_time_settings 
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee') AND enabled = true;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================
SELECT 
    '=== SISTEMA LISTO PARA PROBAR ===' as titulo,
    '✅ Empleados identificados' as paso1,
    '✅ Configuraciones creadas/actualizadas' as paso2,
    '✅ Hora configurada para próximo minuto' as paso3,
    '✅ Registros de prueba limpiados' as paso4,
    '✅ Sistema listo para scheduler' as paso5;

SELECT 
    '=== PRÓXIMOS PASOS ===' as titulo,
    '1. Iniciar servidor: npm run dev' as paso1,
    '2. Esperar 1 minuto para ejecución automática' as paso2,
    '3. Revisar logs del servidor' as paso3,
    '4. Verificar nuevos registros en work_logs' as paso4,
    '5. Probar frontend de empleado' as paso5;
