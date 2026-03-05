-- =====================================================
-- RLS PARA auto_time_settings - CONFIGURACIÓN COMPLETA
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- PASO 1: HABILITAR RLS EN LA TABLA
ALTER TABLE auto_time_settings ENABLE ROW LEVEL SECURITY;

-- PASO 2: ELIMINAR POLÍTICAS EXISTENTES
DROP POLICY IF EXISTS "Users can view own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can insert own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can update own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Users can delete own auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Admins can view all auto time settings" ON auto_time_settings;
DROP POLICY IF EXISTS "Service role can read all auto time settings" ON auto_time_settings;

-- =====================================================
-- POLÍTICAS PARA USUARIOS EMPLEADOS
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
-- POLÍTICAS PARA ADMINISTRADORES
-- =====================================================

-- Política para administradores: VER todas las configuraciones
CREATE POLICY "Admins can view all auto time settings" ON auto_time_settings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::text = auth.uid()::text
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLÍTICA PARA SCHEDULER (SERVICE ROLE)
-- =====================================================

-- Política para el scheduler (service role) - puede leer todo
CREATE POLICY "Service role can read all auto time settings" ON auto_time_settings
    FOR SELECT
    USING (
        auth.role() = 'service_role' OR
        current_setting('role', true) = 'postgres'
    );

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

-- Verificar estado RLS
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'auto_time_settings';

-- Verificar políticas creadas
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
