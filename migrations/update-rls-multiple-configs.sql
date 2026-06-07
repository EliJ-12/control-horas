-- Actualizar políticas RLS para soportar múltiples configuraciones por empleado

-- Paso 1: Eliminar políticas existentes
DROP POLICY IF EXISTS "users_can_view_own_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "users_can_create_own_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "users_can_update_own_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "users_can_delete_own_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "admins_can_view_all_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "admins_can_manage_all_auto_settings" ON auto_time_settings;
DROP POLICY IF EXISTS "service_role_full_access_auto_settings" ON auto_time_settings;

-- Paso 2: Crear nuevas políticas para múltiples configuraciones

-- Política para que los usuarios vean sus propias configuraciones (todas)
CREATE POLICY "users_can_view_own_auto_settings"
ON auto_time_settings FOR SELECT
USING (
    auth.uid()::text = user_id::text OR
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que los usuarios creen sus propias configuraciones
CREATE POLICY "users_can_create_own_auto_settings"
ON auto_time_settings FOR INSERT
WITH CHECK (
    auth.uid()::text = user_id::text OR
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que los usuarios actualicen sus propias configuraciones
CREATE POLICY "users_can_update_own_auto_settings"
ON auto_time_settings FOR UPDATE
USING (
    auth.uid()::text = user_id::text OR
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que los usuarios eliminen sus propias configuraciones
CREATE POLICY "users_can_delete_own_auto_settings"
ON auto_time_settings FOR DELETE
USING (
    auth.uid()::text = user_id::text OR
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que los admins vean todas las configuraciones
CREATE POLICY "admins_can_view_all_auto_settings"
ON auto_time_settings FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que los admins gestionen todas las configuraciones
CREATE POLICY "admins_can_manage_all_auto_settings"
ON auto_time_settings FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users WHERE users.id = auto_time_settings.user_id AND users.role = 'admin'
    )
);

-- Política para que el service role tenga acceso completo (para el scheduler)
CREATE POLICY "service_role_full_access_auto_settings"
ON auto_time_settings FOR ALL
TO postgres, service_role
USING (true)
WITH CHECK (true);

-- Paso 3: Verificar políticas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'auto_time_settings'
ORDER BY policyname;

-- Paso 4: Verificar que RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'auto_time_settings';
