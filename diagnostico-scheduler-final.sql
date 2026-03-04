-- DIAGNÓSTICO FINAL: ¿Por qué el scheduler no funciona?
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR SI HAY CONFIGURACIÓN ACTIVA
-- =====================================================
SELECT '=== PASO 1: CONFIGURACIÓN ACTIVA ===' as paso;

SELECT 
    'CONFIGURACIONES ACTIVAS' as tipo,
    COUNT(*) as total,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ NO HAY CONFIGURACIONES ACTIVAS - ESTE ES EL PROBLEMA'
        ELSE '✅ HAY CONFIGURACIONES ACTIVAS'
    END as estado
FROM auto_time_settings ats
WHERE ats.enabled = true;

-- Mostrar detalles de configuraciones activas
SELECT 
    u.username,
    ats.enabled,
    ats.monday,
    ats.tuesday,
    ats.wednesday,
    ats.thursday,
    ats.friday,
    ats.saturday,
    ats.sunday,
    ats.auto_register_time::text as hora_configurada,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ HORA COINCIDE'
        ELSE '❌ HORA NO COINCIDE'
    END as comparacion_hora,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_actual,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 THEN '✅ DÍA LABORAL'
        ELSE '❌ FIN DE SEMANA'
    END as estado_dia
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.enabled = true;

-- =====================================================
-- PASO 2: SIMULAR EXACTAMENTE LO QUE HACE EL SCHEDULER
-- =====================================================
SELECT '=== PASO 2: SIMULACIÓN DEL SCHEDULER ===' as paso;

-- Simular exactamente el proceso del scheduler
DO $$
DECLARE
    spain_time TEXT;
    current_day INTEGER;
    current_date TEXT;
    config_record RECORD;
    user_record RECORD;
BEGIN
    -- Obtener hora actual en España
    spain_time := TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI');
    current_day := EXTRACT(DOW FROM NOW() AT TIME ZONE 'Europe/Madrid');
    current_date := TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'YYYY-MM-DD');
    
    RAISE NOTICE 'Scheduler simulation:';
    RAISE NOTICE '  Spain time: %, Day: %, Date: %', spain_time, current_day, current_date;
    
    -- Obtener configuraciones activas (como lo hace el scheduler)
    FOR config_record IN
        SELECT ats.*, u.username 
        FROM auto_time_settings ats
        JOIN users u ON ats.user_id = u.id
        WHERE ats.enabled = true
    LOOP
        RAISE NOTICE 'Checking user % (%):', config_record.user_id, config_record.username;
        RAISE NOTICE '  - enabled: %', config_record.enabled;
        RAISE NOTICE '  - autoRegisterTime: %', config_record.auto_register_time::text;
        RAISE NOTICE '  - currentTime: %', spain_time;
        
        -- Verificar día (como shouldRegisterForDay)
        DECLARE
            should_register BOOLEAN := false;
        BEGIN
            CASE current_day
                WHEN 0 THEN should_register := config_record.sunday;
                WHEN 1 THEN should_register := config_record.monday;
                WHEN 2 THEN should_register := config_record.tuesday;
                WHEN 3 THEN should_register := config_record.wednesday;
                WHEN 4 THEN should_register := config_record.thursday;
                WHEN 5 THEN should_register := config_record.friday;
                WHEN 6 THEN should_register := config_record.saturday;
                ELSE should_register := false;
            END CASE;
            
            RAISE NOTICE '  - shouldRegisterForDay: %', should_register;
            
            -- Verificar tiempo (como isTimeToRegister)
            DECLARE
                register_time_text TEXT := config_record.auto_register_time::text;
                time_matches BOOLEAN;
            BEGIN
                -- Simular la comparación del scheduler
                -- registerTimeFull = register_time_text.padEnd(8, '00')
                -- currentFullTime = spain_time + ':00'
                DECLARE
                    register_time_full TEXT;
                    current_time_full TEXT;
                BEGIN
                    register_time_full := RPAD(register_time_text, 8, '00');
                    current_time_full := spain_time || ':00';
                    
                    time_matches := (register_time_full = current_time_full);
                    
                    RAISE NOTICE '  - registerTimeFull: "%"', register_time_full;
                    RAISE NOTICE '  - currentFullTime: "%"', current_time_full;
                    RAISE NOTICE '  - isTimeToRegister: %', time_matches;
                    
                    -- Verificar condiciones finales
                    IF should_register AND time_matches THEN
                        RAISE NOTICE '  ✅ CONDICIONES CUMPLIDAS - DEBERÍA CREAR REGISTRO';
                        
                        -- Verificar si ya existe registro
                        DECLARE
                            existing_count INTEGER;
                        BEGIN
                            SELECT COUNT(*) INTO existing_count
                            FROM work_logs
                            WHERE user_id = config_record.user_id
                            AND date = current_date;
                            
                            RAISE NOTICE '  - Existing logs for today: %', existing_count;
                            
                            IF existing_count = 0 THEN
                                RAISE NOTICE '  ➕ DEBERÍA CREAR NUEVO REGISTRO AQUÍ';
                                
                                -- Simular creación
                                INSERT INTO work_logs (
                                    user_id, date, start_time, end_time, total_hours, type, is_auto_generated
                                ) VALUES (
                                    config_record.user_id,
                                    current_date,
                                    config_record.start_time,
                                    config_record.end_time,
                                    (EXTRACT(HOUR FROM config_record.end_time) * 60 + EXTRACT(MINUTE FROM config_record.end_time)) - 
                                    (EXTRACT(HOUR FROM config_record.start_time) * 60 + EXTRACT(MINUTE FROM config_record.start_time)),
                                    'work',
                                    true
                                );
                                
                                RAISE NOTICE '  ✅ REGISTRO CREADO MANUALMENTE POR SIMULACIÓN';
                            ELSE
                                RAISE NOTICE '  ℹ️ YA TIENE REGISTRO HOY, NO CREA NUEVO';
                            END IF;
                        END;
                    ELSE
                        RAISE NOTICE '  ❌ CONDICIONES NO CUMPLIDAS - NO CREA REGISTRO';
                        RAISE NOTICE '     Día válido: %, Hora coincide: %', should_register, time_matches;
                    END IF;
                END;
            END;
        END;
    END LOOP;
