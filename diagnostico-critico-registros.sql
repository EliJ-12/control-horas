-- DIAGNÓSTICO CRÍTICO: ¿Por qué no aparece el registro en BD?
-- Ejecutar en Supabase SQL Editor paso por paso

-- =====================================================
-- PASO 1: VERIFICAR ESTRUCTURA EXACTA DE work_logs
-- =====================================================
SELECT '=== ESTRUCTURA TABLA work_logs ===' as paso;
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

-- =====================================================
-- PASO 2: VERIFICAR SI EXISTE LA COLUMNA is_auto_generated
-- =====================================================
SELECT '=== VERIFICANDO COLUMNA is_auto_generated ===' as paso;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'work_logs' 
            AND column_name = 'is_auto_generated'
        ) THEN '✅ COLUMNA EXISTE'
        ELSE '❌ COLUMNA NO EXISTE - ESTE ES EL PROBLEMA'
    END as estado_columna;

-- Si la columna no existe, agregarla
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'work_logs' 
        AND column_name = 'is_auto_generated'
    ) THEN
        ALTER TABLE work_logs 
        ADD COLUMN is_auto_generated BOOLEAN DEFAULT FALSE;
        RAISE NOTICE '✅ Columna is_auto_generated agregada a work_logs';
    ELSE
        RAISE NOTICE 'ℹ️ Columna is_auto_generated ya existe en work_logs';
    END IF;
END $$;

-- =====================================================
-- PASO 3: VERIFICAR REGISTROS RECIENTES
-- =====================================================
SELECT '=== REGISTROS RECIENTES EN work_logs ===' as paso;
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.role,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.total_hours,
    wl.type,
    wl.is_auto_generated,
    wl.created_at,
    wl.created_at AT TIME ZONE 'Europe/Madrid' as fecha_creacion_espana,
    CASE 
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as origen,
    CASE 
        WHEN wl.created_at >= NOW() - INTERVAL '10 minutes' THEN 'ÚLTIMOS 10 MINUTOS'
        WHEN wl.created_at >= NOW() - INTERVAL '1 hour' THEN 'ÚLTIMA HORA'
        ELSE 'MÁS ANTIGUO'
    END as antiguedad
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.created_at >= NOW() - INTERVAL '2 hours'
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 4: VERIFICAR CONEXIÓN Y PERMISOS
-- =====================================================
SELECT '=== VERIFICANDO CONEXIÓN ===' as paso;
SELECT 
    'Conexión directa a Supabase' as estado,
    NOW() as timestamp_actual,
    CURRENT_USER as usuario_actual,
    current_database() as base_datos_actual;

-- =====================================================
-- PASO 5: CREAR REGISTRO MANUAL PARA PROBAR
-- =====================================================
SELECT '=== CREANDO REGISTRO MANUAL DE PRUEBA ===' as paso;

-- Primero eliminar registros de prueba si existen
DELETE FROM work_logs 
WHERE user_id IN (SELECT id FROM users WHERE role = 'employee' LIMIT 1)
AND date = CURRENT_DATE 
AND is_auto_generated = true;

-- Obtener un empleado para prueba
DO $$
DECLARE
    emp_id INTEGER;
    emp_username TEXT;
BEGIN
    SELECT id, username INTO emp_id, emp_username 
    FROM users 
    WHERE role = 'employee' 
    LIMIT 1;
    
    IF emp_id IS NOT NULL THEN
        -- Insertar registro manual de prueba
        INSERT INTO work_logs (
            user_id, date, start_time, end_time, total_hours, type, is_auto_generated
        ) VALUES (
            emp_id, -- user_id
            CURRENT_DATE, -- fecha actual
            '09:00', -- start_time
            '17:00', -- end_time
            480, -- total_hours (8 horas = 480 minutos)
            'work', -- type
            true -- is_auto_generated (marcar como automático)
        );
        
        RAISE NOTICE '✅ Registro de prueba creado para empleado % (%)', emp_id, emp_username;
        
        -- Verificar que se creó
        PERFORM * FROM work_logs 
        WHERE user_id = emp_id 
        AND date = CURRENT_DATE 
        AND is_auto_generated = true;
        
        IF FOUND THEN
            RAISE NOTICE '✅ Registro verificado en la base de datos';
        ELSE
            RAISE NOTICE '❌ Registro NO encontrado en la base de datos';
        END IF;
    ELSE
        RAISE NOTICE '❌ No se encontraron empleados para prueba';
    END IF;
END $$;

-- =====================================================
-- PASO 6: VERIFICAR REGISTRO CREADO
-- =====================================================
SELECT '=== VERIFICANDO REGISTRO CREADO ===' as paso;
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.role,
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
    END as origen,
    CASE 
        WHEN wl.created_at >= NOW() - INTERVAL '5 minutes' THEN '✅ CREADO AHORA'
        ELSE '⏰ CREADO ANTES'
    END as estado_creacion
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 7: SIMULAR INSERCIÓN DEL SCHEDULER
-- =====================================================
SELECT '=== SIMULando INSERCIÓN SCHEDULER ===' as paso;

