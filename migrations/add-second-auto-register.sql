-- Agregar columnas para segundo registro automático
ALTER TABLE auto_time_settings 
ADD COLUMN IF NOT EXISTS start_time_2 TEXT,
ADD COLUMN IF NOT EXISTS end_time_2 TEXT,
ADD COLUMN IF NOT EXISTS auto_register_time_2 TEXT;

-- Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings' 
AND column_name IN ('start_time_2', 'end_time_2', 'auto_register_time_2');
