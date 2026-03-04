-- PASO 3 CORREGIDO: SIMULACIÓN DETALLADA DEL SCHEDULER
-- Ejecutar este script DESPUÉS del PASO 2 (solo si PASO 2 fue exitoso)
-- ERROR ANTERIOR CORREGIDO: date = spain_current_date::date

SELECT '=== PASO 3: SIMULACIÓN DETALLADA DEL SCHEDULER (CORREGIDO) ===' as paso;

-- 3.1 Simulación paso a paso del método processScheduledRegistrations
SELECT '3.1 SIMULACIÓN DE processScheduledRegistrations' as subpaso;

-- Paso 3.1.1: Obtener hora actual en España (como hace el scheduler)
SELECT '3.1.1 OBTENCIÓN DE HORA ACTUAL (España)' as subsubpaso;

SELECT
    'DATOS TEMPORALES CALCULADOS' as tipo,
    NOW() as utc_now,
    NOW() AT TIME ZONE 'Europe/Madrid' as spain_datetime,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as current_time_hhmm,
    EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid') as current_day_number,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD') as current_date,
    CASE EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid')
        WHEN 0 THEN 'DOMINGO'
        WHEN 1 THEN 'LUNES'
        WHEN 2 THEN 'MARTES'
        WHEN 3 THEN 'MIÉRCOLES'
        WHEN 4 THEN 'JUEVES'
        WHEN 5 THEN 'VIERNES'
        WHEN 6 THEN 'SÁBADO'
    END as current_day_name;

-- Paso 3.1.2: Obtener configuraciones activas (como hace el scheduler)
SELECT '3.1.2 OBTENCIÓN DE CONFIGURACIONES ACTIVAS' as subsubpaso;

SELECT
    'CONFIGURACIONES ACTIVAS ENCONTRADAS' as tipo,
    COUNT(*) as cantidad_encontradas,
    CASE WHEN COUNT(*) > 0 THEN '✅ CONFIGURACIONES ENCONTRADAS' ELSE '❌ NO HAY CONFIGURACIONES ACTIVAS' END as estado
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true
AND u.role = 'employee';

-- Mostrar configuraciones activas detalladas
SELECT
    'DETALLE DE CONFIGURACIONES ACTIVAS' as tipo,
    u.username,
    ats.user_id,
    ats.enabled,
    ats.auto_register_time::text as auto_register_time_db,
    ats.start_time,
    ats.end_time,
    ats.monday, ats.tuesday, ats.wednesday, ats.thursday, ats.friday, ats.saturday, ats.sunday
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true
AND u.role = 'employee';

-- Paso 3.1.3: Simular el bucle for (para cada configuración)
SELECT '3.1.3 SIMULACIÓN DEL BUCLE PRINCIPAL (CORREGIDO)' as subsubpaso;

DO $$
DECLARE
    spain_current_time TEXT;
    spain_current_day INTEGER;
    spain_current_date TEXT;
    config_record RECORD;
    day_valid BOOLEAN;
    time_valid BOOLEAN;
    should_create BOOLEAN;
    existing_logs_count INTEGER;
