# Design: Client Web Interface

## Context

The À la carte project currently has a Flutter client optimized for mobile platforms (Android, iOS, desktop). While Flutter supports web compilation, the existing UI components and layouts are designed for mobile-first UX patterns (bottom navigation, card-based layouts, touch-optimized interactions).

Users accessing the platform via web browsers need a dedicated interface that:
- Leverages web-specific UX patterns (sidebar navigation, keyboard shortcuts, URL routing)
- Provides responsive design for desktop, tablet, and mobile viewports
- Maintains feature parity with the mobile app
- Uses the same API endpoints and authentication flow
- Can be run locally via docker-compose for development

The existing development infrastructure uses:
- Docker and docker-compose for local development
- API and admin services already integrated into docker-compose stack

## Goals / Non-Goals

**Goals:**
- Create a web-optimized Flutter interface with responsive layouts for desktop, tablet, and mobile
- Implement web-specific navigation patterns (browser history, URL routing, keyboard navigation)
- Build a Dockerfile for local development with docker-compose
- Maintain feature parity with the mobile app without modifying existing mobile code
- Ensure accessibility (WCAG 2.1 AA) and cross-browser compatibility
- Integrate web interface into existing docker-compose stack for local development

**Non-Goals:**
- Modifying the existing mobile app UI or behavior
- Creating a separate API or backend services
- Implementing new features exclusive to web (all features must work on mobile too)
- Changing the authentication flow (use existing Google OAuth)
- Supporting legacy browsers (focus on modern browsers)
- CI/CD deployment, Docker Hub publishing, or Cloud Run deployment (future consideration)

## Decisions

### 1. Flutter Web Compilation Strategy

**Decision:** Use Flutter's web compilation target with conditional UI rendering based on platform.

**Rationale:**
- Flutter provides native web compilation support with CanvasKit and HTML renderers
- Allows code sharing between mobile and web (API clients, models, business logic)
- Conditional rendering enables platform-specific UI without code duplication
- Single codebase reduces maintenance overhead

**Alternatives Considered:**
- **Separate Next.js web app:** Would require duplicating API clients, models, and business logic. More maintenance overhead but better web performance.
- **Progressive Web App (PWA) wrapper:** Doesn't solve the UI optimization problem, just adds installability.

**Implementation:**
- Use `kIsWeb` runtime check to conditionally render web-specific layouts
- Create web-specific widget variants (e.g., `WebItemCard` vs `MobileItemCard`)
- Share state management (Riverpod), API clients, and data models
- Use Flutter's `MediaQuery` and `LayoutBuilder` for responsive breakpoints

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
- Implement collapsible sidebar navigation for desktop/tablet, bottom nav for mobile
- Use Flutter's `AdaptiveScaffold` for platform-appropriate navigation

### 3. Web Server Choice

**Decision:** Use nginx as the web server in the Docker container.

**Rationale:**
- nginx is lightweight, fast, and widely used for static file serving
- Excellent support for gzip compression, caching headers, and URL rewriting
- Smaller image size compared to Apache or other alternatives
- Well-documented and battle-tested in production

**Alternatives Considered:**
- **Apache:** Heavier and slower for static file serving.
- **Caddy:** Auto-HTTPS is nice but adds complexity and larger image size.
- **Node.js server:** Unnecessary overhead for serving static files.

**Implementation:**
- Multi-stage Docker build: Flutter SDK for build stage, nginx for runtime stage
- Configure nginx for SPA routing (all routes redirect to index.html)
- Enable gzip compression for JavaScript, CSS, and HTML
- Set cache headers for static assets (images, fonts)

### 4. Environment Configuration

**Decision:** Inject environment variables at container runtime and use Flutter's `const String.fromEnvironment` to read them.

**Rationale:**
- No need to rebuild the Docker image for different environments
- Matches the existing API and admin deployment patterns
- Environment variables are standard for containerized applications
- Secure (no secrets in source code or build artifacts)

**Alternatives Considered:**
- **Build-time configuration:** Would require separate images for dev/staging/prod.
- **Configuration file mounted as volume:** More complex to manage and version.

**Implementation:**
- Define environment variables in Dockerfile with `ARG` and `ENV` directives
- Use `--dart-define` during Flutter build to pass values to the app
- Support variables: `API_URL`, `OAUTH_CLIENT_ID`, `OAUTH_REDIRECT_URI`
- Provide default values for local development

