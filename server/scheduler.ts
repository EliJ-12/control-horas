import { db } from "../server/db.js";
import { autoTimeSettings, workLogs } from "../shared/schema.js";
import { eq, and } from "drizzle-orm";
import type { AutoTimeSettings } from "../shared/schema.js";

export class AutoTimeScheduler {
  private interval: NodeJS.Timeout | null = null;
  private isProcessing: boolean = false; // Evitar procesamiento concurrente

  constructor() {
    console.log('🚀 [SCHEDULER] Iniciando AutoTimeScheduler...');
    this.testDatabaseConnection();
    // Ejecutar cada minuto
    this.interval = setInterval(() => {
      if (!this.isProcessing) {
        this.processScheduledRegistrations();
      } else {
        console.log('⚠️ [SCHEDULER] Saltando ejecución - procesamiento anterior aún activo');
      }
    }, 60000);
    console.log('⏰ [SCHEDULER] Scheduler iniciado - ejecutándose cada 60 segundos');

    // Ejecutar inmediatamente para pruebas
    setTimeout(() => {
      console.log('🧪 [SCHEDULER] Ejecutando verificación inicial inmediata...');
      if (!this.isProcessing) {
        this.processScheduledRegistrations();
      }
    }, 3000); // Esperar 3 segundos para inicialización
  }

  async testDatabaseConnection() {
    try {
      console.log('🔍 Testing database connection...');
      const settings = await db.select().from(autoTimeSettings).limit(1);
      console.log(`✅ Database connection OK, found ${settings.length} settings`);
    } catch (error) {
      console.error('❌ Database connection failed:', error);
    }
  }

