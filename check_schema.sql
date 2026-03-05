-- Verificar tipos de datos reales en las tablas
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'auto_time_settings', 'work_logs')
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;
