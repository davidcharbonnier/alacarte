# Authentication System Documentation - Frontend

> **Shared behavior (auth flow, token lifecycle, session rules) lives in [/docs/features/authentication.md](/docs/features/authentication.md).** This doc covers only Flutter-specific implementation.

**Last Updated:** November 2026  
**Related Documentation:**
- [Privacy Model](/docs/client/privacy-model.md)
- [Android OAuth Setup](/docs/client/setup/android-oauth-setup.md)
- [Google OAuth Setup](/docs/client/setup/google-oauth-setup.md)

---

## Overview

The Flutter client uses the `google_sign_in` package for Google OAuth and Riverpod (`AuthNotifier` / `AuthState` in `lib/providers/auth_provider.dart`) for auth state. Google tokens are exchanged for the backend JWT, which is stored in `flutter_secure_storage` and attached to every API request.

## File Map

| File | Responsibility |
|------|----------------|
| `lib/services/auth_service.dart` | Google sign-in via `google_sign_in`; uses the web client ID as `serverClientId` (`AppConfig.googleWebClientId`) with `['email', 'profile']` scopes |
| `lib/providers/auth_provider.dart` | `AuthNotifier` / `AuthState` (`isAuthenticated`, `needsProfileSetup`, `user`, `token`, `error`) |
| `lib/services/token_storage.dart` | Secure JWT storage and expiry check |
| `lib/services/api_service.dart` | `googleOAuthExchange`, `completeProfile`, `setAuthToken` / `clearAuthToken` |

## Sign-In Flow

```dart
// lib/services/auth_service.dart
// google_sign_in v7 API
await GoogleSignIn.instance.initialize(
  serverClientId: AppConfig.googleWebClientId, // backend-compatible web client ID
);
final account = await GoogleSignIn.instance.authenticate();            // -> idToken
final authorization = await account.authorizationClient
    .authorizeScopes(['email', 'profile']);                            // -> accessToken
```

1. `AuthNotifier.signInWithGoogle()` runs the platform Google sign-in and obtains the `idToken` (plus scoped `accessToken`).
2. `ApiService.googleOAuthExchange(idToken, accessToken)` POSTs `{ id_token, access_token }` to `/auth/google` and receives `{ token, user }`.
3. The JWT is saved via `TokenStorage.saveToken()` and attached with `ApiService.setAuthToken()` → `Authorization: Bearer <jwt>`.
4. `needsProfileSetup` (from `user.profileCompleted`) drives routing to display-name setup; after `completeProfile()` the user goes to home.

## Token Storage

`lib/services/token_storage.dart`:

- **`flutter_secure_storage`** with platform-specific encryption:
  - Android: Keystore-backed encrypted SharedPreferences (`encryptedSharedPreferences: true`)
  - iOS: Keychain (`first_unlock` accessibility)
  - Web: Web Crypto / IndexedDB
  - Desktop: OS keyring
- **Legacy cleanup:** one-time removal of tokens previously stored in plain-text `SharedPreferences` (pre-v1.0.0), guarded by a `secure_storage_cleanup_done` flag.
- **`isTokenExpired()`** does not decode real JWTs: it only time-checks mock tokens and returns `false` for any real token (the `exp` decode is a TODO). Expiry is learned from `GET /api/user/me` failing (see below). There is no refresh token; see the shared doc.

## Session & Offline Behavior

- On app start, `AuthNotifier._initializeAuth()` reads the stored token; a valid token restores the session.
- The stored token is **revalidated with `GET /api/user/me`** whenever connectivity is restored, so a stale token is cleared and offline users keep working with the token they have.
- Sign-out deletes the token from secure storage and clears the API auth header.

## Environment Configuration

```bash
API_BASE_URL=http://localhost:8080
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

## Platform Setup

- **Web:** Google Sign-In web client ID (`GOOGLE_CLIENT_ID`); authorized JavaScript origin for the served origin. Known gap (read from code, not run): `auth_service.dart` calls `GoogleSignIn.instance.authenticate()`, which `google_sign_in_web` 1.1.0 does not support, and the client has no `renderButton`; so only Android can sign in today and web is expected to fail with an `UnimplementedError`.
- **Android:** `serverClientId` must be the **web** client ID; SHA-1 certificates must be registered — see [Android OAuth Setup](/docs/client/setup/android-oauth-setup.md).
- **Desktop/Linux:** `google_sign_in` has no desktop implementation (the lockfile has only Android, iOS and web), so Google sign-in is not available there; use Android to sign in. See [Google OAuth Setup](/docs/client/setup/google-oauth-setup.md) for the web/Android client IDs.

## Troubleshooting

- **OAuth fails or is cancelled** — verify the client ID configuration, correct redirect URIs / origins in Google Console, and platform setup (Android SHA certificates).
- **401 after ~24h** — expected: the JWT expired. Known gap: nothing signs the user out globally on a 401 (`AuthNotifier.handleAuthError()` is never called), so a token that expires mid-session only gets cleared by the `/api/user/me` check at startup or on reconnect. The user then signs in again; there is no refresh flow.
- **Works on one platform, not another** — verify per-platform client IDs and configuration files; test the flow on each target platform.
