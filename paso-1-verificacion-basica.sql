-- PASO 1 DE 5: VERIFICACIÓN BÁSICA DEL SISTEMA
-- Ejecutar este script PRIMERO y verificar cada resultado

SELECT '=== PASO 1: VERIFICACIÓN DEL SISTEMA BÁSICO ===' as paso;

-- 1.1 Verificar que las tablas existen
SELECT '1.1 TABLAS EXISTENTES' as subpaso;

SELECT
    table_name,
    CASE
        WHEN table_name IN ('users', 'work_logs', 'auto_time_settings') THEN '✅ EXISTE (REQUERIDA)'
        ELSE 'ℹ️ EXISTE (OPCIONAL)'
    END as estado
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('users', 'work_logs', 'auto_time_settings', 'absences')
ORDER BY table_name;

-- 1.2 Verificar estructura de work_logs
SELECT '1.2 ESTRUCTURA DE work_logs' as subpaso;

SELECT
    column_name,
    data_type,
    is_nullable,
    CASE
        WHEN column_name = 'is_auto_generated' AND data_type = 'boolean' THEN '✅ CORRECTO'
        WHEN column_name = 'is_auto_generated' AND data_type != 'boolean' THEN '❌ INCORRECTO - DEBE SER BOOLEAN'
        WHEN column_name IN ('id', 'user_id', 'date', 'start_time', 'end_time', 'total_hours') THEN '✅ CORRECTO'
        ELSE 'ℹ️ VERIFICAR'
    END as estado
FROM information_schema.columns
WHERE table_name = 'work_logs'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 1.3 Verificar estructura de auto_time_settings
SELECT '1.3 ESTRUCTURA DE auto_time_settings' as subpaso;

SELECT
    column_name,
    data_type,
    is_nullable,
    CASE
        WHEN column_name IN ('user_id', 'enabled', 'auto_register_time') THEN '✅ CRÍTICO'
        WHEN column_name IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday') THEN '✅ DÍAS LABORABLES'
        WHEN column_name IN ('start_time', 'end_time') THEN '✅ HORARIO'
        ELSE 'ℹ️ OPCIONAL'
    END as importancia
FROM information_schema.columns
WHERE table_name = 'auto_time_settings'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 1.4 Verificar zona horaria
SELECT '1.4 ZONA HORARIA DEL SISTEMA' as subpaso;

SELECT
    'ZONA HORARIA ACTUAL' as tipo,
    NOW() as utc_time,
    NOW() AT TIME ZONE 'Europe/Madrid' as spain_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD HH24:MI:SS') as spain_formatted,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as spain_hhmm,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as spain_dow;

-- 1.5 RESULTADO DEL PASO 1
SELECT '1.5 RESULTADO PASO 1' as subpaso;

SELECT
    'RESULTADO GENERAL PASO 1' as tipo,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'work_logs' AND column_name = 'is_auto_generated'
        ) THEN '✅ ESTRUCTURA BÁSICA CORRECTA - CONTINUAR CON PASO 2'
        ELSE '❌ FALTA COLUMNA is_auto_generated - EJECUTAR: ALTER TABLE work_logs ADD COLUMN is_auto_generated BOOLEAN DEFAULT FALSE;'
    END as estado_sistema;

-- INSTRUCCIONES PARA CONTINUAR
SELECT '=== INSTRUCCIONES PARA CONTINUAR ===' as titulo;
SELECT 'Si el resultado es ✅: Ejecuta el PASO 2' as siguiente;
SELECT 'Si el resultado es ❌: Ejecuta el comando ALTER TABLE y vuelve a ejecutar PASO 1' as solucion;
