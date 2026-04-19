package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/davidcharbonnier/alacarte-api/services"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

var schemaRegistryItems = services.GetSchemaRegistry()
var validationEngineItems = services.NewValidationEngine(schemaRegistryItems)
var queryBuilderItems = services.NewEAVQueryBuilder(schemaRegistryItems)

func DynamicItemList(c *gin.Context) {
	schemaType := c.Param("type")

	if _, ok := schemaRegistryItems.GetSchema(schemaType); !ok {
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

	if filterStr := c.Query("filter"); filterStr != "" {
		parsedFilters := parseFilterParams(filterStr)
		params.Filters = parsedFilters
	}

	if hasImage := c.Query("filter[has_image]"); hasImage != "" {
		val := hasImage == "true"
		params.HasImage = &val
	}

	result, err := queryBuilderItems.BuildListQuery(params)
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

	item, err := queryBuilderItems.GetItem(schemaType, uint(id))
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

	cached, ok := schemaRegistryItems.GetSchema(schemaType)
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

	validationResult := validationEngineItems.ValidateCreate(schemaType, body)
	if !validationResult.Valid {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "validation_failed",
			"errors": validationResult.Errors,
		})
		return
	}

	item, err := queryBuilderItems.CreateItem(schemaType, userID, body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	createdItem, _ := queryBuilderItems.GetItem(schemaType, item.ID)
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

	validationResult := validationEngineItems.ValidateUpdate(schemaType, body)
	if !validationResult.Valid {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":  "validation_failed",
			"errors": validationResult.Errors,
		})
		return
	}

	item, err := queryBuilderItems.UpdateItem(schemaType, uint(id), userID, body)
	if err != nil {
		if err.Error() == "unauthorized" {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own items"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updatedItem, _ := queryBuilderItems.GetItem(schemaType, item.ID)
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

	if err := queryBuilderItems.DeleteItem(schemaType, uint(id), userID, isAdmin); err != nil {
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

	if _, err := strconv.ParseUint(idStr, 10, 32); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	c.Params = append(c.Params, gin.Param{Key: "itemType", Value: schemaType})
	c.Params = append(c.Params, gin.Param{Key: "itemId", Value: idStr})
	UploadItemImage(c)
}

func DynamicItemDeleteImage(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	if _, err := strconv.ParseUint(idStr, 10, 32); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	userID := utils.GetCurrentUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	c.Params = append(c.Params, gin.Param{Key: "itemType", Value: schemaType})
	c.Params = append(c.Params, gin.Param{Key: "itemId", Value: idStr})
	DeleteItemImage(c)
}

func DynamicItemDeleteImpact(c *gin.Context) {
	schemaType := c.Param("type")
	idStr := c.Param("id")

	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	impact, err := queryBuilderItems.GetDeleteImpact(schemaType, uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, impact)
}

func DynamicItemSeed(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := schemaRegistryItems.GetSchema(schemaType)
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
		userID = 1
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
			existingItems, _ := queryBuilderItems.BuildListQuery(services.QueryParams{
				SchemaName: schemaType,
				Filters:    filters,
			})
			if existingItems.Total > 0 {
				result.Skipped++
				continue
			}
		}

		validationResult := validationEngineItems.ValidateCreate(schemaType, itemData)
		if !validationResult.Valid {
			result.Errors = append(result.Errors, fmt.Sprintf("Validation failed: %v", validationResult.Errors))
			continue
		}

		_, err := queryBuilderItems.CreateItem(schemaType, userID, itemData)
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

	cached, ok := schemaRegistryItems.GetSchema(schemaType)
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
		validationResult := validationEngineItems.ValidateCreate(schemaType, itemData)
		if !validationResult.Valid {
			result.Valid = false
			for _, err := range validationResult.Errors {
				result.Errors = append(result.Errors, fmt.Sprintf("Item %d: %v", i+1, err))
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

func parseFilterParams(filterStr string) map[string]interface{} {
	result := make(map[string]interface{})
	return result
}
