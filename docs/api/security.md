# Security - Backend

> **Concepts first:** the cross-app authentication model (flow, token lifecycle, session rules) lives in [/docs/features/authentication.md](/docs/features/authentication.md) and the privacy model in [/docs/features/privacy-model.md](/docs/features/privacy-model.md). This document covers only the backend security implementation.

**Last Updated:** November 2026  
**Related Documentation:**
- [Authentication System (backend)](authentication-system.md)
- [Privacy Model (canonical)](/docs/features/privacy-model.md)
- [Deployment](deployment.md)

---

## Overview

Security in the API rests on five pillars, each mapped to code:

| Pillar | Implementation | Source |
|--------|----------------|--------|
| Identity verification | Google `id_token` verified via Google Tokeninfo API | `controllers/authController.go` |
| Session tokens | HS256 JWTs signed with `JWT_SECRET_KEY` | `utils/jwt.go` |
| Route protection | Gin middleware chain | `utils/auth.go` |
| Cross-origin access | Origin allowlist with wildcard patterns | `main.go` (`setupCORS`) |
| Error hygiene | Generic client errors, detailed server-side logs | `controllers/*.go` |

---

## Authentication (Google Sign-In)

### Flow

The API never touches OAuth authorization codes or client secrets. The client obtains a Google `id_token`, and the API exchanges it for its own JWT via `POST /auth/google`:

1. Client sends `{ "id_token": "<google-id-token>" }` to `/auth/google`.
2. `parseGoogleIDToken` (`controllers/authController.go`) verifies the token with **Google's Tokeninfo API** (`oauth2Service.Tokeninfo().IdToken(...)`). Google's servers confirm authenticity — no local signature verification.
3. **Audience check:** the token's `aud` must exactly match `GOOGLE_CLIENT_ID`. Mismatch → rejected with a generic error.
4. The JWT payload is decoded (`parseJWTPayload`) to extract the full profile (`sub`, `email`, `name`, ...). Missing `sub`, `email`, or `name` → rejected; the API requires complete profile data.
5. User is found or created by `google_id` and a backend JWT is returned.

### Why no client secret

`GOOGLE_CLIENT_SECRET` is not used anywhere in the API. Verification relies on Google's Tokeninfo API plus the audience check, so only `GOOGLE_CLIENT_ID` is required. This is intentional (backend-for-frontend style token exchange) — do not "fix" it by adding a secret-based flow.

### Trust boundary notes

- The tokeninfo call confirms the token is valid and unexpired **per Google**, but the API performs its own audience check; never skip it, or tokens minted for other apps would authenticate here.
- `parseJWTPayload` decodes the payload *without* verifying the signature — that is safe only because authenticity was already established by the Tokeninfo call in step 2. Keep both steps together.

---

## Session Tokens (JWT)

`utils/jwt.go` issues and validates all session tokens:

- **Algorithm:** HS256 (`jwt.SigningMethodHS256`). Validation rejects any token whose `alg` header is not HMAC — this blocks `alg: none` and algorithm-confusion attacks.
- **Secret:** `JWT_SECRET_KEY`. The code requires it to be non-empty (token generation fails otherwise). **Use 64+ characters in production** — see `.env.example`.
- **Expiry:** 24 hours (`ExpiresAt` + `IssuedAt` claims; enforced by `golang-jwt/v5` during parse).
- **Claims:** `user_id`, `email`, `display_name`, plus registered claims (`iss: alacarte-api`, `sub` = user ID).

There are intentionally **no refresh or logout endpoints** — see token lifecycle in the shared [authentication doc](/docs/features/authentication.md).

---

## Authorization Middleware

`utils/auth.go` provides three middlewares. All read the `Authorization: Bearer <jwt>` header, validate the JWT, and load the user from the database (a valid token for a deleted user is rejected).

| Middleware | Behavior | Failure response |
|------------|----------|------------------|
| `RequireAuth` | Valid JWT **and** completed profile (`HasCompletedSetup`) | 401 `Authentication required` / 403 `Profile setup required` |
| `RequirePartialAuth` | Valid JWT only (profile may be incomplete) | 401 `Authentication required` |
| `RequireAdmin` | Valid JWT **and** admin status | 401 / 403 `Admin access required` |

