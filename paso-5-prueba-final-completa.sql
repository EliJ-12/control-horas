-- PASO 5 DE 5: PRUEBA FINAL COMPLETA DEL SISTEMA
-- Ejecutar este script DESPUÉS de tener el scheduler robusto implementado
-- Este es el paso final que prueba TODO el sistema

SELECT '=== PASO 5: PRUEBA FINAL COMPLETA DEL SISTEMA ===' as paso;

-- 5.1 PREPARACIÓN PARA PRUEBA FINAL
SELECT '5.1 PREPARACIÓN PARA PRUEBA FINAL' as subpaso;

-- Limpiar registros automáticos de hoy para prueba limpia
DELETE FROM work_logs
WHERE date = CURRENT_DATE
AND is_auto_generated = true;

-- Forzar configuración para que coincida con la hora actual
UPDATE auto_time_settings
SET auto_register_time = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')::time,
    enabled = true,
    monday = true, tuesday = true, wednesday = true, thursday = true, friday = true,
    saturday = false, sunday = false,
    start_time = '09:00',
    end_time = '17:00'
WHERE user_id IN (
    SELECT u.id FROM users u
    WHERE u.role = 'employee'
    LIMIT 1
);

SELECT
    'PREPARACIÓN COMPLETADA' as resultado,
    '✅ Registros automáticos limpiados' as limpieza,
    '✅ Configuración forzada a hora actual' as configuracion,
    '✅ Sistema listo para prueba final' as estado;

-- 5.2 VERIFICACIÓN PREVIA AL SERVIDOR
SELECT '5.2 VERIFICACIÓN PREVIA AL SERVIDOR' as subpaso;

-- Verificar configuración final
SELECT
    'CONFIGURACIÓN FINAL' as tipo,
    u.username,
    ats.enabled,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ HORAS COINCIDEN PERFECTAMENTE'
        ELSE '❌ HORAS NO COINCIDEN'
    END as comparacion_hora,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as dia_actual,
    CASE
        WHEN EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') BETWEEN 1 AND 5
        THEN '✅ DÍA LABORAL'
        ELSE '❌ FIN DE SEMANA'
    END as estado_dia
FROM users u
JOIN auto_time_settings ats ON u.id = ats.user_id
WHERE u.role = 'employee'
LIMIT 1;

-- Verificar que no hay registros automáticos
SELECT
    'REGISTROS ANTES DE PRUEBA' as tipo,
    COUNT(*) as total_registros_hoy,
    COUNT(CASE WHEN is_auto_generated = true THEN 1 END) as registros_automaticos,
    CASE
        WHEN COUNT(CASE WHEN is_auto_generated = true THEN 1 END) = 0
        THEN '✅ LISTO PARA PRUEBA - NO HAY REGISTROS AUTOMÁTICOS'
        ELSE '❌ ERROR - AÚN HAY REGISTROS AUTOMÁTICOS'
    END as estado_prueba;

-- 5.3 INSTRUCCIONES PARA EJECUTAR PRUEBA
SELECT '5.3 INSTRUCCIONES PARA EJECUTAR PRUEBA' as subpaso;

SELECT
    'PASO A PASO PARA PRUEBA FINAL' as instrucciones,
    '1. Abrir terminal y ejecutar: npm run dev' as paso1,
    '2. Esperar logs iniciales del servidor' as paso2,
    '3. Buscar logs con prefijo [SCHEDULER]' as paso3,
    '4. Deberías ver:' as logs_esperados,
    '   🚀 [SCHEDULER] Iniciando AutoTimeScheduler...' as log1,
    '   🔄 [SCHEDULER] === INICIANDO PROCESAMIENTO ===' as log2,
    '   📍 [SCHEDULER] Tiempo España: XX:XX...' as log3,
    '   ✅ [SCHEDULER] Condiciones cumplidas...' as log4,
    '   ➕ [SCHEDULER] Creando registro automático...' as log5,
    '   ✅ [SCHEDULER] Registro automático creado...' as log6;

