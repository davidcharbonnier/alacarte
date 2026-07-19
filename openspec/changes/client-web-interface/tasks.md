## Frontend

### Flutter Foundation Setup

- [ ] 1.1 Enable path URL strategy (`usePathUrlStrategy`) for clean web URLs (go_router 16 already in pubspec; web defaults to hash URLs)
- [ ] 1.2 Verify Flutter web compilation target is enabled in `apps/client/`
- [ ] 1.3 Create responsive breakpoint utilities in `apps/client/lib/responsive/` (mobile <768px, tablet 768-1024px, desktop >1024px)
- [ ] 1.4 Create `WebSidebar` navigation widget for desktop/tablet in `apps/client/lib/widgets/web/`
- [ ] 1.5 Create `ResponsiveGrid` widget that adjusts column count based on breakpoint in `apps/client/lib/widgets/web/`
- [ ] 1.6 Create `WebScaffold` responsive within the web tree (NavigationRail on desktop, drawer/bottom nav on narrow viewports) in `apps/client/lib/widgets/web/`
- [ ] 1.7 Add `web/_redirects` with `/* /index.html 200` for SPA deep-linking on static hosts
- [ ] 1.8 Create `.env.example` file in `apps/client/` documenting required environment variables (`API_BASE_URL`, `GOOGLE_CLIENT_ID`, `APP_VERSION`)
- [ ] 1.9 Verify local dev: `flutter run -d web-server --web-port 3001` serves the app and deep links work
- [ ] 1.10 Update `apps/api/.env.example` documenting `ALLOWED_ORIGINS` with `http://localhost:3001` for local web dev

### Web Navigation and Routing

- [ ] 2.1 Extend existing `apps/client/lib/routes/app_router.dart` with platform-aware route builders (`kIsWeb ? WebXxxPage() : XxxScreen()`)
- [ ] 2.2 Add `/profile` route for `WebProfilePage`; verify the existing route table covers all web screens (search stays in-page, no route)
- [ ] 2.3 Verify existing path parameters for item detail pages (`/items/:itemType/:itemId`) work on web
- [ ] 2.4 Test navigation using browser back/forward buttons (go_router default behavior on web)
- [ ] 2.5 Test deep linking by entering URLs directly (depends on 1.1 path URL strategy)
- [ ] 2.6 Create web-styled `NotFoundPage` for invalid routes (router currently renders a placeholder)

### Web-Specific UI Components

- [ ] 3.1 Create `WebItemCard` widget with desktop-optimized layout in `apps/client/lib/widgets/web/`
- [ ] 3.2 Create `WebItemDetailPage` with two-column layout (left: image/info, right: description/ratings) in `apps/client/lib/screens/web/`
- [ ] 3.3 Create `WebRatingWidget` with mouse and keyboard support in `apps/client/lib/widgets/web/`
- [ ] 3.4 Create `WebSearchBar` with real-time results and keyboard navigation in `apps/client/lib/widgets/web/`
- [ ] 3.5 Create `WebProfilePage` with dashboard layout in `apps/client/lib/screens/web/`
- [ ] 3.6 Create `WebErrorPage` with user-friendly error messages in `apps/client/lib/screens/web/`
- [ ] 3.7 Implement inline validation error display in forms
- [ ] 3.8 Add focus indicators for keyboard navigation
- [ ] 3.9 Test all components on desktop viewport (>1024px)
- [ ] 3.10 Test all components on tablet viewport (768-1024px)
- [ ] 3.11 Test all components on mobile viewport (<768px)
- [ ] 3.12 Add `SelectionArea` wrappers for selectable text content
- [ ] 3.13 Add hover cursors (`SystemMouseCursors.click`) and hover states on interactive elements
- [ ] 3.14 Add persistent scrollbars on desktop viewport and keyboard shortcuts (e.g. `/` focuses search)

### Authentication Integration

