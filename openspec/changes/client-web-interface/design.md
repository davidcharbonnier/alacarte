# Design: Client Web Interface

## Context

The À la carte project currently has a Flutter client optimized for mobile platforms (Android, iOS, desktop). While Flutter supports web compilation, the existing UI components and layouts are designed for mobile-first UX patterns (bottom navigation, card-based layouts, touch-optimized interactions).

Users accessing the platform via web browsers need a dedicated interface that:
- Leverages web-specific UX patterns (sidebar navigation, keyboard shortcuts, URL routing)
- Provides responsive design for desktop, tablet, and mobile viewports
- Maintains feature parity with the mobile app
- Uses the same API endpoints and authentication flow
- Runs locally on the host (`flutter run -d web-server --web-port 3001`) against the compose infrastructure

Local development runs infrastructure (API, MySQL, MinIO, admin) in docker-compose while client platforms run on the host (`flutter run`). The web target follows the same pattern. Deployment mirrors the admin app: CI builds a static bundle attached to the GitHub release, deployed manually to a static host (e.g. Netlify).

## Goals / Non-Goals

**Goals:**
- Create a web-optimized Flutter interface with responsive layouts for desktop, tablet, and mobile
- Implement web-specific navigation patterns (browser history, URL routing, keyboard navigation)
- Run locally via `flutter run -d web-server --web-port 3001` (host-run, like other client platforms)
- Maintain feature parity with the mobile app without modifying existing mobile code
- Ensure accessibility (WCAG 2.1 AA) and cross-browser compatibility
- Produce a static bundle deployable to any static host (SPA fallback via `web/_redirects`)
- Build the web bundle as a CI release artifact (mirrors admin pattern)

**Non-Goals:**
- Modifying the existing mobile app UI or behavior
- Creating a separate API or backend services
- Implementing new features exclusive to web (all features must work on mobile too)
- Changing the authentication flow (use existing Google OAuth)
- Supporting legacy browsers (focus on modern browsers)
- Docker/nginx packaging (static hosting needs no container; dev runs on host)
- Automated deployment to a hosting provider (CI produces the artifact; deploy is manual, automation can follow)
- Full i18n for the web UI (EN only at launch; a dedicated i18n rework — including admin integration — is planned separately)
- Offline support for web (web interface requires network connectivity; offline remains a native-app capability)

## Decisions

### 1. Flutter Web Compilation & UI Fork Strategy

**Decision:** Use Flutter's web compilation target with a parallel web widget tree, forked at the router level.

**Rationale:**
- A genuine web UX (sidebar navigation, information density, hover states, keyboard-first) needs its own UI vocabulary — adaptive shared screens converge to mobile-stretched-wide
- Forking at the router keeps one routing table, one auth redirect flow, and identical URLs/deep links across platforms
- Code sharing happens where it matters: API clients, providers, models, l10n, theme tokens
- Single codebase, single package — no duplicated business logic

**Alternatives Considered:**
- **Adaptive shared screens (responsive breakpoints in existing screens):** lowest-common-denominator UX; web feels like a stretched mobile app. Rejected — web needs its own tree.
- **Fork inside each screen (`if (kIsWeb)` per screen):** couples both trees per-file; screens become shell wrappers. Router-level fork is cleaner.
- **Separate Next.js web app:** duplicates API clients, models, and business logic. Rejected.
- **PWA wrapper:** doesn't solve the UI optimization problem.

**Implementation:**
- Existing `lib/routes/app_router.dart` gains platform-aware route builders: `kIsWeb ? WebXxxPage() : XxxScreen()`
- Shared core (one implementation): `services/`, data `providers/`, `models/`, `l10n/`, route paths/names, theme tokens
- Parallel shell (two implementations): `screens/web/*` vs `screens/*`, `widgets/web/*` vs `widgets/*`
- Two orthogonal axes: platform (`kIsWeb`) picks the tree; viewport (`LayoutBuilder`) picks the breakpoint *within* the web tree (>1024 / 768–1024 / <768 — the web tree owns the narrow-browser case)
- Parity contract: every future feature = two UI implementations over one shared provider; the spec parity requirement is the standing rule
- Native web feel (Flutter web does not provide these by default): `SelectionArea` for text selection, `SystemMouseCursors.click` on interactive elements, persistent scrollbars on desktop, hover states, keyboard shortcuts

