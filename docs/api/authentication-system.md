# Authentication System Documentation - Backend

> **Shared behavior (flow, token lifecycle, session rules) lives in [/docs/features/authentication.md](/docs/features/authentication.md).** This doc covers only backend-specific implementation.

**Last Updated:** November 2026  
**Related Documentation:**
- [Privacy Model](privacy-model.md)

---

## API Endpoints

```go
// main.go
func setupAuthRoutes(router *gin.Engine) {
    auth := router.Group("/auth")
    {
        auth.POST("/google", controllers.GoogleOAuthExchange)
    }
}
```

### POST /auth/google

Exchanges a Google `id_token` for a backend JWT.

- Request: `{ "id_token": "<google-id-token>", "access_token": "<optional>" }`
- Handler `GoogleOAuthExchange` (`controllers/authController.go`) validates the `id_token` with Google's API servers (`parseGoogleIDToken` / `parseJWTPayload`), finds or creates the user, updates `LastLoginAt`, and returns:
- Response: `{ "token": "<jwt>", "user": {...} }` (user includes `is_admin` per `utils.IsUserAdmin`)

There are intentionally no `/auth/refresh` or `/auth/logout` endpoints — see token lifecycle in the shared doc.

### Profile Routes (partial auth)

```go
profile := router.Group("/profile")
profile.Use(utils.RequirePartialAuth())
{
    profile.POST("/complete", controllers.CompleteProfile)
    profile.GET("/check-display-name", controllers.CheckDisplayNameAvailability)
}
```

- **POST /profile/complete** — sets display name and discoverable flag; reachable with a valid JWT before profile setup is complete.
- **GET /profile/check-display-name** — availability check for the display name.

### Admin Check

```go
api := router.Group("/api")
api.Use(utils.RequireAuth())
{
    auth := api.Group("/auth")
    auth.GET("/check-admin", controllers.CheckAdminStatus) // → { "is_admin": true/false }
}
```

Admin routes additionally use `admin.Use(utils.RequireAuth(), utils.RequireAdmin())`.

## Middleware & Guards

Defined in `utils/auth.go`:

- **`RequireAuth()`** — validates the JWT, loads the user, rejects with 401 if invalid and 403 unless `user.HasCompletedSetup()`; sets `user` / `userId` in the Gin context.
- **`RequirePartialAuth()`** — validates the JWT but does not require a completed profile (used by the profile-completion routes).
- **`RequireAdmin()`** — requires `utils.IsUserAdmin(user)`: `is_admin` database flag, or email matches `INITIAL_ADMIN_EMAIL`.

## JWT Internals

Defined in `utils/jwt.go`:

```go
type Claims struct {
    UserID      int    `json:"user_id"`
    Email       string `json:"email"`
    DisplayName string `json:"display_name"`
    jwt.RegisteredClaims
}
```

- `GenerateJWT` signs HS256 tokens with a 24-hour expiry, issuer `alacarte-api`.
- `ValidateJWT` enforces HMAC signing method and signature/expiry on every request.

## User Model

`models/userModel.go` — Google identity plus application fields:

```go
type User struct {
    gorm.Model
    GoogleID     string `gorm:"uniqueIndex;not null"`
    Email        string `gorm:"uniqueIndex;not null"`
    FullName     string `gorm:"not null"`
    Avatar       string
    DisplayName  string `gorm:"uniqueIndex"`
    Discoverable bool   `gorm:"default:true"`
    IsAdmin      bool   `gorm:"default:false"`
    LastLoginAt  time.Time
}

func (u *User) HasCompletedSetup() bool { return u.DisplayName != "" }
```

## Environment Configuration

```bash
JWT_SECRET_KEY=your-super-secure-jwt-secret-key-here-64-chars-minimum
GOOGLE_CLIENT_ID=your-google-oauth-client-id.apps.googleusercontent.com
INITIAL_ADMIN_EMAIL=[EMAIL]

GIN_MODE=release
TRUSTED_PROXIES=[IP_ADDRESS],::1

DATABASE_URL=postgres://user:password@localhost:5432/alacarte?sslmode=disable
```

No `GOOGLE_CLIENT_SECRET` is needed — the backend verifies the Google `id_token` through Google's token verification, not a secret.

## Testing & Development

```bash
# Exchange a Google id_token for a JWT
curl -X POST http://localhost:8080/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "GOOGLE_ID_TOKEN"}'

# Test a protected endpoint
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/user/me
```

Auth-related tests live alongside controllers (`schema_controller_test.go` patterns) and `utils/testdb.go` provides a seeded test database.
