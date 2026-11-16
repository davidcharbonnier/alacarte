# Authentication System

> **See also:** App-specific implementation details: [API](/docs/api/authentication-system.md) · [Client](/docs/client/authentication-system.md) · [Admin](/docs/admin/authentication-system.md)

**Last Updated:** November 2026  
**Status:** Production Ready

The À la carte platform uses **Google OAuth 2.0** with **JWT tokens** for secure, cross-platform authentication.

---

## 🎯 Overview

### Authentication Flow

```
1. User → Google OAuth login (platform-specific client)
2. Google → Returns id_token (verified Google identity)
3. Client → Sends id_token to backend POST /auth/google
4. Backend → Validates id_token with Google, finds or creates user, generates JWT
5. Client → Uses JWT (Authorization: Bearer) for all API requests
```

All three apps share this flow. Only the Google-side sign-in UI and token storage differ (see app docs).

### Key Components

- **Google OAuth 2.0** - User authentication via Google accounts
- **JWT Tokens** - Stateless API authentication, signed by the backend
- **Profile Setup** - Display name and privacy configuration after first sign-in
- **Cross-Platform** - Web, mobile, desktop support

---

## 🔑 Token Lifecycle

- **Single access token** — the backend issues one JWT per sign-in. There are no refresh tokens or `/auth/refresh` / `/auth/logout` endpoints today; when the token expires, the client simply signs in again.
- **Lifetime:** 24 hours (`GenerateJWT` in `apps/api/utils/jwt.go`).
- **Signing:** HS256 with `JWT_SECRET_KEY` (64+ character random secret).
- **Claims:** `user_id`, `email`, `display_name` + standard registered claims (`exp`, `iat`, issuer `alacarte-api`).
- **Transport:** Sent as `Authorization: Bearer <jwt>` on every API request; backend validates signature and expiry on each call.

### Session Rules

| App | Storage | Session behavior |
|-----|---------|------------------|
| Flutter client | `flutter_secure_storage` (platform-encrypted) | Session survives app restarts until token expiry; token revalidated with `GET /api/user/me` on connectivity restore |
| Admin SPA | `sessionStorage` (`jwt_token` key) | Session scoped to the browser tab; cleared on sign-out and on 401 |
| Backend | — | Stateless; no server-side sessions |

---

## 👤 Profile Setup & Privacy

After first Google sign-in, a user completes their profile:

- **Display name** (unique, user-chosen — real identity is never exposed)
- **Discoverable toggle** — controls visibility in sharing
- **Private by default** — ratings only visible to the author
- **Explicit sharing** — users choose exactly who sees ratings

See [Privacy Model](/docs/features/privacy-model.md) for the privacy architecture.

### Admin Role

Admin status is a backend concern, checked once per login via `GET /api/auth/check-admin`:

- `is_admin` flag in the database, **or** email matches `INITIAL_ADMIN_EMAIL` (bootstrap admin)
- Backend enforces `RequireAdmin` on every admin endpoint (single source of truth, defense in depth)

---

## 🔒 Security Considerations

- **Token validation:** Backend validates the Google `id_token` with Google's API servers on every exchange — no trust in client claims.
- **HTTPS Only:** Production tokens over HTTPS.
- **Redirect URI / origin validation:** Whitelisted in Google Cloud Console.
- **Minimal error messages:** No technical details exposed to end users.
- **Stateless validation:** Every API request re-checks the JWT signature and expiry.

### Environment Variables (all apps)

```bash
# Backend (apps/api)
JWT_SECRET_KEY=your-64-char-secret
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
INITIAL_ADMIN_EMAIL=[EMAIL]

# Flutter client (apps/client)
API_BASE_URL=http://localhost:8080
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

# Admin SPA (apps/admin)
VITE_API_URL=http://localhost:8080
VITE_GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

The web OAuth client ID is shared across apps so that Google identity and backend audience match.

---

## 🧪 Testing

```bash
# Exchange a Google id_token for a backend JWT
curl -X POST http://localhost:8080/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "GOOGLE_ID_TOKEN"}'

# Test a protected endpoint
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/user/me
```

Client and admin flows are tested through their apps: sign in with Google, complete profile setup (new users), verify protected features.

---

## 📚 Related Documentation

### App-Specific Implementation
- [API Authentication Details](/docs/api/authentication-system.md) - Routes, middleware, JWT internals
- [Client Authentication Details](/docs/client/authentication-system.md) - Flutter provider and platform OAuth setup
- [Admin Authentication Details](/docs/admin/authentication-system.md) - SPA session handling and route guards

### Setup Guides
- [Android OAuth Setup](/docs/client/setup/android-oauth-setup.md) - Android-specific configuration
- [Google OAuth Setup](/docs/client/setup/google-oauth-setup.md) - Google Console configuration

### Related Features
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [User Management](/docs/api/README.md#user-management) - User CRUD operations

---

**Authentication system provides secure, cross-platform user identity with privacy-first design.**
