-- Script para actualizar base de datos existente y configurar zona horaria España
-- Ejecuta esto PRIMERO en el SQL Editor de Supabase

-- 1. Agregar campo faltante a work_logs si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'work_logs' 
        AND column_name = 'is_auto_generated'
    ) THEN
        ALTER TABLE work_logs 
        ADD COLUMN is_auto_generated BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Campo is_auto_generated agregado a work_logs';
    ELSE
        RAISE NOTICE 'Campo is_auto_generated ya existe en work_logs';
    END IF;
END $$;

-- 2. Verificar que el campo se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'work_logs' AND column_name = 'is_auto_generated';

-- 3. Crear índice para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_work_logs_auto_generated 
ON work_logs(is_auto_generated);

-- 4. Configurar zona horaria para España (Europe/Madrid)
-- Esto afectará a las funciones CURRENT_TIMESTAMP y NOW()
SET timezone = 'Europe/Madrid';

-- 5. Verificar la zona horaria actual
SHOW timezone;

-- 6. Probar la hora actual en zona horaria España
SELECT 
    NOW() as hora_actual_espana,
    CURRENT_TIMESTAMP as timestamp_actual,
    CURRENT_TIME as hora_actual,
    CURRENT_DATE as fecha_actual;

-- 7. Verificar configuraciones automáticas existentes
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
    ats.created_at,
    CASE 
        WHEN ats.enabled = true THEN 'ACTIVADO'
        ELSE 'DESACTIVADO'
    END as estado
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' OR ats.enabled = true
ORDER BY u.id;

-- 8. Verificar registros de trabajo recientes
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
    END as origen,
    wl.created_at AT TIME ZONE 'Europe/Madrid' as fecha_creacion_espana
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date >= CURRENT_DATE - INTERVAL '3 days'
ORDER BY wl.date DESC, wl.created_at DESC;
