## Frontend

### Flutter Foundation Setup

- [ ] 1.1 Add `go_router` package to `apps/client/pubspec.yaml`
- [ ] 1.2 Verify Flutter web compilation target is enabled in `apps/client/`
- [ ] 1.3 Create responsive breakpoint utilities in `apps/client/lib/responsive/` (mobile <768px, tablet 768-1024px, desktop >1024px)
- [ ] 1.4 Create `WebSidebar` navigation widget for desktop/tablet in `apps/client/lib/widgets/web/`
- [ ] 1.5 Create `ResponsiveGrid` widget that adjusts column count based on breakpoint in `apps/client/lib/widgets/web/`
- [ ] 1.6 Create `AdaptiveScaffold` wrapper that uses sidebar for web and bottom nav for mobile in `apps/client/lib/widgets/web/`
- [ ] 1.10 Create `.env.example` file in `apps/client/` documenting required environment variables

### Web Navigation and Routing

- [ ] 2.1 Create `apps/client/lib/router/router.dart` with `go_router` configuration
- [ ] 2.2 Define route structure: `/`, `/items`, `/items/:id`, `/profile`, `/search`, `/login`
- [ ] 2.3 Implement path parameters for item detail pages (`/items/:id`)
- [ ] 2.4 Implement query parameters for filtering (`/items?type=cheese`)
- [ ] 2.5 Configure browser history integration in router
- [ ] 2.6 Add deep linking support for item pages
- [ ] 2.7 Create `NotFoundPage` widget for invalid routes
- [ ] 2.8 Test navigation using browser back/forward buttons
- [ ] 2.9 Test navigation by entering URLs directly

### Web-Specific UI Components

- [ ] 3.1 Create `WebItemCard` widget with desktop-optimized layout in `apps/client/lib/widgets/web/`
- [ ] 3.2 Create `WebItemDetailPage` with two-column layout (left: image/info, right: description/ratings) in `apps/client/lib/pages/web/`
- [ ] 3.3 Create `WebRatingWidget` with mouse and keyboard support in `apps/client/lib/widgets/web/`
- [ ] 3.4 Create `WebSearchBar` with real-time results and keyboard navigation in `apps/client/lib/widgets/web/`
- [ ] 3.5 Create `WebProfilePage` with dashboard layout in `apps/client/lib/pages/web/`
- [ ] 3.6 Create `WebErrorPage` with user-friendly error messages in `apps/client/lib/pages/web/`
- [ ] 3.7 Implement inline validation error display in forms
- [ ] 3.8 Add focus indicators for keyboard navigation
- [ ] 3.9 Test all components on desktop viewport (>1024px)
- [ ] 3.10 Test all components on tablet viewport (768-1024px)
- [ ] 3.11 Test all components on mobile viewport (<768px)

### Authentication Integration

