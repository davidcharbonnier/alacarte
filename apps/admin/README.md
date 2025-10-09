# A la carte Admin Panel

[![🚀 CI/CD Pipeline](https://github.com/davidcharbonnier/alacarte-admin/actions/workflows/release.yml/badge.svg)](https://github.com/davidcharbonnier/alacarte-admin/actions/workflows/release.yml)
[![🧪 Test Build](https://github.com/davidcharbonnier/alacarte-admin/actions/workflows/test-build.yml/badge.svg)](https://github.com/davidcharbonnier/alacarte-admin/actions/workflows/test-build.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/davidcharbonnier/alacarte-admin.svg)](https://hub.docker.com/r/davidcharbonnier/alacarte-admin)
[![Docker Image Size](https://img.shields.io/docker/image-size/davidcharbonnier/alacarte-admin/latest.svg)](https://hub.docker.com/r/davidcharbonnier/alacarte-admin)
[![Next.js 15](https://img.shields.io/badge/Next.js-15-black)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)](https://www.typescriptlang.org/)
[![NextAuth.js](https://img.shields.io/badge/NextAuth.js-v5-purple)](https://authjs.dev/)

**Web-based administrative interface for the A la carte platform**

The admin panel provides secure management capabilities for the A la carte rating platform, featuring a config-driven generic architecture that enables adding new item types in minutes.

## Project Overview

The admin panel serves as the administrative interface for A la carte, featuring:

- **Config-Driven Architecture** - Add new item types in ~5 minutes via configuration
- **Google OAuth Authentication** - Production-ready auth with NextAuth.js v5
- **Generic Components** - Single codebase handles all item types consistently
- **Item Management** - View, delete, and bulk seed items (cheese, gin)
- **Dynamic Dashboard** - Auto-generates statistics for all configured item types
- **Delete Impact Assessment** - Preview consequences before destructive operations
- **Bulk Data Operations** - Seed data from remote URLs

## Project Roadmap

### Planned Features (Optional)

**Authentication System:**
- NextAuth.js v5 integration
- Google OAuth provider
- Backend JWT exchange
- Admin role verification (checks database flag + initial admin email)
- Server-side route protection
- Secure session storage (httpOnly cookies)
- Automatic token refresh
- User data transformation in session (GORM to JavaScript conventions)

**Admin Access Control:**
- Initial admin bootstrap via `INITIAL_ADMIN_EMAIL` environment variable
- Database-backed admin role (`is_admin` flag)
- Dual authorization check (database OR initial admin email)
- Admin verification during login
- Protected admin endpoints (middleware)

**Generic Config System:**
- Configuration-driven item type definitions
- Generic components (table, detail, delete, seed)
- Dynamic routing with [itemType] parameter
- API client factory for type-safe operations
- Automatic GORM to JavaScript data transformation (items, users, auth session)
- Dynamic dashboard statistics

**Item Management:**
- Cheese management (list, detail, delete impact, seed with validation)
- Gin management (list, detail, delete impact, seed with validation)
- Both use generic components via configuration
- Dashboard auto-loads item counts for all configured types
- Two-step seeding: validate then import

**User Management:**
- User list page with admin badges and search
- User detail page with full profile information
- Delete users with impact assessment
- Promote/demote admin privileges with safeguards
- Initial admin protection (cannot demote)
- Dashboard shows real-time user count
- "My Account" navigation from header to own profile

### Completed Features

**Phase 2:** Rating moderation system  
**Phase 3:** In-app notifications

## Architecture Overview

### Config-Based Generic Architecture

```typescript
// Add a new item type in ~5 minutes:
// lib/config/item-types.ts
wine: {
  name: 'wine',
  labels: { singular: 'Wine', plural: 'Wines' },
  icon: 'Wine',
  fields: [/* field definitions */],
  table: { columns: [...], searchableFields: [...] },
  apiEndpoints: {/* endpoint patterns */},
}

// components/layout/sidebar.tsx
{ name: 'Wine', href: '/wine', iconName: 'Wine' }

// Done! All pages work automatically
```

**Benefits:**
- All item types use identical components
- Guaranteed consistency across types
- New features added once benefit all types
- Type-safe with TypeScript generics

### Technical Stack

- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript 5 (strict mode)
- **Authentication:** NextAuth.js v5
- **UI Library:** shadcn/ui + Radix UI
- **Styling:** Tailwind CSS
- **State Management:** TanStack Query v5
- **HTTP Client:** Axios
- **Architecture:** Config-driven with generic components

### Project Structure

```
alacarte-admin/
├── auth.ts                      # NextAuth configuration
├── middleware.ts                # Route protection
├── lib/
│   ├── config/
│   │   └── item-types.ts        # Central config for all types
│   ├── api/
│   │   ├── client.ts            # Base API client
│   │   ├── generic-item-api.ts  # API factory
│   │   └── users.ts             # User API
│   └── types/
│       └── item-config.ts       # Config type definitions
├── components/
│   ├── shared/
│   │   ├── generic-item-table.tsx
│   │   ├── generic-item-detail.tsx
│   │   ├── generic-delete-impact.tsx
│   │   └── generic-seed-form.tsx
│   ├── dashboard/
│   │   └── dashboard-stats.tsx  # Dynamic stats
│   └── layout/
│       ├── sidebar.tsx
│       └── header.tsx
├── app/(dashboard)/
│   ├── [itemType]/              # Dynamic routes for all types
│   │   ├── page.tsx             # List
│   │   ├── [id]/page.tsx        # Detail
│   │   ├── [id]/delete/page.tsx # Delete impact
│   │   └── seed/page.tsx        # Seed
│   └── page.tsx                 # Dashboard
└── docs/                        # Documentation
```

## Development Setup

### Prerequisites

- Node.js 18+ (or Docker)
- Access to A la carte backend API
- Google OAuth Web Client ID

### Local Development (without Docker)

1. Clone and install dependencies:
```bash
git clone <repository-url>
cd alacarte-admin
npm install
```

2. Configure environment:
```bash
cp .env.example .env.local
# Edit .env.local with your values
```

3. Generate NextAuth secret:
```bash
openssl rand -base64 32
# Add to NEXTAUTH_SECRET in .env.local
```

4. Configure Google OAuth redirect URI:
```
http://localhost:3000/api/auth/callback/google
```

5. Run development server:
```bash
npm run dev
```

6. Open browser:
```
http://localhost:3000
```

### Docker Development

For a containerized development environment with hot reload:

```bash
# Start development environment
docker compose up

# Rebuild after dependency changes
docker compose up --build

# Stop
docker compose down
```

The Docker setup includes:
- Hot reload enabled (file changes trigger auto-recompilation)
- Volume mounts for live code updates
- Environment variables from `.env.local`

### Production Docker Build

For production deployment (example configuration):

```bash
# Build and run production image
docker compose -f docker-compose.prod.yaml up --build
```

The production image:
- Uses Next.js standalone output (~150-200MB)
- Runs as non-root user (security)
- Minimal attack surface (no dev dependencies)

### Environment Configuration

```bash
NEXT_PUBLIC_API_URL=https://your-api-url.com
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=<generated-secret>
GOOGLE_CLIENT_ID=<same-as-backend>
GOOGLE_CLIENT_SECRET=<from-google-console>
INITIAL_ADMIN_EMAIL=<your-admin-email>  # Optional: mirrors backend for consistency
```

## Backend Integration

### Currently Used

**Authentication:**
- `POST /auth/google` - Exchange Google tokens for backend JWT
- `GET /api/auth/check-admin` - Verify admin privileges

**Item Management:**
- `GET /api/cheese/all` - List cheeses
- `GET /api/cheese/:id` - Cheese details
- `GET /api/gin/all` - List gins
- `GET /api/gin/:id` - Gin details

**Admin Operations:**
- `GET /admin/cheese/:id/delete-impact` - Cheese deletion impact
- `DELETE /admin/cheese/:id` - Delete cheese with cascade
- `POST /admin/cheese/seed` - Bulk import cheeses
- `POST /admin/cheese/validate` - Validate cheese JSON
- `GET /admin/gin/:id/delete-impact` - Gin deletion impact
- `DELETE /admin/gin/:id` - Delete gin with cascade
- `POST /admin/gin/seed` - Bulk import gins
- `POST /admin/gin/validate` - Validate gin JSON

**User Management:**
- `GET /admin/users/all` - List all users
- `GET /admin/user/:id` - User details
- `GET /admin/user/:id/delete-impact` - User deletion impact
- `DELETE /admin/user/:id` - Delete user with cascade
- `PATCH /admin/user/:id/promote` - Grant admin privileges
- `PATCH /admin/user/:id/demote` - Revoke admin privileges

### Planned Features

**Future Phases:**
- Phase 2: Rating moderation system  
- Phase 3: In-app notifications

### Data Format

Backend uses GORM (uppercase fields), admin panel uses JavaScript conventions (lowercase). Transformation happens automatically in:
- Generic API client (for items)
- User API client (for user endpoints)
- Auth session callback (for authenticated user data)

## Security Model

### Authentication Flow

1. User signs in with Google
2. NextAuth exchanges Google tokens with backend
3. Backend returns backend JWT
4. NextAuth stores JWT in session
5. All API requests use backend JWT

### Security Features

- CSRF protection (NextAuth)
- HttpOnly cookies (session storage)
- Server-side route protection (middleware)
- Secure cookies (HTTPS in production)
- Automatic token refresh
- Admin role verification at login
- Backend middleware protection on all admin routes

## Technical Decisions

### Why Config-Based Architecture?

- **Consistency:** All item types behave identically
- **Speed:** Add new types in 5 minutes
- **Maintainability:** Single codebase for all types
- **Scalability:** Ready for 7+ item types
- **Type Safety:** Full TypeScript with generics

### Why NextAuth.js v5?

- Production-ready authentication
- Backend integration support
- Built-in security features
- Middleware for route protection

### Why Next.js 15 App Router?

- Server Components for better performance
- Dynamic routes perfect for generic system
- Built-in API routes for NextAuth
- TypeScript first-class support

## License

Private - A la carte Platform

---

**Built with config-driven generic architecture**

## Documentation

### System Architecture

- **[Authentication System](docs/authentication-system.md)** - NextAuth.js and backend integration
- **[Backend Requirements](docs/backend-requirements.md)** - API endpoint specifications
- **[Adding New Item Types](docs/adding-new-item-types.md)** - 5-minute config-based process
- **[Phased Implementation](docs/phased-implementation.md)** - Development progress
- **[Deployment Guide](docs/deployment-guide.md)** - Cloud Run deployment (planned)
