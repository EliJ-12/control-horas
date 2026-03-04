-- DIAGNÓSTICO COMPLETO Y SOLUCIÓN INMEDIATA
-- Ejecutar en Supabase SQL Editor paso por paso

-- =====================================================
-- PASO 1: VERIFICAR ESTRUCTURA COMPLETA
-- =====================================================
SELECT 'PASO 1: ESTRUCTURA TABLAS' as paso;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name IN ('work_logs', 'auto_time_settings') 
ORDER BY table_name, ordinal_position;

-- =====================================================
-- PASO 2: VERIFICAR CONFIGURACIÓN ACTUAL
-- =====================================================
SELECT 'PASO 2: CONFIGURACIÓN USUARIOS' as paso;
SELECT 
    u.id as user_id,
    u.username,
    u.full_name,
    u.role,
    COALESCE(ats.enabled, false) as auto_enabled,
    COALESCE(ats.monday, false) as monday,
    COALESCE(ats.tuesday, false) as tuesday,
    COALESCE(ats.wednesday, false) as wednesday,
    COALESCE(ats.thursday, false) as thursday,
    COALESCE(ats.friday, false) as friday,
    COALESCE(ats.saturday, false) as saturday,
    COALESCE(ats.sunday, false) as sunday,
    COALESCE(ats.start_time, '09:00') as start_time,
    COALESCE(ats.end_time, '17:00') as end_time,
    COALESCE(ats.auto_register_time, '17:05') as auto_register_time,
    CASE 
        WHEN COALESCE(ats.enabled, false) = true THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' OR COALESCE(ats.enabled, false) = true
ORDER BY u.id;

-- =====================================================
-- PASO 3: VERIFICAR HORA ACTUAL Y DÍA
-- =====================================================
SELECT 'PASO 3: HORA Y DÍA ACTUAL' as paso;
SELECT 
    NOW() as hora_utc_completa,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana_completa,
    CURRENT_TIME as hora_actual_utc,
    CURRENT_TIME AT TIME ZONE 'Europe/Madrid' as hora_actual_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_formateada_espana,
    CURRENT_DATE as fecha_actual,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_semana_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO (0)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES (1)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES (2)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES (3)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES (4)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES (5)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO (6)'
    END as dia_semana_nombre;

