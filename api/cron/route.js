import { NextResponse } from 'next/server';
// Importar el scheduler
import { startAutoTimeScheduler, getScheduler } from '../../server/scheduler.js';

export async function GET() {
  try {
    console.log("🔄 [CRON] Ejecutando scheduler automático desde Vercel cron job...");

    // Inicializar scheduler si no está corriendo
    const scheduler = startAutoTimeScheduler();

    if (scheduler) {
      // Ejecutar procesamiento inmediato
      await scheduler.processScheduledRegistrations();

      console.log("✅ [CRON] Scheduler ejecutado exitosamente desde Vercel cron");

      return NextResponse.json({
        success: true,
        message: "Scheduler ejecutado exitosamente",
        timestamp: new Date().toISOString(),
        source: "vercel-cron",
        schedule: "every 5 minutes"
      });
    } else {
      throw new Error("No se pudo inicializar el scheduler");
    }

  } catch (error) {
    console.error("❌ [CRON] Error ejecutando scheduler desde Vercel:", error);
    return NextResponse.json({
      success: false,
      error: "Error ejecutando scheduler",
      details: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