BEGIN
    -- Obtener datos temporales como el scheduler
    spain_current_time := TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI');
    spain_current_day := EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid');
    spain_current_date := TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD');

    RAISE NOTICE '=== SIMULACIÓN DEL SCHEDULER (CORREGIDO) ===';
    RAISE NOTICE 'Hora España: %, Día: %, Fecha: %', spain_current_time, spain_current_day, spain_current_date;

    -- Procesar cada configuración activa
    FOR config_record IN
        SELECT ats.*, u.username
        FROM auto_time_settings ats
        JOIN users u ON ats.user_id = u.id
        WHERE ats.enabled = true
        AND u.role = 'employee'
    LOOP
        RAISE NOTICE '--- PROCESANDO USUARIO: % (ID: %) ---', config_record.username, config_record.user_id;

        -- Paso 1: Verificar día válido (shouldRegisterForDay)
        CASE spain_current_day
            WHEN 0 THEN day_valid := config_record.sunday;
            WHEN 1 THEN day_valid := config_record.monday;
            WHEN 2 THEN day_valid := config_record.tuesday;
            WHEN 3 THEN day_valid := config_record.wednesday;
            WHEN 4 THEN day_valid := config_record.thursday;
            WHEN 5 THEN day_valid := config_record.friday;
            WHEN 6 THEN day_valid := config_record.saturday;
            ELSE day_valid := false;
        END CASE;

        RAISE NOTICE 'Día válido (shouldRegisterForDay): % (día %)', day_valid, spain_current_day;

        -- Paso 2: Verificar hora válida (isTimeToRegister)
        -- SIMULAR LA LÓGICA DEL SCHEDULER CORREGIDA
        DECLARE
            register_time_normalized TEXT;
            current_time_normalized TEXT;
        BEGIN
            -- Normalizar register_time: si es hh:mm:ss tomar hh:mm, si es hh:mm dejar hh:mm
            IF LENGTH(config_record.auto_register_time::text) >= 5 THEN
                register_time_normalized := SUBSTRING(config_record.auto_register_time::text, 1, 5);
            ELSE
                register_time_normalized := config_record.auto_register_time::text;
            END IF;

            -- current_time ya viene como hh:mm
            current_time_normalized := spain_current_time;

            time_valid := (register_time_normalized = current_time_normalized);

            RAISE NOTICE 'Hora válida (isTimeToRegister): %', time_valid;
            RAISE NOTICE '  - register_time_normalized: "%"', register_time_normalized;
            RAISE NOTICE '  - current_time_normalized: "%"', current_time_normalized;
            RAISE NOTICE '  - comparación: "%" = "%" → %', register_time_normalized, current_time_normalized, time_valid;
        END;

        -- Paso 3: Decidir si crear registro
        should_create := day_valid AND time_valid;
        RAISE NOTICE '¿Crear registro? (day_valid AND time_valid): %', should_create;

        -- Paso 4: Verificar registros existentes (CORREGIDO)
        SELECT COUNT(*) INTO existing_logs_count
        FROM work_logs
        WHERE user_id = config_record.user_id
        AND date = spain_current_date::date; -- CAST a date para evitar error de tipos

        RAISE NOTICE 'Registros existentes para hoy: %', existing_logs_count;

        -- Paso 5: Decisión final
        IF should_create AND existing_logs_count = 0 THEN
            RAISE NOTICE '✅ DECISIÓN: CREAR REGISTRO AUTOMÁTICO';
            RAISE NOTICE '   Insertando registro para usuario % en fecha %', config_record.user_id, spain_current_date;

            -- CREAR EL REGISTRO (simulando createAutoWorkLog)
            INSERT INTO work_logs (
                user_id, date, start_time, end_time, total_hours, type, is_auto_generated
            ) VALUES (
                config_record.user_id,
                spain_current_date::date,
                config_record.start_time,
                config_record.end_time,
                (EXTRACT(HOUR FROM config_record.end_time) * 60 + EXTRACT(MINUTE FROM config_record.end_time)) -
                (EXTRACT(HOUR FROM config_record.start_time) * 60 + EXTRACT(MINUTE FROM config_record.start_time)),
                'work',
                true
            );

            RAISE NOTICE '✅ REGISTRO CREADO EXITOSAMENTE POR SIMULACIÓN';

        ELSIF existing_logs_count > 0 THEN
            RAISE NOTICE 'ℹ️ DECISIÓN: NO CREAR - YA EXISTE REGISTRO';
        ELSE
            RAISE NOTICE '❌ DECISIÓN: NO CREAR - CONDICIONES NO CUMPLIDAS';
        END IF;

        RAISE NOTICE ''; -- línea en blanco
    END LOOP;

    RAISE NOTICE '=== FIN DE SIMULACIÓN (CORREGIDO) ===';
END $$;

-- 3.2 Verificar resultado de la simulación
SELECT '3.2 RESULTADO DE LA SIMULACIÓN' as subpaso;

SELECT
    'REGISTROS CREADOS POR SIMULACIÓN' as tipo,
    COUNT(*) as registros_creados,
    CASE
        WHEN COUNT(*) > 0 THEN '✅ SIMULACIÓN EXITOSA - REGISTROS CREADOS'
        ELSE '❌ SIMULACIÓN FALLIDA - NO SE CREARON REGISTROS'
    END as resultado_simulacion
FROM work_logs
WHERE date = CURRENT_DATE
AND is_auto_generated = true
AND created_at >= NOW() - INTERVAL '1 minute'; -- creados en el último minuto

-- Mostrar registros creados
SELECT
    'DETALLE DE REGISTROS CREADOS' as tipo,
    wl.id,
    u.username,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at,
    '✅ CREADO POR SIMULACIÓN CORREGIDA' as origen
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE
AND wl.is_auto_generated = true
AND wl.created_at >= NOW() - INTERVAL '1 minute'
ORDER BY wl.created_at DESC;

-- 3.3 RESULTADO DEL PASO 3
SELECT '3.3 RESULTADO PASO 3 (CORREGIDO)' as subpaso;

SELECT
    'RESULTADO GENERAL PASO 3' as tipo,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM work_logs
            WHERE date = CURRENT_DATE
            AND is_auto_generated = true
            AND created_at >= NOW() - INTERVAL '1 minute'
        ) THEN '✅ SIMULACIÓN FUNCIONA - EL SCHEDULER DEBERÍA FUNCIONAR IGUAL'
        ELSE '❌ SIMULACIÓN FALLA - HAY PROBLEMA EN LA LÓGICA'
    END as estado_simulacion,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM work_logs
            WHERE date = CURRENT_DATE
            AND is_auto_generated = true
            AND created_at >= NOW() - INTERVAL '1 minute'
        ) THEN 'CONTINUAR CON PASO 4 - HACER EL SCHEDULER MÁS ROBUSTO'
        ELSE 'REVISAR LOGS DE SIMULACIÓN ARRIBA Y CORREGIR LÓGICA'
    END as siguiente_accion;

-- 3.4 RESUMEN DE LO APRENDIDO EN SIMULACIÓN
SELECT '3.4 RESUMEN DE LO APRENDIDO EN SIMULACIÓN' as subpaso;

SELECT
    'APRENDIZAJES CLAVE' as tipo,
    '1. La lógica del scheduler está clara y funciona en simulación' as aprendizaje1,
    '2. Si la simulación falla, hay problema en datos o configuración' as aprendizaje2,
    '3. Si la simulación funciona, el scheduler debería funcionar igual' as aprendizaje3,
    '4. La comparación de tiempo se hace correctamente en la simulación' as aprendizaje4,
    '5. ERROR CORREGIDO: date = spain_current_date::date (cast necesario)' as correccion;