- [ ] 4.1 Configure `google_sign_in` package for web platform in `apps/client/`
- [ ] 4.2 Configure web sign-in with the existing Web-application OAuth client ID (same as admin `VITE_GOOGLE_CLIENT_ID`)
- [ ] 4.3 Add `http://localhost:3001` to authorized JavaScript origins for the web OAuth client (Google Cloud Console)
- [ ] 4.4 Verify JWT storage via existing `token_storage` (flutter_secure_storage) works on web
- [ ] 4.5 Verify auth state refresh and 401 handling (`auth_provider`) work on web; adapt if needed
- [ ] 4.6 Verify router auth redirect on invalid/expired token works on web
- [ ] 4.7 Test Google OAuth sign-in flow on web
- [ ] 4.8 Test logout functionality

### State Management

- [ ] 5.1 Create web-specific Riverpod providers for UI state (e.g., `sidebarToggleProvider`) in `apps/client/lib/providers/`
- [ ] 5.2 Verify existing Riverpod providers work correctly on web platform
- [ ] 5.3 Add URL-based state providers for filters and search queries

### Item Listing and Filtering

- [ ] 6.1 Create `WebItemListPage` with responsive grid layout in `apps/client/lib/screens/web/`
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
- [ ] 8.4 Wire `WebSearchBar` to existing search support in `dynamic_item_service` (`?search=` param)
- [ ] 8.5 Test search with keyboard navigation
- [ ] 8.6 Test search with mouse interaction

### Error Handling

- [ ] 9.1 Implement network error handling with retry button
- [ ] 9.2 Add error boundary for unexpected errors
- [ ] 9.3 Test network error scenarios
- [ ] 9.4 Test validation error scenarios

### Accessibility

- [ ] 10.1 Ensure all interactive elements are keyboard accessible
- [ ] 10.2 Add ARIA labels for screen readers
- [ ] 10.3 Verify sufficient color contrast ratios (WCAG 2.1 AA)
- [ ] 10.4 Test keyboard navigation (Tab, Enter, Escape, arrow keys)
- [ ] 10.5 Test with screen reader software
- [ ] 10.6 Fix any accessibility issues found

### Performance Optimization

- [ ] 11.1 Implement lazy loading for images
- [ ] 11.2 Implement lazy loading for routes
- [ ] 11.3 Optimize images and assets
- [ ] 11.4 Remove unused dependencies
- [ ] 11.5 Monitor bundle size and optimize if needed
- [ ] 11.6 Test page load performance (target <3 seconds)

### Testing

- [ ] 12.1 Add web platform to existing widget tests
- [ ] 12.2 Create integration test for login flow on web
- [ ] 12.3 Create integration test for item listing on web
- [ ] 12.4 Create integration test for item detail on web
- [ ] 12.5 Create integration test for rating on web
- [ ] 12.6 Run tests with `flutter test --platform chrome`

### Cross-Browser Testing

- [ ] 13.1 Test on Chrome (latest version)
- [ ] 13.2 Test on Firefox (latest version)
- [ ] 13.3 Test on Safari (latest version)
- [ ] 13.4 Test on Edge (latest version)
- [ ] 13.5 Test on Chrome Mobile
- [ ] 13.6 Test on Safari Mobile (iOS)
- [ ] 13.7 Fix any browser-specific issues found

## DevOps

### CI Release Artifact

- [ ] 14.1 Add web build to client release workflow: write `.env` from CI secrets, `flutter build web --release`
- [ ] 14.2 Attach `build/web` bundle to the GitHub release (mirror admin `dist/` pattern)
- [ ] 14.3 Add release note: "Deploy `build/web/` to any static host (Netlify, Cloudflare Pages, etc.)"
- [ ] 14.4 Verify CI artifact contains `_redirects` and loads on a static host (manual Netlify deploy test)

## Documentation

- [ ] 15.1 Update `README.md` with web interface information
- [ ] 15.2 Add web interface setup instructions to `docs/client/`
- [ ] 15.3 Document environment variables in `docs/client/`
- [ ] 15.4 Document local dev workflow in `docs/client/` (`flutter run -d web-server --web-port 3001`, `.env` setup)
- [ ] 15.5 Document manual deploy of the `build/web` artifact to a static host (Netlify) in `docs/client/`
- [ ] 15.6 Update architecture documentation in `docs/architecture/`