### 2. Responsive Design Approach

**Decision:** Implement a mobile-first responsive design with three breakpoints: mobile (<768px), tablet (768px-1024px), and desktop (>1024px).

**Rationale:**
- Mobile-first approach ensures mobile viewports work correctly (primary use case)
- Three breakpoints provide sufficient granularity without excessive complexity
- Aligns with common web design frameworks (Bootstrap, Tailwind)
- Flutter's `LayoutBuilder` and `MediaQuery` support this pattern natively

**Alternatives Considered:**
- **Desktop-first approach:** Would require more complex media queries and could break mobile layouts.
- **More granular breakpoints (5+):** Unnecessary complexity for this use case.

**Implementation:**
- Use `LayoutBuilder` to detect viewport width and render appropriate layouts
- Create responsive grid widgets that adjust column count based on breakpoint
- `WebScaffold` adapts nav chrome within the web tree: NavigationRail on desktop/tablet, drawer or bottom nav on narrow browser viewports

### 3. Local Development Workflow

**Decision:** Run the web target on the host with `flutter run -d web-server --web-port 3001`. No Docker container for the client.

**Rationale:**
- All other client platforms (Android, Linux) already run on the host; compose provides only infrastructure (API, MySQL, MinIO, admin)
- A static nginx image requires a rebuild per change — no hot reload, dead dev loop
- Fixed port 3001 keeps CORS (`ALLOWED_ORIGINS`) and Google OAuth authorized JS origins stable

**Alternatives Considered:**
- **nginx container in docker-compose:** production-style packaging without a deployment target; terrible dev loop. Deployment packaging belongs to static hosting, not a container.
- **Flutter dev server in a container:** adds SDK-in-container complexity for no isolation gain.

**Implementation:**
- Document `flutter run -d web-server --web-port 3001` in `docs/client/`
- `http://localhost:3001` added to local `ALLOWED_ORIGINS` (documented in `apps/api/.env.example`; no API code change)

### 4. Environment Configuration

**Decision:** Build-time configuration via the existing `flutter_dotenv` mechanism (`.env` bundled as an asset).

**Rationale:**
- Flutter web compiles to a static bundle — there is no server runtime, so runtime env injection is impossible without a templating server
- `flutter_dotenv` is already used on all platforms; `AppConfig` reads `API_BASE_URL`, `GOOGLE_CLIENT_ID`, `APP_VERSION` — zero client code changes
- The same `.env` file serves `flutter run` (dev) and `flutter build web` (CI)
- Changing a value requires a rebuild — acceptable: values change rarely (API URL, OAuth client ID)

**Alternatives Considered:**
- **`--dart-define` / `String.fromEnvironment`:** also build-time, but rewrites shared `AppConfig` — mobile churn for no gain.
- **Runtime config (fetched `config.json`, envsubst):** pays off only for one-image-many-environments container deployments; no container → no need.

**Implementation:**
- Variables: `API_BASE_URL`, `GOOGLE_CLIENT_ID`, `APP_VERSION` (existing names; no `OAUTH_REDIRECT_URI` — web sign-in uses Google Identity Services with authorized JS origins, no redirect flow)
- Add `.env.example` in `apps/client/` documenting required variables
- CI writes `.env` from secrets before `flutter build web`
- Production API origins are env-managed (`ALLOWED_ORIGINS`), documented in `apps/api/.env.example`

### 5. Static Hosting & CI Artifact

**Decision:** Build the web bundle as a CI release artifact, mirroring the admin app; deploy manually to a static host (e.g. Netlify).

**Rationale:**
- Admin precedent: CI builds `dist/`, attaches it to the GitHub release, release notes say "deploy to any static host"
- Static hosting provides CDN, gzip/brotli, caching headers, and SPA fallback — no custom server to maintain
- Manual deploy is sufficient at current release cadence; automation is a later add-on

