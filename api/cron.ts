import type { VercelRequest, VercelResponse } from "@vercel/node";
import { startAutoTimeScheduler } from "../server/scheduler.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Solo permitir método GET
  if (req.method !== 'GET') {
    return res.status(405).json({
      success: false,
      error: "Method not allowed"
    });
  }

  try {
    // Verificar CRON_SECRET para seguridad
    const authHeader = req.headers.authorization;
    const cronSecret = process.env.CRON_SECRET;

    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      console.log("❌ [CRON] Acceso no autorizado - CRON_SECRET inválido");
      return res.status(401).json({
        success: false,
        error: "Unauthorized"
      });
    }

    console.log("🔄 [CRON] Ejecutando scheduler automático desde Vercel cron job...");

    // Inicializar scheduler si no está corriendo
    const scheduler = startAutoTimeScheduler();

    if (scheduler) {
      // Ejecutar procesamiento inmediato
      await scheduler.processScheduledRegistrations();

      console.log("✅ [CRON] Scheduler ejecutado exitosamente desde Vercel cron");

      return res.status(200).json({
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
    return res.status(500).json({
      success: false,
      error: "Error ejecutando scheduler",
      details: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString()
    });
  }
}
