import { serveStatic } from "./static.js";
import { createApp } from "./app.js";
import { startAutoTimeScheduler } from "./scheduler.js";
import { startSimpleAutoTimeScheduler } from "./simple-scheduler.js";

export function log(message: string, source = "express") {
  const formattedTime = new Date().toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });

  console.log(`${formattedTime} [${source}] ${message}`);
}

(async () => {
  const { app, httpServer } = await createApp();

  if (process.env.NODE_ENV === "production") {
    serveStatic(app);
  } else {
    const { setupVite } = await import("./vite.js");
    await setupVite(httpServer, app);
  }

  const port = parseInt(process.env.PORT || "5000", 10);
  httpServer.listen(
    {
      port,
      host: "0.0.0.0",
      reusePort: true,
    },
    () => {
      log(`serving on port ${port}`);
    },
  );

  // Start the auto time scheduler (original - corregido)
  startAutoTimeScheduler();
  
  // Simple scheduler comentado - solo para debugging
  // startSimpleAutoTimeScheduler();
})();
