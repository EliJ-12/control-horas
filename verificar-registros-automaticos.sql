-- Script para verificar registros automáticos en Supabase
-- Ejecuta este script en el SQL Editor de Supabase para verificar

-- 1. Verificar si la tabla auto_time_settings existe
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings' 
ORDER BY ordinal_position;

-- 2. Verificar si el campo is_auto_generated existe en work_logs
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'work_logs' AND column_name = 'is_auto_generated';

-- 3. Verificar configuraciones automáticas activas
SELECT 
    u.id as user_id,
    u.username,
    u.full_name,
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
    ats.created_at
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' OR ats.enabled = true
ORDER BY u.id;

-- 4. Verificar work logs con el nuevo campo
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.full_name,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.total_hours,
    wl.type,
    wl.is_auto_generated,
    wl.created_at,
    CASE 
        WHEN wl.is_auto_generated = true THEN 'Automático'
        ELSE 'Manual'
    END as origen
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date >= CURRENT_DATE - INTERVAL '7 days'  -- Últimos 7 días
ORDER BY wl.date DESC, wl.user_id, wl.created_at DESC;

-- 5. Verificar si hay registros automáticos recientes
SELECT 
    COUNT(*) as total_automaticos,
    COUNT(CASE WHEN wl.is_auto_generated = true THEN 1 END) as registros_automaticos,
    COUNT(CASE WHEN wl.is_auto_generated = false THEN 1 END) as registros_manuales,
    MAX(wl.created_at) as ultimo_registro
FROM work_logs wl
WHERE wl.date >= CURRENT_DATE - INTERVAL '7 days'
AND wl.type = 'work';

-- 6. Buscar registros automáticos de hoy
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.total_hours,
    wl.is_auto_generated,
    wl.created_at
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC;

-- 7. Estadísticas de registro automático
SELECT 
    DATE(wl.created_at) as fecha,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN wl.is_auto_generated = true THEN 1 END) as automaticos,
    COUNT(CASE WHEN wl.is_auto_generated = false THEN 1 END) as manuales,
    ROUND(
        COUNT(CASE WHEN wl.is_auto_generated = true THEN 1 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 2
    ) as porcentaje_automaticos
FROM work_logs wl
WHERE wl.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(wl.created_at)
ORDER BY fecha DESC;
