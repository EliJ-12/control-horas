# Configuración de Supabase para Registro Automático de Horas

## Pasos para Configurar Supabase

### 1. Crear Proyecto Supabase
1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta o inicia sesión
3. Crea un nuevo proyecto
4. Espera a que el proyecto esté listo

### 2. Obtener Credenciales
Una vez creado el proyecto, ve a:
- **Project Settings** > **Database**
- Copia la **Connection string**
- Ve a **Project Settings** > **API**
- Copia el **Project URL** y **anon key**

### 3. Ejecutar Script SQL
1. Ve a **SQL Editor** en tu proyecto Supabase
2. Copia y pega el contenido del archivo `supabase-setup.sql`
3. Ejecuta el script para crear todas las tablas

### 4. Configurar Variables de Entorno
Crea un archivo `.env.local` en la raíz del proyecto con:

```env
# Database Configuration - Supabase
DATABASE_URL=postgresql://postgres:[TU-PASSWORD]@db.[TU-PROJECT-REF].supabase.co:5432/postgres
SUPABASE_URL=https://[TU-PROJECT-REF].supabase.co
SUPABASE_ANON_KEY=[TU-ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY=[TU-SERVICE-ROLE-KEY]

# Session Configuration
SESSION_SECRET=una-clave-secreta-para-sesiones

# Environment
NODE_ENV=development
```

### 5. Iniciar el Servidor
```bash
npm run dev
```

## Tablas Creadas

### `users`
- Almacena información de usuarios (admin y empleados)

### `work_logs` 
- Registros de horas de trabajo y ausencias
- Cada registro tiene: usuario, fecha, hora inicio, hora fin, total en minutos

### `absences`
- Solicitudes de ausencia (pendientes, aprobadas, rechazadas)

### `auto_time_settings` ⭐ **NUEVA**
- Configuración para registro automático de horas
- Campos principales:
  - `enabled`: activa/desactiva el sistema
  - `monday`...`sunday`: días de la semana seleccionados
  - `start_time`, `end_time`: horario de trabajo
  - `auto_register_time`: hora específica para crear el registro

## Funcionalidad del Sistema

### Registro Automático
- El scheduler se ejecuta cada minuto
- Verifica usuarios con `enabled = true`
- Comprueba día y hora actuales
- Crea automáticamente registros de trabajo

### Ejemplo de Configuración
```sql
-- Usuario quiere registro automático lunes-viernes 9:00-14:00
INSERT INTO auto_time_settings (
  user_id, enabled, monday, tuesday, wednesday, thursday, friday,
  start_time, end_time, auto_register_time
) VALUES (
  1, true, true, true, true, true, true,
  '09:00:00', '14:00:00', '14:05:00'
);
```

Esto creará automáticamente un registro cada día laboral a las 14:05 con horas 09:00-14:00.

## Verificación

1. Inicia sesión como empleado
2. Ve al dashboard
3. Deberías ver la sección "Registro Automático de Horas"
4. Configura tus preferencias
5. El sistema creará registros automáticamente según tu configuración

## Troubleshooting

### Error: "DATABASE_URL must be set"
- Asegúrate de tener el archivo `.env.local` con las credenciales correctas

### Error: "relation does not exist"
- Ejecuta el script SQL en el editor de Supabase
- Verifica que todas las tablas se crearon correctamente

### El componente no aparece
- Revisa la consola del navegador por errores
- Verifica que el servidor esté corriendo sin errores

¡Listo! Tu sistema de registro automático de horas está funcional.