**Alternatives Considered:**
- **Netlify CI integration / auto-deploy:** more moving parts; add when manual deploys become tedious.
- **Docker image to Cloud Run:** contradicts static hosting choice; unnecessary server for a static bundle.

**Implementation:**
- Client release workflow: write `.env` from CI secrets, `flutter build web --release`, attach `build/web` to the release
- Add `web/_redirects` (`/*  /index.html  200`) so SPA deep links survive static hosting (copied into `build/web` at build time)
- Document manual deploy (Netlify drag-and-drop or CLI) in `docs/client/`

### 7. URL Routing Strategy

**Decision:** Use Flutter's `go_router` package for declarative routing with deep linking support.

**Rationale:**
- Declarative routing is easier to maintain and understand
- Deep linking support enables URL-based navigation
- Browser history integration works out of the box
- Type-safe navigation with code generation

**Alternatives Considered:**
- **Flutter's built-in Navigator:** Imperative and harder to manage for complex routing.
- **auto_route:** Similar to go_router but with more boilerplate.

**Implementation:**
- Existing `lib/routes/app_router.dart` + `route_names.dart` provide the route structure; extend with platform-aware builders (see §1)
- Enable `usePathUrlStrategy` for clean URLs (no hash) on web
- Use existing path parameters (`/items/:itemType/:itemId`) for item detail pages
- Use query parameters (e.g., `/items?type=cheese`) for filtering
- SPA fallback: dev server serves `index.html`; static hosts use `web/_redirects`

### 8. State Management

**Decision:** Continue using Riverpod for state management, sharing providers between mobile and web.

**Rationale:**
- Existing codebase uses Riverpod
- No need to learn or introduce a new state management solution
- Providers can be shared between mobile and web
- Riverpod supports web-specific features (e.g., URL-based state)

**Alternatives Considered:**
- **Provider package:** Less feature-rich than Riverpod.
- **Bloc:** More boilerplate and steeper learning curve.

**Implementation:**
- Keep existing Riverpod providers for API clients, models, and business logic
- Create web-specific providers for UI state (e.g., sidebar toggle)
- Use `ref.watch` for reactive updates
- Use `ref.read` for one-time reads

### 9. Authentication Flow

**Decision:** Use the existing Google OAuth flow; web sign-in runs through Google Identity Services (authorized JS origins, no redirect URI).

**Rationale:**
- No changes to the backend API or authentication flow
- Existing Google Sign-In package supports web
- JWT token storage in localStorage with appropriate safeguards
- Consistent user experience across platforms

**Alternatives Considered:**
- **Cookie-based authentication:** More complex to implement and doesn't match existing flow.
- **OAuth PKCE:** More secure but adds complexity and doesn't match existing flow.

**Implementation:**
- Use `google_sign_in` package with web support (GIS)
- Reuse the admin/api Web-application OAuth client ID
- Store JWT via existing `token_storage` (flutter_secure_storage, web-capable)
- Implement token refresh logic
- Redirect to login page if token is invalid or expired

### 10. Testing Strategy

**Decision:** Use Flutter's web testing capabilities with integration tests for critical user flows.

**Rationale:**
- Flutter supports web testing out of the box
- Integration tests can run on web platform
- Ensures web-specific features work correctly
- Complements existing mobile tests

**Alternatives Considered:**
- **End-to-end testing with Selenium:** More complex and harder to maintain.
- **Manual testing only:** Insufficient for ensuring quality.

**Implementation:**
- Add web platform to existing widget tests
- Create integration tests for critical flows (login, item listing, rating)
- Run tests in CI/CD pipeline
- Use `flutter test --platform chrome` for web-specific tests

## Risks / Trade-offs

### Risk: Flutter Web Performance

**Risk:** Flutter web applications can be larger and slower than native web frameworks (React, Vue).

**Mitigation:**
- Use the default web renderer (CanvasKit); the HTML renderer no longer exists in current Flutter
- Implement lazy loading for routes and components
- Optimize images and assets
- Rely on the static host for gzip/brotli compression and cache headers
- Monitor performance metrics and optimize as needed

### Risk: Cross-Browser Compatibility

**Risk:** Flutter web may have inconsistencies across different browsers.

