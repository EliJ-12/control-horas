import { pgTable, text, serial, integer, boolean, timestamp, date } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";
import { relations } from "drizzle-orm";

// === TABLE DEFINITIONS ===

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  role: text("role", { enum: ["admin", "employee"] }).notNull().default("employee"),
  fullName: text("full_name").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const workLogs = pgTable("work_logs", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").references(() => users.id).notNull(),
  date: text("date").notNull(), // YYYY-MM-DD
  startTime: text("start_time").notNull(), // HH:mm
  endTime: text("end_time").notNull(), // HH:mm
  totalHours: integer("total_hours").notNull(), // stored in minutes
  type: text("type", { enum: ["work", "absence"] }).notNull().default("work"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const absences = pgTable("absences", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").references(() => users.id).notNull(),
  startDate: text("start_date").notNull(),
  endDate: text("end_date").notNull(),
  reason: text("reason").notNull(),
  status: text("status", { enum: ["pending", "approved", "rejected"] }).default("pending"),
  fileUrl: text("file_url"),
  isPartial: boolean("is_partial").default(false),
  partialHours: integer("partial_hours"), // in minutes
  createdAt: timestamp("created_at").defaultNow(),
});

export const autoTimeSettings = pgTable("auto_time_settings", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").references(() => users.id).notNull().unique(),
  enabled: boolean("enabled").default(false),
  monday: boolean("monday").default(false),
  tuesday: boolean("tuesday").default(false),
  wednesday: boolean("wednesday").default(false),
  thursday: boolean("thursday").default(false),
  friday: boolean("friday").default(false),
  saturday: boolean("saturday").default(false),
  sunday: boolean("sunday").default(false),
  startTime: text("start_time").notNull(), // HH:mm format
  endTime: text("end_time").notNull(), // HH:mm format
  autoRegisterTime: text("auto_register_time").notNull(), // HH:mm format when to auto-create the record
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// === RELATIONS ===
export const usersRelations = relations(users, ({ many }) => ({
  workLogs: many(workLogs),
  absences: many(absences),
  autoTimeSettings: many(autoTimeSettings),
}));

export const workLogsRelations = relations(workLogs, ({ one }) => ({
  user: one(users, {
    fields: [workLogs.userId],
    references: [users.id],
  }),
}));

export const absencesRelations = relations(absences, ({ one }) => ({
  user: one(users, {
    fields: [absences.userId],
    references: [users.id],
  }),
}));

export const autoTimeSettingsRelations = relations(autoTimeSettings, ({ one }) => ({
  user: one(users, {
    fields: [autoTimeSettings.userId],
    references: [users.id],
  }),
}));

// === BASE SCHEMAS ===
export const insertUserSchema = createInsertSchema(users).omit({ id: true, createdAt: true });
export const insertWorkLogSchema = createInsertSchema(workLogs).omit({ id: true, createdAt: true });
export const insertAbsenceSchema = createInsertSchema(absences).omit({ id: true, createdAt: true });
export const insertAutoTimeSettingsSchema = createInsertSchema(autoTimeSettings).omit({ id: true, createdAt: true, updatedAt: true });

// === TYPES ===
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type WorkLog = typeof workLogs.$inferSelect;
export type InsertWorkLog = z.infer<typeof insertWorkLogSchema>;
export type Absence = typeof absences.$inferSelect;
export type InsertAbsence = z.infer<typeof insertAbsenceSchema>;
export type AutoTimeSettings = typeof autoTimeSettings.$inferSelect;
export type InsertAutoTimeSettings = z.infer<typeof insertAutoTimeSettingsSchema>;

// Request types
export type CreateUserRequest = InsertUser;
export type CreateWorkLogRequest = InsertWorkLog;
export type CreateAbsenceRequest = InsertAbsence;
export type CreateAutoTimeSettingsRequest = InsertAutoTimeSettings;

// API Response types (for complex queries)
export type WorkLogWithUser = WorkLog & { user: User };
export type AbsenceWithUser = Absence & { user: User };
export type AutoTimeSettingsWithUser = AutoTimeSettings & { user: User };
