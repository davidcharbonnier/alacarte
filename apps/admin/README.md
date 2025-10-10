# A la carte Admin Panel

Next.js admin panel for managing the A la carte platform.

## Quick Start

```bash
cd apps/admin
npm install
npm run dev
```

**Admin panel runs on:** http://localhost:3001

## Key Features

- **Config-Driven Architecture** - Add item types in ~5 minutes
- **Generic Components** - Reusable UI for all item types
- **User Management** - Admin/user administration
- **Bulk Operations** - Seed data, delete with impact assessment
- **NextAuth.js** - Secure authentication
- **Type-Safe** - Full TypeScript coverage

## Common Tasks

### Adding a New Item Type
See [Adding New Item Types - Admin Section](/docs/guides/adding-new-item-types.md#phase-3-admin-panel-implementation-5-min)

Just add config entry + navigation item = done!

### Running Development Server
```bash
npm run dev
```

### Building for Production
```bash
npm run build
npm start
```

### Adding New Item Type
1. Add config to `lib/config/item-types.ts`
2. Add navigation item to `components/layout/sidebar.tsx`
3. Done! (~5 minutes)

## 📚 Full Documentation

Complete admin documentation available at [/docs/admin/](/docs/admin/)

### Admin-Specific Docs
- [Deployment Guide](/docs/admin/deployment.md) - Production deployment
- [Backend Requirements](/docs/admin/backend-requirements.md) - API specs
- [Phased Implementation](/docs/admin/phased-implementation.md) - Development phases

### Cross-App Features
- [Authentication System](/docs/features/authentication.md) - NextAuth.js integration
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Complete guide

## Technology Stack

- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript
- **UI:** Tailwind CSS + shadcn/ui
- **Authentication:** NextAuth.js with JWT
- **Data Fetching:** TanStack Query
- **Forms:** React Hook Form with Zod validation
- **Icons:** Lucide React

## Project Structure

```
apps/admin/
├── app/                    # Next.js app directory
│   ├── (dashboard)/       # Protected routes
│   │   └── [itemType]/    # Dynamic item type routes
│   └── auth/              # Authentication pages
├── components/
│   ├── layout/            # Sidebar, header, etc.
│   └── shared/            # Generic components
├── lib/
│   ├── api/               # API client factory
│   ├── config/            # Item type configuration
│   └── types/             # TypeScript types
└── docs/                  # (moved to /docs/admin/)
```

## Environment Variables

Create `.env.local` file:

```bash
NEXTAUTH_URL=http://localhost:3001
NEXTAUTH_SECRET=your-secret-key
NEXT_PUBLIC_API_URL=http://localhost:8080
```

## Generic Architecture

The admin panel uses a **config-driven approach**:

```typescript
// Add to lib/config/item-types.ts
wine: {
  name: 'wine',
  labels: { singular: 'Wine', plural: 'Wines' },
  icon: 'Wine',
  fields: [ /* field config */ ],
  table: { /* table config */ },
  apiEndpoints: { /* API endpoints */ },
}
```

All views and operations work automatically:
- ✅ List view
- ✅ Detail view  
- ✅ Delete with impact assessment
- ✅ Bulk seed import
- ✅ Search and filtering
- ✅ Dashboard stats

## License

Private - All Rights Reserved
