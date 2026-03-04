-- VERIFICACIÓN: Hora corregida exitosamente
-- Ejecutar después de aplicar la solución

SELECT '=== VERIFICACIÓN DE CORRECCIÓN ===' as titulo;

-- Verificar que la hora ahora coincide
SELECT
    'VERIFICACIÓN HORA CORREGIDA' as tipo,
    u.username,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
        THEN '✅ HORA AHORA COINCIDE PERFECTAMENTE'
        ELSE '❌ HORA AÚN NO COINCIDE'
    END as estado_hora,
    CASE
        WHEN ats.enabled = true AND u.role = 'employee' AND
             ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') AND
             EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') IN (1,2,3,4,5)
        THEN '✅ TODAS LAS CONDICIONES LISTAS PARA SCHEDULER'
        ELSE '❌ AÚN HAY CONDICIONES PENDIENTES'
    END as estado_general
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE u.role = 'employee'
LIMIT 1;

-- Verificar día laborable
SELECT
    'VERIFICACIÓN DÍA LABORABLE' as tipo,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as dia_actual,
    CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
        WHEN 1 THEN 'LUNES ✅'
        WHEN 2 THEN 'MARTES ✅'
        WHEN 3 THEN 'MIÉRCOLES ✅'
        WHEN 4 THEN 'JUEVES ✅'
        WHEN 5 THEN 'VIERNES ✅'
        ELSE 'FIN DE SEMANA ❌ - HABILITAR SI QUIERES PROBAR'
    END as estado_dia;

-- Próximos pasos
SELECT
    'PRÓXIMOS PASOS' as tipo,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM auto_time_settings ats
            JOIN users u ON ats.user_id = u.id
            WHERE ats.enabled = true AND u.role = 'employee'
            AND ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI')
            AND EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') IN (1,2,3,4,5)
        ) THEN '✅ EJECUTAR: npm run dev - EL SCHEDULER DEBERÍA FUNCIONAR AHORA'
        ELSE '❌ CORREGIR LOS PROBLEMAS RESTANTES PRIMERO'
    END as accion_recomendada;
