# Sistema de Registro Automático de Horas

## Overview
El sistema de registro automático de horas permite a los empleados configurar registros automáticos de tiempo de trabajo según un horario predefinido. El sistema crea automáticamente los registros de horas en los días y horas especificadas.

## Características

### ✅ Funcionalidades Implementadas

1. **Configuración de Días de la Semana**
   - Los usuarios pueden seleccionar qué días de la semana desean registro automático
   - Soporte para lunes a domingo individualmente

2. **Configuración de Horarios**
   - Hora de inicio (ej: 09:00)
   - Hora de fin (ej: 14:00)
   - Hora específica para el registro automático (ej: 14:05)

3. **Registro Automático**
   - El sistema verifica cada minuto si debe crear registros
   - Crea registros automáticamente según la configuración
   - Evita duplicados (no crea si ya existe un registro para ese día)

4. **Modificación de Registros**
   - Los registros creados automáticamente pueden ser editados
   - Los usuarios pueden modificar horas después de la creación automática
   - Funcionalidad de eliminación disponible

5. **Interfaz de Usuario**
   - Panel de configuración intuitivo en el dashboard del empleado
   - Interruptor para activar/desactivar el sistema
   - Selectores de día con switches individuales
   - Campos de tiempo para configurar horarios

## Arquitectura Técnica

### Base de Datos
```sql
-- Nueva tabla para configuraciones automáticas
CREATE TABLE auto_time_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) UNIQUE,
    enabled BOOLEAN DEFAULT FALSE,
    monday BOOLEAN DEFAULT FALSE,
    tuesday BOOLEAN DEFAULT FALSE,
    wednesday BOOLEAN DEFAULT FALSE,
    thursday BOOLEAN DEFAULT FALSE,
    friday BOOLEAN DEFAULT FALSE,
    saturday BOOLEAN DEFAULT FALSE,
    sunday BOOLEAN DEFAULT FALSE,
    start_time TEXT NOT NULL, -- HH:mm
    end_time TEXT NOT NULL, -- HH:mm
    auto_register_time TEXT NOT NULL, -- HH:mm
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints

#### Para Empleados
- `GET /api/auto-time-settings` - Obtener configuración del usuario actual
- `POST /api/auto-time-settings` - Crear o actualizar configuración

#### Para Administradores
- `GET /api/admin/auto-time-settings` - Ver todas las configuraciones de usuarios

### Scheduler (Programador de Tareas)
- Se ejecuta cada minuto
- Verifica usuarios con configuración activa
- Comprueba día y hora actuales
- Crea registros de trabajo automáticamente

## Flujo de Trabajo

### 1. Configuración del Usuario
1. El empleado accede a su dashboard
2. Activa el "Registro Automático de Horas"
3. Selecciona los días de la semana (ej: lunes a viernes)
4. Configura hora de inicio (09:00) y fin (14:00)
5. Establece hora de registro automático (14:05)
6. Guarda la configuración

### 2. Proceso Automático
1. El scheduler se ejecuta cada minuto
2. A las 14:05 de un día seleccionado (lunes-viernes):
   - Verifica que el usuario tenga configuración activa
   - Confirma que el día actual está seleccionado
   - Comprueba que no exista un registro para hoy
   - Crea automáticamente el registro de 09:00 a 14:00

### 3. Modificación Posterior
1. Si el empleado necesita ajustar las horas:
   - Accede al historial de registros
   - Edita el registro creado automáticamente
   - Puede modificar horas de inicio/fin
   - O eliminar el registro si es necesario

## Ejemplo de Uso

### Escenario: Empleado con Horario Fijo
- **Configuración:** Lunes a viernes, 09:00-14:00, registro automático a las 14:05
- **Resultado:** Cada día laboral a las 14:05 se crea automáticamente un registro de 5 horas
- **Flexibilidad:** Si un día llega tarde o sale temprano, puede editar ese registro específico

### Escenario: Trabajo de Fin de Semana
- **Configuración:** Sábado y domingo, 10:00-15:00, registro automático a las 15:05
- **Resultado:** Cada fin de semana a las 15:05 se crea automáticamente un registro de 5 horas

## Validaciones y Seguridad

### Validaciones del Sistema
- ✅ Verificación de autenticación del usuario
- ✅ Validación de formatos de tiempo (HH:mm)
- ✅ Comprobación de rangos de tiempo válidos
- ✅ Prevención de registros duplicados
- ✅ Solo usuarios autenticados pueden configurar sus propios ajustes

### Seguridad
- Los ajustes son por usuario (no compartidos)
- Solo el administrador puede ver configuraciones de otros usuarios
- Los registros automáticos se marcan como tipo "work" normal

## Pruebas Realizadas

### Tests Unitarios Aprobados
- ✅ Lógica de selección de días
- ✅ Lógica de coincidencia de tiempo
- ✅ Cálculo de horas de trabajo
- ✅ Escenarios completos
- ✅ Diferentes configuraciones

### Casos de Prueba
1. **Días Laborales:** Lunes-viernes, 09:00-14:00, registro a 14:05
2. **Fin de Semana:** Sábado-domingo, 10:00-15:00, registro a 15:05
3. **Días Mixtos:** Lunes, miércoles, viernes con diferentes horarios
4. **Horarios Inválidos:** Sistema rechaza rangos de tiempo inválidos

## Instalación y Configuración

### 1. Actualizar Base de Datos
```bash
npm run db:push
```

### 2. Reiniciar Servidor
```bash
npm run dev
```

### 3. Verificar Funcionamiento
- Acceder como empleado al dashboard
- Configurar el registro automático
- Verificar que el scheduler está activo (logs en consola)

## Mantenimiento

### Monitoreo
- El scheduler logs cada proceso en consola
- Errores son capturados y registrados
- Los registros creados automáticamente son idénticos a los manuales

### Troubleshooting
- **No se crean registros:** Verificar que la configuración esté activa y el día/hora actual coincida
- **Registros duplicados:** El sistema previene duplicados automáticamente
- **Horarios incorrectos:** Los registros pueden editarse manualmente después

## Mejoras Futuras

### Posibles Enhancements
1. **Notificaciones:** Alertar cuando se crea un registro automático
2. **Reglas Complejas:** Soporte para múltiples horarios por día
3. **Vacaciones:** Excluir automáticamente días festivos
4. **Reportes:** Estadísticas de uso del sistema automático
5. **Aprobaciones:** Requerir aprobación para registros automáticos

## Conclusión

El sistema de registro automático de horas está completamente implementado y probado. Ofrece una solución robusta y flexible para empleados con horarios predecibles, manteniendo la capacidad de ajuste manual cuando sea necesario.

**Estado:** ✅ **COMPLETO Y LISTO PARA PRODUCCIÓN**
