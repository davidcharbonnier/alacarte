package controllers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/services"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func getOrRefreshSchema(schemaType string) (*services.CachedSchema, bool) {
	cached, ok := schemaRegistry.GetActiveSchema(schemaType)
	if !ok {
		if err := schemaRegistry.RefreshSchema(schemaType); err != nil {
			log.Printf("WARNING: failed to refresh schema cache for '%s': %v", schemaType, err)
			return nil, false
		}
		cached, ok = schemaRegistry.GetActiveSchema(schemaType)
	}
	return cached, ok
}

func DynamicItemList(c *gin.Context) {
	schemaType := c.Param("type")

	if _, ok := getOrRefreshSchema(schemaType); !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	params := services.QueryParams{
		SchemaName: schemaType,
		Page:       page,
		PerPage:    perPage,
		Sort:       c.Query("sort"),
		Search:     c.Query("search"),
	}

	// Parse filter parameters from query string
	parsedFilters := parseFilterParams(c)
	if len(parsedFilters) > 0 {
		params.Filters = parsedFilters
	}

	if hasImage := c.Query("filter[has_image]"); hasImage != "" {
		val := hasImage == "true"
		params.HasImage = &val
	}

	if c.Query("rated") == "true" {
		if userID := utils.GetCurrentUserID(c); userID > 0 {
			params.Rated = true
			params.RatedByUserID = int(userID)
		}
	}

	result, err := queryBuilder.BuildListQuery(params)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"items":       result.Items,
		"total":       result.Total,
		"page":        result.Page,
		"per_page":    result.PerPage,
		"total_pages": result.TotalPages,
	})
}

func DynamicItemDetails(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	item, err := queryBuilder.GetItem(schemaType, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, item)
}

func DynamicItemCreate(c *gin.Context) {
	schemaType := c.Param("type")

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	cached, ok := getOrRefreshSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	if !cached.Schema.IsActive {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Schema is not active"})
		return
	}

	var body map[string]interface{}
	if err := c.Bind(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	fields := body
	if fieldValues, ok := body["field_values"].(map[string]interface{}); ok {
		fields = fieldValues
	}

	if name, ok := body["name"].(string); ok && name != "" {
		fields["name"] = name
	}

	validationResult := validationEngine.ValidateCreate(schemaType, fields)
	if !validationResult.Valid {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "validation_failed",
			"errors": validationResult.Errors,
		})
		return
	}

	item, err := queryBuilder.CreateItem(schemaType, userID, fields)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	createdItem, err := queryBuilder.GetItem(schemaType, item.ID)
	if err != nil {
		log.Printf("WARNING: failed to fetch item %d after create: %v", item.ID, err)
	}
	if createdItem != nil {
		c.JSON(http.StatusOK, createdItem)
	} else {
		c.JSON(http.StatusOK, item)
	}
}

func DynamicItemUpdate(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var body map[string]interface{}
	if err := c.Bind(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	fields := body
	if fieldValues, ok := body["field_values"].(map[string]interface{}); ok {
		fields = fieldValues
	}

	if name, ok := body["name"].(string); ok && name != "" {
		fields["name"] = name
	}

	validationResult := validationEngine.ValidateUpdate(schemaType, fields)
	if !validationResult.Valid {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "validation_failed",
			"errors": validationResult.Errors,
		})
		return
	}

	item, err := queryBuilder.UpdateItem(schemaType, uint(id), userID, fields)
	if err != nil {
		if err.Error() == "unauthorized" {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own items"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updatedItem, err := queryBuilder.GetItem(schemaType, item.ID)
	if err != nil {
		log.Printf("WARNING: failed to fetch item %d after update: %v", item.ID, err)
	}
	if updatedItem != nil {
		c.JSON(http.StatusOK, updatedItem)
	} else {
		c.JSON(http.StatusOK, item)
	}
}

func DynamicItemDelete(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	user, _ := utils.GetCurrentUser(c)
	isAdmin := false
	if user != nil {
		isAdmin = utils.IsUserAdmin(user)
	}

	if err := queryBuilder.DeleteItem(schemaType, uint(id), userID, isAdmin); err != nil {
		if err.Error() == "unauthorized" {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own items"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Item deleted successfully"})
}

func DynamicItemUploadImage(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	item, err := utils.GetDynamicItem(schemaType, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	if uint(item.(*models.Item).UserID) != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only manage images for your own items"})
		return
	}

	processAndSaveImage(c, item, schemaType)
}

func DynamicItemDeleteImage(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	item, err := utils.GetDynamicItem(schemaType, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	if uint(item.(*models.Item).UserID) != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only manage images for your own items"})
		return
	}

	// Delete image from storage
	imageURL := item.GetImageURL()
	if imageURL == nil || *imageURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Item has no image"})
		return
	}

	filename := utils.ExtractFilenameFromURL(*imageURL)
	if err := utils.DeleteFromStorage(filename); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete image"})
		return
	}

	// Clear image URL in database
	item.SetImageURL(nil)
	if err := utils.SaveItem(item); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update database"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Image deleted successfully"})
}

