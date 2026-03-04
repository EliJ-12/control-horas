import { db } from "../server/db.js";
import { autoTimeSettings, workLogs } from "../shared/schema.js";
import { eq, and } from "drizzle-orm";
import type { AutoTimeSettings } from "../shared/schema.js";

export class AutoTimeScheduler {
  private interval: NodeJS.Timeout | null = null;

  constructor() {
    console.log('🚀 Initializing AutoTimeScheduler...');
    this.testDatabaseConnection();
    // Run every minute to check for scheduled registrations
    this.interval = setInterval(() => {
      this.processScheduledRegistrations();
    }, 60000); // Check every minute
    console.log('⏰ AutoTimeScheduler started, checking every minute');
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
    try {
      console.log('Processing scheduled time registrations...');
      
      // Usar zona horaria de España (Europe/Madrid)
      const now = new Date();
      const spainTime = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Madrid" }));
      const currentTime = spainTime.toTimeString().slice(0, 5); // HH:mm format
      const currentDay = spainTime.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      const currentDate = spainTime.toISOString().split('T')[0]; // YYYY-MM-DD

      console.log(`Spain time: ${currentTime}, Day: ${currentDay}, Date: ${currentDate}`);
      console.log(`UTC time: ${now.toTimeString().slice(0, 5)}, UTC Day: ${now.getDay()}`);

      // Get all enabled auto time settings
      const allSettings = await db.select().from(autoTimeSettings).where(eq(autoTimeSettings.enabled, true));
      console.log(`Found ${allSettings.length} enabled auto time settings`);

      for (const settings of allSettings) {
        console.log(`Checking user ${settings.userId}: enabled=${settings.enabled}, day=${this.shouldRegisterForDay(settings, currentDay)}, time=${this.isTimeToRegister(settings.autoRegisterTime, currentTime)}`);
        
        // Check if current time matches the auto register time (within the same minute)
        if (this.shouldRegisterForDay(settings, currentDay) && 
            this.isTimeToRegister(settings.autoRegisterTime, currentTime)) {
          
          // Check if a work log already exists for today
          const existingLog = await db.select()
            .from(workLogs)
            .where(and(
              eq(workLogs.userId, settings.userId),
              eq(workLogs.date, currentDate)
            ))
            .limit(1);

          console.log(`User ${settings.userId}: Existing logs for today (${currentDate}): ${existingLog.length}`);

          if (existingLog.length === 0) {
            // Create new work log
            await this.createAutoWorkLog(settings, currentDate);
            console.log(`✅ Created auto work log for user ${settings.userId} on ${currentDate} from ${settings.startTime} to ${settings.endTime} at ${currentTime} Spain time`);
          } else {
            console.log(`ℹ️ User ${settings.userId} already has a work log for ${currentDate}, skipping auto creation`);
          }
        }
      }
    } catch (error) {
      console.error('Error processing scheduled time registrations:', error);
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
    // Convertir time a string para comparación segura
    const registerTimeStr = autoRegisterTime.toString().slice(0, 5); // HH:mm format
    const currentTimeStr = currentTime.slice(0, 5); // HH:mm format
    return registerTimeStr === currentTimeStr;
  }

  async createAutoWorkLog(settings: AutoTimeSettings, date: string) {
    // Calculate total hours in minutes
    const [startHour, startMin] = settings.startTime.split(':').map(Number);
    const [endHour, endMin] = settings.endTime.split(':').map(Number);
    
    const startTotalMinutes = startHour * 60 + startMin;
    const endTotalMinutes = endHour * 60 + endMin;
    const totalMinutes = endTotalMinutes - startTotalMinutes;

    if (totalMinutes <= 0) {
      console.warn(`Invalid time range for user ${settings.userId}: ${settings.startTime} - ${settings.endTime}`);
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

    console.log(`Inserting work log:`, workLogData);

    try {
      const result = await db.insert(workLogs).values(workLogData).returning();
      console.log(`✅ Successfully inserted work log with ID: ${result[0]?.id}`);
      return result[0];
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
