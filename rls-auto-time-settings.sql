-- RLS (Row Level Security) para auto_time_settings
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- PASO 1: HABILITAR RLS EN LA TABLA
-- =====================================================
ALTER TABLE auto_time_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PASO 2: ELIMINAR POLÍTICAS EXISTENTES (si las hay)
-- =====================================================
DROP POLICY IF EXISTS "Users can view own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can insert own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can update own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can delete own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Admins can view all auto time settings" ON auto_time_settings;

-- =====================================================
-- PASO 3: POLÍTICAS PARA USUARIOS NORMALES
-- =====================================================

-- Política para VER configuración propia
CREATE POLICY "Users can view own auto time settings" ON auto_time_settings
    FOR SELECT
    USING (
        auth.uid()::text = user_id::text
    );

-- Política para INSERTAR configuración propia
CREATE POLICY "Users can insert own auto time settings" ON auto_time_settings
    FOR INSERT
    WITH CHECK (
        auth.uid()::text = user_id::text
    );

-- Política para ACTUALIZAR configuración propia
CREATE POLICY "Users can update own auto time settings" ON auto_time_settings
    FOR UPDATE
    USING (
        auth.uid()::text = user_id::text
    )
    WITH CHECK (
        auth.uid()::text = user_id::text
    );

-- Política para ELIMINAR configuración propia
CREATE POLICY "Users can delete own auto time settings" ON auto_time_settings
    FOR DELETE
    USING (
        auth.uid()::text = user_id::text
    );

-- =====================================================
-- PASO 4: POLÍTICAS PARA ADMINISTRADORES
-- =====================================================

-- Política para administradores: VER todas las configuraciones
CREATE POLICY "Admins can view all auto time settings" ON auto_time_settings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auto_time_settings.user_id 
            AND users.role = 'admin'
            AND auth.uid()::text = users.id::text
        )
    );

-- =====================================================
-- PASO 5: POLÍTICA ESPECIAL PARA SCHEDULER (SERVICE ROLE)
-- =====================================================

-- Política para el scheduler (service role) - puede leer todo
CREATE POLICY "Service role can read all auto time settings" ON auto_time_settings
    FOR SELECT
    USING (
        -- Permitir si es service role (rol.postgres) o si el usuario está autenticado
        current_setting('role', true) = 'postgres' OR
        auth.role() = 'service_role'
    );

-- =====================================================
-- PASO 6: VERIFICACIÓN DE POLÍTICAS CREADAS
-- =====================================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'auto_time_settings'
ORDER BY policyname;

-- =====================================================
-- PASO 7: VERIFICAR ESTADO RLS
-- =====================================================
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'auto_time_settings';

-- =====================================================
-- PASO 8: PRUEBAS DE PERMISOS
-- =====================================================

-- Prueba 1: Verificar que un usuario solo puede ver su configuración
-- (Esto debe ejecutarse como usuario autenticado, no como postgres)
/*
-- Simular usuario con ID 1
SET LOCAL auth.uid = '1';
SET LOCAL auth.role = 'authenticated';

SELECT * FROM auto_time_settings WHERE user_id = 1; -- Debe funcionar
SELECT * FROM auto_time_settings WHERE user_id = 2; -- No debe devolver filas
*/

-- Prueba 2: Verificar que admin puede ver todas las configuraciones
/*
-- Simular usuario admin
SET LOCAL auth.uid = '1';
SET LOCAL auth.role = 'authenticated';

-- Esto debe funcionar si el usuario 1 es admin
SELECT ats.*, u.role 
FROM auto_time_settings ats
JOIN users u ON ats.user_id = u.id;
*/

-- =====================================================
-- PASO 9: FUNCIONES DE AYUDA PARA VERIFICACIÓN
-- =====================================================

-- Función para verificar configuración de un usuario específico
CREATE OR REPLACE FUNCTION get_user_auto_settings(user_uuid TEXT)
RETURNS TABLE (
    id INTEGER,
    user_id INTEGER,
    enabled BOOLEAN,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN,
    start_time TIME,
    end_time TIME,
    auto_register_time TIME,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
BEGIN
    SET LOCAL auth.uid = user_uuid;
    SET LOCAL auth.role = 'authenticated';
    
    RETURN QUERY
    SELECT *
    FROM auto_time_settings
    WHERE user_id = user_uuid::integer;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PASO 10: RESUMEN DE CONFIGURACIÓN
-- =====================================================
SELECT 
    '=== RLS CONFIGURADO PARA auto_time_settings ===' as titulo,
    '✅ RLS habilitado' as paso1,
    '✅ Políticas de usuarios creadas' as paso2,
    '✅ Políticas de admin creadas' as paso3,
    '✅ Política service role creada' as paso4,
    '✅ Funciones de ayuda creadas' as paso5;

SELECT 
    '=== RECOMENDACIONES ===' as titulo,
    '1. Probar con usuario autenticado' as rec1,
    '2. Verificar logs de Supabase' as rec2,
    '3. Revisar que el scheduler use service role' as rec3,
    '4. Probar inserción desde frontend' as rec4;

-- =====================================================
-- PASO 11: LIMPIEZA (opcional - descomentar si necesitas resetear)
-- =====================================================

/*
-- Si necesitas limpiar todo y empezar de nuevo:
ALTER TABLE auto_time_settings DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can insert own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can update own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can delete own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Admins can view all auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Service role can read all auto time settings" ON auto_time_settings;
DROP FUNCTION IF EXISTS get_user_auto_settings(TEXT);
ALTER TABLE auto_time_settings ENABLE ROW LEVEL SECURITY;
*/
