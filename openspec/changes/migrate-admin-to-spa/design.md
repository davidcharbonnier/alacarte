## Context

The admin panel (`apps/admin`) is a Next.js 15 App Router application using shadcn/ui (Radix primitives + Tailwind v4) for components and NextAuth.js v5 for Google OAuth. The `dynamic-item-schema` change is already implemented — all item types are schema-driven, and shared components render dynamically from runtime schema definitions. The admin is functionally complete; this migration is a pure technology stack swap.

The Go backend (`apps/api`) provides `POST /auth/google` (accepts `{id_token, access_token}` → returns `{token, user}`) and `GET /api/auth/check-admin` (returns `{is_admin}` for authenticated user). The Flutter client already uses these endpoints directly; the admin panel currently proxies through NextAuth.js unnecessarily.

The Flutter client uses Material Design 3 with `ColorScheme.fromSeed(Colors.deepPurple)` and `useMaterial3: true`. The admin already mirrors the same design tokens (spacing, radius, item-type colors) in `lib/config/design-system.ts`, but uses a different UI library.

### Current State

```
apps/admin/
├── Next.js 15 App Router
├── shadcn/ui (Radix primitives + Tailwind v4)
├── NextAuth.js v5 (Google OAuth → backend JWT exchange)
├── Axios API client with NextAuth getSession() interceptor
├── React Query v5, react-hook-form + zod, SchemaProvider context
├── 12 pages, 6 shared components, 2 layout components
├── Design tokens in lib/config/design-system.ts (mirrors Flutter AppConstants)
└── Dockerfile: next build (standalone output) + node:alpine
```

### Target State

```
apps/admin/
├── Vite + React 19 SPA
├── MUI v6 (Material Design 3 via extendTheme + CSS variables)
├── @react-oauth/google (direct POST /auth/google → JWT in sessionStorage → Axios interceptor)
├── Axios API client with memory-aware interceptor (same API modules, unchanged)
├── React Query v5, react-hook-form + zod, SchemaProvider context (preserved)
├── MUI X Data Grid replacing GenericItemTable
├── TanStack Router (file-based, type-safe, escape hatch to React Router v7)
├── Design tokens migrated to MUI theme (same values, new carrier)
└── Dockerfile: vite build + nginx:alpine
```

## Goals / Non-Goals

**Goals:**

- Eliminate Next.js server dependency (no SSR, no API routes, no middleware)
- Unify auth pattern with Flutter client (direct Google OAuth → backend JWT exchange)
- Align design system with Flutter client (M3 tokens, deepPurple seed, same spacing/radius/color scales)
- Maintain all existing functionality (schema management, item CRUD, user management, seed import, delete impact)
- Keep React Router v7 escape hatch open via router-agnostic component architecture
- Reduce dependency count (remove 15+ Radix packages, NextAuth, Tailwind, PostCSS, shadcn config)

**Non-Goals:**

- Changing backend API (no Go code changes)
- Changing Flutter client (no Dart changes)
- Adding new admin features (functionality parity only)
- Changing the `dynamic-item-schema` data model or API
- Updating CI/CD pipelines (deferred to `refactor-ci-cd-pipeline`)
- Netlify deployment configuration (handled separately)
- PWA, offline support, or service workers

## Decisions

### Decision 1: SPA-owned OAuth with sessionStorage

**Choice**: `@react-oauth/google` → `POST /auth/google` → JWT in `sessionStorage` → Axios interceptor

**Rationale**: The backend endpoint already accepts this exact payload from the Flutter client. No backend changes needed. `sessionStorage` survives page refreshes (better UX than in-memory) but clears on tab close and is not shared across tabs (better security than `localStorage`). The admin panel is an internal tool — XSS risk from third-party scripts is minimal, and `sessionStorage` is a pragmatic middle ground.

**Alternatives considered**:
- *In-memory (React Context)*: Most secure (no JS API access) but token lost on refresh → user must re-authenticate. Poor UX for an admin tool used throughout the day.
- *localStorage*: Survives everything but accessible to any JS on the origin. Higher XSS surface. Rejected for security.
- *httpOnly cookie with BFF proxy*: Requires a server (defeats the SPA goal). Rejected.
- *NextAuth.js (keep current)*: Requires Next.js server. Rejected — the entire motivation for this change.

**Flow**:
```
┌──────────┐   Google Sign-In    ┌──────────┐   id_token      ┌───────────┐
│  Admin   │◀──── credential ────│ @react-  │────────────────▶│ Go Backend│
│  Login   │                     │ oauth    │                 │ POST      │
│  Page    │                     │ /google  │◀── {token,user}─│ /auth/google│
└────┬─────┘                     └──────────┘                 └───────────┘
     │
     │ sessionStorage.setItem('jwt_token', token)
     │ fetch GET /api/auth/check-admin
     │
     ├─ is_admin === true  → navigate to /dashboard
     └─ is_admin === false → navigate to /access-denied
```

