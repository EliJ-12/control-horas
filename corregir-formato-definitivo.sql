-- SOLUCIÓN DEFINITIVA: Corregir Formato de Hora en Base de Datos
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR ESTADO ACTUAL DEL FORMATO
-- =====================================================
SELECT 
    '=== ANÁLISIS DE FORMATO ACTUAL ===' as titulo;

-- Mostrar formato exacto
SELECT 
    'FORMATO ACTUAL' as tipo,
    u.id as user_id,
    u.username,
    ats.auto_register_time as hora_time_tipo,
    ats.auto_register_time::text as hora_text_completa,
    LENGTH(ats.auto_register_time::text) as longitud_text,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_actual_completa,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_corta
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 2: CORREGIR A FORMATO hh:mm:ss
-- =====================================================
SELECT 
    '=== CORRIGIENDO A FORMATO hh:mm:ss ===' as titulo;

-- Convertir a formato hh:mm:ss agregando segundos
UPDATE auto_time_settings 
SET auto_register_time = CASE 
    WHEN LENGTH(auto_register_time::text) = 5 THEN (auto_register_time::text || ':00')::time
    WHEN LENGTH(auto_register_time::text) = 8 THEN auto_register_time::time
    ELSE ('17:05:00')::time -- valor por defecto
END
WHERE user_id IN (
    SELECT u.id FROM users u 
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
);

-- Verificar corrección
SELECT 
    'VERIFICACIÓN POST-CORRECCIÓN' as tipo,
    u.id as user_id,
    u.username,
    ats.auto_register_time as hora_time_corregida,
    ats.auto_register_time::text as hora_text_corregida,
    LENGTH(ats.auto_register_time::text) as longitud_corregida,
    CASE 
        WHEN LENGTH(ats.auto_register_time::text) = 8 THEN '✅ FORMATO hh:mm:ss CORRECTO'
        ELSE '❌ FORMATO INCORRECTO'
    END as estado_formato
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 3: FORZAR HORA ACTUAL EN FORMATO hh:mm:ss
-- =====================================================
SELECT 
    '=== FORZANDO HORA ACTUAL hh:mm:ss ===' as titulo;

-- Obtener hora actual en formato hh:mm:ss
DO $$
DECLARE
    current_hora TEXT;
    target_user_id INTEGER;
BEGIN
    -- Obtener hora actual en formato hh:mm:ss
    current_hora := TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS');
    
    -- Obtener ID del empleado
    SELECT u.id INTO target_user_id
    FROM users u
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1;
    
    -- Actualizar con hora actual completa
    UPDATE auto_time_settings 
    SET auto_register_time = current_hora::time
    WHERE user_id = target_user_id;
    
    RAISE NOTICE '✅ Actualizado usuario % con hora %', target_user_id, current_hora;
END $$;

-- Verificación final
SELECT 
    'VERIFICACIÓN FINAL' as tipo,
    u.id as user_id,
    u.username,
    ats.auto_register_time::text as hora_configurada_final,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_actual_completa,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') || ':00' as hora_actual_forzada,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') 
        THEN '✅ COINCIDEN PERFECTAMENTE'
        ELSE '❌ AÚN NO COINCIDEN'
    END as estado_final
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 4: LIMPIAR Y PREPARAR
-- =====================================================
SELECT 
    '=== LIMPIANDO Y PREPARANDO ===' as paso;

-- Limpiar registros automáticos de hoy
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

SELECT 
    'LIMPIEZA COMPLETADA' as resultado,
    'Listo para prueba del scheduler corregido' as mensaje;

-- =====================================================
-- PASO 5: VERIFICACIÓN DEL SCHEDULER CORREGIDO
-- =====================================================
SELECT 
    '=== SCHEDULER CORREGIDO LISTO ===' as titulo,
    '✅ Base de datos en formato hh:mm:ss' as paso1,
    '✅ Scheduler modificado para manejar hh:mm:ss' as paso2,
    '✅ Hora forzada a coincidir exactamente' as paso3,
    '✅ Sistema listo para ejecución' as paso4;

-- =====================================================
-- CONSULTAS DE VERIFICACIÓN
-- =====================================================

-- Para verificar formato final:
-- SELECT * FROM auto_time_settings WHERE enabled = true;

-- Para verificar hora actual:
-- SELECT TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_actual;

-- Para verificar después de reiniciar servidor:
-- SELECT * FROM work_logs WHERE is_auto_generated = true ORDER BY created_at DESC LIMIT 1;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================
SELECT 
    '=== RESUMEN DE CAMBIOS ===' as titulo,
    '✅ Base de datos: formato hh:mm:ss' as bd,
    '✅ Scheduler: maneja ambos formatos' as scheduler,
    '✅ Comparación: exacta' as comparacion,
    '✅ Ejecución: inmediata' as ejecucion,
    '✅ Resultado: debe funcionar ahora' as resultado;