END $$;

-- =====================================================
-- PASO 3: VERIFICAR RESULTADO
-- =====================================================
SELECT '=== PASO 3: RESULTADO FINAL ===' as paso;

SELECT 
    'REGISTROS AUTOMÁTICOS HOY' as tipo,
    COUNT(*) as total,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ SE CREARON REGISTROS'
        ELSE '❌ NO SE CREARON REGISTROS'
    END as estado
FROM work_logs 
WHERE date = CURRENT_DATE 
AND is_auto_generated = true;

-- Mostrar registros creados
SELECT 
    wl.id,
    wl.user_id,
    u.username,
    wl.date,
    wl.start_time,
    wl.end_time,
    wl.is_auto_generated,
    wl.created_at,
    CASE 
        WHEN wl.created_at >= NOW() - INTERVAL '1 minute' THEN '✅ CREADO AHORA'
        ELSE '⏰ CREADO ANTES'
    END as cuando_creado
FROM work_logs wl
JOIN users u ON wl.user_id = u.id
WHERE wl.date = CURRENT_DATE 
AND wl.is_auto_generated = true
ORDER BY wl.created_at DESC;

-- =====================================================
-- PASO 4: DIAGNÓSTICO FINAL
-- =====================================================
SELECT 
    '=== DIAGNÓSTICO FINAL ===' as titulo,
    'Si la simulación creó registro pero el scheduler automático no:' as problema1,
    '   - El scheduler NO se está ejecutando' as causa1,
    '   - Revisa logs del servidor con npm run dev' as solucion1,
    'Si la simulación NO creó registro:' as problema2,
    '   - Problema en configuración o condiciones' as causa2,
    '   - Revisa los logs de arriba' as solucion2,
    'Si todo funciona:' as problema3,
    '   - ¡El scheduler funciona correctamente!' as causa3;
