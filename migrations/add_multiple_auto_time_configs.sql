-- Migración para permitir múltiples configuraciones de tiempo automático por empleado
-- Esto permite tener diferentes horarios para diferentes días (ej: Lunes-Jueves vs Viernes)

-- Paso 1: Eliminar el constraint único en user_id
ALTER TABLE auto_time_settings DROP CONSTRAINT IF EXISTS auto_time_settings_user_id_unique;

-- Paso 2: Agregar columna 'name' para identificar cada configuración
ALTER TABLE auto_time_settings ADD COLUMN IF NOT EXISTS name text NOT NULL DEFAULT 'Configuración por defecto';

-- Paso 3: Agregar columna 'priority' para resolver conflictos entre configuraciones
ALTER TABLE auto_time_settings ADD COLUMN IF NOT EXISTS priority integer DEFAULT 0;

-- Paso 4: Actualizar registros existentes con nombres descriptivos
UPDATE auto_time_settings SET name = 'Horario principal' WHERE name = 'Configuración por defecto';

-- Paso 5: Verificar la estructura de la tabla
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings' 
ORDER BY ordinal_position;

-- Paso 6: Verificar registros existentes
SELECT * FROM auto_time_settings;
