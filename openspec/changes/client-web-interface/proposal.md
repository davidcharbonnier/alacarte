## Why

The current Flutter client is primarily designed for mobile platforms. While Flutter supports web compilation, the existing mobile UI is not optimized for desktop/web browsers. Users accessing the platform via web need a dedicated interface that leverages web-specific UX patterns and responsive design, while maintaining feature parity with the mobile app. The web interface ships as a static bundle deployable to any static host (e.g. Netlify), mirroring the admin app's release pattern.

## What Changes

- Add a dedicated web interface for the client app using Flutter web compilation
- Implement web-specific UI adaptations (responsive design, web navigation patterns, keyboard support)
- Ensure the web interface uses the same API endpoints and authentication as the mobile app
- Run locally on the host via `flutter run -d web-server --web-port 3001` (no Docker; same pattern as other client platforms)
- Add `web/_redirects` so SPA deep links survive static hosting
- Build the web bundle as a CI release artifact (mirrors admin: build, attach to release, deploy manually)
- Keep the existing mobile app unchanged (Android/iOS/desktop builds unaffected)

## Capabilities

### New Capabilities
- `client-web-interface`: Web-specific user interface for the client app with responsive design, web navigation patterns, and desktop-optimized UX

### Modified Capabilities
- None (this change adds new capabilities without modifying existing spec-level requirements)

## Impact

- **apps/client**: Web-specific UI components and layouts, `.env.example`, `web/_redirects`
- **CI workflows**: Client web build artifact added to the release pipeline (mirrors admin `dist/` pattern)
- **apps/api**: `.env.example` documents `ALLOWED_ORIGINS` entry for `http://localhost:3001` (no code change)
- **Documentation**: Update development documentation with web interface setup and deploy instructions
- **API**: No code changes required (existing endpoints support both mobile and web)
