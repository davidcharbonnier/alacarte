## Why

The admin panel currently runs on Next.js with NextAuth.js as a middle layer for Google OAuth — but the Go backend already supports direct SPA-owned OAuth, proven by the Flutter client which calls `POST /auth/google` directly with id_token + access_token. NextAuth adds ~150 lines of indirection without value.

The admin has already been refactored to the dynamic item schema system (`dynamic-item-schema` change, implemented but not yet archived). All item types are now defined via the schema registry, and shared components (GenericItemTable, GenericItemDetail, GenericSeedForm, GenericDeleteImpact) render dynamically from schema definitions fetched at runtime. This means the admin is already fully schema-driven — the Next.js migration is purely a UI technology swap, not a functional change.

Additionally, the shadcn/ui + Tailwind stack creates visual inconsistency with the Flutter client's Material Design 3 system, despite both already using identical design tokens (same spacing scale, same radius scale, same item-type colors, same deepPurple seed). Migrating to a pure SPA with direct OAuth and MUI v6 eliminates the framework mismatch, unifies the auth pattern across both clients, and aligns the design system end-to-end.

## What Changes

- **BREAKING**: Replace Next.js 15 App Router with Vite + React 19 SPA (no server-side rendering, no API routes)
- **BREAKING**: Replace NextAuth.js v5 with direct Google OAuth via `@react-oauth/google` (identical flow to Flutter client: id_token + access_token → `POST /auth/google` → JWT in memory → Axios interceptor)
- **BREAKING**: Replace shadcn/ui (Radix primitives + Tailwind v4) with MUI v6 component library
- **BREAKING**: Replace Tailwind CSS with MUI's `extendTheme` + CSS variables (Material Design 3 tonal palette)
- Add M3-aligned theme derived from deepPurple seed color, matching Flutter client's `ColorScheme.fromSeed(Colors.deepPurple)`
- Add TanStack Router for type-safe file-based routing with escape hatch for React Router v7
- Replace custom GenericItemTable with MUI X Data Grid (pagination, sorting, filtering built-in)
- Replace custom LoadingSpinner with MUI CircularProgress and Skeleton components
- Migrate route structure to SPA-compatible client-side routing with auth guards
- Preserve all existing API integration (Axios client, React Query v5, react-hook-form + zod, SchemaProvider context)
- Remove all Next.js-specific artifacts: API routes, middleware, server components, NextAuth configuration

## Capabilities

### New Capabilities

- `admin-spa-auth`: Standalone SPA authentication using Google OAuth directly (no server-side proxy). The admin panel exchanges a Google id_token + access_token for a backend JWT, stores it in memory, attaches it via Axios interceptor, and performs a client-side admin status check post-login. Mirror of the Flutter client's auth pattern.
- `admin-mui-theme`: M3-aligned design system using MUI v6 `extendTheme` with CSS variables. Theme tokens (colors, spacing, radius, typography) match the Flutter client's `ColorScheme.fromSeed(Colors.deepPurple)` and `AppConstants` scaling system. Supports light/dark mode with `.light`/`.dark` class toggling.

### Modified Capabilities

None. This is a technology stack migration with no behavioral changes to existing capabilities. The admin panel provides the same schema management, item management, and user management functionality as before.

## Impact

**Admin app (`apps/admin`)** — complete rewrite of the UI layer:
- Remove: Next.js framework (`next`, `next-auth`), Radix primitives (15 packages), Tailwind v4 + PostCSS, shadcn/ui components (`components/ui/*`), `auth.ts`, `middleware.ts`, `next.config.ts`, `postcss.config.mjs`, `components.json`, `types/next-auth.d.ts`
- Add: Vite, TanStack Router, MUI v6 (`@mui/material`, `@mui/icons-material`, `@mui/x-data-grid`), `@react-oauth/google` (already in package.json), `@tanstack/react-router`
- Rewrite: All JSX templates (12 pages, 6 shared components, 2 layout components) from shadcn/Tailwind to MUI components. Route structure, auth flow, theme provider.
- Preserve: `lib/api/*` (Axios client + API modules), `lib/context/schema-context.tsx`, `lib/types/*`, React Query hooks, react-hook-form + zod patterns, Dockerfile (rewrite for Vite/nginx)
- Remove: `lib/config/item-types.ts` (already dead code — hardcoded item types replaced by schema registry per `dynamic-item-schema`)

**API (`apps/api`)** — no changes required:
- `POST /auth/google` and `GET /api/auth/check-admin` already support SPA-owned OAuth (Flutter client uses them today)
- CORS configuration already supports configurable `ALLOWED_ORIGINS` (add Netlify domain when deployed)

**Client (`apps/client`)** — no changes:
- Already uses identical auth pattern and M3 design system

**Database** — no changes

**CI/CD** — deferred to `refactor-ci-cd-pipeline` change which will run after this migration

**Docker** — rewrite admin Dockerfile for Vite build + nginx serve (replaces Next.js standalone output)