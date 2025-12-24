# Control Horario - Employee Time Tracking System

## Overview

Control Horario is a full-stack employee time tracking and absence management application. It enables employees to log their work hours and request absences, while administrators can manage users, view all work logs, and approve/reject absence requests. The system features role-based access control with separate dashboards for employees and administrators.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **Framework**: React with TypeScript, using Vite as the build tool
- **Routing**: Wouter for lightweight client-side routing
- **State Management**: TanStack React Query for server state management and caching
- **UI Components**: Shadcn/ui component library built on Radix UI primitives
- **Styling**: Tailwind CSS with custom CSS variables for theming (supports light/dark modes)
- **Path Aliases**: `@/` maps to `client/src/`, `@shared/` maps to `shared/`

### Backend Architecture
- **Framework**: Express.js with TypeScript
- **Authentication**: Passport.js with local strategy, session-based authentication using express-session
- **Password Security**: Scrypt hashing with random salts
- **API Design**: RESTful endpoints defined in `shared/routes.ts` with Zod schema validation
- **Development**: Vite middleware integration for hot module replacement

### Data Storage
- **Database**: PostgreSQL
- **ORM**: Drizzle ORM with drizzle-zod for schema validation
- **Schema Location**: `shared/schema.ts` contains all table definitions
- **Migrations**: Managed via `drizzle-kit push` command

### Core Data Models
1. **Users**: Stores employee/admin accounts with roles
2. **Work Logs**: Records daily work hours with start/end times
3. **Absences**: Tracks absence requests with approval workflow (pending/approved/rejected)

### Authentication & Authorization
- Session-based auth with Passport.js local strategy
- Role-based access control: `admin` and `employee` roles
- Admins redirect to `/admin`, employees redirect to `/dashboard`
- Protected routes check authentication and role permissions

### Build & Deployment
- **Development**: `npm run dev` runs TSX with Vite middleware
- **Production Build**: Custom build script bundles server with esbuild and client with Vite
- **Output**: Production build outputs to `dist/` directory

## External Dependencies

### Database
- **PostgreSQL**: Primary database, connection via `DATABASE_URL` environment variable
- **connect-pg-simple**: PostgreSQL session store for production

### Key Libraries
- **drizzle-orm**: Database ORM with type-safe queries
- **zod**: Runtime schema validation for API inputs/outputs
- **date-fns**: Date formatting and manipulation utilities
- **recharts**: Data visualization for statistics dashboards

### Environment Variables
- `DATABASE_URL`: PostgreSQL connection string (required)
- `SESSION_SECRET`: Session encryption key (defaults to fallback for development)