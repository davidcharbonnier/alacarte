package utils

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/gin-gonic/gin"
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

// Require partial authentication (allows incomplete profiles)
func RequirePartialAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, err := authenticateRequest(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
			c.Abort()
			return
		}

		c.Set("user", user)
		c.Set("userId", user.ID)
		c.Next()
	}
}

// Core authentication logic
func authenticateRequest(c *gin.Context) (*models.User, error) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return nil, fmt.Errorf("authorization header required")
	}

	// Extract Bearer token
	parts := strings.Fields(authHeader)
	if len(parts) != 2 || parts[0] != "Bearer" {
		return nil, fmt.Errorf("invalid authorization header format")
	}

	tokenString := parts[1]

	// Validate JWT
	claims, err := ValidateJWT(tokenString)
	if err != nil {
		return nil, fmt.Errorf("invalid token: %v", err)
	}

	// Get user from database
	var user models.User
	if err := DB.First(&user, claims.UserID).Error; err != nil {
		return nil, fmt.Errorf("user not found")
	}

	return &user, nil
}

// Helper to get current user from context
func GetCurrentUser(c *gin.Context) (*models.User, error) {
	user, exists := c.Get("user")
	if !exists {
		return nil, fmt.Errorf("user not found in context")
	}

	if u, ok := user.(*models.User); ok {
		return u, nil
	}

	return nil, fmt.Errorf("invalid user type in context")
}

// Helper to get current user ID from context
func GetCurrentUserID(c *gin.Context) uint {
	userID, exists := c.Get("userId")
	if !exists {
		return 0
	}

	if id, ok := userID.(uint); ok {
		return id
	}

	return 0
}

// IsUserAdmin checks if user is admin via database flag or initial admin email
// This is the single source of truth for admin status checks
func IsUserAdmin(user *models.User) bool {
	if user == nil {
		return false
	}

	initialAdminEmail := GetEnv("INITIAL_ADMIN_EMAIL", "")
	return user.IsAdmin || (initialAdminEmail != "" && user.Email == initialAdminEmail)
}

// RequireAdmin ensures user is admin (has IsAdmin flag or is initial admin from env)
func RequireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, err := GetCurrentUser(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
			c.Abort()
			return
		}

		if !IsUserAdmin(user) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			c.Abort()
			return
		}

		c.Next()
	}
}