### Decision 2: TanStack Router with router-agnostic components

**Choice**: TanStack Router (file-based) + rule that `components/` never imports router hooks

**Rationale**: TanStack Router provides full type safety for params (with `parse` coercion), search params (with `validateSearch`), loader data, and route context — eliminating a class of bugs where `useParams()` returns `string | undefined`. The router-agnostic component rule keeps the React Router v7 escape hatch open: route files use TanStack APIs, components receive everything as props. Switching to React Router v7 later requires changing only route files.

**Alternatives considered**:
- *React Router v7 file-based*: Larger ecosystem, better AI training data. But no built-in type safety for params/search params. Would need zod helpers per route. Chosen as escape hatch.
- *React Router v7 programmatic*: Legacy pattern. Not file-based. Rejected.
- *TanStack Router with deep coupling*: Would lock us in. Rejected the deep coupling, kept the router.

**Architecture boundary**:
```
src/routes/                    ← TanStack Router APIs allowed
  _dashboard.items.$itemType.$id.tsx
    → imports ItemDetailPage from components/
    → passes params as props

src/components/                ← NO router imports (useParams, useNavigate, etc.)
  shared/ItemDetailPage.tsx
    → receives itemType: string, id: number as props
    → calls API, renders UI
```

### Decision 3: MUI v6 extendTheme with CSS variables

**Choice**: `extendTheme` with `cssVariables: { colorSchemeSelector: 'class' }`, M3 tonal palette from deepPurple seed

**Rationale**: MUI v6's `extendTheme` with CSS variables enables design tokens to be consumed by both MUI components and any residual custom styles. The `colorSchemeSelector: 'class'` toggles light/dark by toggling `.light`/`.dark` on `<html>` — same mechanism the current ThemeProvider uses. The M3 tonal palette from deepPurple seed generates all color roles (primary, onPrimary, primaryContainer, secondary, tertiary, surface, error) matching Flutter's `ColorScheme.fromSeed`.

**Token migration**:
```
lib/config/design-system.ts          →    src/theme.ts (MUI extendTheme)
─────────────────────────────              ─────────────────────────────
brandColors.primary: '#673AB7'      →    palette.primary.main: '#673AB7'
brandColors.secondary: '#9C27B0'    →    palette.secondary.main: '#9C27B0'
itemTypeColors.cheese: '#673AB7'    →    read from schema.color at render (grey fallback)
spacing: { xs:4, s:8, m:16, ... }   →    spacing: 8 (MUI default = 8px base)
radius: { xs:2, s:4, m:8, ... }     →    shape.borderRadius: 8
```

Item-type colors (cheese, gin, wine, etc.) are no longer hardcoded. They are read from `schema.color` at render time (see theme spec `admin-mui-theme`), with a grey fallback when absent. The schema registry is the single source of truth — no theme extension or local color map is needed.

### Decision 4: MUI X Data Grid replaces GenericItemTable

**Choice**: `@mui/x-data-grid` (Community, free) for the item listing tables

**Rationale**: GenericItemTable is a substantial custom component (~400 lines) implementing pagination, search, sort, and image filtering. MUI X Data Grid provides all of this built-in: server-side pagination, sortable columns, filter panel, column visibility. It also handles loading states, empty states, and error states natively. For the admin's item lists (10-50 items per page), the Community plan (no row grouping, no advanced filtering) is sufficient.

**Trade-off**: Data Grid has its own API patterns (column definitions, row models, callback signatures) — the item table page needs rewriting, not just component swapping. But the net code reduction is significant.

### Decision 5: Big-bang migration with full rewrite

**Choice**: Replace the entire `apps/admin` UI layer in one change. No incremental path.

**Rationale**: You can't mix Next.js and Vite in the same application. The auth system, routing, component library, and build pipeline are all coupled to Next.js. A phased migration would require running two admin apps simultaneously, which doubles operational complexity for no benefit. The admin is an internal tool with a small user base — brief downtime during deployment is acceptable.

**Migration unit**: The entire `apps/admin` directory is rewritten. The new code lives alongside the old until the PR merges, then the old code is deleted.

### Decision 6: Vite + nginx Docker setup

**Choice**: Multi-stage Dockerfile: `node:alpine` build stage (vite build) → `nginx:alpine` serve stage

**Rationale**: Vite produces static files (`dist/`). nginx serves them efficiently with built-in compression, caching headers, and SPA routing support (`try_files $uri /index.html`). Replaces the current `next start` (Node process) with a lightweight nginx process.

