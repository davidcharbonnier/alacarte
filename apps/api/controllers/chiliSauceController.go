package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

// ChiliSauceCreate handles creation of new chili sauce entries
func ChiliSauceCreate(c *gin.Context) {
	var body struct {
		Name        string `json:"name"`
		Brand       string `json:"brand"`
		SpiceLevel  string `json:"spiceLevel"`
		Chilis      string `json:"chilis"`
		Description string `json:"description"`
	}
	c.Bind(&body)

	chiliSauce := models.ChiliSauce{
		Name:        body.Name,
		Brand:       body.Brand,
		SpiceLevel:  models.SpiceLevel(body.SpiceLevel),
		Chilis:      body.Chilis,
		Description: body.Description,
	}

	if err := utils.DB.Create(&chiliSauce).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, chiliSauce)
}

// ChiliSauceIndex returns all chili sauces
func ChiliSauceIndex(c *gin.Context) {
	var chiliSauces []models.ChiliSauce

	if err := utils.DB.Find(&chiliSauces).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, chiliSauces)
}

// ChiliSauceDetails returns a specific chili sauce by ID
func ChiliSauceDetails(c *gin.Context) {
	var chiliSauce models.ChiliSauce

	id := c.Param("id")
	if err := utils.DB.First(&chiliSauce, id).Error; err != nil {
		c.JSON(http.StatusNotFound, "Chili sauce not found")
		return
	}

	c.JSON(http.StatusOK, chiliSauce)
}

// ChiliSauceEdit updates an existing chili sauce
func ChiliSauceEdit(c *gin.Context) {
	var chiliSauce models.ChiliSauce

	id := c.Param("id")
	if err := utils.DB.First(&chiliSauce, id).Error; err != nil {
		c.JSON(http.StatusNotFound, "Chili sauce not found")
		return
	}

	var body struct {
		Name        string `json:"name"`
		Brand       string `json:"brand"`
		SpiceLevel  string `json:"spiceLevel"`
		Chilis      string `json:"chilis"`
		Description string `json:"description"`
	}
	c.Bind(&body)

	chiliSauce.Name = body.Name
	chiliSauce.Brand = body.Brand
	chiliSauce.SpiceLevel = models.SpiceLevel(body.SpiceLevel)
	chiliSauce.Chilis = body.Chilis
	chiliSauce.Description = body.Description

	if err := utils.DB.Save(&chiliSauce).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, chiliSauce)
}

// ChiliSauceRemove deletes a chili sauce by ID
func ChiliSauceRemove(c *gin.Context) {
	var chiliSauce models.ChiliSauce

	id := c.Param("id")
	if err := utils.DB.First(&chiliSauce, id).Error; err != nil {
		c.JSON(http.StatusNotFound, "Chili sauce not found")
		return
	}

	if err := utils.DB.Delete(&chiliSauce).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusNoContent)
}

// GetChiliSauceDeleteImpact returns the impact of deleting a chili sauce (admin endpoint)
func GetChiliSauceDeleteImpact(c *gin.Context) {
	var chiliSauce models.ChiliSauce

	id := c.Param("id")
	if err := utils.DB.Preload("Ratings").First(&chiliSauce, id).Error; err != nil {
		c.JSON(http.StatusNotFound, "Chili sauce not found")
		return
	}

	impact := gin.H{
		"chiliSauce":  chiliSauce,
		"ratingCount": len(chiliSauce.Ratings),
		"userCount":   0,
	}

	// Count unique users affected
	if len(chiliSauce.Ratings) > 0 {
		userIDs := make(map[uint]bool)
		for _, rating := range chiliSauce.Ratings {
			userIDs[uint(rating.UserID)] = true
		}
		impact["userCount"] = len(userIDs)
	}

	c.JSON(http.StatusOK, impact)
}

// DeleteChiliSauce deletes a chili sauce with cascade (admin endpoint)
func DeleteChiliSauce(c *gin.Context) {
	var chiliSauce models.ChiliSauce

	id := c.Param("id")
	if err := utils.DB.First(&chiliSauce, id).Error; err != nil {
		c.JSON(http.StatusNotFound, "Chili sauce not found")
		return
	}

	// Delete with cascade (will delete associated ratings)
	if err := utils.DB.Select("Ratings").Delete(&chiliSauce).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusNoContent)
}

// SeedChiliSauces seeds chili sauces from JSON data (admin endpoint)
func SeedChiliSauces(c *gin.Context) {
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var chiliSauces []models.ChiliSauce
	if err := json.Unmarshal(data, &chiliSauces); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON format: " + err.Error()})
		return
	}

	seedResult := utils.SeedResult{}

	for _, chiliSauce := range chiliSauces {
		// Check if chili sauce already exists
		var existing models.ChiliSauce
		result := utils.DB.Where("name = ? AND brand = ?", chiliSauce.Name, chiliSauce.Brand).First(&existing)

		if result.Error != nil && result.Error.Error() != "record not found" {
			seedResult.Errors = append(seedResult.Errors, fmt.Sprintf("Database error for %s %s: %s", chiliSauce.Name, chiliSauce.Brand, result.Error.Error()))
			seedResult.Skipped++
			continue
		}

		if result.Error == nil {
			// Already exists, skip
			seedResult.Skipped++
			continue
		}

		// Create new chili sauce
		if err := utils.DB.Create(&chiliSauce).Error; err != nil {
			seedResult.Errors = append(seedResult.Errors, fmt.Sprintf("Failed to create %s %s: %s", chiliSauce.Name, chiliSauce.Brand, err.Error()))
			seedResult.Skipped++
		} else {
			seedResult.Added++
		}
	}

	c.JSON(http.StatusOK, seedResult)
}

// ValidateChiliSauces validates chili sauce JSON data without creating items (admin endpoint)
func ValidateChiliSauces(c *gin.Context) {
	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var chiliSauces []models.ChiliSauce
	if err := json.Unmarshal(data, &chiliSauces); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON format: " + err.Error()})
		return
	}

	validationResult := utils.ValidationResult{
		ItemCount: len(chiliSauces),
	}

	// Check for duplicates in the input data
	seen := make(map[string]bool)
	for _, chiliSauce := range chiliSauces {
		key := chiliSauce.Name + "|" + chiliSauce.Brand
		if seen[key] {
			validationResult.Duplicates++
			validationResult.Errors = append(validationResult.Errors, fmt.Sprintf("Duplicate entry: %s %s", chiliSauce.Name, chiliSauce.Brand))
		}
		seen[key] = true
	}

	if len(validationResult.Errors) == 0 {
		validationResult.Valid = true
	}

	c.JSON(http.StatusOK, validationResult)
}
