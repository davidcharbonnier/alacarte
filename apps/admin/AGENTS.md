# apps/admin — Vite + React SPA

## Purpose

SPA admin panel for the À la carte platform. Provides user management, item CRUD, schema management, bulk operations, and dashboard views for administrators.

## Ownership

- Code: `apps/admin/`
- Docs: `docs/admin/`
- Release tag: `admin-v*`
- Docker image: `ghcr.io/{repo}-admin`

## Local Contracts

- Framework: Vite + React 19 + TypeScript (strict), MUI v6
- Design system: Material Design 3 (`ColorScheme.fromSeed(deepPurple)` parity with Flutter client). Theme tokens in `src/theme.ts` — no Tailwind, no hex-opacity tinted boxes. M3 surface containers (`surfaceContainerLow/High/Highest`) are first-class palette roles.
- Shell: M3 Medium TopAppBar (surfaceContainer) + M3 Permanent NavigationDrawer (surfaceContainerLow) with state-layer ListItems — see `src/components/layout/app-shell.tsx`
- Routing: TanStack Router (file-based via `@tanstack/router-plugin`); route files in `src/routes/`, page components in `src/pages/` (router-agnostic, receive params as props)
- Auth: `@react-oauth/google` → `POST /auth/google` → JWT in `sessionStorage` → Axios interceptor. Admin check via `GET /api/auth/check-admin` post-login
- Data fetching: TanStack Query v5
- Forms: React Hook Form + Zod validation
- Icons: `@mui/icons-material` via a curated registry in `src/lib/icons/icon-registry.ts` (no namespace import)
- Config-driven architecture: item types defined via backend schema registry at runtime
- Generic components: shared UI for all item types (table, detail, delete impact, seed form)
- Route pattern: `/items/:itemType`, `/schemas`, `/users`
- Environment: `VITE_API_URL`, `VITE_GOOGLE_CLIENT_ID` (baked in at build time, not runtime)
- CHANGELOG in `apps/admin/CHANGELOG.md`

## Work Guidance

- Adding a new icon: extend `ICON_OPTIONS` and `ICON_MAP` in `src/lib/icons/icon-registry.ts` together
- Adding a route: create `src/routes/_dashboard.<segment>.tsx` exporting `createFileRoute(...)`; create `src/pages/<name>.tsx` with props-only signature
- API client: `src/lib/api/client.ts` (base), `src/lib/api/schema-api.ts`, `src/lib/api/users.ts`
- Schema context: `src/lib/context/schema-context.tsx` provides schema data to components
- Components: `src/components/shared/` — reusable generic components; `src/components/layout/` — sidebar, header, app shell
- Theme tokens: `src/theme.ts` (MUI extendTheme) — no `lib/config/design-system.ts`
- Auth: `src/lib/auth/auth-context.tsx` + `src/lib/auth/auth-guard.ts` (TanStack Router `beforeLoad`)

## Verification

- `npm run build` — production build (verifies TypeScript + Vite)
- `npm run dev` — Vite dev server with HMR
- `npm run preview` — serve the built `dist/` locally

## Child DOX Index

No children. Flat structure under `apps/admin/`.