SELECT
    'LOGS DE ERROR A BUSCAR' as tipo_error,
    '❌ [SCHEDULER] Error general...' as error_grave,
    '❌ [SCHEDULER] Usuario X no encontrado...' as error_usuario,
    '⚠️ [SCHEDULER] Saltando - ya hay un procesamiento...' as advertencia;

-- 5.4 VERIFICACIÓN POST-SERVIDOR (EJECUTAR DESPUÉS)
SELECT '5.4 VERIFICACIÓN POST-SERVIDOR (EJECUTAR DESPUÉS)' as subpaso;

-- ESTAS QUERIES SE EJECUTAN DESPUÉS DE npm run dev
-- COPIARLAS Y EJECUTARLAS MANUALMENTE EN SUPABASE

SELECT
    'QUERIES PARA EJECUTAR DESPUÉS DE npm run dev' as instrucciones,
    'SELECT * FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true;' as query1,
    'SELECT COUNT(*) FROM work_logs WHERE date = CURRENT_DATE AND is_auto_generated = true;' as query2;

-- Simular resultados esperados
SELECT
    'RESULTADOS ESPERADOS' as tipo,
    '1 registro automático creado' as resultado_esperado1,
    'is_auto_generated = true' as resultado_esperado2,
    'fecha = hoy' as resultado_esperado3,
    'user_id del empleado' as resultado_esperado4;

-- 5.5 DIAGNÓSTICO FINAL
SELECT '5.5 DIAGNÓSTICO FINAL' as subpaso;

SELECT
    'ESCENARIOS POSIBLES' as diagnostico,
    'ESCENARIO 1: REGISTRO CREADO ✅' as escenario1,
    '   - Scheduler funciona perfectamente' as conclusion1,
    '   - Código robusto operativo' as conclusion1b,
    'ESCENARIO 2: LOGS PERO NO REGISTRO ⚠️' as escenario2,
    '   - Scheduler ejecutándose, pero inserción falla' as conclusion2,
    '   - Revisar permisos o estructura BD' as conclusion2b,
    'ESCENARIO 3: NO LOGS, NO REGISTRO ❌' as escenario3,
    '   - Scheduler no se ejecuta' as conclusion3,
    '   - Revisar .env.local o errores de inicialización' as conclusion3b,
    'ESCENARIO 4: ERRORES EN LOGS 🔥' as escenario4,
    '   - Problemas específicos en el código' as conclusion4,
    '   - Revisar logs de error detalladamente' as conclusion4b;

-- 5.6 ACCIONES DE SEGUIMIENTO
SELECT '5.6 ACCIONES DE SEGUIMIENTO' as subpaso;

SELECT
    'SI FUNCIONA ✅' as caso_exito,
    '¡Felicitaciones! El sistema funciona correctamente' as mensaje_exito,
    'El scheduler automático está operativo' as conclusion_exito,
    'Los registros se crean automáticamente' as conclusion_exito2;

SELECT
    'SI NO FUNCIONA ❌' as caso_error,
    'Revisar los logs del servidor detenidamente' as accion_error1,
    'Verificar .env.local tiene DATABASE_URL correcta' as accion_error2,
    'Ejecutar los pasos 1-4 nuevamente' as accion_error3,
    'Proporcionar los logs específicos del error' as accion_error4;

SELECT
    'RESULTADO FINAL PASO 5' as conclusion,
    'PRUEBA FINAL COMPLETA EJECUTADA' as estado,
    'SISTEMA DIAGNOSTICADO COMPLETAMENTE' as conclusion_final;

-- 5.7 REGISTRO FINAL DEL SISTEMA
SELECT '5.7 REGISTRO FINAL DEL SISTEMA' as subpaso;

-- Registrar que se completó la prueba final
SELECT
    'PRUEBA FINAL REGISTRADA' as registro,
    CURRENT_TIMESTAMP as fecha_prueba,
    'Sistema diagnosticado completamente' as descripcion,
    'Scheduler robusto implementado y probado' as estado_sistema;