func DynamicItemDeleteImpact(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	impact, err := queryBuilder.GetDeleteImpact(schemaType, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, impact)
}

func DynamicItemSeed(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := getOrRefreshSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var rawData map[string]interface{}
	if err := json.Unmarshal(data, &rawData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	var items []map[string]interface{}

	if itemsData, ok := rawData["items"].([]interface{}); ok {
		for _, item := range itemsData {
			if itemMap, ok := item.(map[string]interface{}); ok {
				items = append(items, itemMap)
			}
		}
	} else {
		for _, key := range []string{"gins", "wines", "cheeses", "coffees", "chili_sauces", "chili-sauces"} {
			if itemsData, ok := rawData[key].([]interface{}); ok {
				for _, item := range itemsData {
					if itemMap, ok := item.(map[string]interface{}); ok {
						items = append(items, itemMap)
					}
				}
				break
			}
		}
	}

	if len(items) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No items to seed"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	result := utils.SeedResult{Errors: []string{}}

	for _, itemData := range items {
		filters := make(map[string]interface{})
		for _, key := range cached.UniqueFields {
			if val, exists := itemData[key]; exists {
				filters[key] = val
			}
		}

		if len(filters) > 0 {
			existingItems, err := queryBuilder.BuildListQuery(services.QueryParams{
				SchemaName: schemaType,
				Filters:    filters,
			})
			if err != nil {
				result.Errors = append(result.Errors, fmt.Sprintf("Failed to check duplicates: %v", err))
				continue
			}
			if existingItems.Total > 0 {
				result.Skipped++
				continue
			}
		}

		validationResult := validationEngine.ValidateCreate(schemaType, itemData)
		if !validationResult.Valid {
			result.Errors = append(result.Errors, fmt.Sprintf("Validation failed: %v", validationResult.Errors))
			continue
		}

		_, err := queryBuilder.CreateItem(schemaType, userID, itemData)
		if err != nil {
			nameVal := "unknown"
			if name, ok := itemData["name"].(string); ok {
				nameVal = name
			}
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", nameVal, err))
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

func DynamicItemValidate(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := getOrRefreshSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	data, err := utils.GetSeedData(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var rawData map[string]interface{}
	if err := json.Unmarshal(data, &rawData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	var items []map[string]interface{}

	if itemsData, ok := rawData["items"].([]interface{}); ok {
		for _, item := range itemsData {
			if itemMap, ok := item.(map[string]interface{}); ok {
				items = append(items, itemMap)
			}
		}
	} else {
		for _, key := range []string{"gins", "wines", "cheeses", "coffees", "chili_sauces", "chili-sauces"} {
			if itemsData, ok := rawData[key].([]interface{}); ok {
				for _, item := range itemsData {
					if itemMap, ok := item.(map[string]interface{}); ok {
						items = append(items, itemMap)
					}
				}
				break
			}
		}
	}

	result := struct {
		Valid     bool     `json:"valid"`
		Errors    []string `json:"errors"`
		ItemCount int      `json:"item_count"`
	}{
		Valid:     true,
		Errors:    []string{},
		ItemCount: len(items),
	}

	for i, itemData := range items {
		validationResult := validationEngine.ValidateCreate(schemaType, itemData)
		if !validationResult.Valid {
			result.Valid = false
			for _, err := range validationResult.Errors {
				result.Errors = append(result.Errors, fmt.Sprintf("Item %d: %s", i+1, err.Message))
			}
		}

		for _, key := range cached.UniqueFields {
			if _, exists := itemData[key]; !exists {
				result.Valid = false
				result.Errors = append(result.Errors, fmt.Sprintf("Item %d: missing unique field '%s'", i+1, key))
			}
		}
	}

	c.JSON(http.StatusOK, result)
}

func parseFilterParams(c *gin.Context) map[string]interface{} {
	result := make(map[string]interface{})
	for key, values := range c.Request.URL.Query() {
		if strings.HasPrefix(key, "filter[") && strings.HasSuffix(key, "]") {
			fieldKey := key[7 : len(key)-1]
			if len(values) > 0 && values[0] != "" {
				result[fieldKey] = values[0]
			}
		}
	}
	return result
}

func GetTypeStats(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := getOrRefreshSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var totalItems int64
	utils.DB.Model(&models.Item{}).
		Where("schema_id = ?", cached.Schema.ID).
		Count(&totalItems)

	var userRatedCount int64
	utils.DB.Model(&models.Rating{}).
		Joins("JOIN items ON items.id = ratings.item_id").
		Where("items.schema_id = ? AND ratings.user_id = ?", cached.Schema.ID, userID).
		Distinct("ratings.item_id").
		Count(&userRatedCount)

	c.JSON(http.StatusOK, gin.H{
		"total_items":      totalItems,
		"user_rated_count": userRatedCount,
	})
}