  async processScheduledRegistrations() {
    if (this.isProcessing) {
      console.log('⚠️ [SCHEDULER] Saltando - ya hay un procesamiento activo');
      return;
    }

    this.isProcessing = true;
    const startTime = Date.now();

    try {
      console.log('🔄 [SCHEDULER] === INICIANDO PROCESAMIENTO DE REGISTROS PROGRAMADOS ===');

      // PASO 1: Calcular tiempo actual en España
      console.log('📅 [SCHEDULER] PASO 1: Calculando tiempo actual en España...');
      const now = new Date();
      const spainTime = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Madrid" }));
      const currentTime = spainTime.toTimeString().slice(0, 5); // HH:mm format
      const currentDay = spainTime.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      const currentDate = spainTime.toISOString().split('T')[0]; // YYYY-MM-DD

      console.log(`📍 [SCHEDULER] Tiempo España: ${currentTime}, Día: ${currentDay}, Fecha: ${currentDate}`);
      console.log(`🌍 [SCHEDULER] UTC actual: ${now.toTimeString().slice(0, 5)}, Día UTC: ${now.getDay()}`);

      // PASO 2: Obtener configuraciones activas
      console.log('👥 [SCHEDULER] PASO 2: Obteniendo configuraciones activas...');
      const allSettings = await db.select().from(autoTimeSettings).where(eq(autoTimeSettings.enabled, true));
      console.log(`� [SCHEDULER] Encontradas ${allSettings.length} configuraciones activas`);

      if (allSettings.length === 0) {
        console.log('⚠️ [SCHEDULER] No hay configuraciones activas - terminando procesamiento');
        return;
      }

      // PASO 3: Procesar cada configuración
      console.log('🔄 [SCHEDULER] PASO 3: Procesando cada configuración activa...');

      for (const settings of allSettings) {
        try {
          console.log(`👤 [SCHEDULER] --- PROCESANDO USUARIO ${settings.userId} ---`);

          // Validar que el usuario existe y es empleado
          const userCheck = await db.select()
            .from(autoTimeSettings)
            .where(eq(autoTimeSettings.userId, settings.userId))
            .limit(1);

          if (userCheck.length === 0) {
            console.log(`❌ [SCHEDULER] Usuario ${settings.userId} no encontrado - saltando`);
            continue;
          }

          console.log(`✅ [SCHEDULER] Usuario ${settings.userId} validado`);
          console.log(`   - enabled: ${settings.enabled}`);
          console.log(`   - autoRegisterTime: ${settings.autoRegisterTime}`);
          console.log(`   - currentTime: ${currentTime}`);

          // PASO 3.1: Verificar día válido
          const dayValid = this.shouldRegisterForDay(settings, currentDay);
          console.log(`📅 [SCHEDULER] Día válido: ${dayValid} (día ${currentDay})`);

          // PASO 3.2: Verificar hora válida
          const timeValid = this.isTimeToRegister(settings.autoRegisterTime, currentTime);
          console.log(`⏰ [SCHEDULER] Hora válida: ${timeValid}`);

          // PASO 3.3: Decidir si crear registro
          if (dayValid && timeValid) {
            console.log(`✅ [SCHEDULER] Condiciones cumplidas para usuario ${settings.userId} - verificando registros existentes...`);

            // PASO 3.4: Verificar registros existentes
            const existingLog = await db.select()
              .from(workLogs)
              .where(and(
                eq(workLogs.userId, settings.userId),
                eq(workLogs.date, currentDate)
              ))
              .limit(1);

            console.log(`📋 [SCHEDULER] Registros existentes para ${settings.userId} en ${currentDate}: ${existingLog.length}`);

            if (existingLog.length === 0) {
              console.log(`➕ [SCHEDULER] Creando registro automático para usuario ${settings.userId}...`);
              await this.createAutoWorkLog(settings, currentDate);
              console.log(`✅ [SCHEDULER] Registro automático creado exitosamente para usuario ${settings.userId}`);
            } else {
              console.log(`ℹ️ [SCHEDULER] Ya existe registro para usuario ${settings.userId} en ${currentDate} - saltando creación`);
            }
          } else {
            console.log(`❌ [SCHEDULER] Condiciones NO cumplidas para usuario ${settings.userId}: día=${dayValid}, hora=${timeValid}`);
          }

          console.log(`🏁 [SCHEDULER] --- FIN PROCESAMIENTO USUARIO ${settings.userId} ---`);
        } catch (userError) {
          console.error(`❌ [SCHEDULER] Error procesando usuario ${settings.userId}:`, userError);
          // Continuar con el siguiente usuario
        }
      }

      console.log('✅ [SCHEDULER] === PROCESAMIENTO COMPLETADO EXITOSAMENTE ===');

    } catch (error) {
      console.error('❌ [SCHEDULER] Error general en processScheduledRegistrations:', error);
    } finally {
      this.isProcessing = false;
      const duration = Date.now() - startTime;
      console.log(`⏱️ [SCHEDULER] Procesamiento finalizado en ${duration}ms`);
    }
  }

  shouldRegisterForDay(settings: any, currentDay: number): boolean {
    const dayMap = {
      0: settings.sunday,    // Sunday
      1: settings.monday,    // Monday
      2: settings.tuesday,   // Tuesday
      3: settings.wednesday, // Wednesday
      4: settings.thursday,  // Thursday
      5: settings.friday,    // Friday
      6: settings.saturday   // Saturday
    };
    
    return dayMap[currentDay as keyof typeof dayMap] || false;
  }

  isTimeToRegister(autoRegisterTime: string, currentTime: string): boolean {
    // CORREGIDO: Comparar normalizando ambos tiempos a formato hh:mm
    // El autoRegisterTime viene de la BD como TIME y puede tener formato hh:mm:ss o hh:mm
    // El currentTime viene del cálculo como hh:mm
    // Normalizar ambos a hh:mm para comparación correcta

    let registerTimeNormalized: string;

    // Si autoRegisterTime tiene formato hh:mm:ss, tomar solo hh:mm
    if (autoRegisterTime.length === 8 && autoRegisterTime.includes(':')) {
      registerTimeNormalized = autoRegisterTime.substring(0, 5); // hh:mm
    } else {
      registerTimeNormalized = autoRegisterTime.substring(0, 5); // hh:mm
    }

    // currentTime ya viene como hh:mm, pero asegurarse
    const currentTimeNormalized = currentTime.substring(0, 5); // hh:mm

    const timeMatches = registerTimeNormalized === currentTimeNormalized;

    console.log(`⏰ Time comparison: registerTime="${registerTimeNormalized}" vs currentTime="${currentTimeNormalized}" → ${timeMatches}`);

    return timeMatches;
  }