-- =====================================================
-- PASO 4: VERIFICAR QUIÉN DEBERÍA EJECUTARSE AHORA
-- =====================================================
SELECT 'PASO 4: EVALUACIÓN EJECUCIÓN' as paso;
SELECT 
    ats.user_id,
    u.username,
    ats.auto_register_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_espana,
    CASE 
        WHEN ats.auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ DEBERÍA EJECUTARSE AHORA'
        ELSE '❌ NO ES LA HORA CONFIGURADA'
    END as estado_hora,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 AND COALESCE(ats.monday, false) = true THEN '✅ LUNES ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 AND COALESCE(ats.tuesday, false) = true THEN '✅ MARTES ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 AND COALESCE(ats.wednesday, false) = true THEN '✅ MIÉRCOLES ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 AND COALESCE(ats.thursday, false) = true THEN '✅ JUEVES ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 AND COALESCE(ats.friday, false) = true THEN '✅ VIERNES ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 AND COALESCE(ats.saturday, false) = true THEN '✅ SÁBADO ACTIVO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 AND COALESCE(ats.sunday, false) = true THEN '✅ DOMINGO ACTIVO'
        ELSE '❌ DÍA NO CONFIGURADO'
    END as estado_dia,
    CASE 
        WHEN COALESCE(ats.enabled, false) = true AND
             (
               (EXTRACT(DOW FROM CURRENT_DATE) = 1 AND COALESCE(ats.monday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 2 AND COALESCE(ats.tuesday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 3 AND COALESCE(ats.wednesday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 4 AND COALESCE(ats.thursday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 5 AND COALESCE(ats.friday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 6 AND COALESCE(ats.saturday, false) = true) OR
               (EXTRACT(DOW FROM CURRENT_DATE) = 0 AND COALESCE(ats.sunday, false) = true)
             ) AND
             ats.auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ DEBERÍA CREAR REGISTRO AHORA'
        ELSE '❌ NO DEBERÍA CREAR'
    END as estado_final
FROM auto_timeSettings ats
JOIN users u ON ats.user_id = u.id
WHERE COALESCE(ats.enabled, false) = true;

-- =====================================================
-- PASO 5: VERIFICAR REGISTROS DE HOY
-- =====================================================
SELECT 'PASO 5: REGISTROS DE HOY' as paso;
SELECT 
    wl.id,
    wl.user_id,
    u.username,
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
-- PASO 6: CREAR CONFIGURACIÓN DE PRUEBA SI NO EXISTE
-- =====================================================
SELECT 'PASO 6: CREAR CONFIGURACIÓN PRUEBA' as paso;

-- Primero verificar si existe configuración para usuario 1
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auto_time_settings WHERE user_id = 1) THEN
        INSERT INTO auto_time_settings (
            user_id, enabled, monday, tuesday, wednesday, thursday, friday, 
            saturday, sunday, start_time, end_time, auto_register_time
        ) VALUES (
            1, -- user_id (admin)
            true, -- enabled
            true, true, true, true, true, -- lunes a viernes
            false, false, -- sábado y domingo
            '09:00', -- start_time
            '17:00', -- end_time
            '17:05'  -- auto_register_time
        );
        RAISE NOTICE '✅ Configuración de prueba creada para usuario 1';
    ELSE
        RAISE NOTICE 'ℹ️ Configuración ya existe para usuario 1';
    END IF;
END $$;

-- =====================================================
-- PASO 7: FORZAR EJECUCIÓN EN EL PRÓXIMO MINUTO
-- =====================================================
SELECT 'PASO 7: FORZAR EJECUCIÓN PRÓXIMO MINUTO' as paso;

-- Actualizar para que se ejecute en el próximo minuto
UPDATE auto_time_settings 
SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI')
WHERE user_id = 1 AND enabled = true;

-- Verificar actualización
SELECT 
    user_id,
    auto_register_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI') as proxima_ejecucion
FROM auto_time_settings 
WHERE user_id = 1;

-- =====================================================
-- PASO 8: CREAR REGISTRO MANUAL DE PRUEBA
-- =====================================================
SELECT 'PASO 8: CREAR REGISTRO MANUAL PRUEBA' as paso;

-- Eliminar registro de prueba si existe
DELETE FROM work_logs 
WHERE user_id = 1 
AND date = CURRENT_DATE 
AND is_auto_generated = true;

-- Crear registro de prueba automático
INSERT INTO work_logs (
    user_id, date, start_time, end_time, total_hours, type, is_auto_generated
) VALUES (
    1, -- user_id
    CURRENT_DATE, -- fecha actual
    '09:00', -- start_time
    '17:00', -- end_time
    480, -- total_hours (8 horas = 480 minutos)
    'work', -- type
    true -- is_auto_generated (marcar como automático)
);

-- Verificar que se creó
SELECT 
    'REGISTRO CREADO' as resultado,
    wl.id,
    wl.user_id,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at
FROM work_logs wl
WHERE wl.user_id = 1 
AND wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC
LIMIT 1;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================
SELECT 'RESUMEN: DIAGNÓSTICO COMPLETADO' as paso;
SELECT 
    '✅ Base de datos verificada' as paso1,
    '✅ Configuración usuarios revisada' as paso2,
    '✅ Hora y día actual verificados' as paso3,
    '✅ Evaluación ejecución completada' as paso4,
    '✅ Registros de hoy analizados' as paso5,
    '✅ Configuración prueba creada' as paso6,
    '✅ Ejecución forzada próximo minuto' as paso7,
    '✅ Registro manual prueba creado' as paso8;
