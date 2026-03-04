-- SOLUCIÓN INMEDIATA: Problema de Formato hh:mm:ss vs hh:mm
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR PROBLEMA DE FORMATO
-- =====================================================
SELECT 
    '=== PROBLEMA IDENTIFICADO ===' as titulo;

-- Mostrar el problema claramente
SELECT 
    'COMPARACIÓN DE FORMATOS' as tipo,
    ats.auto_register_time::text as config_text_completo,
    SUBSTRING(ats.auto_register_time::text, 1, 5) as config_text_solo_hora,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as actual_text_solo_hora,
    CASE 
        WHEN SUBSTRING(ats.auto_register_time::text, 1, 5) = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ COINCIDEN (usando SUBSTRING)'
        ELSE '❌ NO COINCIDEN'
    END as estado_con_substring
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 2: CORREGIR CONFIGURACIÓN ACTUAL
-- =====================================================
SELECT 
    '=== CORRIGIENDO CONFIGURACIÓN ===' as titulo;

-- Actualizar para que solo tenga hh:mm (sin segundos)
UPDATE auto_time_settings 
SET auto_register_time = SUBSTRING(auto_register_time::text, 1, 5)::time
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
    ats.auto_register_time::text as config_text_corregido,
    LENGTH(ats.auto_register_time::text) as longitud_corregida,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as actual_text,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ AHORA COINCIDE'
        ELSE '❌ AÚN NO COINCIDE'
    END as estado_final
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 3: FORZAR HORA ACTUAL PARA EJECUCIÓN INMEDIATA
-- =====================================================
SELECT 
    '=== FORZANDO EJECUCIÓN INMEDIATA ===' as titulo;

-- Configurar para hora actual exacta
UPDATE auto_time_settings 
SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')::time
WHERE user_id IN (
    SELECT u.id FROM users u 
    JOIN auto_time_settings ats ON u.id = ats.user_id
    WHERE u.role = 'employee' 
    AND ats.enabled = true
    LIMIT 1
);

-- Verificación final
SELECT 
    'VERIFICACIÓN FINAL FORZADA' as tipo,
    u.id as user_id,
    u.username,
    ats.auto_register_time::text as hora_configurada_final,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ DEBERÍA EJECUTARSE AHORA'
        ELSE '❌ TODAVÍA HAY PROBLEMA'
    END as estado_ejecucion
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 4: LIMPIAR Y PREPARAR
-- =====================================================
-- Limpiar registros automáticos de hoy
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

SELECT 
    '=== SISTEMA LISTO PARA PRUEBA ===' as titulo,
    '✅ Formato corregido a hh:mm' as paso1,
    '✅ Hora forzada a actual' as paso2,
    '✅ Registros limpiados' as paso3,
    '✅ Reiniciar servidor y esperar 30 segundos' as paso4;

-- =====================================================
-- PASO 5: VERIFICACIÓN RÁPIDA
-- =====================================================
SELECT 
    '=== VERIFICACIÓN RÁPIDA ===' as titulo,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_espana,
    (SELECT auto_register_time::text FROM auto_time_settings WHERE enabled = true LIMIT 1) as hora_configurada,
    CASE 
        WHEN (SELECT auto_register_time::text FROM auto_time_settings WHERE enabled = true LIMIT 1) = 
             TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ LISTO PARA EJECUTAR'
        ELSE '❌ REQUIERE ATENCIÓN'
    END as estado_listo;

-- =====================================================
-- CONSULTAS POST-EJECUCIÓN
-- =====================================================

-- Después de reiniciar el servidor y esperar 30 segundos:
-- SELECT * FROM work_logs WHERE is_auto_generated = true ORDER BY created_at DESC LIMIT 1;

-- Para verificar logs del scheduler:
-- SELECT * FROM scheduler_debug_log ORDER BY timestamp DESC LIMIT 5;
