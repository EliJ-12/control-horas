import type { Express } from "express";
import { createServer, type Server } from "http";
import multer from "multer";
import path from "path";
import { storage } from "./storage.js";
import { setupAuth } from "./auth.js";
import { api } from "../shared/routes.js";
import { z } from "zod";
import { insertUserSchema, insertWorkLogSchema, insertAbsenceSchema } from "../shared/schema.js";
import { createClient } from '@supabase/supabase-js';

import { db } from "./db.js";
import { users, workLogs } from "../shared/schema.js";
import { eq, and, gte, lte } from "drizzle-orm";

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  // Setup Auth
  const { hashPassword } = await setupAuth(app);

  // Initialize Supabase client with comprehensive environment checking
  const supabaseUrl = process.env.SUPABASE_URL || 
                        process.env.NEXT_PUBLIC_SUPABASE_URL || 
                        process.env.VITE_SUPABASE_URL || '';
  
  // Try multiple service key names (most common ones)
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 
                       process.env.SERVICE_ROLE_KEY ||
                       process.env.SUPABASE_KEY || 
                       process.env.NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY || '';
  
  console.log('Environment check:', {
    supabaseUrl: !!supabaseUrl,
    supabaseKey: !!supabaseKey,
    availableEnvVars: Object.keys(process.env).filter(key => 
      key.toLowerCase().includes('supabase')
    )
  });
  
  if (!supabaseUrl || !supabaseKey) {
    console.error('Missing Supabase environment variables.');
    console.error('Required variables:');
    console.error('- SUPABASE_URL or NEXT_PUBLIC_SUPABASE_URL or VITE_SUPABASE_URL');
    console.error('- SUPABASE_SERVICE_ROLE_KEY or SERVICE_ROLE_KEY or SUPABASE_KEY');
    console.error('Available Supabase env vars:', Object.keys(process.env).filter(key => 
      key.toLowerCase().includes('supabase')
    ));
    throw new Error('Supabase configuration is missing. Please check your environment variables.');
  }

  const supabase = createClient(supabaseUrl, supabaseKey);

  // Configure multer for file uploads
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
      fileSize: 5 * 1024 * 1024, // 5MB limit
    },
    fileFilter: (req, file, cb) => {
      const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
      if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
      } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and PDF files are allowed.'));
      }
    }
  });

  // File upload endpoint with Supabase Storage
  app.post('/api/upload', upload.single('file'), async (req, res) => {
    console.log('Upload request received');
    
    if (!req.isAuthenticated()) {
      console.log('Upload failed: Not authenticated');
      return res.status(401).json({ message: "Unauthorized" });
    }

    if (!req.file) {
      console.log('Upload failed: No file');
      return res.status(400).json({ message: "No file uploaded" });
    }

    try {
      console.log('File details:', {
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size
      });

      const userId = (req.user as any).id;
      const originalName = req.file.originalname;
      
      // Clean file name: replace spaces with hyphens, remove special characters
      const cleanFileName = originalName
        .replace(/\s+/g, '-')
        .replace(/[^a-zA-Z0-9.-]/g, '');
      
      // Create organized path with user folder and timestamp
      const timestamp = Date.now();
      const filePath = `${userId}/${timestamp}-${cleanFileName}`;
      
      console.log('Upload path:', filePath);
      console.log('Supabase client initialized:', !!supabase);
      
      // Upload to Supabase Storage
      console.log('Attempting upload to bucket: absence-files');
      const { data, error } = await supabase.storage
        .from('absence-files')
        .upload(filePath, req.file.buffer, {
          contentType: req.file.mimetype,
          cacheControl: '3600',
          upsert: false
        });

      console.log('Supabase upload result:', { data, error });

      if (error) {
        console.error('Supabase upload error:', error);
        // Try alternative bucket name if needed
        console.log('Trying alternative approach...');
        
        const { data: altData, error: altError } = await supabase.storage
          .from('absence-files')
          .upload(filePath, req.file.buffer);
          
        if (altError) {
          const errorMessage = altError instanceof Error ? altError.message : String(altError);
          throw new Error(`Failed to upload file to Supabase Storage: ${errorMessage}`);
        }
        
        console.log('Alternative upload successful:', altData);
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('absence-files')
        .getPublicUrl(filePath);

      console.log('Public URL result:', urlData);

      res.json({ fileUrl: urlData.publicUrl });
    } catch (error) {
      console.error('Upload error:', error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({ message: "Failed to upload file", error: errorMessage });
    }
  });

  // === User Management (Admin Only ideally, but open for now for setup) ===
  app.get(api.users.list.path, async (req, res) => {
    if (!req.isAuthenticated() || (req.user as any).role !== 'admin') {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const users = await storage.getAllUsers();
    res.json(users);
  });

  app.post(api.users.create.path, async (req, res) => {
    // Only admins can create users, or if no users exist (initial setup)
    const allUsers = await storage.getAllUsers();
    const isAdmin = req.isAuthenticated() && (req.user as any).role === 'admin';
    
    if (allUsers.length > 0 && !isAdmin) {
       return res.status(401).json({ message: "Unauthorized. Only admins can create users." });
    }

    try {
      const input = insertUserSchema.parse(req.body);
      const hashedPassword = await hashPassword(input.password);
      const user = await storage.createUser({
        ...input,
        password: hashedPassword,
      });
      res.status(201).json(user);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return res.status(400).json({ message: err.errors[0].message });
      }
      throw err;
    }
  });

  // === Work Logs ===
  app.get(api.workLogs.list.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    // Admins see all or filter. Employees see only theirs.
    const user = req.user as any;
    let userId = user.id;
    
    if (user.role === 'admin') {
      // If admin passed a userId query param, use it. Otherwise get all.
      if (req.query.userId) {
        userId = Number(req.query.userId);
      } else {
        userId = undefined; // Get all
      }
    }

    const logs = await storage.getWorkLogs(
      userId,
      req.query.startDate as string,
      req.query.endDate as string
    );
    res.json(logs);
  });

  app.post(api.workLogs.create.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    try {
      const input = insertWorkLogSchema.parse(req.body);
      
      // Check for duplicate work log on same date for same user and type
      const existingLogs = await storage.getWorkLogs(input.userId, input.date, input.date);
      const duplicate = existingLogs.find(log => 
        log.date === input.date && 
        log.type === input.type &&
        log.userId === input.userId
      );
      
      if (duplicate) {
        return res.status(409).json({ 
          message: `Ya existe un registro de ${input.type === 'work' ? 'trabajo' : 'ausencia'} para esta fecha.` 
        });
      }
      
      const log = await storage.createWorkLog({
        ...input,
        userId: (req.user as any).id // Enforce current user
      });
      res.status(201).json(log);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return res.status(400).json({ message: err.errors[0].message });
      }
      throw err;
    }
  });

  app.patch(api.workLogs.update.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    const id = Number(req.params.id);
    const existing = await storage.getWorkLog(id);
    if (!existing) return res.status(404).json({ message: "Not found" });
    
    // Only owner (if pending) or admin can update
    const user = req.user as any;
    if (user.role !== 'admin' && existing.userId !== user.id) {
      return res.status(403).json({ message: "Cannot edit this log" });
    }

    const updated = await storage.updateWorkLog(id, req.body);
    res.json(updated);
  });

  app.delete(api.workLogs.update.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    const id = Number(req.params.id);
    const existing = await storage.getWorkLog(id);
    if (!existing) return res.status(404).json({ message: "Not found" });
    
    const user = req.user as any;
    if (user.role !== 'admin' && existing.userId !== user.id) {
      return res.status(403).json({ message: "Cannot delete this log" });
    }

    await storage.deleteWorkLog(id);
    res.sendStatus(204);
  });

  // === Absences ===
  app.get(api.absences.list.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });

    const user = req.user as any;
    let userId = user.id;

    if (user.role === 'admin') {
      if (req.query.userId) {
         userId = Number(req.query.userId);
      } else {
        userId = undefined;
      }
    }

    const list = await storage.getAbsences(userId, req.query.status as string);
    res.json(list);
  });

  app.post(api.absences.create.path, async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });

    try {
      const input = insertAbsenceSchema.parse(req.body);
      
      // Check for overlapping absence requests
      const existingAbsences = await storage.getAbsences(input.userId);
      const overlap = existingAbsences.find(absence => {
        const existingStart = new Date(absence.startDate);
        const existingEnd = new Date(absence.endDate);
        const newStart = new Date(input.startDate);
        const newEnd = new Date(input.endDate);
        
        return (
          (newStart >= existingStart && newStart <= existingEnd) ||
          (newEnd >= existingStart && newEnd <= existingEnd) ||
          (newStart <= existingStart && newEnd >= existingEnd)
        );
      });
      
      if (overlap) {
        return res.status(409).json({ 
          message: "Ya existe una solicitud de ausencia para este período." 
        });
      }
      
      const absence = await storage.createAbsence({
        ...input,
        userId: (req.user as any).id
      });
      res.status(201).json(absence);
    } catch (err) {
       if (err instanceof z.ZodError) {
        return res.status(400).json({ message: err.errors[0].message });
      }
      throw err;
    }
  });

  app.patch(api.absences.updateStatus.path, async (req, res) => {
    if (!req.isAuthenticated() || (req.user as any).role !== 'admin') {
      return res.status(401).json({ message: "Unauthorized" });
    }
    
    const id = Number(req.params.id);
    const updated = await storage.updateAbsenceStatus(id, req.body.status);
    res.json(updated);
  });

  // Allow employees to delete their own absence requests (only if pending)
  app.delete("/api/absences/:id", async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    const id = Number(req.params.id);
    const absence = await storage.getAbsence(id);
    if (!absence) return res.status(404).json({ message: "Not found" });
    
    const user = req.user as any;
    // Only owner (if pending) or admin can delete
    if (user.role !== 'admin' && (absence.userId !== user.id || absence.status !== 'pending')) {
      return res.status(403).json({ message: "Cannot delete this absence request" });
    }

    await storage.deleteAbsence(id);
    res.sendStatus(204);
  });

  // Allow employees to update their own absence requests (only if pending)
  app.patch("/api/absences/:id", async (req, res) => {
    if (!req.isAuthenticated()) return res.status(401).json({ message: "Unauthorized" });
    
    const id = Number(req.params.id);
    const absence = await storage.getAbsence(id);
    if (!absence) return res.status(404).json({ message: "Not found" });
    
    const user = req.user as any;
    // Only owner (if pending) or admin can update
    if (user.role !== 'admin' && (absence.userId !== user.id || absence.status !== 'pending')) {
      return res.status(403).json({ message: "Cannot edit this absence request" });
    }

    const updated = await storage.updateAbsence(id, req.body);
    res.json(updated);
  });

  app.delete("/api/users/:id", async (req, res) => {
    if (!req.isAuthenticated() || (req.user as any).role !== 'admin') {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const id = Number(req.params.id);
    await db.delete(users).where(eq(users.id, id));
    res.sendStatus(204);
  });

  app.patch("/api/users/:id", async (req, res) => {
    if (!req.isAuthenticated() || (req.user as any).role !== 'admin') {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const id = Number(req.params.id);
    const [updated] = await db.update(users).set(req.body).where(eq(users.id, id)).returning();
    res.json(updated);
  });

  return httpServer;
}
