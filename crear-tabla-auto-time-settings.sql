-- SOLUCIÓN INMEDIATA: Crear tabla auto_time_settings
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: VERIFICAR SI EXISTE LA TABLA
-- =====================================================
SELECT 'VERIFICANDO TABLA auto_time_settings' as paso;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'auto_time_settings';

-- =====================================================
-- PASO 2: CREAR TABLA SI NO EXISTE
-- =====================================================
SELECT 'CREANDO TABLA auto_time_settings' as paso;

CREATE TABLE IF NOT EXISTS auto_time_settings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  enabled BOOLEAN DEFAULT FALSE,
  monday BOOLEAN DEFAULT FALSE,
  tuesday BOOLEAN DEFAULT FALSE,
  wednesday BOOLEAN DEFAULT FALSE,
  thursday BOOLEAN DEFAULT FALSE,
  friday BOOLEAN DEFAULT FALSE,
  saturday BOOLEAN DEFAULT FALSE,
  sunday BOOLEAN DEFAULT FALSE,
  start_time TIME NOT NULL, -- HH:mm format
  end_time TIME NOT NULL, -- HH:mm format
  auto_register_time TIME NOT NULL, -- HH:mm format when to auto-create the record
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PASO 3: VERIFICAR QUE SE CREÓ
-- =====================================================
SELECT 'VERIFICANDO ESTRUCTURA CREADA' as paso;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'auto_time_settings' 
ORDER BY ordinal_position;

-- =====================================================
-- PASO 4: CREAR ÍNDICES
-- =====================================================
SELECT 'CREANDO ÍNDICES' as paso;
CREATE INDEX IF NOT EXISTS idx_auto_time_settings_user_enabled 
ON auto_time_settings(user_id, enabled);

-- =====================================================
-- PASO 5: CREAR TRIGGER PARA updated_at
-- =====================================================
SELECT 'CREANDO TRIGGER updated_at' as paso;

-- Crear o reemplazar la función del trigger
CREATE OR REPLACE FUNCTION update_auto_time_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear el trigger
CREATE TRIGGER update_auto_time_settings_updated_at 
BEFORE UPDATE ON auto_time_settings 
FOR EACH ROW EXECUTE FUNCTION update_auto_time_settings_updated_at();

-- =====================================================
-- PASO 6: INSERTAR CONFIGURACIÓN DE PRUEBA
-- =====================================================
SELECT 'INSERTANDO CONFIGURACIÓN PRUEBA' as paso;

-- Eliminar configuración existente si hay
DELETE FROM auto_time_settings WHERE user_id = 1;

-- Insertar configuración de prueba para usuario admin (id=1)
INSERT INTO auto_time_settings (
    user_id, enabled, monday, tuesday, wednesday, thursday, friday, 
    saturday, sunday, start_time, end_time, auto_register_time
) VALUES (
    1, -- user_id (admin)
    true, -- enabled
    true, true, true, true, true, -- lunes a viernes
    false, false, -- sábado y domingo
    '09:00', -- start_time
    '17:00', -- end_time
    '17:05'  -- auto_register_time
);

-- =====================================================
-- PASO 7: VERIFICAR CONFIGURACIÓN CREADA
-- =====================================================
SELECT 'VERIFICANDO CONFIGURACIÓN' as paso;
SELECT 
    ats.id,
    ats.user_id,
    u.username,
    u.full_name,
    ats.enabled,
    ats.monday,
    ats.tuesday,
    ats.wednesday,
    ats.thursday,
    ats.friday,
    ats.saturday,
    ats.sunday,
    ats.start_time,
    ats.end_time,
    ats.auto_register_time,
    ats.created_at,
    ats.updated_at,
    CASE 
        WHEN ats.enabled = true THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.user_id = 1;

-- =====================================================
-- PASO 8: VERIFICAR HORA ACTUAL
-- =====================================================
SELECT 'VERIFICANDO HORA ACTUAL' as paso;
SELECT 
    NOW() as hora_utc,
    NOW() AT TIME ZONE 'Europe/Madrid' as hora_espana,
    CURRENT_TIME as hora_actual_utc,
    CURRENT_TIME AT TIME ZONE 'Europe/Madrid' as hora_actual_espana,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_formateada_espana,
    CURRENT_DATE as fecha_actual,
    EXTRACT(DOW FROM CURRENT_DATE) as dia_semana_numero,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN 'LUNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 2 THEN 'MARTES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 3 THEN 'MIÉRCOLES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 4 THEN 'JUEVES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 5 THEN 'VIERNES'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN 'SÁBADO'
        WHEN EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN 'DOMINGO'
    END as dia_semana_nombre;

-- =====================================================
-- PASO 9: VERIFICAR SI DEBERÍA EJECUTARSE
-- =====================================================
SELECT 'VERIFICANDO EJECUCIÓN' as paso;
SELECT 
    ats.user_id,
    u.username,
    ats.auto_register_time,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') as hora_actual_espana,
    CASE 
        WHEN ats.auto_register_time::text = TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI') 
        THEN '✅ DEBERÍA EJECUTARSE AHORA'
        ELSE CONCAT('❌ Hora configurada: ', ats.auto_register_time::text, ', Actual: ', TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid', 'HH24:MI'))
    END as estado_hora,
    CASE 
        WHEN EXTRACT(DOW FROM CURRENT_DATE) BETWEEN 1 AND 5 AND ats.enabled = true
        THEN '✅ DÍA LABORAL ACTIVO'
        ELSE '❌ DÍA NO LABORAL O DESACTIVADO'
    END as estado_dia
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id
WHERE ats.user_id = 3;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================
SELECT '✅ TABLA auto_time_settings CREADA CORRECTAMENTE' as resultado;
SELECT '✅ CONFIGURACIÓN DE PRUEBA INSERTADA' as paso1;
SELECT '✅ ÍNDICES CREADOS' as paso2;
SELECT '✅ TRIGGERS CONFIGURADOS' as paso3;
SELECT '✅ LISTO PARA PROBAR SCHEDULER' as paso4;

-- =====================================================
-- PASO 10: FORZAR EJECUCIÓN EN 1 MINUTO
-- =====================================================
SELECT 'CONFIGURANDO EJECUCIÓN INMEDIATA' as paso;

-- Actualizar para que se ejecute en el próximo minuto
UPDATE auto_time_settings 
SET auto_register_time = (TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI'))::time
WHERE user_id = 1;

-- Verificar actualización
SELECT 
    'CONFIGURADO PARA EJECUTAR EN:' as mensaje,
    TO_CHAR(NOW() AT TIME ZONE 'Europe/Madrid' + INTERVAL '1 minute', 'HH24:MI') as proxima_ejecucion,
    auto_register_time::text as hora_configurada
FROM auto_time_settings 
WHERE user_id = 1;