-- Simular exactamente lo que hace el scheduler
DO $$
DECLARE
    emp_record RECORD;
    work_log_data RECORD;
    insert_result RECORD;
BEGIN
    -- Obtener primer empleado con configuración
    SELECT u.id, u.username, ats.start_time, ats.end_time
    INTO emp_record
    FROM users u
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1;
    
    IF emp_record IS NOT NULL THEN
        -- Calcular total hours como lo hace el scheduler
        DECLARE
            start_hour INTEGER;
            start_min INTEGER;
            end_hour INTEGER;
            end_min INTEGER;
            start_total INTEGER;
            end_total INTEGER;
            total_minutes INTEGER;
        BEGIN
            start_hour := SPLIT_PART(emp_record.start_time::text, ':', 1)::INTEGER;
            start_min := SPLIT_PART(emp_record.start_time::text, ':', 2)::INTEGER;
            end_hour := SPLIT_PART(emp_record.end_time::text, ':', 1)::INTEGER;
            end_min := SPLIT_PART(emp_record.end_time::text, ':', 2)::INTEGER;
            
            start_total := start_hour * 60 + start_min;
            end_total := end_hour * 60 + end_min;
            total_minutes := end_total - start_total;
            
            -- Insertar como lo hace el scheduler
            INSERT INTO work_logs (
                user_id, date, start_time, end_time, total_hours, type, is_auto_generated
            ) VALUES (
                emp_record.id,
                CURRENT_DATE,
                emp_record.start_time, -- Mantener como time, no convertir a text
                emp_record.end_time,   -- Mantener como time, no convertir a text
                total_minutes,
                'work',
                true
            ) RETURNING * INTO insert_result;
            
            RAISE NOTICE '✅ Inserción simulada exitosa - ID: %, Usuario: %', insert_result.id, emp_record.username;
            RAISE NOTICE '📊 Datos insertados: user_id=%, date=%, start_time=%, end_time=%, total_hours=%, is_auto_generated=%', 
                insert_result.user_id, insert_result.date, insert_result.start_time::text, insert_result.end_time::text, insert_result.total_hours, insert_result.is_auto_generated;
        END;
    ELSE
        RAISE NOTICE '❌ No se encontraron empleados con configuración activa';
    END IF;
END $$;

-- =====================================================
-- PASO 8: VERIFICAR RESULTADO FINAL
-- =====================================================
SELECT '=== RESULTADO FINAL ===' as paso;
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.role,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.total_hours,
    wl.type,
    wl.is_auto_generated,
    wl.created_at,
    wl.created_at AT TIME ZONE 'Europe/Madrid' as fecha_creacion_espana,
    CASE 
        WHEN wl.is_auto_generated = true THEN '🤖 AUTOMÁTICO'
        ELSE '👤 MANUAL'
    END as origen,
    CASE 
        WHEN wl.created_at >= NOW() - INTERVAL '2 minutes' THEN '✅ CREADO EN ÚLTIMOS 2 MINUTOS'
        ELSE '⏰ MÁS ANTIGUO'
    END as estado_reciente
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 9: DIAGNÓSTICO DE PROBLEMAS COMUNES
-- =====================================================
SELECT '=== DIAGNÓSTICO DE PROBLEMAS ===' as paso;

-- Verificar si hay registros automáticos hoy
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM work_logs 
            WHERE date = CURRENT_DATE 
            AND is_auto_generated = true
        ) THEN '✅ HAY REGISTROS AUTOMÁTICOS HOY'
        ELSE '❌ NO HAY REGISTROS AUTOMÁTICOS HOY'
    END as estado_registros_hoy;

-- Verificar si la columna existe
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'work_logs' 
            AND column_name = 'is_auto_generated'
        ) THEN '✅ COLUMNA is_auto_generated EXISTE'
        ELSE '❌ COLUMNA is_auto_generated NO EXISTE'
    END as estado_columna;

-- Verificar si hay empleados con configuración
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM auto_time_settings ats
            JOIN users u ON ats.user_id = u.id
            WHERE u.role = 'employee' 
            AND ats.enabled = true
        ) THEN '✅ HAY EMPLEADOS CON CONFIGURACIÓN ACTIVA'
        ELSE '❌ NO HAY EMPLEADOS CON CONFIGURACIÓN ACTIVA'
    END as estado_configuracion;

-- =====================================================
-- RESUMEN Y RECOMENDACIONES
-- =====================================================
SELECT 
    '=== RESUMEN FINAL ===' as titulo,
    '1. Verificar estructura de work_logs' as paso1,
    '2. Asegurar que exists is_auto_generated' as paso2,
    '3. Probar inserción manual' as paso3,
    '4. Simular inserción del scheduler' as paso4,
    '5. Verificar resultado final' as paso5;

SELECT 
    '=== SI SIGUE SIN FUNCIONAR ===' as titulo,
    '1. Revisar logs del servidor' as rec1,
    '2. Verificar conexión a base de datos' as rec2,
    '3. Revisar permisos de la tabla' as rec3,
    '4. Probar con service role key' as rec4,
    '5. Revisar si hay triggers bloqueando' as rec5;