**Mitigation:**
- Test on Chrome, Firefox, Safari, and Edge
- Use progressive enhancement for unsupported features
- Provide fallbacks for browser-specific issues
- Monitor browser compatibility reports

### Risk: SEO Limitations

**Risk:** Single-page applications (SPAs) have inherent SEO limitations compared to server-rendered pages.

**Mitigation:**
- Implement meta tags and Open Graph tags dynamically
- Use semantic HTML for better indexing
- Consider pre-rendering for critical pages if SEO becomes important
- Monitor search engine indexing

### Risk: Increased Bundle Size

**Risk:** Flutter web bundle size is larger than traditional web frameworks.

**Mitigation:**
- Use code splitting and lazy loading
- Remove unused dependencies
- Optimize assets and images
- Monitor bundle size and optimize as needed

### Risk: UI Tree Drift

**Risk:** Parallel trees mean web can lag mobile when new features land; maintenance cost is two UIs.

**Mitigation:**
- Shared providers/services keep business logic identical; trees differ only in presentation
- Spec parity requirement acts as standing acceptance checklist
- New features ship with both implementations in the same change

### Trade-off: Development Speed vs. Performance

**Trade-off:** Using Flutter for web enables faster development but may not match the performance of native web frameworks.

**Mitigation:**
- Prioritize user experience over theoretical performance
- Optimize based on real-world usage metrics
- Consider native web framework if performance becomes a blocker

## Migration Plan

### Phase 1: Foundation (Week 1-2)
1. Set up Flutter web compilation target
2. Create web-specific layout components (sidebar, responsive grid)
3. Implement responsive breakpoints
4. Add `web/_redirects` and `.env.example`
5. Verify local dev workflow (`flutter run -d web-server --web-port 3001`)

### Phase 2: Core Features (Week 3-4)
1. Implement web navigation with `go_router`
2. Create web-specific item listing and detail pages
3. Implement rating interface with keyboard support
4. Add search interface with real-time results
5. Implement error handling and validation

### Phase 3: Integration (Week 5)
1. Test web interface with live API (local compose stack)
2. Verify environment variable configuration (`.env`, CORS, OAuth JS origins)
3. Add CI release artifact for the web bundle
4. Test all user flows end-to-end

### Phase 4: Polish (Week 6)
1. Implement accessibility features (keyboard navigation, screen reader support)
2. Optimize performance (lazy loading, caching)
3. Cross-browser testing and fixes
4. Update documentation

### Rollback Strategy
- Keep previous version of mobile app unchanged
- Web artifact is additive to releases; simply don't deploy it
- Static host deploys can be rolled back by redeploying the previous bundle

## Open Questions

1. **OAuth Client ID:** ✅ **RESOLVED** - Use the existing Web-application client ID (same one admin uses, `VITE_GOOGLE_CLIENT_ID`).
   - **Decision:** Reuse the admin/api Web-type client ID — mobile client IDs are platform-typed (Android/iOS) and cannot drive Google Identity Services web sign-in; same GCP project, so the API already accepts its audience
   - **Impact:** No new Google OAuth client to create; only `http://localhost:3001` (and the deployed host) added to authorized JavaScript origins

2. **OAuth Authorized JS Origin:** ✅ **RESOLVED** - Use localhost for local development.
   - **Decision:** Add `http://localhost:3001` to authorized JavaScript origins (GIS flow; no redirect URI), plus the production host when deployed
   - **Impact:** Web interface works in local development and on the deployed static host

3. **Analytics:** ✅ **RESOLVED** - No analytics for now.
   - **Decision:** Defer analytics implementation to future iteration
   - **Impact:** Simpler implementation, can add analytics later if needed

4. **PWA Support:** ✅ **RESOLVED** - No PWA support needed.
   - **Decision:** Skip Progressive Web App features (installability, offline support)
   - **Impact:** Reduces complexity, mobile app already provides installable experience

5. **SEO Requirements:** ✅ **RESOLVED** - No SEO requirements for now.
   - **Decision:** Defer SEO optimization to future iteration
   - **Impact:** Simpler implementation, can add pre-rendering/SSR later if needed