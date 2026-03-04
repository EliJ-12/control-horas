-- DIAGNÓSTICO RÁPIDO: ¿Por qué no funciona el scheduler?
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR QUE EL REGISTRO EXISTA
-- =====================================================
SELECT '=== VERIFICANDO REGISTRO CREADO ===' as paso;

SELECT 
    'REGISTROS AUTOMÁTICOS DE HOY' as tipo,
    COUNT(*) as total,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ EXISTE REGISTRO'
        ELSE '❌ NO EXISTE REGISTRO'
    END as estado
FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

-- Mostrar detalles si existe
SELECT 
    'DETALLES DEL REGISTRO' as tipo,
    wl.id,
    wl.user_id,
    u.username,
    wl.date,
    wl.start_time,
    wl.end_time,
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
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 2: VERIFICAR CONFIGURACIÓN DEL SCHEDULER
-- =====================================================
SELECT '=== CONFIGURACIÓN DEL SCHEDULER ===' as paso;

SELECT 
    u.id as user_id,
    u.username,
    u.role,
    ats.enabled,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_actual,
    CASE 
        WHEN ats.enabled = true THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado_configuracion,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') 
        THEN '✅ HORA COINCIDE'
        ELSE '❌ HORA NO COINCIDE'
    END as estado_hora
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
LIMIT 1;

-- =====================================================
-- PASO 3: VERIFICAR DÍA DE LA SEMANA
-- =====================================================
SELECT 
    '=== DÍA DE LA SEMANA ===' as paso,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES (1)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES (2)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES (3)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES (4)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES (5)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO (6)'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO (0)'
    END as dia_nombre,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '✅ DÍA LABORAL'
        ELSE '❌ FIN DE SEMANA'
    END as estado_dia;

-- =====================================================
-- PASO 4: PROBAR CREACIÓN MANUAL DIRECTA
-- =====================================================
SELECT '=== PRUEBA DE CREACIÓN MANUAL ===' as paso;

-- Eliminar registro existente si hay
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

-- Crear registro manual directo
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
    '09:00',
    '17:00',
    480,
    'work',
    true
);

-- Verificar que se creó
SELECT 
    'REGISTRO MANUAL CREADO' as resultado,
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
-- PASO 5: DIAGNÓSTICO FINAL
-- =====================================================
SELECT 
    '=== DIAGNÓSTICO FINAL ===' as titulo,
    '1. Si el registro manual aparece:' as paso1,
    '   - La base de datos funciona correctamente' as paso1a,
    '   - El problema está en el scheduler' as paso1b,
    '2. Si el registro manual NO aparece:' as paso2,
    '   - Hay problema de permisos o RLS' as paso2a,
    '   - Revisa políticas de seguridad' as paso2b,
    '3. Si el registro existe pero no en frontend:' as paso3,
    '   - El frontend no está actualizando' as paso3a,
    '   - Refresca la página del navegador' as paso3b;

SELECT 
    '=== ACCIONES INMEDIATAS ===' as titulo,
    '1. Verificar que el registro manual aparezca en la lista anterior' as accion1,
    '2. Si aparece, el problema es el scheduler automático' as accion2,
    '3. Si no aparece, hay problema de base de datos' as accion3,
    '4. Revisa logs del servidor con npm run dev' as accion4;
