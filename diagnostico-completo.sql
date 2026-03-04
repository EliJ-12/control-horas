-- DIAGNÓSTICO COMPLETO - Ejecutar paso a paso en Supabase SQL Editor

-- PASO 1: Verificar estructura completa de work_logs
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'work_logs' 
ORDER BY ordinal_position;

-- PASO 2: Verificar que auto_time_settings existe y tiene datos
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings'
ORDER BY ordinal_position;

-- PASO 3: Verificar configuraciones activas
SELECT 
    u.id as user_id,
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
    ats.start_time,
    ats.end_time,
    ats.auto_register_time,
    CASE 
        WHEN ats.enabled = true THEN 'ACTIVADO'
        ELSE 'DESACTIVADO'
    END as estado,
    CASE 
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 1 AND ats.monday = true THEN 'HOY TOCA LUNES'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 2 AND ats.tuesday = true THEN 'HOY TOCA MARTES'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 3 AND ats.wednesday = true THEN 'HOY TOCA MIÉRCOLES'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 4 AND ats.thursday = true THEN 'HOY TOCA JUEVES'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 5 AND ats.friday = true THEN 'HOY TOCA VIERNES'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 6 AND ats.saturday = true THEN 'HOY TOCA SÁBADO'
        WHEN CURRENT_DATE >= CURRENT_DATE AND 
        EXTRACT(DOW FROM CURRENT_DATE) = 0 AND ats.sunday = true THEN 'HOY TOCA DOMINGO'
        ELSE 'HOY NO TOCA'
    END as dia_actual
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' OR ats.enabled = true
ORDER BY u.id;

-- PASO 4: Verificar hora actual y configuración
SELECT 
    NOW() as hora_utc_completa,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana_completa,
    CURRENT_TIME as hora_actual_utc,
    CURRENT_TIME AT TIME ZONE 'Europe/Madrid' as hora_actual_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_formateada_espana,
    CURRENT_DATE as fecha_actual,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_semana_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO'
    END as dia_semana_nombre;

-- PASO 5: Verificar registros de hoy
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
        WHEN wl.is_auto_generated = true THEN 'AUTOMÁTICO'
        ELSE 'MANUAL'
    END as origen,
    CASE 
        WHEN wl.date = CURRENT_DATE THEN 'HOY'
        WHEN wl.date = CURRENT_DATE - INTERVAL '1 day' THEN 'AYER'
        ELSE 'ANTERIOR'
    END as periodo
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY wl.date DESC, wl.created_at DESC;

-- PASO 6: Verificar si el scheduler debería ejecutarse ahora
SELECT 
    ats.user_id,
    u.username,
    ats.auto_register_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_espana,
    CASE 
        WHEN ats.auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN 'DEBERÍA EJECUTARSE AHORA'
        ELSE 'NO ES LA HORA'
    END as estado_ejecucion,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 AND ats.monday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 AND ats.tuesday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 AND ats.wednesday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 AND ats.thursday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 AND ats.friday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 AND ats.saturday = true THEN 'DÍA CORRECTO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 AND ats.sunday = true THEN 'DÍA CORRECTO'
        ELSE 'DÍA INCORRECTO'
    END as dia_valido
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true;

-- PASO 7: Forzar creación para prueba (descomentar si necesario)
/*
-- Configurar para ejecutar en el próximo minuto
UPDATE auto_time_settings 
SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI')
WHERE enabled = true;

-- Verificar actualización
SELECT auto_register_time FROM auto_time_settings WHERE enabled = true;
*/