- [ ] 4.1 Configure `google_sign_in` package for web platform in `apps/client/`
- [ ] 4.2 Set OAuth client ID for web platform (reuse existing client ID)
- [ ] 4.3 Configure OAuth redirect URI to use localhost (http://localhost:3001)
- [ ] 4.4 Implement JWT token storage in localStorage
- [ ] 4.5 Add token refresh logic in API client
- [ ] 4.6 Implement redirect to login page on invalid/expired token
- [ ] 4.7 Test Google OAuth sign-in flow on web
- [ ] 4.8 Test token refresh flow
- [ ] 4.9 Test logout functionality

### State Management

- [ ] 5.1 Create web-specific Riverpod providers for UI state (e.g., `sidebarToggleProvider`) in `apps/client/lib/providers/`
- [ ] 5.2 Verify existing Riverpod providers work correctly on web platform
- [ ] 5.3 Add URL-based state providers for filters and search queries
- [ ] 5.4 Test reactive updates with `ref.watch`
- [ ] 5.5 Test one-time reads with `ref.read`

### Item Listing and Filtering

- [ ] 6.1 Create `WebItemListPage` with responsive grid layout in `apps/client/lib/pages/web/`
- [ ] 6.2 Implement filter UI (consumable type, rating range) in sidebar
- [ ] 6.3 Connect filters to URL query parameters
- [ ] 6.4 Implement real-time filter updates without page reload
- [ ] 6.5 Add sorting functionality (name, rating, date)
- [ ] 6.6 Test item listing on desktop (3-4 columns)
- [ ] 6.7 Test item listing on tablet (2 columns)
- [ ] 6.8 Test item listing on mobile (1 column)
- [ ] 6.9 Test filter functionality
- [ ] 6.10 Test sorting functionality

### Item Detail Page

- [ ] 7.1 Implement two-column layout for desktop in `WebItemDetailPage`
- [ ] 7.2 Implement stacked layout for mobile in `WebItemDetailPage`
- [ ] 7.3 Display item image and basic info in left column (desktop)
- [ ] 7.4 Display description, ratings, and reviews in right column (desktop)
- [ ] 7.5 Add keyboard navigation support for rating widget
- [ ] 7.6 Test item detail page on desktop viewport
- [ ] 7.7 Test item detail page on tablet viewport
- [ ] 7.8 Test item detail page on mobile viewport

### Search Interface

- [ ] 8.1 Implement real-time search results in `WebSearchBar`
- [ ] 8.2 Display search results in dropdown/overlay
- [ ] 8.3 Add keyboard navigation (arrow keys, Enter) for search results
- [ ] 8.4 Connect search to existing API endpoints
- [ ] 8.5 Test search with keyboard navigation
- [ ] 8.6 Test search with mouse interaction

### Error Handling

- [ ] 9.1 Create `WebErrorPage` with user-friendly error messages
- [ ] 9.2 Implement network error handling with retry button
- [ ] 9.3 Implement validation error display inline with form fields
- [ ] 9.4 Add error boundary for unexpected errors
- [ ] 9.5 Test network error scenarios
- [ ] 9.6 Test validation error scenarios

### Accessibility

- [ ] 10.1 Ensure all interactive elements are keyboard accessible
- [ ] 10.2 Add ARIA labels for screen readers
- [ ] 10.3 Verify sufficient color contrast ratios (WCAG 2.1 AA)
- [ ] 10.4 Test keyboard navigation (Tab, Enter, Escape, arrow keys)
- [ ] 10.5 Test with screen reader software
- [ ] 10.6 Fix any accessibility issues found

### Performance Optimization (Frontend)

- [ ] 11.3 Implement lazy loading for images
- [ ] 11.4 Implement lazy loading for routes
- [ ] 11.5 Optimize images and assets
- [ ] 11.6 Remove unused dependencies
- [ ] 11.7 Monitor bundle size and optimize if needed
- [ ] 11.8 Test page load performance (target <3 seconds)

### Testing

- [ ] 12.1 Add web platform to existing widget tests
- [ ] 12.2 Create integration test for login flow on web
- [ ] 12.3 Create integration test for item listing on web
- [ ] 12.4 Create integration test for item detail on web
- [ ] 12.5 Create integration test for rating on web
- [ ] 12.6 Run tests with `flutter test --platform chrome`

### Cross-Browser Testing

- [ ] 16.1 Test on Chrome (latest version)
- [ ] 16.2 Test on Firefox (latest version)
- [ ] 16.3 Test on Safari (latest version)
- [ ] 16.4 Test on Edge (latest version)
- [ ] 16.5 Test on Chrome Mobile
- [ ] 16.6 Test on Safari Mobile (iOS)
- [ ] 16.7 Fix any browser-specific issues found

## DevOps

### Docker Configuration

- [ ] 1.7 Create `Dockerfile` in `apps/client/` with multi-stage build (Flutter SDK stage + nginx runtime stage)
- [ ] 1.8 Create `nginx.conf` in `apps/client/` for SPA routing, gzip compression, and cache headers
- [ ] 1.9 Configure environment variable injection in Dockerfile using `ARG` and `--dart-define` for `API_URL`, `OAUTH_CLIENT_ID`, `OAUTH_REDIRECT_URI`
- [ ] 1.11 Test local Docker build with `docker build -t client-web .` in `apps/client/`
- [ ] 1.12 Test local Docker container with `docker run -p 3001:80 client-web`

### Performance Optimization (Docker)

- [ ] 11.1 Enable gzip compression in nginx configuration
- [ ] 11.2 Set cache headers for static assets (images, fonts)

### Docker Compose Integration

- [ ] 13.1 Create `apps/client/docker-compose.yaml` with web service definition
- [ ] 13.2 Configure web service to depend on api service
- [ ] 13.3 Expose web interface on port 3001
- [ ] 13.4 Configure build context for local development with hot reload
- [ ] 13.5 Add environment variables for API_URL, OAUTH_CLIENT_ID, OAUTH_REDIRECT_URI
- [ ] 13.6 Add include path to root `docker-compose.yml`
- [ ] 13.7 Test docker-compose up with all services
- [ ] 13.8 Test web interface connectivity to API
- [ ] 13.9 Test OAuth flow with localhost redirect URI

## Documentation

- [ ] 17.1 Update `README.md` with web interface information
- [ ] 17.2 Add web interface setup instructions to `docs/client/`
- [ ] 17.3 Document environment variables in `docs/client/`
- [ ] 17.4 Document Docker build process in `docs/client/`
- [ ] 17.5 Document docker-compose usage in `docs/client/`
- [ ] 17.6 Update architecture documentation in `docs/architecture/`