**nginx SPA config**:
```
location / {
  try_files $uri /index.html;
}
```

This ensures client-side routing works — any path that doesn't match a static file falls back to `index.html`, where TanStack Router takes over.

## Risks / Trade-offs

### Risk 1: sessionStorage token theft via XSS

**Risk**: If a malicious script executes on the admin origin, it can read `sessionStorage.getItem('jwt')` and exfiltrate the token.

**Mitigation**: 
- The admin panel loads few external scripts (Google OAuth, MUI, no ads/analytics). Attack surface is small.
- Token has 24-hour expiry, limiting the window of abuse.
- Backend requires both valid JWT AND `is_admin` flag for admin endpoints. A stolen token from a non-admin user cannot access admin routes.
- Content-Security-Policy headers can be set in nginx to restrict script sources.
- The 401 interceptor (Decision 1) clears the JWT and redirects via the TanStack Router instance (imported into the Axios setup) rather than `window.location`, so a 401 from inside the app tree performs a clean SPA navigation to `/login` without a full page reload. Only the initial auth-context bootstrap path may fall back to `window.location` if the router is not yet mounted.

### Risk 2: TanStack Router ecosystem immaturity

**Risk**: Smaller community, fewer StackOverflow answers, less AI training data. If we hit a blocking bug or API limitation, debugging may take longer.

**Mitigation**:
- TanStack Router v1 has been stable since 2024. The TanStack organization (Tanner Linsley) ships production-quality libraries (React Query, Table, Form).
- The escape hatch to React Router v7 is kept open by the router-agnostic component rule. Switching would require rewriting only `src/routes/` (~12 files), not `src/components/`.
- For the 12 routes in this admin panel, the routing complexity is low. Even a full router swap is a day's work.

### Risk 3: MUI X Data Grid API mismatch

**Risk**: GenericItemTable has custom behavior (image presence toggle, item-type color theming, delete action column) that may not map 1:1 to Data Grid's column definition API.

**Mitigation**:
- Data Grid supports custom cell renderers — item-type badges, image thumbnails, and action buttons are standard column renderer patterns.
- If Data Grid proves insufficient for the schema-driven dynamic columns (field count varies per item type), fall back to MUI `<Table>` with manual pagination (same pattern as current, just MUI-styled).

### Risk 4: Loss of server-side admin check during login

**Risk**: Currently, NextAuth checks `GET /api/auth/check-admin` server-side during the JWT callback and throws `AccessDenied` before the user sees any admin UI. In SPA, the check happens client-side post-login — a non-admin user briefly sees the app before being redirected.

**Mitigation**:
- The post-login admin check is a fast API call (~50ms). Show a loading spinner during the check.
- The access-denied page is a static route with no admin functionality exposed.
- Backend still enforces admin status on all `/admin/*` routes — a non-admin token cannot access admin data even if they bypass the client-side check.

### Risk 5: Design token drift between admin and client

**Risk**: Over time, MUI theme tokens and Flutter AppConstants could drift apart as each is maintained independently.

**Mitigation**:
- Both derive from the same foundation: deepPurple seed color, 8px spacing base, same radius scale. Drift would require intentional changes.
- Not in scope for this change, but a future shared design token source (JSON/YAML consumed by both) would eliminate the risk entirely.

### Decision 7: Design token strategy — delete design-system.ts, inline in MUI theme

**Choice**: Delete `lib/config/design-system.ts`. Move all token values into `src/theme.ts` as MUI `extendTheme` configuration.

**Rationale**: The tokens only serve the admin UI layer. Keeping them in a separate file adds an import indirection with no consumer other than the MUI theme. If tokens need to be shared across frameworks in the future, a JSON/YAML source of truth can be created then.

### Decision 8: Environment variables — build-time via Vite

**Choice**: `VITE_API_URL` and `VITE_GOOGLE_CLIENT_ID` injected at build time via Vite's `define` or `.env` files.

**Rationale**: Vite's build-time env variable pattern is standard and well-supported. The admin panel is deployed as static files — there's only one API backend per deployment target. Runtime config adds an extra HTTP request on startup for no meaningful benefit at this scale.

### Decision 9: Complex component mapping to MUI

**Choice**: All current shared components map directly to MUI equivalents. No custom composition needed beyond MUI's built-in components.

**GenericItemDetail mapping**:

