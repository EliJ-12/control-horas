-- BÚSQUEDA SISTEMÁTICA DEL PROBLEMA
-- Ejecutar en Supabase SQL Editor paso por paso

-- =====================================================
-- PASO 1: VERIFICAR ESTRUCTURA COMPLETA DE work_logs
-- =====================================================
SELECT '=== PASO 1: ESTRUCTURA DE work_logs ===' as paso;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'work_logs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar si existe la columna is_auto_generated
SELECT 
    'COLUMNA is_auto_generated' as tipo,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'work_logs' 
            AND column_name = 'is_auto_generated'
        ) THEN '✅ EXISTE'
        ELSE '❌ NO EXISTE - ESTE ES EL PROBLEMA'
    END as estado;

-- =====================================================
-- PASO 2: VERIFICAR REGISTROS EXISTENTES
-- =====================================================
SELECT '=== PASO 2: REGISTROS EXISTENTES ===' as paso;

-- Mostrar todos los registros de hoy
SELECT 
    'TODOS LOS REGISTROS DE HOY' as tipo,
    COUNT(*) as total_registros,
    STRING_AGG(
        CASE 
            WHEN is_auto_generated = true THEN 'AUTO'
            ELSE 'MANUAL'
        END, ', '
    ) as tipos
FROM work_logs 
WHERE date = CURRENT_DATE;

-- Mostrar detalles de todos los registros de hoy
SELECT 
    'DETALLES COMPLETOS' as tipo,
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
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as origen
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 3: VERIFICAR USUARIOS Y CONFIGURACIÓN
-- =====================================================
SELECT '=== PASO 3: USUARIOS Y CONFIGURACIÓN ===' as paso;

-- Verificar usuarios empleados
SELECT 
    'USUARIOS EMPLEADOS' as tipo,
    u.id,
    u.username,
    u.role,
    CASE 
        WHEN ats.enabled IS NOT NULL THEN '✅ TIENE CONFIG'
        ELSE '❌ SIN CONFIG'
    END as estado_config
FROM users u
LEFT JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee'
ORDER BY u.id;

-- Verificar configuración detallada
SELECT 
    'CONFIGURACIÓN DETALLADA' as tipo,
    u.id as user_id,
    u.username,
    ats.enabled,
    ats.monday,
    ats.tuesday,
    ats.wednesday,
    ats.thursday,
    ats.friday,
    ats.saturday,
    ats.sunday,
    ats.auto_register_time::text as hora_config,
    ats.start_time,
    ats.end_time
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true;

-- =====================================================
-- PASO 4: VERIFICAR CONDICIONES DE EJECUCIÓN
-- =====================================================
SELECT '=== PASO 4: CONDICIONES DE EJECUCIÓN ===' as paso;

-- Verificar día actual
SELECT 
    'DÍA ACTUAL' as tipo,
    CURRENT_DATE as fecha,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO'
    END as dia_nombre;

-- Verificar hora actual
SELECT 
    'HORA ACTUAL' as tipo,
    NOW() as utc_time,
    NOW() AT TIME ZONE 'Europe/Madrid' as spain_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as spain_hhmmss,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as spain_hhmm;

-- =====================================================
-- PASO 5: PROBAR INSERCIÓN MANUAL COMPLETA
-- =====================================================
SELECT '=== PASO 5: INSERCIÓN MANUAL COMPLETA ===' as paso;

-- Limpiar primero
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

-- Probar inserción con todos los campos
DO $$
DECLARE
    emp_id INTEGER;
    emp_username TEXT;
    insert_result RECORD;
BEGIN
    -- Obtener empleado
    SELECT u.id, u.username INTO emp_id, emp_username
    FROM users u
    WHERE u.role = 'employee' 
    LIMIT 1;
    
    IF emp_id IS NOT NULL THEN
        -- Insertar con todos los campos
        INSERT INTO work_logs (
            user_id, 
            date, 
            start_time, 
            end_time, 
            total_hours, 
            type, 
            is_auto_generated
        ) VALUES (
            emp_id,
            CURRENT_DATE,
            '09:00',
            '17:00',
            480,
            'work',
            true
        ) RETURNING * INTO insert_result;
        
        RAISE NOTICE '✅ Inserción manual exitosa: ID=%, Usuario=%', insert_result.id, emp_username;
        
        -- Verificar que se puede leer
        PERFORM * FROM work_logs 
        WHERE id = insert_result.id;
        
        IF FOUND THEN
            RAISE NOTICE '✅ Verificación de lectura exitosa';
        ELSE
            RAISE NOTICE '❌ Error: No se puede leer el registro insertado';
        END IF;
    ELSE
        RAISE NOTICE '❌ No se encontró empleado para prueba';
    END IF;
END $$;

-- Verificar resultado final
SELECT 
    'RESULTADO FINAL INSERCIÓN' as tipo,
    wl.id,
    wl.user_id,
    u.username,
    wl.is_auto_generated,
    wl.created_at,
    CASE 
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as origen
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC
LIMIT 1;

-- =====================================================
-- PASO 6: VERIFICAR POLÍTICAS RLS
-- =====================================================
SELECT '=== PASO 6: POLÍTICAS RLS ===' as paso;

-- Verificar si RLS está activado
SELECT 
    'RLS EN work_logs' as tipo,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE tablename = 'work_logs' 
            AND rowsecurity = true
        ) THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado_rls;

-- Mostrar políticas existentes
SELECT 
    'POLÍTICAS EXISTENTES' as tipo,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'work_logs'
ORDER BY policyname;

-- =====================================================
-- DIAGNÓSTICO FINAL
-- =====================================================
SELECT 
    '=== DIAGNÓSTICO FINAL ===' as titulo,
    '1. Si is_auto_generated no existe:' as paso1,
    '   - Agregar columna: ALTER TABLE work_logs ADD COLUMN is_auto_generated BOOLEAN DEFAULT FALSE' as solucion1,
    '2. Si no hay usuarios empleados:' as paso2,
    '   - Crear usuario con role employee' as solucion2,
    '3. Si no hay configuración:' as paso3,
    '   - Crear configuración en auto_time_settings' as solucion3,
    '4. Si RLS bloquea:' as paso4,
    '   - Desactivar RLS o crear políticas correctas' as solucion4,
    '5. Si inserción manual funciona:' as paso5,
    '   - El problema está en el scheduler del servidor' as solucion5;