  async createAutoWorkLog(settings: AutoTimeSettings, date: string) {
    console.log(`🔧 Creating auto work log for user ${settings.userId} on ${date}`);
    
    // Calculate total hours in minutes
    const [startHour, startMin] = settings.startTime.split(':').map(Number);
    const [endHour, endMin] = settings.endTime.split(':').map(Number);
    
    const startTotalMinutes = startHour * 60 + startMin;
    const endTotalMinutes = endHour * 60 + endMin;
    const totalMinutes = endTotalMinutes - startTotalMinutes;

    console.log(`⏱️ Time calculation: ${startHour}:${startMin} to ${endHour}:${endMin} = ${totalMinutes} minutes`);

    if (totalMinutes <= 0) {
      console.warn(`❌ Invalid time range for user ${settings.userId}: ${settings.startTime} - ${settings.endTime}`);
      return;
    }

    const workLogData = {
      userId: settings.userId,
      date: date,
      startTime: settings.startTime,
      endTime: settings.endTime,
      totalHours: totalMinutes,
      type: 'work' as const,
      isAutoGenerated: true // Mark as auto-generated
    };

    console.log(`📝 Work log data to insert:`, workLogData);

    try {
      // Usar db.insert sin .returning() para evitar problemas
      console.log(`💾 Inserting work log into database...`);
      const result = await db.insert(workLogs).values(workLogData);
      console.log(`✅ Successfully inserted work log for user ${settings.userId}`);
      
      // Verificar que se insertó consultando directamente
      console.log(`🔍 Verifying insertion...`);
      const verification = await db.select()
        .from(workLogs)
        .where(and(
          eq(workLogs.userId, settings.userId),
          eq(workLogs.date, date),
          eq(workLogs.isAutoGenerated, true)
        ))
        .limit(1);
      
      if (verification.length > 0) {
        console.log(`✅ Verified work log exists in database with ID: ${verification[0].id}`);
        console.log(`📊 Created record: user_id=${verification[0].userId}, date=${verification[0].date}, start_time=${verification[0].startTime}, end_time=${verification[0].endTime}, is_auto_generated=${verification[0].isAutoGenerated}`);
        return verification[0];
      } else {
        console.error(`❌ Work log insertion claimed success but verification failed for user ${settings.userId}`);
        return null;
      }
    } catch (error) {
      console.error(`❌ Error inserting work log for user ${settings.userId}:`, error);
      throw error;
    }
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }

  // Función para forzar creación de registro (para pruebas)
  async forceCreateTestRecord(userId: number) {
    console.log(`🧪 Forcing test record creation for user ${userId}`);
    
    const settings = await db.select()
      .from(autoTimeSettings)
      .where(eq(autoTimeSettings.userId, userId))
      .limit(1);
    
    if (settings.length === 0) {
      console.error(`❌ No auto time settings found for user ${userId}`);
      return;
    }
    
    const currentDate = new Date().toISOString().split('T')[0];
    await this.createAutoWorkLog(settings[0], currentDate);
    console.log(`✅ Test record created for user ${userId}`);
  }
}

// Global scheduler instance
let scheduler: AutoTimeScheduler | null = null;

export function startAutoTimeScheduler() {
  if (!scheduler) {
    scheduler = new AutoTimeScheduler();
    console.log('Auto time scheduler started');
  }
  return scheduler;
}

export function getScheduler() {
  return scheduler;
}

export function forceCreateTestRecord(userId: number) {
  if (scheduler) {
    return scheduler.forceCreateTestRecord(userId);
  } else {
    console.error('Scheduler not initialized');
  }
}

export function stopAutoTimeScheduler() {
  if (scheduler) {
    scheduler.stop();
    scheduler = null;
    console.log('Auto time scheduler stopped');
  }
}
