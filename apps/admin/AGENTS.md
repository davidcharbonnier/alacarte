# apps/admin — Next.js Admin Panel

## Purpose

Next.js admin panel for managing the À la carte platform. Provides user management, item CRUD, schema management, bulk operations, and dashboard views for administrators.

## Ownership

- Code: `apps/admin/`
- Docs: `docs/admin/`
- Release tag: `admin-v*`
- Docker image: `ghcr.io/{repo}-admin`

## Local Contracts

- Framework: Next.js 14 (App Router), TypeScript (strict), Tailwind CSS + shadcn/ui
- Auth: NextAuth.js with JWT, requires admin role (`is_admin = true`)
- Prerequisite: User must complete profile in client app before admin login works
- Data fetching: TanStack Query
- Forms: React Hook Form + Zod validation
- Icons: Lucide React
- Config-driven architecture: item types defined in `lib/config/item-types.ts`, design tokens in `lib/config/design-system.ts`
- Generic components: shared UI for all item types (table, detail, delete impact, seed form)
- Route pattern: `app/(dashboard)/[itemType]/` — dynamic routes adapt to any item type config
- Admin-only routes: `/admin/schemas`, `/admin/schemas/[type]` for schema management
- Environment: `.env.local` (not committed)
- CHANGELOG in `apps/admin/CHANGELOG.md`

## Work Guidance

- Adding item type: add config entry in `lib/config/item-types.ts` + color in `lib/config/design-system.ts` — sidebar/views auto-update (~5 min)
- API client: `lib/api/client.ts` (base), `lib/api/generic-item-api.ts`, `lib/api/schema-api.ts`, `lib/api/users.ts`
- Schema context: `lib/context/schema-context.tsx` provides schema data to components
- Components: `components/shared/` — reusable generic components; `components/ui/` — shadcn primitives; `components/layout/` — sidebar, header
- Dashboard routes: `(dashboard)` group with `layout.tsx` for authenticated layout

## Verification

- `npm run build` — production build check (verifies TypeScript + compilation)
- No dedicated test suite configured

## Child DOX Index

No children. Flat structure under `apps/admin/`.