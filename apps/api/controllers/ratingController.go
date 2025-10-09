package controllers

import (
	"net/http"
	"strconv"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RatingCreate(c *gin.Context) {
	var body struct {
		Grade    float32 `json:"grade" binding:"required"`
		Note     string  `json:"note"`
		ItemID   int     `json:"item_id" binding:"required"`
		ItemType string  `json:"item_type" binding:"required"`
	}
	c.Bind(&body)

	// Get current user from auth context
	userID := utils.GetCurrentUserID(c)
	_, err := utils.GetCurrentUser(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	rating := models.Rating{
		Grade:    body.Grade,
		Note:     body.Note,
		UserID:   int(userID),
		ItemID:   body.ItemID,
		ItemType: body.ItemType,
	}

	if err := utils.DB.Create(&rating).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// No longer add author as viewer - ownership is implicit through UserID
	// Ratings are private by default with no viewers

	c.JSON(http.StatusOK, rating)
}

func RatingByAuthor(c *gin.Context) {
	// get id from uri and convert it to int
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Ensure user can only access their own ratings
	currentUserID := utils.GetCurrentUserID(c)
	if uint(id) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	itemType := c.DefaultQuery("type", "%")

	// get our list of ratings for a specific id
	var ratings []models.Rating
	if err := utils.DB.
		Preload("User", func(db *gorm.DB) *gorm.DB {
			// Select only necessary user fields for privacy
			return db.Select("id, display_name, avatar, discoverable")
		}).
		Preload("Viewers", func(db *gorm.DB) *gorm.DB {
			// Select only necessary viewer fields for privacy
			return db.Select("id, display_name, avatar")
		}).
		Where(models.Rating{
			UserID: id,
		}).
		Where("`ratings`.`item_type` LIKE ?", itemType).
		Find(&ratings).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, ratings)
}

func RatingByViewer(c *gin.Context) {
	// get id from uri and convert it to int
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Ensure user can only access their own reference list
	currentUserID := utils.GetCurrentUserID(c)
	if uint(id) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	itemType := c.DefaultQuery("type", "%")

	// Get ratings where user is EITHER the author OR in viewers list
	var ratings []models.Rating
	viewerSubQuery := utils.DB.Table("rating_viewers").Select("rating_id").Where("user_id = ?", id)

	if err := utils.DB.
		Preload("User", func(db *gorm.DB) *gorm.DB {
			// Select only necessary user fields for privacy
			return db.Select("id, display_name, avatar, discoverable")
		}).
		Preload("Viewers", func(db *gorm.DB) *gorm.DB {
			// Select only necessary viewer fields for privacy
			return db.Select("id, display_name, avatar")
		}).
		Where("user_id = ? OR id IN (?)", id, viewerSubQuery).
		Where("item_type LIKE ?", itemType).
		Find(&ratings).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, ratings)
}