| shadcn/ui | MUI v6 | Notes |
|-----------|--------|-------|
| `<Dialog>` + `<DialogTrigger>` | `<Dialog open={} onClose={}>` + `onClick` | MUI's API is simpler — no `DialogTrigger` wrapper needed |
| `<Card borderLeftColor>` | `<Card sx={{ borderLeft: '4px solid' }}>` | Same visual, MUI `sx` prop replaces inline style |
| `lucide-react` icons (app chrome) | `@mui/icons-material` | ArrowBack, Delete, CheckCircle, Cancel, Inventory2, ZoomIn — static icons hardcoded in JSX |
| `lucide-react` icons (schema-driven) | curated MUI icon registry | `schema.icon` resolved via a bounded `ICON_MAP` of ~40-80 MUI icons, not `import *` (see Decision 10) |
| `formatFieldValue()` | Same logic, different icon components | Business logic unchanged, only JSX shell changes |

**GenericSeedForm mapping**:

| shadcn/ui | MUI v6 | Notes |
|-----------|--------|-------|
| `<Tabs>` + `<TabsTrigger>` | `<Tabs value={} onChange={}>` + `<Tab label="">` | Standard MUI tabs |
| `<Input type="file">` | `<Button component="label">` + hidden `<input>` | MUI has no file input — standard pattern is styled label wrapping hidden input |
| `<Input type="url">` | `<TextField fullWidth>` | MUI TextField replaces all text inputs |
| Multiple `<Alert>` variants | `<Alert severity="info|error|success">` | Same semantics, different API |
| `<LoadingSpinner>` | `<CircularProgress size={20}>` | Inline spinner for button loading states |
| Step indicator (text card) | `<Stepper>` or plain `<Typography>` | Stepper is optional polish, plain text keeps it simple |

The seed form's state machine (idle → validating → validated → imported → error) is pure business logic driven by React Query mutation states. Only the component shell changes.

### Decision 10: MUI-only icons with a curated registry

**Choice**: Replace `lucide-react` entirely. All icons — both app chrome and schema-driven — use `@mui/icons-material`. Schema-driven icons resolve through a curated registry of ~40-80 MUI icons (food/drink/general), imported individually and exposed as a bounded `ICON_MAP`. The schema editor's icon picker sources its options from this registry.

**Rationale**: A single icon library keeps the stack uniform and removes a dependency. `import * as Icons from '@mui/icons-material'` would bundle all ~2,000 icons (~2MB+), defeating tree-shaking — so the schema-driven lookup cannot use a namespace import the way the current lucide code does. A curated registry with explicit per-icon imports keeps the bundle small while covering the consumables domain (cheese, gin, wine, coffee, chili sauce, and foreseeable future types). Render sites use `ICON_MAP[schema.icon] ?? DefaultIcon`. The schema editor's existing `ICON_OPTIONS` array is replaced with the registry's option list (searchable).

**Accepted breakage**: Existing `schema.icon` values in the database are lucide component names (`'Pizza'`, `'Wine'`, `'Flame'`, ...). MUI uses different names (`'WineBar'`, `'Coffee'`, `'LocalFireDepartment'`, ...), so every existing type renders the fallback icon until an admin re-sets its icon via the schema editor. This temporary breakage is accepted — the admin panel is internal with a handful of item types, and re-setting icons is a one-time manual pass. No DB migration script is written; icons are corrected through the existing schema editor UI.

**Alternatives considered**:
- *Keep lucide for schema-driven icons*: Zero DB breakage, but retains a second icon library and its dependency purely for data-driven rendering. Rejected in favor of a single uniform stack.
- *Full namespace import (`import *`)*: Simplest code, picker shows all icons, but ~2MB+ bundle bloat for a static SPA. Rejected.
- *Lazy-load picker (dynamic import on open)*: All 2,000 icons available with a small base bundle, but complex wiring and slower picker open for a domain that needs ~40-80 icons. Rejected as over-build.

### Decision 11: Schema color picker — curated palette, not free input

**Choice**: The schema editor's color picker offers a curated palette of ~16-24 named hex swatches (expanded from the current 8). Free color input (`<input type="color">` + hex field) is not offered.

**Rationale**: `schema.color` drives per-type visual identity (sidebar indicators, item-table badges, card accents). A curated palette keeps colors visually distinct and readable on both light/dark surfaces, while ~16-24 swatches cover the foreseeable range of consumable types without collisions. Free input risks bad contrast, clashing badges, and loss of per-type identity — an admin picking `#FF00FF` would render an unreadable badge. The palette is expandable later if the type count grows beyond it; the stored value is just a hex string, so expanding the picker costs no data migration.

**Note on existing values**: Current `schema.color` values in the DB are from an arbitrary Flat UI palette (`#E67E22`, `#9B59B6`, ...) chosen during `dynamic-item-schema`. These hex values render fine under MUI and are preserved unchanged — only the picker's offered set changes.