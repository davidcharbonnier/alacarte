package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func CoffeeCreate(c *gin.Context) {
	var body struct {
		Name             string                         `json:"name"`
		Roaster          string                         `json:"roaster"`
		Country          string                         `json:"country"`
		Region           string                         `json:"region"`
		Farm             string                         `json:"farm"`
		Altitude         string                         `json:"altitude"`
		Species          models.CoffeeSpecies           `json:"species"`
		Variety          string                         `json:"variety"`
		ProcessingMethod models.CoffeeProcessingMethod  `json:"processing_method"`
		Decaffeinated    bool                           `json:"decaffeinated"`
		RoastLevel       models.CoffeeRoastLevel        `json:"roast_level"`
		TastingNotes     models.StringArray             `json:"tasting_notes"`
		Acidity          models.CoffeeIntensityLevel    `json:"acidity"`
		Body             models.CoffeeIntensityLevel    `json:"body"`
		Sweetness        models.CoffeeIntensityLevel    `json:"sweetness"`
		Organic          bool                           `json:"organic"`
		FairTrade        bool                           `json:"fair_trade"`
		Description      string                         `json:"description"`
	}
	c.Bind(&body)

	coffeeItem := models.Coffee{
		Name:             body.Name,
		Roaster:          body.Roaster,
		Country:          body.Country,
		Region:           body.Region,
		Farm:             body.Farm,
		Altitude:         body.Altitude,
		Species:          body.Species,
		Variety:          body.Variety,
		ProcessingMethod: body.ProcessingMethod,
		Decaffeinated:    body.Decaffeinated,
		RoastLevel:       body.RoastLevel,
		TastingNotes:     body.TastingNotes,
		Acidity:          body.Acidity,
		Body:             body.Body,
		Sweetness:        body.Sweetness,
		Organic:          body.Organic,
		FairTrade:        body.FairTrade,
		Description:      body.Description,
	}

	if err := utils.DB.Create(&coffeeItem).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, coffeeItem)
}

func CoffeeIndex(c *gin.Context) {
	var coffees []models.Coffee

	if err := utils.DB.Find(&coffees).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, coffees)
}

func CoffeeDetails(c *gin.Context) {
	id := c.Param("id")

	coffeeItem := models.Coffee{}

	if err := utils.DB.First(&coffeeItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, coffeeItem)
}

func CoffeeEdit(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Name             string                         `json:"name"`
		Roaster          string                         `json:"roaster"`
		Country          string                         `json:"country"`
		Region           string                         `json:"region"`
		Farm             string                         `json:"farm"`
		Altitude         string                         `json:"altitude"`
		Species          models.CoffeeSpecies           `json:"species"`
		Variety          string                         `json:"variety"`
		ProcessingMethod models.CoffeeProcessingMethod  `json:"processing_method"`
		Decaffeinated    bool                           `json:"decaffeinated"`
		RoastLevel       models.CoffeeRoastLevel        `json:"roast_level"`
		TastingNotes     models.StringArray             `json:"tasting_notes"`
		Acidity          models.CoffeeIntensityLevel    `json:"acidity"`
		Body             models.CoffeeIntensityLevel    `json:"body"`
		Sweetness        models.CoffeeIntensityLevel    `json:"sweetness"`
		Organic          bool                           `json:"organic"`
		FairTrade        bool                           `json:"fair_trade"`
		Description      string                         `json:"description"`
	}
	c.Bind(&body)

	coffeeItem := models.Coffee{}

	if err := utils.DB.First(&coffeeItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := utils.DB.Model(&coffeeItem).Updates(models.Coffee{
		Name:             body.Name,
		Roaster:          body.Roaster,
		Country:          body.Country,
		Region:           body.Region,
		Farm:             body.Farm,
		Altitude:         body.Altitude,
		Species:          body.Species,
		Variety:          body.Variety,
		ProcessingMethod: body.ProcessingMethod,
		Decaffeinated:    body.Decaffeinated,
		RoastLevel:       body.RoastLevel,
		TastingNotes:     body.TastingNotes,
		Acidity:          body.Acidity,
		Body:             body.Body,
		Sweetness:        body.Sweetness,
		Organic:          body.Organic,
		FairTrade:        body.FairTrade,
		Description:      body.Description,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, coffeeItem)
}

func CoffeeRemove(c *gin.Context) {
	id := c.Param("id")

	if err := utils.DB.Delete(&models.Coffee{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusOK)
}

// ===== ADMIN ENDPOINTS =====

// GetCoffeeDeleteImpact shows what will be affected if coffee is deleted
func GetCoffeeDeleteImpact(c *gin.Context) {
	coffeeID := c.Param("id")

	// Check if coffee exists
	var coffeeItem models.Coffee
	if err := utils.DB.First(&coffeeItem, coffeeID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Coffee not found"})
		return
	}

	// Get all ratings for this coffee
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_type = ? AND item_id = ?", "coffee", coffeeID).Find(&ratings)

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

// DeleteCoffee deletes a coffee and all associated ratings
func DeleteCoffee(c *gin.Context) {
	coffeeID := c.Param("id")

	// Check if coffee exists
	var coffeeItem models.Coffee
	if err := utils.DB.First(&coffeeItem, coffeeID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Coffee not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings for this coffee
	var ratings []models.Rating
	tx.Where("item_type = ? AND item_id = ?", "coffee", coffeeID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Delete ratings
	tx.Where("item_type = ? AND item_id = ?", "coffee", coffeeID).Delete(&models.Rating{})

	// Delete the coffee
	if err := tx.Delete(&coffeeItem).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete coffee"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "Coffee deleted successfully"})
}

// SeedCoffees bulk imports coffees from remote URL or direct file upload
func SeedCoffees(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse coffee-specific JSON structure
	var jsonData struct {
		Coffees []models.Coffee `json:"coffees"`
	}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	// Import coffees with coffee-specific natural key logic
	result := utils.SeedResult{Errors: []string{}}

	for _, coffeeItem := range jsonData.Coffees {
		// Check if coffee already exists (natural key: name + roaster)
		var existing models.Coffee
		err := utils.DB.Where("name = ? AND roaster = ?", coffeeItem.Name, coffeeItem.Roaster).First(&existing).Error

		if err == nil {
			// Already exists - skip
			result.Skipped++
			continue
		}

		// Create new coffee
		if err := utils.DB.Create(&coffeeItem).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", coffeeItem.Name, err))
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

// ValidateCoffees validates JSON structure without importing
func ValidateCoffees(c *gin.Context) {
	// Use generic helper to get data from either URL or direct upload
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse coffee-specific JSON structure
	var jsonData struct {
		Coffees []models.Coffee `json:"coffees"`
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

	// Validate coffee-specific requirements
	result := utils.ValidationResult{
		Valid:     true,
		Errors:    []string{},
		ItemCount: len(jsonData.Coffees),
	}

	seen := make(map[string]bool)

	for i, coffeeItem := range jsonData.Coffees {
		// Check required fields for coffee (only name and roaster are required)
		if coffeeItem.Name == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing name", i+1))
		}
		if coffeeItem.Roaster == "" {
			result.Valid = false
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing roaster", i+1))
		}

		// Check for duplicates within file (coffee natural key: name + roaster)
		key := coffeeItem.Name + "|" + coffeeItem.Roaster
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
