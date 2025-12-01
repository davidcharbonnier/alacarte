package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func CheeseCreate(c *gin.Context) {
	var body struct {
		Name        string `json:"name"`
		Type        string `json:"type"`
		Origin      string `json:"origin"`
		Producer    string `json:"producer"`
		Description string `json:"description"`
	}
	c.Bind(&body)

	cheese := models.Cheese{
		Name:        body.Name,
		Type:        body.Type,
		Origin:      body.Origin,
		Producer:    body.Producer,
		Description: body.Description,
	}

	if err := utils.DB.Create(&cheese).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, cheese)
}

func CheeseIndex(c *gin.Context) {
	var cheeses []models.Cheese

	if err := utils.DB.Find(&cheeses).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, cheeses)
}

func CheeseDetails(c *gin.Context) {
	id := c.Param("id")

	cheese := models.Cheese{}

	if err := utils.DB.First(&cheese, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, cheese)
}

func CheeseEdit(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Name        string `json:"name"`
		Type        string `json:"type"`
		Origin      string `json:"origin"`
		Producer    string `json:"producer"`
		Description string `json:"description"`
	}
	c.Bind(&body)

	cheese := models.Cheese{}

	if err := utils.DB.First(&cheese, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := utils.DB.Model(&cheese).Updates(models.Cheese{
		Name:        body.Name,
		Type:        body.Type,
		Origin:      body.Origin,
		Producer:    body.Producer,
		Description: body.Description,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, cheese)
}

func CheeseRemove(c *gin.Context) {
	id := c.Param("id")

	if err := utils.DB.Delete(&models.Cheese{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusOK)
}

// ===== ADMIN ENDPOINTS =====

// GetCheeseDeleteImpact shows what will be affected if cheese is deleted
func GetCheeseDeleteImpact(c *gin.Context) {
	cheeseID := c.Param("id")

	// Check if cheese exists
	var cheese models.Cheese
	if err := utils.DB.First(&cheese, cheeseID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Cheese not found"})
		return
	}

	// Get all ratings for this cheese
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_type = ? AND item_id = ?", "cheese", cheeseID).Find(&ratings)

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

// DeleteCheese deletes a cheese and all associated ratings
func DeleteCheese(c *gin.Context) {
	cheeseID := c.Param("id")

	// Check if cheese exists
	var cheese models.Cheese
	if err := utils.DB.First(&cheese, cheeseID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Cheese not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings for this cheese
	var ratings []models.Rating
	tx.Where("item_type = ? AND item_id = ?", "cheese", cheeseID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Delete ratings
	tx.Where("item_type = ? AND item_id = ?", "cheese", cheeseID).Delete(&models.Rating{})

	// Delete the cheese
	if err := tx.Delete(&cheese).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete cheese"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "Cheese deleted successfully"})
}

// SeedCheeses bulk imports cheeses from remote URL or direct file upload
func SeedCheeses(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse cheese-specific JSON structure
	var jsonData struct {
		Cheeses []models.Cheese `json:"cheeses"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	// Import cheeses with cheese-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, cheese := range jsonData.Cheeses {
		// Check if cheese already exists (natural key: name)
		var existing models.Cheese
		err := utils.DB.Where("name = ?", cheese.Name).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		// Create new cheese
		if err := utils.DB.Create(&cheese).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", cheese.Name, err))
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

// ValidateCheeses validates JSON structure without importing
func ValidateCheeses(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse cheese-specific JSON structure
	var jsonData struct {
		Cheeses []models.Cheese `json:"cheeses"`
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

	// Validate cheese-specific requirements
	result := utils.ValidationResult{
		Valid:     true,
		Errors:    []string{},
		ItemCount: len(jsonData.Cheeses),
	}

	seen := make(map[string]bool)

	for i, cheese := range jsonData.Cheeses {
		// Check required fields for cheese
		if cheese.Name == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing name", i+1))
		}
		if cheese.Type == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing type", i+1))
		}

		// Check for duplicates within file (cheese natural key: name)
		key := cheese.Name
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
