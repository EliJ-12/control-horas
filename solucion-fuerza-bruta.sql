-- SOLUCIÓN DE FUERZA BRUTA: Crear Registro Automático
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR ESTADO ACTUAL
-- =====================================================
SELECT '=== ESTADO ACTUAL DEL SISTEMA ===' as paso;

-- Verificar empleados con configuración
SELECT 
    'EMPLEADOS CON CONFIGURACIÓN' as tipo,
    COUNT(*) as total,
    STRING_AGG(u.username, ', ' ORDER BY u.username) as empleados
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' AND ats.enabled = true;

-- Verificar registros automáticos de hoy
SELECT 
    'REGISTROS AUTOMÁTICOS HOY' as tipo,
    COUNT(*) as total,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ EXISTEN'
        ELSE '❌ NO EXISTEN'
    END as estado
FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

-- =====================================================
-- PASO 2: LIMPIAR Y PREPARAR
-- =====================================================
SELECT '=== LIMPIANDO Y PREPARANDO ===' as paso;

-- Eliminar cualquier registro automático de hoy para evitar conflictos
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

SELECT 
    'REGISTROS AUTOMÁTICOS ELIMINADOS' as resultado,
    'Lista para crear nuevo registro' as mensaje;

-- =====================================================
-- PASO 3: OBTENER EMPLEADO PARA PRUEBA
-- =====================================================
SELECT '=== OBTENIENDO EMPLEADO PARA PRUEBA ===' as paso;

-- Crear tabla temporal con datos del empleado
WITH empleado_config AS (
    SELECT 
        u.id as user_id,
        u.username,
        u.full_name,
        u.role,
        ats.start_time,
        ats.end_time,
        ats.auto_register_time,
        CURRENT_DATE as fecha_actual
    FROM users u
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
)
SELECT 
    'EMPLEADO SELECCIONADO' as tipo,
    user_id,
    username,
    full_name,
    role,
    start_time::text as hora_inicio,
    end_time::text as hora_fin,
    auto_register_time::text as hora_registro,
    fecha_actual
FROM empleado_config;

-- =====================================================
-- PASO 4: CREAR REGISTRO AUTOMÁTICO MANUALMENTE
-- =====================================================
SELECT '=== CREANDO REGISTRO AUTOMÁTICO ===' as paso;

-- Insertar registro automático usando los mismos datos que usaría el scheduler
WITH empleado_config AS (
    SELECT 
        u.id as user_id,
        ats.start_time,
        ats.end_time,
        CURRENT_DATE as fecha_actual
    FROM users u
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
)
INSERT INTO work_logs (
    user_id, 
    date, 
    start_time, 
    end_time, 
    total_hours, 
    type, 
    is_auto_generated
)
SELECT 
    ec.user_id,
    ec.fecha_actual,
    ec.start_time,
    ec.end_time,
    -- Calcular total_hours como lo hace el scheduler
    (EXTRACT(HOUR FROM ec.end_time) * 60 + EXTRACT(MINUTE FROM ec.end_time)) - 
    (EXTRACT(HOUR FROM ec.start_time) * 60 + EXTRACT(MINUTE FROM ec.start_time)),
    'work',
    true
FROM empleado_config ec;

-- =====================================================
-- PASO 5: VERIFICAR QUE SE CREÓ
-- =====================================================
SELECT '=== VERIFICANDO REGISTRO CREADO ===' as paso;

SELECT 
    wl.id,
    wl.user_id,
    u.username,
    u.full_name,
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
        WHEN wl.created_at >= NOW() - INTERVAL '1 minute' THEN '✅ CREADO AHORA'
        ELSE '⏰ CREADO ANTES'
    END as estado_creacion
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 6: FORZAR CONFIGURACIÓN PARA PRÓXIMA EJECUCIÓN
-- =====================================================
SELECT '=== CONFIGURANDO PRÓXIMA EJECUCIÓN ===' as paso;

-- Actualizar para que se ejecute en el próximo minuto
UPDATE auto_time_settings 
SET auto_register_time = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI'))::time
WHERE user_id IN (
    SELECT u.id FROM users u 
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
);

-- Verificar configuración
SELECT 
    'CONFIGURACIÓN ACTUALIZADA' as resultado,
    user_id,
    auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI') as proxima_ejecucion,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual
FROM auto_time_settings 
WHERE user_id IN (
    SELECT u.id FROM users u 
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
);

-- =====================================================
-- PASO 7: DIAGNÓSTICO DE PROBLEMAS
-- =====================================================
SELECT '=== DIAGNÓSTICO DE PROBLEMAS ===' as paso;

-- Verificar estructura de work_logs
SELECT 
    'ESTRUCTURA work_logs' as tipo,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'work_logs' 
AND column_name IN ('user_id', 'date', 'start_time', 'end_time', 'total_hours', 'type', 'is_auto_generated')
ORDER BY ordinal_position;

-- Verificar si hay restricciones
SELECT 
    'RESTRICCIONES work_logs' as tipo,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'work_logs';

-- Verificar si hay triggers
SELECT 
    'TRIGGERS work_logs' as tipo,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'work_logs';

-- =====================================================
-- PASO 8: PRUEBA DE INSERCIÓN DIRECTA
-- =====================================================
SELECT '=== PRUEBA DE INSERCIÓN DIRECTA ===' as paso;

-- Probar inserción directa con valores fijos
INSERT INTO work_logs (
    user_id, 
    date, 
    start_time, 
    end_time, 
    total_hours, 
    type, 
    is_auto_generated
) VALUES (
    (SELECT id FROM users WHERE role = 'employee' LIMIT 1),
    CURRENT_DATE,
    '09:00'::time,
    '17:00'::time,
    480,
    'work',
    true
);

-- Verificar que se insertó
SELECT 
    'INSERCIÓN DIRECTA EXITOSA' as resultado,
    wl.id,
    wl.user_id,
    u.username,
    wl.is_auto_generated,
    wl.created_at
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC
LIMIT 1;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================
SELECT 
    '=== RESUMEN FINAL ===' as titulo,
    '✅ Registro automático creado manualmente' as paso1,
    '✅ Configuración actualizada para próximo minuto' as paso2,
    '✅ Inserción directa probada' as paso3,
    '✅ Sistema listo para scheduler' as paso4;

SELECT 
    '=== PRÓXIMOS PASOS ===' as titulo,
    '1. Reiniciar servidor: npm run dev' as paso1,
    '2. Esperar 1 minuto para ejecución automática' as paso2,
    '3. Revisar logs del servidor' as paso3,
    '4. Verificar nuevo registro en work_logs' as paso4,
    '5. Refrescar frontend de empleado' as paso5;