`RequireAdmin` is always chained after `RequireAuth` (see admin route group in `main.go`); it re-reads the user from the request context.

### Admin status

Single source of truth: `utils.IsUserAdmin(user)` — admin if either:

- `user.IsAdmin` (database flag, manageable via promote/demote admin endpoints), or
- the user's email equals `INITIAL_ADMIN_EMAIL` (env config; the initial admin also bypasses profile setup at first login).

### Route protection map (`main.go`)

| Route group | Protection |
|-------------|------------|
| `/auth/google` | Public (token exchange itself) |
| `/health` | Public |
| `/profile/*` | `RequirePartialAuth` (profile completion, display name check) |
| Most item/rating/schema read & write routes | `RequireAuth` or `RequirePartialAuth` per route |
| `/admin/*` (users, schemas, item admin) | `RequireAuth` + `RequireAdmin` |

For per-endpoint details see [endpoints.md](endpoints.md).

---

## CORS

`setupCORS` in `main.go`:

- Origins come from `ALLOWED_ORIGINS` (comma-separated). Default if unset: `http://localhost:3000,http://localhost:8080`.
- Each entry is matched with Go's `path.Match`, so shell-style wildcards (`*`, `?`) are supported, e.g. `https://*.example.com` (useful for Cloud Run preview URLs).
- Unknown origins get no CORS headers; the browser blocks the request.

---

## Error Handling & Information Disclosure

### Client responses

All client-facing error messages are generic and stable. Internal causes (parsing errors, Google API responses, validation internals) are never returned — handlers return fixed strings such as:

- `Invalid Google ID token or missing profile data`
- `Authentication required` / `Profile setup required` / `Admin access required`
- `Failed to create user` / `Failed to generate token`

This prevents attackers from learning validation logic, expected audiences, or backend internals from error text.

### Server-side logging

Detailed error causes are logged server-side with `slog.Error` (structured logging, e.g. `authController.go`), so developers keep full debugging information without exposing it to clients. Note: errors logged this way can include internal detail — ship logs to a trusted sink only.

### Configuration display

At startup the OAuth config is printed, but `GOOGLE_CLIENT_ID` is shown in full only when `GIN_MODE=debug`; in any other mode it prints `[configured]` (`main.go`, `setupAuthRoutes`). The API defaults to `release` mode unless `GIN_MODE` says otherwise.

---

## Additional Hardening

- **Trusted proxies:** `TRUSTED_PROXIES` env var controls which proxies Gin trusts for client IP resolution; unset → no proxies trusted (`router.SetTrustedProxies(nil)`), preventing IP spoofing via `X-Forwarded-For`.
- **Release mode by default:** gin runs in `release` mode unless `GIN_MODE` is set, disabling debug output.
- **Request logging:** all requests are logged (`gin.Logger`), except `/health`.
- **Upload limits:** image uploads capped at 5 MB (`MaxMultipartMemory`).
- **Panic recovery:** `gin.Recovery()` converts panics into 500s without stack traces leaking to clients.
- **Password-less auth:** no passwords are stored anywhere; credential theft surface is limited to stolen JWTs (24h window) and Google tokens.

---

## Security Checklist for Deployment

- [ ] `JWT_SECRET_KEY` set, 64+ random characters, never reused across environments
- [ ] `GOOGLE_CLIENT_ID` matches the client app's OAuth client
- [ ] `ALLOWED_ORIGINS` lists only production frontend origins (wildcards kept narrow)
- [ ] `TRUSTED_PROXIES` set to the actual load balancer (Cloud Run) or left unset
- [ ] `GIN_MODE` not set to `debug` in production
- [ ] `INITIAL_ADMIN_EMAIL` set to the operator account; promote/demote used for ongoing admin management

---

**Related Documentation:**
- [Authentication System](authentication-system.md) — endpoints and flows
- [Privacy Model](/docs/features/privacy-model.md) — data visibility and sharing guarantees
- [Deployment](deployment.md) — environment configuration
