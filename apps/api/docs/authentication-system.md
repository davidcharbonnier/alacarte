# Authentication System Documentation - Backend

## Table of Contents
- [Overview](#overview)
- [Architecture Migration](#architecture-migration)
- [Google OAuth Integration](#google-oauth-integration)
- [JWT Token Management](#jwt-token-management)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Security Implementation](#security-implementation)
- [Middleware & Guards](#middleware--guards)
- [Migration Strategy](#migration-strategy)
- [Testing & Development](#testing--development)
- [Deployment Considerations](#deployment-considerations)

---
**Last Updated:** January 2025  
**Related Documentation:**
- [Privacy Model](privacy-model.md)
---

## Overview

The A la carte backend authentication system has evolved from a simple profile-based model to a secure Google OAuth implementation with JWT token protection. This transformation provides:

- **Secure API endpoints** - All routes protected with JWT authentication
- **Google OAuth integration** - Exchange Google tokens for application JWT tokens
- **User identity management** - Real user accounts with Google profile information
- **Cross-platform support** - Same authentication flow for web, mobile, desktop
- **Scalable architecture** - Standard authentication patterns for future enhancements

### Why Google OAuth?

The backend chose Google OAuth for several key reasons:
- ✅ **Security** - Google handles OAuth security, token validation, user verification
- ✅ **Simplicity** - Single OAuth provider reduces complexity
- ✅ **User adoption** - Nearly universal Google account ownership
- ✅ **Profile data** - Access to verified user names, emails, avatars
- ✅ **Cross-platform** - Works identically across all client platforms

## Architecture Migration

### Current Profile System → Google OAuth

**Before (Profile-based):**
```
HTTP Request → No Authentication → Direct Database Access
```

**After (OAuth-based):**
```
HTTP Request → JWT Validation → User Context → Protected Database Access
```

### Database Schema Evolution

**Before:**
```go
type User struct {
    gorm.Model
    Name string `gorm:"unique"` // Simple profile name
}

type Rating struct {
    gorm.Model
    AuthorID int // References User.ID
    // ...
}
```

**After:**
```go
type User struct {
    gorm.Model
    GoogleID    string `gorm:"unique"`     // Google OAuth subject ID
    Email       string `gorm:"unique"`     // Verified Google email
    FullName    string                     // From Google profile
    DisplayName string `gorm:"unique"`     // User-chosen display name
    Avatar      string                     // Google profile photo URL
    Discoverable bool  `gorm:"default:true"` // Privacy setting
    CreatedAt   time.Time
    LastLoginAt time.Time
}

type Rating struct {
    gorm.Model
    UserID   int  // References User.ID (cleaner naming)
    User     User `gorm:"foreignKey:UserID"`
    // ... rest unchanged
}
```

## Google OAuth Integration

### OAuth Flow Implementation

```go
// OAuth configuration
type OAuthConfig struct {
    ClientID     string `json:"client_id"`
    ClientSecret string `json:"client_secret"`
    RedirectURI  string `json:"redirect_uri"`
}

// Google OAuth handler
func GoogleOAuthCallback(c *gin.Context) {
    code := c.Query("code")
    if code == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Authorization code required"})
        return
    }

    // Exchange authorization code for Google tokens
    googleUser, err := exchangeCodeForGoogleUser(code)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to verify Google token"})
        return
    }

    // Find or create user in our database
    user, err := findOrCreateUser(googleUser)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user account"})
        return
    }

    // Update last login time
    user.LastLoginAt = time.Now()
    if err := utils.DB.Save(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
        return
    }

    // Generate JWT token for our application
    token, err := generateJWT(user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "token": token,
        "user":  user,
    })
}
```

## JWT Token Management

### Token Generation

```go
// JWT claims structure
type Claims struct {
    UserID      int    `json:"user_id"`
    Email       string `json:"email"`
    DisplayName string `json:"display_name"`
    jwt.RegisteredClaims
}

// Generate JWT token for authenticated user
func generateJWT(user *models.User) (string, error) {
    expirationTime := time.Now().Add(24 * time.Hour) // 24 hour expiration
    
    claims := &Claims{
        UserID:      int(user.ID),
        Email:       user.Email,
        DisplayName: user.DisplayName,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(expirationTime),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            Issuer:    "alacarte-api",
            Subject:   fmt.Sprintf("%d", user.ID),
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    
    // Sign token with secret key
    secretKey := []byte(os.Getenv("JWT_SECRET_KEY"))
    if len(secretKey) == 0 {
        return "", fmt.Errorf("JWT secret key not configured")
    }
    
    tokenString, err := token.SignedString(secretKey)
    if err != nil {
        return "", fmt.Errorf("failed to sign token: %v", err)
    }
    
    return tokenString, nil
}
```

## Database Schema

### Enhanced User Model

```go
// models/userModel.go (Updated)
package models

import (
    "gorm.io/gorm"
    "time"
)

type User struct {
    gorm.Model
    
    // Google OAuth fields
    GoogleID    string `gorm:"uniqueIndex;not null" json:"google_id"`
    Email       string `gorm:"uniqueIndex;not null" json:"email"`
    FullName    string `gorm:"not null" json:"full_name"`
    Avatar      string `json:"avatar"`
    
    // Application-specific fields
    DisplayName  string `gorm:"uniqueIndex" json:"display_name"`
    Discoverable bool   `gorm:"default:true" json:"discoverable"`
    
    // Timestamps
    LastLoginAt time.Time `json:"last_login_at"`
    
    // Relationships
    Ratings []Rating `gorm:"foreignKey:UserID" json:"ratings,omitempty"`
}

// Check if user has completed profile setup
func (u *User) HasCompletedSetup() bool {
    return u.DisplayName != ""
}
```

## API Endpoints

### Authentication Routes

```go
// main.go (Updated with auth routes)
func main() {
    router := gin.New()
    
    // Health check (no auth required)
    router.GET("/health", healthCheck)
    
    // Authentication routes (no auth required)
    auth := router.Group("/auth")
    {
        auth.POST("/google", GoogleOAuthCallback)
        auth.POST("/refresh", RefreshToken)
        auth.POST("/logout", Logout)
    }
    
    // Profile completion (requires partial auth)
    profile := router.Group("/profile")
    profile.Use(RequirePartialAuth())
    {
        profile.POST("/complete", CompleteProfile)
        profile.GET("/check-display-name", CheckDisplayNameAvailability)
    }
    
    // Protected API routes (requires full auth)
    api := router.Group("/api")
    api.Use(RequireAuth())
    {
        // User management
        user := api.Group("/user")
        {
            user.GET("/me", GetCurrentUser)
            user.PUT("/display-name", UpdateDisplayName)
            user.PUT("/privacy/discoverable", UpdateDiscoverability)
            user.GET("/sharing-stats", GetSharingStats)
            user.GET("/export", ExportUserData)
            user.DELETE("/account", DeleteAccount)
        }
        
        // Existing protected routes
        // ... cheese, rating routes
    }
    
    router.Run()
}
```

## Security Implementation

### Environment Configuration

```go
// .env file template
JWT_SECRET_KEY=your-super-secure-jwt-secret-key-here-64-chars-minimum
GOOGLE_CLIENT_ID=your-google-oauth-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-oauth-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/auth/callback

# Development vs Production
GIN_MODE=release
TRUSTED_PROXIES=127.0.0.1,::1

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=password
DB_NAME=alacarte
```

## Middleware & Guards

### Authentication Middleware

```go
// middleware/auth.go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/davidcharbonnier/rest-api/models"
    "github.com/davidcharbonnier/rest-api/utils"
)

// Require full authentication (completed profile)
func RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        user, err := authenticateRequest(c)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
            c.Abort()
            return
        }
        
        if !user.HasCompletedSetup() {
            c.JSON(http.StatusForbidden, gin.H{"error": "Profile setup required"})
            c.Abort()
            return
        }
        
        // Set user context
        c.Set("user", user)
        c.Set("userId", user.ID)
        c.Next()
    }
}
```

---

**This authentication system provides a secure, scalable backend foundation that integrates seamlessly with Google OAuth while maintaining the flexibility to add additional authentication methods in the future.**
