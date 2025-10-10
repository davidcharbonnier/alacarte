# Authentication System

**Last Updated:** January 2025  
**Status:** Production Ready

The A la carte platform uses **Google OAuth 2.0** with **JWT tokens** for secure, cross-platform authentication.

---

## 🎯 Overview

### Authentication Flow

```
1. User → Google OAuth login
2. Google → Returns authorization code
3. Client → Sends code to backend
4. Backend → Validates with Google, generates JWT
5. Client → Uses JWT for all API requests
```

### Key Components

- **Google OAuth 2.0** - User authentication via Google accounts
- **JWT Tokens** - Stateless API authentication
- **Profile Setup** - Display name and privacy configuration
- **Cross-Platform** - Web, mobile, desktop support

---

## 🔧 Backend Implementation

### Database Schema

```go
type User struct {
    gorm.Model
    GoogleID     string `gorm:"unique"`      // Google OAuth subject
    Email        string `gorm:"unique"`      // Verified email
    FullName     string                      // From Google profile
    DisplayName  string `gorm:"unique"`      // User-chosen name
    Avatar       string                      // Profile photo URL
    Discoverable bool   `gorm:"default:true"` // Privacy setting
    IsAdmin      bool   `gorm:"default:false"` // Admin role
    LastLoginAt  time.Time
}
```

### API Endpoints

**Authentication:**
- `POST /auth/google` - Exchange Google OAuth code for JWT token

**Profile Setup:**
- `POST /profile/complete` - Set display name and privacy (requires partial auth)
- `GET /profile/check-display-name` - Check name availability

**User Management:**
- `GET /api/user/me` - Get current user (requires auth)
- `PATCH /api/user/me` - Update profile (requires auth)
- `DELETE /api/user/account` - Delete account (requires auth)

### Middleware

```go
// Require JWT authentication
api.Use(utils.RequireAuth())

// Require admin role
admin.Use(utils.RequireAuth(), utils.RequireAdmin())
```

### Environment Variables

```bash
JWT_SECRET_KEY=your-64-char-secret
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
INITIAL_ADMIN_EMAIL=admin@example.com
```

**See:** [API authentication docs](/docs/api/authentication-system.md) for implementation details

---

## 📱 Frontend Implementation

### Google Sign-In Integration

```dart
// Using google_sign_in package
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: AppConfig.googleWebClientId,
);

// Sign in flow
final account = await _googleSignIn.signIn();
final auth = await account.authentication;

// Exchange with backend
final response = await apiService.exchangeGoogleToken(
  authorizationCode: auth.serverAuthCode,
  idToken: auth.idToken,
);

// Store JWT token
await _tokenStorage.saveToken(response.token);
```

### Auth Provider

```dart
// Riverpod auth state management
class AuthProvider extends StateNotifier<AuthState> {
  Future<void> signInWithGoogle() async {
    // 1. Google OAuth
    // 2. Backend exchange
    // 3. Profile check
    // 4. Navigate appropriately
  }
  
  Future<void> completeProfile(String displayName, bool discoverable) async {
    // Profile setup after OAuth
  }
  
  Future<void> signOut() async {
    // Clear tokens and Google session
  }
}
```

### Cross-Platform OAuth

- **Web:** Google Sign-In web library
- **Android:** Native Google Sign-In with serverClientId
- **Desktop:** Web OAuth flow via browser

### Environment Variables

```bash
API_BASE_URL=http://localhost:8080
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

**See:** [Client authentication docs](/docs/client/authentication-system.md) for implementation details

---

## ⚙️ Admin Panel Implementation

### NextAuth.js Configuration

```typescript
// NextAuth providers
providers: [
  GoogleProvider({
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  }),
]

// JWT callback - exchange for backend JWT
callbacks: {
  async jwt({ token, account }) {
    if (account) {
      // Exchange Google token for backend JWT
      const response = await fetch(`${API_URL}/auth/google`, {
        method: 'POST',
        body: JSON.stringify({ code: account.access_token }),
      });
      const { token: backendToken } = await response.json();
      token.backendToken = backendToken;
    }
    return token;
  },
}
```

### Protected Routes

```typescript
// Middleware protection
export { default } from 'next-auth/middleware';

export const config = {
  matcher: [
    '/((?!auth|api/auth|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

### Environment Variables

```bash
NEXTAUTH_URL=http://localhost:3001
NEXTAUTH_SECRET=your-nextauth-secret
NEXT_PUBLIC_API_URL=http://localhost:8080
GOOGLE_CLIENT_ID=your-web-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
```

**See:** [Admin authentication docs](/docs/admin/authentication-system.md) for implementation details

---

## 🔒 Security Considerations

### JWT Token Security

- **Expiration:** 24-hour token lifetime
- **Secret Key:** 64+ character random secret
- **HTTPS Only:** Production tokens over HTTPS
- **HttpOnly Cookies:** (Admin panel only)

### OAuth Security

- **PKCE Flow:** Used for mobile apps
- **State Parameter:** CSRF protection
- **Redirect URI Validation:** Whitelist in Google Console
- **Token Validation:** Backend validates with Google tokeninfo API

### Privacy Controls

- **Display Names:** Hide real identity
- **Discoverable Toggle:** Control visibility in sharing
- **Private by Default:** Ratings only visible to author
- **Explicit Sharing:** Users choose exactly who sees ratings

---

## 🧪 Testing

### Backend Testing

```bash
# Test Google OAuth endpoint
curl -X POST http://localhost:8080/auth/google \
  -H "Content-Type: application/json" \
  -d '{"code": "GOOGLE_AUTH_CODE"}'

# Test protected endpoint
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/user/me
```

### Frontend Testing

```bash
# Run with OAuth configuration
flutter run -d linux

# Test flow:
# 1. Click "Sign in with Google"
# 2. Complete OAuth in browser
# 3. Return to app
# 4. Complete profile setup
# 5. Access protected features
```

### Admin Testing

```bash
npm run dev
# Navigate to http://localhost:3001
# Sign in with Google
# Verify admin access
```

---

## 📚 Related Documentation

### Component-Specific Docs
- [API Authentication Details](/docs/api/authentication-system.md) - Backend implementation
- [Client Authentication Details](/docs/client/authentication-system.md) - Frontend implementation
- [Admin Authentication Details](/docs/admin/authentication-system.md) - Admin panel implementation

### Setup Guides
- [Android OAuth Setup](/docs/client/setup/android-oauth-setup.md) - Android-specific configuration
- [Google OAuth Setup](/docs/client/google-oauth-setup.md) - Google Console configuration

### Related Features
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [User Management](/docs/api/README.md#user-management) - User CRUD operations

---

## 🚀 Quick Setup

### 1. Google Cloud Console

1. Create OAuth 2.0 credentials
2. Add authorized redirect URIs
3. Copy client ID and secret

### 2. Backend

```bash
cd apps/api
# Update .env with Google credentials
go run main.go
```

### 3. Frontend

```bash
cd apps/client
# Update .env with client ID
flutter run
```

### 4. Admin

```bash
cd apps/admin
# Update .env.local with credentials
npm run dev
```

**Total setup time: ~15 minutes**

---

**Authentication system provides secure, cross-platform user identity with privacy-first design.**
