# Authentication System Documentation - Admin Panel

> **Shared behavior (auth flow, token lifecycle, session rules) lives in [/docs/features/authentication.md](/docs/features/authentication.md).** This doc covers only the admin SPA's session handling.

**Last Updated:** October 2025  
**Status:** Production-Ready

---

## Overview

The admin panel is a Vite + React SPA that signs users in with **`@react-oauth/google`** and holds the backend JWT in **`sessionStorage`**. There is no NextAuth.js or server-side session — all auth state lives in React context and the browser tab.

### Key Files

- `src/lib/auth/auth-context.tsx` - `AuthProvider` / `useAuth`: sign-in, admin check, sign-out, user reconstruction from JWT claims
- `src/lib/auth/auth-guard.ts` - `requireAuth()` route guard used as TanStack Router `beforeLoad`
- `src/lib/api/client.ts` - Axios client: attaches `Bearer` token, redirects to `/login` on 401
- `src/pages/login.tsx` - `GoogleLogin` button and configuration error display

---

## Authentication Flow

```
User clicks "Sign in with Google" (GoogleLogin)
  ↓
Google returns a credential (JWT id_token)
  ↓
signInWithGoogle() → POST /auth/google { id_token }
  ← { token: backend-jwt, user: {...} }
  ↓
JWT stored in sessionStorage under `jwt_token`; user set in AuthContext
  ↓
checkAdmin() → GET /api/auth/check-admin (with backend JWT)
  ← { is_admin: true/false }
  ↓
is_admin → navigate to /
not admin → navigate to /access-denied
```

The `GoogleLogin` `credential` is the Google `id_token` — exactly what the backend `/auth/google` endpoint verifies. `access_token` is omitted (optional for the backend); the Flutter client also sends `access_token`.

`AuthProvider` rebuilds the `User` object from JWT claims on page load (`jwtDecode`, `sub` = user id), so a page refresh inside the same tab restores the session without a backend round-trip.

---

## Session Handling

- **Storage:** `sessionStorage` key `jwt_token` (`JWT_STORAGE_KEY` in `lib/api/client.ts`) — session is scoped to the browser tab and ends when the tab closes.
- **Why `sessionStorage`:** survives page refreshes but clears on tab close and is not shared across tabs. Alternatives were rejected: `localStorage` widens the XSS surface (token outlives the tab), in-memory forces re-auth on refresh, and an httpOnly-cookie BFF needs a server component the static-host deploy doesn't have. XSS risk from third-party scripts is deemed minimal — a pragmatic middle ground.
- **Request attachment:** Axios request interceptor adds `Authorization: Bearer <jwt>` to every call.
- **Expiry:** The JWT is checked client-side on context init (`exp` claim); a 24h-expired token decodes to no user, but the route guard only checks that a token exists, so the redirect to `/login` happens on the first 401.
- **401 handling:** The Axios response interceptor navigates to `/login` on any 401 (SPA navigation via a held router reference; a 401 during boot is a cold-start race with the same target).
- **Sign-out:** Removes `jwt_token` from `sessionStorage`, clears context state, navigates to `/login`.

### Route Protection

`requireAuth()` (`src/lib/auth/auth-guard.ts`) is used as `beforeLoad` on protected TanStack Router routes: no token in `sessionStorage` → redirect to `/login`. The login page and `/access-denied` are public (no `beforeLoad`).

---

## Admin Role Verification

Admin verification uses the **backend endpoint** (single source of truth):

```
GET /api/auth/check-admin
Authorization: Bearer <backend-jwt>

Response: { "is_admin": true/false }
```

Backend logic in `utils/auth.go`:

```go
func IsUserAdmin(user *models.User) bool {
    if user == nil {
        return false
    }
    initialAdminEmail := GetEnv("INITIAL_ADMIN_EMAIL", "")
    return user.IsAdmin || (initialAdminEmail != "" && user.Email == initialAdminEmail)
}
```

- `is_admin` database flag (persistent), **or** email matches `INITIAL_ADMIN_EMAIL` (bootstrap admin)
- Checked once per login in the SPA; backend also enforces `RequireAdmin` on every admin endpoint (defense in depth)

---

## Error Handling

- **Missing/placeholder client ID:** the login page shows a configuration alert with setup steps when `VITE_GOOGLE_CLIENT_ID` is missing.
- **Sign-in errors:** surfaced inline in the login page (`response.credential` missing, backend error messages).
- **Non-admin:** redirected to `/access-denied` rather than shown a generic error.
- **Backend unreachable:** the sign-in promise rejects and the message is shown in the login page alert.
- **Error messages** — the login page alert shows the raw error message (e.g. "Network Error" when the sign-in request cannot reach the API). If the follow-up admin check fails (`checkAdmin()` swallows errors and returns `false`), the user lands on `/access-denied` instead.

---

## Deployment

### Environment Variables

```bash
# API URL
VITE_API_URL=https://alacarte-api-xxx.run.app

# Google OAuth (web client ID, same as backend)
VITE_GOOGLE_CLIENT_ID=<production-web-client-id>
```

### Google OAuth Configuration

Add the admin origin (`https://admin.example.com`, `http://localhost:3000` for dev) to **Authorized JavaScript origins** in Google Cloud Console → Credentials → OAuth Client. As a SPA there is no redirect-URI callback.

---

## Troubleshooting

### "Access Denied" on Valid Admin

1. Check `INITIAL_ADMIN_EMAIL` matches the user's Google email, **or**
2. Set `is_admin = true` in the database for the user.

### Backend Unreachable / Sign-In Fails

1. Verify `VITE_API_URL` is correct.
2. Check the backend is running and reachable from the admin origin.
3. Verify the Google OAuth client ID and authorized JavaScript origins.

### Profile Pictures Not Loading

Google avatar images use a plain MUI `Avatar` (no special referrer handling); if avatars fail to load, the initials fallback shows.
