package controllers

import (
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

// Get users available for sharing (discoverable + previous connections)
func GetShareableUsers(c *gin.Context) {
	userID := utils.GetCurrentUserID(c)

	// Get users who have shared with current user (previous connections)
	// Only include users who have completed their profile setup
	var previousConnections []models.User
	err := utils.DB.Raw(`
		SELECT DISTINCT u.id, u.google_id, u.email, u.full_name, 
		               u.display_name, u.avatar, u.discoverable, u.profile_completed
		FROM users u
		INNER JOIN ratings r ON r.user_id = u.id
		INNER JOIN rating_viewers rv ON rv.rating_id = r.id
		WHERE rv.user_id = ? AND u.id != ? AND u.profile_completed = true
		ORDER BY u.display_name
	`, userID, userID).Scan(&previousConnections).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get previous connections"})
		return
	}

	// Get IDs of previous connections to exclude from discoverable list
	excludeIDs := []uint{userID} // Always exclude current user
	for _, user := range previousConnections {
		excludeIDs = append(excludeIDs, user.ID)
	}

	// Get discoverable users who have completed their profile
	// (excluding current user and previous connections)
	var discoverableUsers []models.User
	query := utils.DB.Select("id, google_id, email, full_name, display_name, avatar, discoverable, profile_completed").
		Where("discoverable = ? AND profile_completed = ?", true, true)

	if len(excludeIDs) > 0 {
		query = query.Where("id NOT IN ?", excludeIDs)
	}

	err = query.Order("display_name").Find(&discoverableUsers).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get discoverable users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"previous_connections": previousConnections,
		"discoverable":         discoverableUsers,
	})
}

// Update user profile (PATCH endpoint for flexible updates)
func UpdateCurrentUser(c *gin.Context) {
	userID := utils.GetCurrentUserID(c)

	// Parse request body for partial updates
	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate allowed fields
	allowedFields := map[string]bool{
		"display_name": true,
		"discoverable": true,
	}

	validUpdates := make(map[string]interface{})
	for field, value := range updates {
		if allowedFields[field] {
			validUpdates[field] = value
		}
	}

	if len(validUpdates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No valid fields to update"})
		return
	}

	// Update user with valid fields
	if err := utils.DB.Model(&models.User{}).Where("id = ?", userID).Updates(validUpdates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	// Return updated user
	var updatedUser models.User
	if err := utils.DB.First(&updatedUser, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get updated user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User updated successfully",
		"user":    updatedUser,
	})
}

// Get current user profile
func GetCurrentUser(c *gin.Context) {
	user, err := utils.GetCurrentUser(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get user"})
		return
	}

	c.JSON(http.StatusOK, user)
}

// Delete current user account (CASCADE deletion)
func DeleteCurrentUser(c *gin.Context) {
	userID := utils.GetCurrentUserID(c)

	// Get user info for logging before deletion
	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Database CASCADE will automatically handle:
	// - Delete all user's ratings (ratings.user_id → CASCADE)
	// - Remove user from rating_viewers many-to-many relationships
	// - Delete user account
	if err := utils.DB.Delete(&models.User{}, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete account"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Account deleted successfully",
		"deleted_user": user.DisplayName,
	})
}

// ===== ADMIN ENDPOINTS =====

// GetAllUsers lists all users (admin only - exposes emails)
func GetAllUsers(c *gin.Context) {
	var users []models.User
	utils.DB.Order("created_at DESC").Find(&users)

	c.JSON(http.StatusOK, users)
}

// GetUserDetails gets specific user details
func GetUserDetails(c *gin.Context) {
	userID := c.Param("id")

	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

// GetUserDeleteImpact shows what will be affected if user is deleted
func GetUserDeleteImpact(c *gin.Context) {
	userID := c.Param("id")

	// Check if user exists
	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Get all ratings by this user
	var ratings []models.Rating
	utils.DB.Where("user_id = ?", userID).Find(&ratings)

	// Find users who have ratings shared FROM this user
	affectedUserMap := make(map[uint]bool)
	userRatingsCount := make(map[uint]int)

	for _, rating := range ratings {
		// Get viewers of this rating
		var viewerIDs []uint
		utils.DB.Table("rating_viewers").Where("rating_id = ?", rating.ID).Pluck("user_id", &viewerIDs)

		for _, viewerID := range viewerIDs {
			affectedUserMap[viewerID] = true
			userRatingsCount[viewerID]++
		}
	}

	// Build affected users list
	affectedUsers := []gin.H{}
	for affectedUserID := range affectedUserMap {
		var affectedUser models.User
		if err := utils.DB.First(&affectedUser, affectedUserID).Error; err == nil {
			affectedUsers = append(affectedUsers, gin.H{
				"id":            affectedUser.ID,
				"display_name":  affectedUser.DisplayName,
				"ratings_count": userRatingsCount[affectedUserID],
			})
		}
	}

	// Count total sharings
	var sharingsCount int64
	for _, rating := range ratings {
		var count int64
		utils.DB.Table("rating_viewers").Where("rating_id = ?", rating.ID).Count(&count)
		sharingsCount += count
	}

	c.JSON(http.StatusOK, gin.H{
		"can_delete": true,
		"warnings": []string{
			"This will delete all of the user's ratings",
			"Other users will lose shared ratings from this user",
		},
		"impact": gin.H{
			"ratings_count":  len(ratings),
			"users_affected": len(affectedUserMap),
			"sharings_count": sharingsCount,
			"affected_users": affectedUsers,
		},
	})
}

// DeleteUser deletes a user and all associated data
func DeleteUser(c *gin.Context) {
	userID := c.Param("id")

	// Check if user exists
	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings by this user
	var ratings []models.Rating
	tx.Where("user_id = ?", userID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Remove user as viewer from other people's ratings
	tx.Exec("DELETE FROM rating_viewers WHERE user_id = ?", userID)

	// Delete all ratings by this user
	tx.Where("user_id = ?", userID).Delete(&models.Rating{})

	// Delete sharing relationships
	tx.Exec("DELETE FROM sharing_relationships WHERE user_a_id = ? OR user_b_id = ?", userID, userID)

	// Delete the user
	if err := tx.Delete(&user).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "User deleted successfully"})
}

// PromoteUser sets IsAdmin flag to true for a user
func PromoteUser(c *gin.Context) {
	userID := c.Param("id")

	// Check if user exists
	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if already admin
	if user.IsAdmin {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User is already an admin"})
		return
	}

	// Promote to admin
	if err := utils.DB.Model(&user).Update("is_admin", true).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to promote user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User promoted to admin successfully",
		"user": gin.H{
			"id":           user.ID,
			"display_name": user.DisplayName,
			"email":        user.Email,
			"is_admin":     true,
		},
	})
}

// DemoteUser sets IsAdmin flag to false for a user
func DemoteUser(c *gin.Context) {
	userID := c.Param("id")

	// Check if user exists
	var user models.User
	if err := utils.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if not an admin
	if !user.IsAdmin {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User is not an admin"})
		return
	}

	// Check if trying to demote the initial admin from env
	initialAdminEmail := utils.GetEnv("INITIAL_ADMIN_EMAIL", "")
	if initialAdminEmail != "" && user.Email == initialAdminEmail {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Cannot demote initial admin configured in INITIAL_ADMIN_EMAIL",
		})
		return
	}

	// Demote from admin
	if err := utils.DB.Model(&user).Update("is_admin", false).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to demote user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User demoted from admin successfully",
		"user": gin.H{
			"id":           user.ID,
			"display_name": user.DisplayName,
			"email":        user.Email,
			"is_admin":     false,
		},
	})
}
