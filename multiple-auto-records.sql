-- MIGRACIÓN: Permitir múltiples registros automáticos por día

-- PASO 1: Eliminar constraint único que previene múltiples registros por día
ALTER TABLE work_logs DROP CONSTRAINT IF EXISTS unique_user_date_auto;

-- PASO 2: Modificar auto_time_settings para permitir múltiples configuraciones por usuario
ALTER TABLE auto_time_settings DROP CONSTRAINT IF EXISTS auto_time_settings_user_id_key;

-- PASO 3: Agregar un campo para identificar el "slot" o período del registro
ALTER TABLE work_logs ADD COLUMN IF NOT EXISTS slot_id INTEGER DEFAULT 1;

-- PASO 4: Crear nuevo constraint único que permite múltiples registros pero previene duplicados exactos
ALTER TABLE work_logs ADD CONSTRAINT unique_user_date_slot 
UNIQUE (user_id, date, slot_id);

-- PASO 5: Actualizar auto_time_settings para incluir slot_id
ALTER TABLE auto_time_settings ADD COLUMN IF NOT EXISTS slot_id INTEGER DEFAULT 1;

-- PASO 6: Crear constraint único para auto_time_settings (user_id + slot_id)
ALTER TABLE auto_time_settings ADD CONSTRAINT unique_user_slot 
UNIQUE (user_id, slot_id);

-- Verificar cambios
SELECT 
    '=== ESTRUCTURA ACTUAL ===' as info,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('work_logs', 'auto_time_settings')
AND column_name IN ('slot_id', 'user_id', 'date')
ORDER BY table_name, column_name;

-- Verificar constraints
SELECT 
    '=== CONSTRAINTS ===' as info,
    conname,
    contype,
    pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid::regclass::text IN ('work_logs', 'auto_time_settings')
ORDER BY conrelid::regclass::text, conname;
