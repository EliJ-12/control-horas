-- Script de prueba para crear registro automático inmediatamente
-- Ejecuta esto después de actualizar la base de datos

-- 1. Verificar que el campo existe
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'work_logs' AND column_name = 'is_auto_generated';

-- 2. Crear configuración de prueba (si no existe)
INSERT INTO auto_time_settings (
    user_id, enabled, monday, tuesday, wednesday, thursday, friday, saturday, sunday,
    start_time, end_time, auto_register_time
) VALUES (
    1, -- ID del usuario admin (ajusta según tu usuario)
    true, -- enabled
    true, true, true, true, true, -- lunes a viernes
    false, false, -- sábado y domingo
    '09:00', -- start_time
    '17:00', -- end_time
    '17:05'  -- auto_register_time (ajusta a hora actual + 2 minutos)
) ON CONFLICT (user_id) DO UPDATE SET
    enabled = EXCLUDED.enabled,
    monday = EXCLUDED.monday,
    tuesday = EXCLUDED.tuesday,
    wednesday = EXCLUDED.wednesday,
    thursday = EXCLUDED.thursday,
    friday = EXCLUDED.friday,
    saturday = EXCLUDED.saturday,
    sunday = EXCLUDED.sunday,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    auto_register_time = EXCLUDED.auto_register_time;

-- 3. Verificar configuración creada
SELECT * FROM auto_time_settings WHERE user_id = 1;

-- 4. Crear registro manual de prueba para verificar que el campo funciona
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

-- 5. Verificar que el registro se creó correctamente
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
    CASE 
        WHEN wl.is_auto_generated = true THEN 'AUTOMÁTICO'
        ELSE 'MANUAL'
    END as origen
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY wl.created_at DESC
LIMIT 5;

-- 6. Limpiar registro de prueba (opcional)
-- DELETE FROM work_logs WHERE user_id = 1 AND date = CURRENT_DATE AND is_auto_generated = true;

-- 7. Verificar hora actual en España
SELECT 
    NOW() as hora_utc,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana,
    CURRENT_TIME as hora_actual,
    CURRENT_TIME AT TIME ZONE 'Europe/Madrid' as hora_espana_actual;
