package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func WineCreate(c *gin.Context) {
	var body struct {
		Name        string
		Producer    string
		Country     string
		Region      string
		Color       string
		Grape       string
		Alcohol     float64
		Description string
		Designation string
		Sugar       float64
		Organic     bool
	}
	c.Bind(&body)

	// Validate and convert color to enum
	wineColor := models.WineColor(body.Color)
	if !wineColor.IsValid() {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid wine color. Must be one of: Rouge, Blanc, Rosé, Mousseux, Orange"})
		return
	}

	wineItem := models.Wine{
		Name:        body.Name,
		Producer:    body.Producer,
		Country:     body.Country,
		Region:      body.Region,
		Color:       wineColor,
		Grape:       body.Grape,
		Alcohol:     body.Alcohol,
		Description: body.Description,
		Designation: body.Designation,
		Sugar:       body.Sugar,
		Organic:     body.Organic,
	}

	if err := utils.DB.Create(&wineItem).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, wineItem)
}

func WineIndex(c *gin.Context) {
	var wines []models.Wine

	if err := utils.DB.Find(&wines).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, wines)
}

func WineDetails(c *gin.Context) {
	id := c.Param("id")

	wineItem := models.Wine{}

	if err := utils.DB.First(&wineItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, wineItem)
}

func WineEdit(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Name        string
		Producer    string
		Country     string
		Region      string
		Color       string
		Grape       string
		Alcohol     float64
		Description string
		Designation string
		Sugar       float64
		Organic     bool
	}
	c.Bind(&body)

	// Validate and convert color to enum
	wineColor := models.WineColor(body.Color)
	if !wineColor.IsValid() {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid wine color. Must be one of: Rouge, Blanc, Rosé, Mousseux, Orange"})
		return
	}

	wineItem := models.Wine{}

	if err := utils.DB.First(&wineItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := utils.DB.Model(&wineItem).Updates(models.Wine{
		Name:        body.Name,
		Producer:    body.Producer,
		Country:     body.Country,
		Region:      body.Region,
		Color:       wineColor,
		Grape:       body.Grape,
		Alcohol:     body.Alcohol,
		Description: body.Description,
		Designation: body.Designation,
		Sugar:       body.Sugar,
		Organic:     body.Organic,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, wineItem)
}

func WineRemove(c *gin.Context) {
	id := c.Param("id")

	if err := utils.DB.Delete(&models.Wine{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusOK)
}

// ===== ADMIN ENDPOINTS =====

// GetWineDeleteImpact shows what will be affected if wine is deleted
func GetWineDeleteImpact(c *gin.Context) {
	wineID := c.Param("id")

	// Check if wine exists
	var wineItem models.Wine
	if err := utils.DB.First(&wineItem, wineID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wine not found"})
		return
	}

	// Get all ratings for this wine
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_type = ? AND item_id = ?", "wine", wineID).Find(&ratings)

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

// DeleteWine deletes a wine and all associated ratings
func DeleteWine(c *gin.Context) {
	wineID := c.Param("id")

	// Check if wine exists
	var wineItem models.Wine
	if err := utils.DB.First(&wineItem, wineID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wine not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings for this wine
	var ratings []models.Rating
	tx.Where("item_type = ? AND item_id = ?", "wine", wineID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Delete ratings
	tx.Where("item_type = ? AND item_id = ?", "wine", wineID).Delete(&models.Rating{})

	// Delete the wine
	if err := tx.Delete(&wineItem).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete wine"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "Wine deleted successfully"})
}

// SeedWines bulk imports wines from remote URL or direct file upload
func SeedWines(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse wine-specific JSON structure
	var jsonData struct {
		Wines []models.Wine `json:"wines"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	// Import wines with wine-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, wineItem := range jsonData.Wines {
		// Check if wine already exists (natural key: name + color)
		var existing models.Wine
		err := utils.DB.Where("name = ? AND color = ?", wineItem.Name, wineItem.Color).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		// Create new wine
		if err := utils.DB.Create(&wineItem).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", wineItem.Name, err))
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

// ValidateWines validates JSON structure without importing
func ValidateWines(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse wine-specific JSON structure
	var jsonData struct {
		Wines []models.Wine `json:"wines"`
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

	// Validate wine-specific requirements
	result := utils.ValidationResult{
		Valid:     true,
		Errors:    []string{},
		ItemCount: len(jsonData.Wines),
	}

	seen := make(map[string]bool)

	for i, wineItem := range jsonData.Wines {
		// Check required fields for wine
		if wineItem.Name == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing name", i+1))
		}
		if wineItem.Color == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing color", i+1))
		} else if !wineItem.Color.IsValid() {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: invalid color '%s'. Must be one of: Rouge, Blanc, Rosé, Mousseux, Orange", i+1, wineItem.Color))
		}
		if wineItem.Country == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing country", i+1))
		}

		// Check for duplicates within file (wine natural key: name + color)
		key := wineItem.Name + "|" + string(wineItem.Color)
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