### 5. Docker Compose Integration

**Decision:** Integrate the web interface into the existing docker-compose stack for local development.

**Rationale:**
- Consistent with existing API and admin development workflow
- Single command to start all services (`docker compose up`)
- Easy to test web interface with live API
- Matches existing monorepo patterns

**Alternatives Considered:**
- **Separate docker-compose for web:** Would require multiple commands and add complexity.
- **Manual Docker commands:** More error-prone and harder to maintain.

**Implementation:**
- Create `apps/client/docker-compose.yaml` with web service definition
- Add include path to root `docker-compose.yml`
- Configure web service to depend on api service
- Expose web interface on port 3001 (or other available port)
- Use build context for local development with hot reload

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
- Define route structure in a single configuration file
- Use path parameters (e.g., `/items/:id`) for item detail pages
- Use query parameters (e.g., `/items?type=cheese`) for filtering
- Configure nginx to redirect all routes to index.html for SPA behavior

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

**Decision:** Use the existing Google OAuth flow with web-specific redirect URI.

**Rationale:**
- No changes to the backend API or authentication flow
- Existing Google Sign-In package supports web
- JWT token storage in localStorage with appropriate safeguards
- Consistent user experience across platforms

**Alternatives Considered:**
- **Cookie-based authentication:** More complex to implement and doesn't match existing flow.
- **OAuth PKCE:** More secure but adds complexity and doesn't match existing flow.

**Implementation:**
- Use `google_sign_in` package with web support
- Configure OAuth client ID for web platform
- Store JWT token in localStorage with HttpOnly flag (if using cookies)
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
- Use Flutter's HTML renderer for smaller bundle size (trade-off with performance)
- Implement lazy loading for routes and components
- Optimize images and assets
- Enable gzip compression in nginx
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

### Trade-off: Code Sharing vs. Optimization

**Trade-off:** Sharing code between mobile and web reduces maintenance but may not be optimal for either platform.

**Mitigation:**
- Use conditional rendering for platform-specific UI
- Create web-specific widget variants where needed
- Monitor performance and optimize critical paths
- Accept some code duplication for better platform optimization

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
4. Set up Docker multi-stage build with nginx
5. Configure environment variable injection
6. Create docker-compose configuration for web service

### Phase 2: Core Features (Week 3-4)
1. Implement web navigation with `go_router`
2. Create web-specific item listing and detail pages
3. Implement rating interface with keyboard support
4. Add search interface with real-time results
5. Implement error handling and validation

### Phase 3: Integration (Week 5)
1. Integrate web service into docker-compose stack
2. Test web interface with live API
3. Verify environment variable configuration
4. Test all user flows end-to-end

### Phase 4: Polish (Week 6)
1. Implement accessibility features (keyboard navigation, screen reader support)
2. Optimize performance (lazy loading, caching)
3. Cross-browser testing and fixes
4. Update documentation

### Rollback Strategy
- Keep previous version of mobile app unchanged
- If web interface has issues, can remove from docker-compose while keeping mobile functional
- Docker image can be rebuilt if needed
- No production deployment to rollback from

## Open Questions

1. **OAuth Client ID:** ✅ **RESOLVED** - Use the same OAuth client ID as the mobile app.
   - **Decision:** Reuse existing client ID for web platform
   - **Impact:** Simplifies configuration, no changes needed to Google OAuth setup

2. **OAuth Redirect URI:** ✅ **RESOLVED** - Use localhost for local development.
   - **Decision:** Configure OAuth redirect URI to http://localhost:3001 for docker-compose
   - **Impact:** Web interface will work in local development environment

3. **Analytics:** ✅ **RESOLVED** - No analytics for now.
   - **Decision:** Defer analytics implementation to future iteration
   - **Impact:** Simpler implementation, can add analytics later if needed

4. **PWA Support:** ✅ **RESOLVED** - No PWA support needed.
   - **Decision:** Skip Progressive Web App features (installability, offline support)
   - **Impact:** Reduces complexity, mobile app already provides installable experience

5. **SEO Requirements:** ✅ **RESOLVED** - No SEO requirements for now.
   - **Decision:** Defer SEO optimization to future iteration
   - **Impact:** Simpler implementation, can add pre-rendering/SSR later if needed