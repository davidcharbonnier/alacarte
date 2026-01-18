# Authentication System Documentation - Admin Panel

**Last Updated:** October 2025  
**Status:** Production-Ready

---

## Table of Contents
- [Overview](/docs/admin/authentication-system.md#overview)
- [Architecture](/docs/admin/authentication-system.md#architecture)
- [Admin Role Verification](/docs/admin/authentication-system.md#admin-role-verification)
- [Error Handling](/docs/admin/authentication-system.md#error-handling)
- [Security Features](/docs/admin/authentication-system.md#security-features)
- [Deployment](/docs/admin/authentication-system.md#deployment)
- [Troubleshooting](/docs/admin/authentication-system.md#troubleshooting)

---

## Overview

The admin panel uses NextAuth.js v5 for authentication with Google OAuth, integrated with the backend API for JWT-based authorization and admin role verification.

### Key Features

- Google OAuth authentication
- Backend JWT exchange
- Admin role verification (database flag + initial admin email)
- Enhanced error handling with user-friendly messages
- Server-side route protection
- Secure session management

---

## Architecture

### Authentication Flow

```
User clicks "Sign in with Google"
  ↓
Google OAuth flow (handled by NextAuth)
  ↓
NextAuth receives Google tokens
  ↓
Step 1: Exchange with backend
  POST /auth/google { id_token, access_token }
  ← Returns: { token: backend-jwt, user: {...} }
  ↓
Step 2: Transform user data
  Backend returns GORM format (ID, CreatedAt, UpdatedAt)
  Transform to JavaScript conventions (id, created_at, updated_at)
  ↓
Step 3: Check admin privileges
  GET /api/auth/check-admin (with backend JWT)
  ← Returns: { is_admin: true/false }
  ↓
If is_admin: true → Login succeeds → Dashboard
If is_admin: false → Throw "AccessDenied" → Redirect to /login?error=AccessDenied
If backend unreachable → Throw "ServiceUnavailable" → Redirect to /login?error=ServiceUnavailable
```

### Components

**`auth.ts`** - Core NextAuth configuration
- Google OAuth provider setup
- Token exchange callbacks
- Admin verification logic
- Error handling
- GORM to JavaScript data transformation for session user data

**`middleware.ts`** - Route protection
- Uses NextAuth `auth` wrapper to protect routes
- Redirects unauthenticated users to `/login`
- Allows access to the login page for unauthenticated users
- Admin verification is performed in the JWT callback of `auth.ts`; backend API routes can additionally use the `RequireAdmin` middleware from `utils/auth.go` for extra protection.

**`lib/api/client.ts`** - API client
- Adds backend JWT to all requests
- Handles 401 errors

---

## Admin Role Verification

### Implementation

Admin verification uses a **backend endpoint** that checks:
1. User's `is_admin` flag in database (persistent admin status)
2. OR user's email matches `INITIAL_ADMIN_EMAIL` env variable (bootstrap admin)

**Backend endpoint:**
```
GET /api/auth/check-admin
Authorization: Bearer <backend-jwt>

Response:
{
  "is_admin": true/false
}
```

**Backend logic (single source of truth):**
```go
// utils/auth.go
func IsUserAdmin(user *models.User) bool {
    if user == nil {
        return false
    }
    initialAdminEmail := GetEnv("INITIAL_ADMIN_EMAIL", "")
    return user.IsAdmin || (initialAdminEmail != "" && user.Email == initialAdminEmail)
}
```

### Why This Approach?

✅ **Single source of truth** - Admin logic defined once in backend  
✅ **No duplication** - Same logic used in middleware and login check  
✅ **Bootstrap-friendly** - Initial admin can login immediately  
✅ **Secure** - Backend validates on every API call (defense in depth)  
✅ **Minimal overhead** - ~50ms check once per login session  

---

## Error Handling

### Error Types

The admin panel provides clear, actionable error messages for different failure scenarios:

**AccessDenied** - User is not an admin
```
Title: "Access Denied"
Message: "Your account does not have administrator privileges. 
          Please contact the administrator if you believe this is an error."
```

**ServiceUnavailable** - Backend unreachable
```
Title: "Service Unavailable"
Message: "Unable to connect to the authentication service. 
          Please try again later or contact the administrator if the problem persists."
```

**AuthenticationFailed** - Unexpected auth errors
```
Title: "Authentication Failed"
Message: "An unexpected error occurred during sign-in. 
          Please try again or contact the administrator."
```

**Configuration** - NextAuth config issue
```
Title: "Configuration Error"
Message: "There is a problem with the server configuration. 
          Please contact the administrator."
```

### Implementation

**auth.ts error detection:**
```typescript
catch (error) {
  if (axios.isAxiosError(error)) {
    if (!error.response) {
      throw new Error("ServiceUnavailable");
    } else if (error.response.status === 401 || error.response.status === 403) {
      throw new Error("AccessDenied");
    }
  }
  throw new Error("AuthenticationFailed");
}
```

**login/page.tsx error display:**
```typescript
const searchParams = useSearchParams();
const error = searchParams.get('error');
const errorInfo = getErrorMessage(error);

// Display alert if error exists
{errorInfo && (
  <Alert variant="destructive">
    <AlertTitle>{errorInfo.title}</AlertTitle>
    <AlertDescription>{errorInfo.description}</AlertDescription>
  </Alert>
)}
```

---

## Error Handling (continued)

### API Client Error Handling

The `apiClient` in `lib/api/client.ts` automatically redirects the user to the sign‑in page when a 401 response is received from the backend, ensuring a seamless re‑authentication flow.

## Security Features

- **JWT Validation** – Backend validates every API request using the `RequireAuth` middleware, ensuring tokens are checked on each call.

### Built-in Security

- **CSRF Protection** - NextAuth built-in
- **HttpOnly Cookies** - Session not accessible via JavaScript
- **Secure Cookies** - HTTPS-only in production
- **Server-Side Validation** - Middleware checks session before page render
- **JWT Validation** - Backend validates every API request
- **Admin Verification** - Checked at login and on every admin endpoint

### Security Hardening

- **No tech stack disclosure** - Removed version info from login page
- **Disabled X-Powered-By header** - `poweredByHeader: false` in next.config.ts
- **Minimal error messages** - No technical details exposed to users
- **Non-root Docker user** - Container runs as unprivileged user
- **Trust Host** - `trustHost: true` for Cloud Run compatibility

---

## Deployment

### Environment Variables (Production)

```bash
# API URLs
API_URL=https://alacarte-api-xxx.run.app
NEXT_PUBLIC_API_URL=https://alacarte-api-xxx.run.app

# NextAuth
NEXTAUTH_URL=https://alacarte-admin-xxx.run.app
NEXTAUTH_SECRET=<strong-64-char-secret>

# Google OAuth (same as backend)
GOOGLE_CLIENT_ID=<production-client-id>
GOOGLE_CLIENT_SECRET=<production-client-secret>
```

### Google OAuth Configuration

**Production redirect URI:**
```
https://alacarte-admin-xxx.run.app/api/auth/callback/google
```

Must be added to Google Cloud Console → Credentials → OAuth Client

### Cloud Run Deployment

The admin panel is deployed as a Docker container:

```bash
# Pull latest image
docker pull davidcharbonnier/alacarte-admin:latest

# Deploy to Cloud Run
gcloud run deploy alacarte-admin \
  --image davidcharbonnier/alacarte-admin:latest \
  --platform managed \
  --region northamerica-northeast1 \
  --allow-unauthenticated
```

---

## Troubleshooting

### "UntrustedHost" Error

**Symptom:** Login fails with UntrustedHost error in Cloud Run logs  
**Cause:** NextAuth doesn't trust the Cloud Run URL  
**Fix:** Ensure `trustHost: true` is set in `auth.ts` and `NEXTAUTH_URL` matches your Cloud Run URL

### "Access Denied" on Valid Admin

**Symptom:** Admin user sees access denied message  
**Cause:** Backend admin check failing  
**Fix:** 
1. Check `INITIAL_ADMIN_EMAIL` matches user's Google email
2. Or set `is_admin = true` in database for the user

### Backend Unreachable

**Symptom:** "Service Unavailable" error on login  
**Cause:** Admin panel can't reach backend API  
**Fix:**
1. Verify `API_URL` environment variable is correct
2. Check backend is running and accessible
3. Verify network connectivity between services

### Images Not Loading

**Symptom:** Profile pictures show fallback icons  
**Cause:** CORS or referrer policy blocking Google images  
**Fix:** Images now use `referrerPolicy="no-referrer"` with automatic fallback

---

## Data Flow Summary

```
User Authentication:
  NextAuth → Google OAuth → Backend token exchange → Admin check → Session ✅

API Requests:
  Component → API Client → getSession() → Backend JWT → Backend API ✅

Security Layers:
  1. Middleware (server-side route protection)
  2. Session validation (NextAuth)
  3. Backend JWT validation (all API calls)
  4. Admin role check (login + middleware)
```

---

## Status: Production Ready ✅

The authentication system is fully functional and deployed to production with:
- Complete admin role verification
- Comprehensive error handling
- Security hardening
- Cloud Run compatibility
- User-friendly error messages

