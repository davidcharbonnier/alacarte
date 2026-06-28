## 1. Project scaffolding

- [ ] 1.1 Initialize Vite + React + TypeScript project in `apps/admin` (replace existing)
- [ ] 1.2 Install core dependencies: `react`, `react-dom`, `@mui/material`, `@mui/icons-material`, `@emotion/react`, `@emotion/styled`
- [ ] 1.3 Install MUI X: `@mui/x-data-grid` (Community)
- [ ] 1.4 Install routing: `@tanstack/react-router`
- [ ] 1.5 Install auth: `@react-oauth/google` (already in package.json, keep)
- [ ] 1.6 Install data layer: `axios`, `@tanstack/react-query`, `react-hook-form`, `@hookform/resolvers`, `zod`
- [ ] 1.7 Install utilities: `date-fns`, `jwt-decode`
- [ ] 1.8 Add dev dependencies: `@types/react`, `@types/react-dom`, `typescript`, `vite`, `@vitejs/plugin-react`, `vitest`
- [ ] 1.9 Configure `vite.config.ts` (React plugin, path aliases `@/` → `src/`)
- [ ] 1.10 Configure `tsconfig.json` (strict, path aliases, JSX react-jsx)
- [ ] 1.11 Create `index.html` entry point
- [ ] 1.12 Create `src/main.tsx` with ReactDOM.createRoot

## 2. Theme & design system

- [ ] 2.1 Create `src/theme.ts` with MUI `extendTheme` (deepPurple seed, colorSchemes for light/dark)
- [ ] 2.2 Enable CSS variables with `colorSchemeSelector: 'class'`
- [ ] 2.3 Configure spacing base (8px), shape borderRadius (8px), typography (Roboto)
- [ ] 2.4 Add item-type accent colors as theme extensions
- [ ] 2.5 Create `ThemeProvider` wrapper with `localStorage` persistence
- [ ] 2.6 Delete `lib/config/design-system.ts` (tokens moved to `theme.ts`)

## 3. Auth system

- [ ] 3.1 Create `src/lib/auth/auth-context.tsx` — React Context for JWT + user state
- [ ] 3.2 Implement JWT storage in `sessionStorage` (set, get, clear helpers)
- [ ] 3.3 Implement Google OAuth flow: `@react-oauth/google` credential → `POST /auth/google` → store JWT
- [ ] 3.4 Implement admin check: `GET /api/auth/check-admin` after login, redirect to `/access-denied` if false
- [ ] 3.5 Rewrite `lib/api/client.ts` Axios instance: replace NextAuth `getSession()` interceptor with JWT from `sessionStorage`
- [ ] 3.6 Add 401 response interceptor → clear JWT, redirect to `/login`
- [ ] 3.7 Create `authGuard` function for TanStack Router `beforeLoad` (redirect to `/login` if no JWT)
- [ ] 3.8 Create login page component with Google Sign-In button and error states
- [ ] 3.9 Create access-denied page component

## 4. Routing

- [ ] 4.1 Configure TanStack Router with `createRouter` in `src/router.tsx`
- [ ] 4.2 Create `__root.tsx` route with `<Outlet>` and theme/provider wrappers
- [ ] 4.3 Create `_dashboard.tsx` pathless layout with `beforeLoad` auth guard
- [ ] 4.4 Create route files for all 12 routes (see route map below)
- [ ] 4.5 Configure TanStack Router devtools for development

**Route map:**
```
src/routes/
├── __root.tsx
├── login.tsx
├── access-denied.tsx
├── _dashboard.tsx                        (auth guard, sidebar + header layout)
├── _dashboard.index.tsx                  (/)
├── _dashboard.items.$itemType.index.tsx  (/:itemType)
├── _dashboard.items.$itemType.$id.tsx    (/:itemType/:id)
├── _dashboard.items.$itemType.$id.delete.tsx
├── _dashboard.items.$itemType.seed.tsx
├── _dashboard.schemas.index.tsx          (/schemas)
├── _dashboard.schemas.$type.tsx          (/schemas/:type)
├── _dashboard.users.index.tsx            (/users)
├── _dashboard.users.$id.tsx              (/users/:id)
├── _dashboard.users.$id.delete.tsx       (/users/:id/delete)
```

## 5. Layout components

- [ ] 5.1 Create `AppLayout` — sidebar + header + `<Outlet>` main content area
- [ ] 5.2 Create `Header` — app title, theme toggle (MUI `IconButton` + `DarkMode`/`LightMode` icons), user dropdown (email, sign-out)
- [ ] 5.3 Create `Sidebar` — navigation links with MUI `ListItemButton`, active state highlighting, dynamic item-type entries from schema context, color-coded indicators

## 6. Shared components

- [ ] 6.1 Rewrite `DashboardStats` — MUI `Card` + `Grid` layout, dynamic item-type cards
- [ ] 6.2 Rewrite `ItemTypeCard` — MUI `Card` with colored icon, count, "View all" link
- [ ] 6.3 Rewrite `GenericItemTable` — MUI X `DataGrid` with server-side pagination, sorting, custom cell renderers (image thumbnail, item-type badge, actions), column visibility from schema fields
- [ ] 6.4 Rewrite `GenericItemDetail` — MUI `Card` grid, `Dialog` for image zoom, dynamic field rendering from schema, metadata card
- [ ] 6.5 Rewrite `GenericDeleteImpact` — MUI `Card` with impact summary, `Alert` for warnings, `TextField` for type-to-confirm, `Button` with loading state
- [ ] 6.6 Rewrite `GenericSeedForm` — MUI `Tabs` (file/URL), `Button` with hidden file input, `Alert` for validation results and import status, three-state button progression (validate → import → done)
- [ ] 6.7 Replace `LoadingSpinner` usage with MUI `CircularProgress` and `Skeleton`
- [ ] 6.8 Replace `ErrorMessage` usage with MUI `Alert severity="error"`

