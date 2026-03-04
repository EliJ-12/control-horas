// API endpoint para cron jobs - ejecuta el scheduler
import type { VercelRequest, VercelResponse } from "@vercel/node";
import { startAutoTimeScheduler, getScheduler } from "../server/scheduler.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Solo permitir POST requests
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // Verificar API key si está configurada (seguridad básica)
  const apiKey = process.env.CRON_API_KEY;
  const providedKey = req.headers.authorization?.replace("Bearer ", "");

  if (apiKey && providedKey !== apiKey) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    console.log("🔄 [CRON] Ejecutando scheduler automático desde cron job...");

    // Iniciar scheduler si no está corriendo
    const scheduler = startAutoTimeScheduler();

    // Ejecutar procesamiento inmediato
    if (scheduler) {
      // Forzar ejecución inmediata (simulando el cron)
      await scheduler.processScheduledRegistrations();

      console.log("✅ [CRON] Scheduler ejecutado exitosamente");
      return res.status(200).json({
        success: true,
        message: "Scheduler ejecutado exitosamente",
        timestamp: new Date().toISOString()
      });
    } else {
      throw new Error("No se pudo inicializar el scheduler");
    }

  } catch (error) {
    console.error("❌ [CRON] Error ejecutando scheduler:", error);
    return res.status(500).json({
      success: false,
      error: "Error ejecutando scheduler",
      details: error instanceof Error ? error.message : String(error)
    });
  }
}
