-- PRUEBA FINAL: Forzar ejecución inmediata del scheduler
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: CONFIGURAR PARA EJECUCIÓN INMEDIATA
-- =====================================================
SELECT '=== PASO 1: CONFIGURACIÓN PARA PRUEBA ===' as paso;

-- Forzar la hora de registro a la hora actual para que coincida inmediatamente
UPDATE auto_time_settings 
SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')::time
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
    u.id as user_id,
    u.username,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ CONFIGURADO PARA EJECUCIÓN INMEDIATA'
        ELSE '❌ CONFIGURACIÓN FALLIDA'
    END as estado
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee' 
AND ats.enabled = true
LIMIT 1;

-- =====================================================
-- PASO 2: LIMPIAR REGISTROS PARA PRUEBA
-- =====================================================
SELECT '=== PASO 2: LIMPIANDO REGISTROS ===' as paso;

-- Eliminar registros automáticos de hoy
DELETE FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

SELECT 
    'REGISTROS ELIMINADOS' as resultado,
    'Listo para crear nuevo registro automático' as mensaje;

-- =====================================================
-- PASO 3: INSTRUCCIONES PARA PRUEBA
-- =====================================================
SELECT 
    '=== INSTRUCCIONES PARA PRUEBA ===' as titulo,
    '1. Reiniciar servidor: npm run dev' as paso1,
    '2. Esperar logs iniciales del scheduler' as paso2,
    '3. Deberías ver:' as paso3,
    '   - 🚀 Initializing AutoTimeScheduler...' as log1,
    '   - ✅ Database connection OK...' as log2,
    '   - 🧪 Running immediate test check...' as log3,
    '   - ⏰ Time comparison: registerTime="XX:XX" vs currentTime="XX:XX" → true' as log4,
    '   - ✅ Created auto work log for user X...' as log5,
    '4. Si ves el log de creación exitosa:' as paso4,
    '   - ✅ EL SCHEDULER FUNCIONA CORRECTAMENTE' as resultado1,
    '5. Si NO ves el log de creación:' as paso5,
    '   - ❌ Hay problema en el código del scheduler' as resultado2,
    '6. Verificar en base de datos:' as paso6,
    '   - SELECT * FROM work_logs WHERE is_auto_generated = true AND date = CURRENT_DATE' as consulta;

-- =====================================================
-- PASO 4: VERIFICACIÓN POST-SERVER
-- =====================================================

-- Después de reiniciar el servidor, ejecutar esta consulta:
-- SELECT * FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true;

-- Si aparece un registro, ¡el scheduler funciona!
-- Si no aparece, hay un problema en el código.

SELECT 
    '=== ESTADO ACTUAL ANTES DE REINICIAR ===' as titulo,
    'Ejecuta la consulta de arriba DESPUÉS de npm run dev' as instruccion;