## 7. Page components

- [ ] 7.1 Rewrite dashboard page (`/`) — welcome message, `<DashboardStats>`, TanStack Router navigation links
- [ ] 7.2 Rewrite item list page (`/:itemType`) — schema-driven header with icon/color, `<GenericItemTable>`, "Add item" FAB, "Seed data" link
- [ ] 7.3 Rewrite item detail page (`/:itemType/:id`) — `<GenericItemDetail>`, edit link, delete link
- [ ] 7.4 Rewrite item delete page (`/:itemType/:id/delete`) — `<GenericDeleteImpact>`
- [ ] 7.5 Rewrite item seed page (`/:itemType/seed`) — `<GenericSeedForm>`
- [ ] 7.6 Rewrite schema list page (`/schemas`) — MUI `Table` or `DataGrid` with activate/deactivate toggles, create dialog
- [ ] 7.7 Rewrite schema editor page (`/schemas/:type`) — MUI `Tabs` (Fields builder, Settings, Version History), `useFieldArray` from react-hook-form for field reordering
- [ ] 7.8 Rewrite user list page (`/users`) — MUI `Card` grid with avatars, email, admin badges, search
- [ ] 7.9 Rewrite user detail page (`/users/:id`) — MUI `Card` with user info, promote/demote buttons with confirmation `Dialog`
- [ ] 7.10 Rewrite user delete page (`/users/:id/delete`) — impact summary with type-to-confirm

## 8. API layer adaptation

- [ ] 8.1 Verify `lib/api/schema-api.ts` works unchanged with new Axios instance
- [ ] 8.2 Verify `lib/api/users.ts` works unchanged with new Axios instance
- [ ] 8.3 Remove `lib/api/generic-item-api.ts` (hardcoded item types, replaced by `schema-api.ts`)
- [ ] 8.4 Remove `lib/config/item-types.ts` (already dead, cleanup from dynamic-item-schema)
- [ ] 8.5 Verify `lib/context/schema-context.tsx` works unchanged
- [ ] 8.6 Verify all React Query hooks work after migration

## 9. Docker & build

- [ ] 9.1 Create multi-stage `Dockerfile`: `node:alpine` build (vite build) → `nginx:alpine` serve
- [ ] 9.2 Create `nginx.conf` with SPA routing (`try_files $uri /index.html`), gzip, cache headers for assets
- [ ] 9.3 Update `docker-compose.yaml` for new Dockerfile (remove Next.js-specific env vars)
- [ ] 9.4 Verify `npm run build` produces static `dist/` output
- [ ] 9.5 Verify `npm run dev` runs Vite dev server with HMR
- [ ] 9.6 Add `VITE_API_URL` and `VITE_GOOGLE_CLIENT_ID` to `.env.example`

## 10. Cleanup — remove Next.js artifacts

- [ ] 10.1 Delete `next.config.ts`
- [ ] 10.2 Delete `middleware.ts`
- [ ] 10.3 Delete `auth.ts`
- [ ] 10.4 Delete `types/next-auth.d.ts`
- [ ] 10.5 Delete `postcss.config.mjs`
- [ ] 10.6 Delete `components.json`
- [ ] 10.7 Delete `next-env.d.ts`
- [ ] 10.8 Delete `app/` directory (App Router)
- [ ] 10.9 Delete `components/ui/` directory (all shadcn components)
- [ ] 10.10 Delete `components/providers.tsx` (replaced by MUI ThemeProvider + TanStack Router)
- [ ] 10.11 Delete `components/theme-provider.tsx` (replaced by MUI theme)
- [ ] 10.12 Delete `components/theme-toggle.tsx` (moved to Header)
- [ ] 10.13 Delete `components/design-system-preview.tsx` (unused dev tool)
- [ ] 10.14 Remove Next.js, NextAuth, Radix, Tailwind, PostCSS from `package.json` dependencies
- [ ] 10.15 Update `eslint.config.mjs` (remove `next/core-web-vitals`, `next/typescript`)

## 11. Verification

- [ ] 11.1 Verify Google OAuth flow end-to-end (login → JWT exchange → admin check → dashboard)
- [ ] 11.2 Verify route protection (unauthenticated redirect, admin check redirect)
- [ ] 11.3 Verify token expiry handling (401 → clear session → redirect to login)
- [ ] 11.4 Verify theme toggle (light ↔ dark, persistence across refresh)
- [ ] 11.5 Verify all 12 pages render correctly with MUI components
- [ ] 11.6 Verify Data Grid: pagination, sorting, search filtering, column rendering
- [ ] 11.7 Verify schema-driven pages render correctly for all item types
- [ ] 11.8 Verify seed import flow end-to-end (file upload and URL)
- [ ] 11.9 Verify user management (list, detail, promote/demote, delete)
- [ ] 11.10 Verify schema management (list, create, edit fields, activate/deactivate)
- [ ] 11.11 Verify Docker build produces working container
- [ ] 11.12 Verify `npm run build` succeeds with no TypeScript errors
- [ ] 11.13 Verify login redirect for non-admin users shows access-denied page