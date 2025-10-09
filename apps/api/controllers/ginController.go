package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func GinCreate(c *gin.Context) {
	var body struct {
		Name        string
		Producer    string
		Origin      string
		Profile     string
		Description string
	}
	c.Bind(&body)

	ginItem := models.Gin{
		Name:        body.Name,
		Producer:    body.Producer,
		Origin:      body.Origin,
		Profile:     body.Profile,
		Description: body.Description,
	}

	if err := utils.DB.Create(&ginItem).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinIndex(c *gin.Context) {
	var gins []models.Gin

	if err := utils.DB.Find(&gins).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, gins)
}

func GinDetails(c *gin.Context) {
	id := c.Param("id")

	ginItem := models.Gin{}

	if err := utils.DB.First(&ginItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinEdit(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Name        string
		Producer    string
		Origin      string
		Profile     string
		Description string
	}
	c.Bind(&body)

	ginItem := models.Gin{}

	if err := utils.DB.First(&ginItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := utils.DB.Model(&ginItem).Updates(models.Gin{
		Name:        body.Name,
		Producer:    body.Producer,
		Origin:      body.Origin,
		Profile:     body.Profile,
		Description: body.Description,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinRemove(c *gin.Context) {
	id := c.Param("id")

	if err := utils.DB.Delete(&models.Gin{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusOK)
}

// ===== ADMIN ENDPOINTS =====

// GetGinDeleteImpact shows what will be affected if gin is deleted
func GetGinDeleteImpact(c *gin.Context) {
	ginID := c.Param("id")

	// Check if gin exists
	var ginItem models.Gin
	if err := utils.DB.First(&ginItem, ginID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Gin not found"})
		return
	}

	// Get all ratings for this gin
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_type = ? AND item_id = ?", "gin", ginID).Find(&ratings)

	// Count unique users affected
	userMap := make(map[uint]bool)
	userDetails := make(map[uint]struct {
		ID           uint
		DisplayName  string
		RatingsCount int
	})

	for _, rating := range ratings {
		userMap[uint(rating.UserID)] = true
		if user, exists := userDetails[uint(rating.UserID)]; exists {
			user.RatingsCount++
			userDetails[uint(rating.UserID)] = user
		} else {
			userDetails[uint(rating.UserID)] = struct {
				ID           uint
				DisplayName  string
				RatingsCount int
			}{
				ID:           rating.User.ID,
				DisplayName:  rating.User.DisplayName,
				RatingsCount: 1,
			}
		}
	}

	// Count total sharings
	var sharingsCount int64
	for _, rating := range ratings {
		var count int64
		utils.DB.Table("rating_viewers").Where("rating_id = ?", rating.ID).Count(&count)
		sharingsCount += count
	}

	// Build affected users list
	affectedUsers := []gin.H{}
	for _, user := range userDetails {
		affectedUsers = append(affectedUsers, gin.H{
			"id":            user.ID,
			"display_name":  user.DisplayName,
			"ratings_count": user.RatingsCount,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"can_delete": true,
		"warnings": []string{
			"This will permanently delete all ratings for this item",
			"Users who rated this item will lose their ratings",
		},
		"impact": gin.H{
			"ratings_count":  len(ratings),
			"users_affected": len(userMap),
			"sharings_count": sharingsCount,
			"affected_users": affectedUsers,
		},
	})
}

// DeleteGin deletes a gin and all associated ratings
func DeleteGin(c *gin.Context) {
	ginID := c.Param("id")

	// Check if gin exists
	var ginItem models.Gin
	if err := utils.DB.First(&ginItem, ginID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Gin not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings for this gin
	var ratings []models.Rating
	tx.Where("item_type = ? AND item_id = ?", "gin", ginID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Delete ratings
	tx.Where("item_type = ? AND item_id = ?", "gin", ginID).Delete(&models.Rating{})

	// Delete the gin
	if err := tx.Delete(&ginItem).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete gin"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "Gin deleted successfully"})
}

// SeedGins bulk imports gins from remote URL
func SeedGins(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required"})
		return
	}

	// Fetch data using generic utility
	data, err := utils.FetchURLData(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse gin-specific JSON structure
	var jsonData struct {
		Gins []models.Gin `json:"gins"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	// Import gins with gin-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, ginItem := range jsonData.Gins {
		// Check if gin already exists (natural key: name + origin)
		var existing models.Gin
		err := utils.DB.Where("name = ? AND origin = ?", ginItem.Name, ginItem.Origin).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		// Create new gin
		if err := utils.DB.Create(&ginItem).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", ginItem.Name, err))
			continue
		}
		result.Added++
	}

	c.JSON(http.StatusOK, gin.H{
		"added":   result.Added,
		"skipped": result.Skipped,
		"errors":  result.Errors,
	})
}

// ValidateGins validates JSON structure without importing
func ValidateGins(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required"})
		return
	}

	// Fetch data using generic utility
	data, err := utils.FetchURLData(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse gin-specific JSON structure
	var jsonData struct {
		Gins []models.Gin `json:"gins"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"valid":      false,
			"errors":     []string{fmt.Sprintf("Invalid JSON format: %v", err)},
			"item_count": 0,
			"duplicates": 0,
		})
		return
	}

	// Validate gin-specific requirements
	result := utils.ValidationResult{
		Valid:     true,
		Errors:    []string{},
		ItemCount: len(jsonData.Gins),
	}

	seen := make(map[string]bool)

	for i, ginItem := range jsonData.Gins {
		// Check required fields for gin
		if ginItem.Name == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing name", i+1))
		}
		if ginItem.Origin == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing origin", i+1))
		}

		// Check for duplicates within file (gin natural key: name + origin)
		key := ginItem.Name + "|" + ginItem.Origin
		if seen[key] {
			result.Duplicates++
		}
		seen[key] = true
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":      result.Valid,
		"errors":     result.Errors,
		"item_count": result.ItemCount,
		"duplicates": result.Duplicates,
	})
}