func RatingShare(c *gin.Context) {
	// get id from uri and convert it to int
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var body struct {
		UserIDs []int `json:"user_ids" binding:"required"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// get rating and verify ownership
	var rating models.Rating
	if err := utils.DB.Preload("Viewers").First(&rating, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
		return
	}

	currentUserID := utils.GetCurrentUserID(c)
	if uint(rating.UserID) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only share your own ratings"})
		return
	}

	// get users to share with
	var usersToAdd []models.User
	if err := utils.DB.Where("id IN ?", body.UserIDs).Find(&usersToAdd).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get users"})
		return
	}

	// append viewers to rating (GORM handles duplicates)
	if err := utils.DB.Model(&rating).Association("Viewers").Append(&usersToAdd); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to share rating"})
		return
	}

	// Reload rating with updated viewers to return
	var updatedRating models.Rating
	if err := utils.DB.Preload("User").Preload("Viewers").First(&updatedRating, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reload rating"})
		return
	}

	c.JSON(http.StatusOK, updatedRating)
}

func RatingHide(c *gin.Context) {
	// get id from uri and convert it to int
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var body struct {
		UserID  int   `json:"user_id,omitempty"`  // Single user (legacy)
		UserIDs []int `json:"user_ids,omitempty"` // Multiple users (batch)
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// get rating and verify ownership
	var rating models.Rating
	if err := utils.DB.First(&rating, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
		return
	}

	currentUserID := utils.GetCurrentUserID(c)
	if uint(rating.UserID) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only unshare your own ratings"})
		return
	}

	// Determine which users to remove
	var userIDsToRemove []int
	if len(body.UserIDs) > 0 {
		// Batch unshare
		userIDsToRemove = body.UserIDs
	} else if body.UserID > 0 {
		// Single user unshare (legacy)
		userIDsToRemove = []int{body.UserID}
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Must specify user_id or user_ids"})
		return
	}

	// get viewers to remove
	var usersToRemove []models.User
	if err := utils.DB.Where("id IN ?", userIDsToRemove).Find(&usersToRemove).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Users not found"})
		return
	}

	// remove viewers from rating
	if err := utils.DB.Model(&rating).Association("Viewers").Delete(&usersToRemove); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unshare rating"})
		return
	}

	// Reload rating with updated viewers to return
	var updatedRating models.Rating
	if err := utils.DB.Preload("User").Preload("Viewers").First(&updatedRating, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reload rating"})
		return
	}

	c.JSON(http.StatusOK, updatedRating)
}

func RatingByItem(c *gin.Context) {
	itemType := c.Param("type")
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	currentUserID := utils.GetCurrentUserID(c)

	// Use subquery to get ratings visible to current user for this item
	var ratings []models.Rating
	subQuery := utils.DB.Table("rating_viewers").Select("rating_id").Where("user_id = ?", currentUserID)

	if err := utils.DB.
		Preload("User", func(db *gorm.DB) *gorm.DB {
			// Select only necessary user fields for privacy
			return db.Select("id, display_name, avatar, discoverable")
		}).
		Preload("Viewers", func(db *gorm.DB) *gorm.DB {
			// Select only necessary viewer fields for privacy
			return db.Select("id, display_name, avatar")
		}).
		Where("id IN (?)", subQuery).
		Where(models.Rating{
			ItemType: itemType,
			ItemID:   id,
		}).
		Find(&ratings).
		Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, ratings)
}

func RatingEdit(c *gin.Context) {
	id := c.Param("id")
	var body struct {
		Grade    float32 `json:"grade" binding:"required"`
		Note     string  `json:"note"`
		ItemID   int     `json:"item_id" binding:"required"`
		ItemType string  `json:"item_type" binding:"required"`
	}
	c.Bind(&body)

	var rating models.Rating
	if err := utils.DB.First(&rating, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
		return
	}

	// Verify ownership
	currentUserID := utils.GetCurrentUserID(c)
	if uint(rating.UserID) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only edit your own ratings"})
		return
	}

	if err := utils.DB.Model(&rating).Updates(models.Rating{
		Grade:    body.Grade,
		Note:     body.Note,
		ItemID:   body.ItemID,
		ItemType: body.ItemType,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rating)
}

func RatingRemove(c *gin.Context) {
	id := c.Param("id")

	// Get rating and verify ownership
	var rating models.Rating
	if err := utils.DB.First(&rating, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rating not found"})
		return
	}

	currentUserID := utils.GetCurrentUserID(c)
	if uint(rating.UserID) != currentUserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own ratings"})
		return
	}

	if err := utils.DB.Delete(&models.Rating{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

// Get anonymous community statistics for an item
func GetCommunityStats(c *gin.Context) {
	itemType := c.Param("type")
	itemId, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	// Get aggregate statistics for all ratings of this item (ignore privacy for anonymous stats)
	var result struct {
		Count   int     `json:"count"`
		Average float64 `json:"average"`
	}

	err = utils.DB.Model(&models.Rating{}).
		Where("item_type = ? AND item_id = ?", itemType, itemId).
		Select("COUNT(*) as count, COALESCE(AVG(grade), 0) as average").
		Scan(&result).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get community stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"total_ratings":  result.Count,
		"average_rating": result.Average,
		"item_type":      itemType,
		"item_id":        itemId,
	})
}

// Bulk make all user's ratings private
func BulkMakeRatingsPrivate(c *gin.Context) {
	userID := utils.GetCurrentUserID(c)

	// Get all ratings by this user
	var userRatings []models.Rating
	if err := utils.DB.Where("user_id = ?", userID).Find(&userRatings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get user ratings"})
		return
	}

	// Remove all viewers from all user's ratings
	var totalRemoved int64 = 0
	for _, rating := range userRatings {
		// Clear all viewers for this rating
		if err := utils.DB.Model(&rating).Association("Viewers").Clear(); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear rating viewers"})
			return
		}
		totalRemoved++
	}

	c.JSON(http.StatusOK, gin.H{
		"message":          "All ratings made private successfully",
		"ratings_affected": totalRemoved,
	})
}

// Bulk remove specific user from all shares
func BulkRemoveUserFromShares(c *gin.Context) {
	targetUserID, err := strconv.Atoi(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	currentUserID := utils.GetCurrentUserID(c)

	// Get all ratings by current user that are shared with target user
	var affectedRatings []models.Rating
	err = utils.DB.Joins("JOIN rating_viewers ON rating_viewers.rating_id = ratings.id").
		Where("ratings.user_id = ? AND rating_viewers.user_id = ?", currentUserID, targetUserID).
		Find(&affectedRatings).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get shared ratings"})
		return
	}

	// Get target user for removal
	var targetUser models.User
	if err := utils.DB.First(&targetUser, targetUserID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Target user not found"})
		return
	}

	// Remove target user from all affected ratings
	var ratingsModified int64 = 0
	for _, rating := range affectedRatings {
		if err := utils.DB.Model(&rating).Association("Viewers").Delete(&targetUser); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove user from rating"})
			return
		}
		ratingsModified++
	}

	c.JSON(http.StatusOK, gin.H{
		"message":          "User removed from all shares successfully",
		"ratings_affected": ratingsModified,
		"removed_user":     targetUser.DisplayName,
	})
}
