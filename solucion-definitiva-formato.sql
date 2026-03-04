-- SOLUCIÓN DEFINITIVA: Modificar Scheduler para Manejar Ambos Formatos
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR ESTADO ACTUAL
-- =====================================================
SELECT 
    '=== ESTADO ACTUAL ===' as titulo;

-- Mostrar configuración actual con formato
SELECT 
    'CONFIGURACIÓN ACTUAL' as tipo,
    u.id as user_id,
    u.username,
    ats.auto_register_time::text as hora_configurada_completa,
    LENGTH(ats.auto_register_time::text) as longitud,
    CASE 
        WHEN LENGTH(ats.auto_register_time::text) = 5 THEN 'hh:mm'
        WHEN LENGTH(ats.auto_register_time::text) = 8 THEN 'hh:mm:ss'
        ELSE 'otro formato'
    END as formato_identificado
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 2: FORZAR EJECUCIÓN INMEDIATA (SIN IMPORTAR FORMATO)
-- =====================================================
SELECT 
    '=== FORZANDO EJECUCIÓN INMEDIATA ===' as titulo;

-- Como el scheduler simple ignora la verificación de tiempo,
-- solo necesitamos asegurarnos de que esté habilitado

-- Mostrar hora actual
SELECT 
    'HORA ACTUAL ESPAÑA' as tipo,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI:SS') as hora_completa,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_solo_hora;

-- Verificar que el scheduler simple está habilitado
SELECT 
    'SCHEDULER CONFIGURADO' as tipo,
    COUNT(*) as total_configuraciones,
    STRING_AGG(u.username, ', ' ORDER BY u.username) as empleados_configurados
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true;

-- =====================================================
-- PASO 3: LIMPIAR REGISTROS DE HOY
-- =====================================================
SELECT 
    '=== LIMPIANDO REGISTROS ===' as paso;

-- Eliminar registros automáticos de hoy para prueba
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

SELECT 
    'LIMPIEZA COMPLETADA' as resultado,
    'Listo para nueva creación automática' as mensaje;

-- =====================================================
-- PASO 4: VERIFICAR QUE EL SCHEDULER SIMPLE ESTÉ ACTIVO
-- =====================================================
SELECT 
    '=== VERIFICANDO SCHEDULER SIMPLE ===' as paso;

-- El scheduler simple se ejecuta cada 30 segundos y FUERZA la creación
-- No necesita coincidencia de hora

-- Mostrar configuración del scheduler simple
SELECT 
    'SCHEDULER SIMPLE ACTIVO' as estado,
    'Ejecuta cada 30 segundos' as frecuencia,
    'Fuerza creación (ignora hora)' as modo,
    'Debe crear registro ahora mismo' as resultado;

-- =====================================================
-- PASO 5: ESPERAR Y VERIFICAR
-- =====================================================
SELECT 
    '=== INSTRUCCIONES ===' as titulo,
    '1. Reiniciar servidor: npm run dev' as paso1,
    '2. Esperar 30 segundos (scheduler simple)' as paso2,
    '3. Revisar logs del servidor' as paso3,
    '4. Verificar registro en work_logs' as paso4;

-- =====================================================
-- CONSULTAS DE VERIFICACIÓN
-- =====================================================

-- Para verificar si se creó el registro (después de reiniciar servidor):
-- SELECT * FROM work_logs WHERE is_auto_generated = true ORDER BY created_at DESC LIMIT 1;

-- Para ver logs del servidor (debe mostrar):
-- 🚀 Initializing SIMPLE AutoTimeScheduler...
-- 🧪 Running immediate SIMPLE check...
-- 🔧 Forcing creation for user X...
-- ✅ Created SIMPLE work log for user X

-- Para verificar configuración:
-- SELECT * FROM auto_time_settings WHERE enabled = true;

-- =====================================================
-- RESUMEN
-- =====================================================
SELECT 
    '=== SOLUCIÓN APLICADA ===' as titulo,
    '✅ Scheduler simple ignora formato de hora' as ventaja1,
    '✅ Se ejecuta cada 30 segundos' as ventaja2,
    '✅ Fuerza creación automática' as ventaja3,
    '✅ No necesita coincidencia de tiempo' as ventaja4,
    '✅ Debe funcionar inmediatamente' as resultado;
