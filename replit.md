# Control Horario - Employee Time Tracking System

## Overview

This is an employee time tracking and absence management system built for businesses. It provides separate portals for administrators and employees to manage work hours, submit absence requests, and view reports. The application is built with a React frontend and Express backend, using PostgreSQL for data persistence.

Key features:
- Role-based authentication (admin/employee)
- Work log entry and management
- Absence request submission and approval workflow
- Dashboard views with statistics
- Spanish language UI

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **Framework**: React 18 with TypeScript
- **Routing**: Wouter (lightweight React router)
- **State Management**: TanStack React Query for server state
- **UI Components**: shadcn/ui component library built on Radix UI primitives
- **Styling**: Tailwind CSS with CSS variables for theming
- **Build Tool**: Vite

The frontend follows a component-based architecture with:
- Protected routes that check authentication and role-based access
- Custom hooks for data fetching (`use-auth`, `use-work-logs`, `use-absences`, `use-users`)
- Shared layout component with role-specific navigation
- Reusable UI components from shadcn/ui

### Backend Architecture
- **Framework**: Express.js with TypeScript
- **Authentication**: Passport.js with local strategy, session-based auth
- **Session Storage**: In-memory by default (configurable for production)
- **Password Hashing**: Node.js crypto scrypt

The server uses a clean separation:
- `server/routes.ts` - API endpoint definitions
- `server/storage.ts` - Database access layer (IStorage interface)
- `server/auth.ts` - Authentication setup and password utilities
- `shared/routes.ts` - Shared API route definitions with Zod schemas
- `shared/schema.ts` - Drizzle ORM schema definitions

### Data Storage
- **Database**: PostgreSQL
- **ORM**: Drizzle ORM with drizzle-zod for validation
- **Schema Location**: `shared/schema.ts`

Database tables:
- `users` - User accounts with roles (admin/employee)
- `work_logs` - Daily work hour entries
- `absences` - Absence requests with approval status

### API Design
Routes are defined in `shared/routes.ts` with Zod schemas for type-safe request/response validation. The API follows REST conventions:
- `/api/auth/*` - Authentication endpoints
- `/api/users/*` - User management (admin only)
- `/api/work-logs/*` - Work log CRUD
- `/api/absences/*` - Absence request management

## External Dependencies

### Database
- PostgreSQL database (required, connection via `DATABASE_URL` environment variable)
- Drizzle Kit for migrations (`npm run db:push`)

### Key NPM Packages
- `drizzle-orm` / `drizzle-zod` - Database ORM and validation
- `express-session` - Session management
- `passport` / `passport-local` - Authentication
- `@tanstack/react-query` - Data fetching and caching
- `date-fns` - Date manipulation
- `zod` - Schema validation

### Environment Variables Required
- `DATABASE_URL` - PostgreSQL connection string
- `SESSION_SECRET` - Session encryption key (optional, has default for development)

### Development Tools
- Replit Vite plugins for development experience
- TypeScript for type safety across the stack