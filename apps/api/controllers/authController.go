package controllers

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
	"google.golang.org/api/oauth2/v2"
	"google.golang.org/api/option"
)

// Google OAuth token exchange endpoint
func GoogleOAuthExchange(c *gin.Context) {
	var body struct {
		IDToken     string `json:"id_token" binding:"required"`
		AccessToken string `json:"access_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Google tokens required"})
		return
	}

	// Parse Google ID token (with complete profile data required)
	googleUser, err := parseGoogleIDToken(body.IDToken)
	if err != nil {
		// Secure logging - no sensitive data in production
		utils.AppLogger.LogOAuthError(err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid Google ID token or missing profile data",
		})
		return
	}

	// Find or create user from Google account
	var user models.User
	err = utils.DB.Where("google_id = ?", googleUser.Sub).First(&user).Error

	if err != nil {
		// Create new user from Google account
		user = models.User{
			GoogleID:     googleUser.Sub,
			Email:        googleUser.Email,
			FullName:     googleUser.Name,
			DisplayName:  "", // Will be set during profile completion
			Avatar:       googleUser.Picture,
			Discoverable: true,
			LastLoginAt:  time.Now(),
		}

		if err := utils.DB.Create(&user).Error; err != nil {
			utils.AppLogger.LogError("User creation", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
			return
		}
		utils.AppLogger.LogAuthSuccess(user.Email)
	} else {
		// Update last login
		user.LastLoginAt = time.Now()
		utils.DB.Save(&user)
		utils.AppLogger.LogAuthSuccess(user.Email)
	}

	// Generate real JWT token
	token, err := utils.GenerateJWT(&user)
	if err != nil {
		utils.AppLogger.LogError("JWT generation", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":   token,
		"user":    user,
		"message": "Authentication successful",
	})
}

// Google user info from ID token
type GoogleUserInfo struct {
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Locale        string `json:"locale"`
}

// Parse and verify Google ID token with Google's API
func parseGoogleIDToken(idToken string) (*GoogleUserInfo, error) {
	// Use Google's OAuth2 service to verify the token
	oauth2Service, err := oauth2.NewService(context.Background(), option.WithoutAuthentication())
	if err != nil {
		return nil, fmt.Errorf("failed to create oauth2 service: %v", err)
	}

	// Verify token authenticity and audience
	tokenInfo, err := oauth2Service.Tokeninfo().IdToken(idToken).Do()
	if err != nil {
		return nil, fmt.Errorf("invalid token")
	}

	// Verify audience matches your client ID
	clientID := os.Getenv("GOOGLE_CLIENT_ID")
	if tokenInfo.Audience != clientID {
		return nil, fmt.Errorf("unauthorized token")
	}

	// Parse JWT payload for complete profile data
	googleUser, err := parseJWTPayload(idToken)
	if err != nil {
		// FAIL: We need complete profile data for the app to work properly
		return nil, fmt.Errorf("incomplete profile data")
	}

	// Success: return complete profile data from JWT
	return googleUser, nil
}

// Parse JWT payload to extract complete Google user profile
func parseJWTPayload(idToken string) (*GoogleUserInfo, error) {
	// Split JWT into parts (header.payload.signature)
	parts := strings.Split(idToken, ".")
	if len(parts) != 3 {
		return nil, fmt.Errorf("invalid JWT format")
	}

	// Decode the payload (middle part)
	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, fmt.Errorf("invalid token format")
	}

	// Parse JSON payload into our GoogleUserInfo struct
	var googleUser GoogleUserInfo
	if err := json.Unmarshal(payloadBytes, &googleUser); err != nil {
		return nil, fmt.Errorf("invalid token payload")
	}

	// Validate that we got the essential fields for app functionality
	if googleUser.Sub == "" {
		return nil, fmt.Errorf("incomplete user profile")
	}
	if googleUser.Email == "" {
		return nil, fmt.Errorf("incomplete user profile")
	}
	if googleUser.Name == "" {
		return nil, fmt.Errorf("incomplete user profile")
	}
	// Note: Picture can be empty (user might not have profile picture)
	// Note: GivenName/FamilyName can be empty (some users only have single name)
	// Note: Locale can be empty (will default to 'en' in frontend)

	return &googleUser, nil
}

// Generate realistic avatar URL using UI Avatars service (fallback for users without profile pictures)
func generateAvatarURL(name string) string {
	if len(name) == 0 {
		return "https://ui-avatars.com/api/?name=User&size=96&background=CCCCCC&color=666&rounded=true"
	}

	// Use UI Avatars service for consistent, professional-looking avatars
	// This service generates initials-based avatars that look like real profile pictures
	encodedName := strings.ReplaceAll(name, " ", "+")

	// Choose color based on name hash for consistency
	colors := []string{"FF6B6B", "4ECDC4", "45B7D1", "F7DC6F", "BB8FCE", "82E0AA"}
	color := colors[len(name)%len(colors)]

	return fmt.Sprintf("https://ui-avatars.com/api/?name=%s&size=96&background=%s&color=fff&rounded=true",
		encodedName, color)
}

// Complete user profile setup
func CompleteProfile(c *gin.Context) {
	userID := utils.GetCurrentUserID(c)

	var body struct {
		DisplayName  string `json:"display_name" binding:"required,min=2,max=50"`
		Discoverable bool   `json:"discoverable"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile data"})
		return
	}

	// Check display name uniqueness
	var existingUser models.User
	if err := utils.DB.Where("display_name = ? AND id != ?", body.DisplayName, userID).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Display name already taken"})
		return
	}

	// Update user profile
	if err := utils.DB.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"display_name":      body.DisplayName,
		"discoverable":      body.Discoverable,
		"profile_completed": true, // Mark profile as completed
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Profile completed successfully"})
}

// Check if display name is available
func CheckDisplayNameAvailability(c *gin.Context) {
	displayName := c.Query("display_name")
	if displayName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Display name required"})
		return
	}

	var count int64
	utils.DB.Model(&models.User{}).Where("display_name = ?", displayName).Count(&count)

	c.JSON(http.StatusOK, gin.H{"available": count == 0})
}

// Check if current user has admin privileges
func CheckAdminStatus(c *gin.Context) {
	user, err := utils.GetCurrentUser(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"is_admin": utils.IsUserAdmin(user),
	})
}
