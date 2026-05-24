package controllers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/services"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

var schemaRegistry = services.GetSchemaRegistry()
var validationEngine = services.NewValidationEngine(schemaRegistry)
var queryBuilder = services.NewEAVQueryBuilder(schemaRegistry)

func parseFieldOptionsValue(options *string) interface{} {
	if options == nil || *options == "" || *options == "null" {
		return []interface{}{}
	}
	var arr []string
	if err := json.Unmarshal([]byte(*options), &arr); err != nil {
		return []interface{}{}
	}
	result := make([]interface{}, len(arr))
	for i, v := range arr {
		result[i] = map[string]interface{}{"value": v, "label": v}
	}
	return result
}

func parseFieldValidationValue(validation *string) interface{} {
	if validation == nil || *validation == "" || *validation == "null" {
		return []interface{}{}
	}
	var v interface{}
	if err := json.Unmarshal([]byte(*validation), &v); err != nil {
		return []interface{}{}
	}
	return v
}

func parseFieldDisplayValue(display *string) interface{} {
	if display == nil || *display == "" || *display == "null" {
		return map[string]interface{}{}
	}
	var v interface{}
	if err := json.Unmarshal([]byte(*display), &v); err != nil {
		return map[string]interface{}{}
	}
	return v
}

func parseUniqueFields(uniqueFields string) []string {
	if uniqueFields == "" || uniqueFields == "null" {
		return []string{}
	}
	var result []string
	if err := json.Unmarshal([]byte(uniqueFields), &result); err != nil {
		return []string{}
	}
	return result
}

func SchemaList(c *gin.Context) {
	includeCounts := c.Query("include_counts") == "true"
	includeInactive := c.Query("include_inactive") == "true"

	var response []map[string]interface{}

	// Pre-fetch item counts in a single query to avoid N+1
	var countMap map[uint]int64
	if includeCounts {
		type schemaCount struct {
			SchemaID uint
			Count    int64
		}
		var counts []schemaCount
		utils.DB.Model(&models.Item{}).
			Select("schema_id, COUNT(*) as count").
			Group("schema_id").
			Find(&counts)
		countMap = make(map[uint]int64, len(counts))
		for _, c := range counts {
			countMap[c.SchemaID] = c.Count
		}
	}

	schemas := schemaRegistry.GetAllSchemas()

	for _, cached := range schemas {
		if !includeInactive && !cached.Schema.IsActive {
			continue
		}

		fields := make([]map[string]interface{}, 0, len(cached.Fields))
		for _, field := range cached.Fields {
			fieldData := map[string]interface{}{
				"key":        field.Key,
				"label":      field.Label,
				"field_type": field.FieldType,
				"required":   field.Required,
				"order":      field.Order,
				"options":    parseFieldOptionsValue(field.Options),
				"validation": parseFieldValidationValue(field.Validation),
				"display":    parseFieldDisplayValue(field.Display),
			}
			if field.Group != nil {
				fieldData["group"] = *field.Group
			}
			fields = append(fields, fieldData)
		}

		schemaData := map[string]interface{}{
			"id":            cached.Schema.ID,
			"name":          cached.Schema.Name,
			"display_name":  cached.Schema.DisplayName,
			"plural_name":   cached.Schema.PluralName,
			"icon":          cached.Schema.Icon,
			"color":         cached.Schema.Color,
			"is_active":     cached.Schema.IsActive,
			"unique_fields": parseUniqueFields(cached.Schema.UniqueFields),
			"fields":        fields,
		}

		if includeCounts {
			schemaData["item_count"] = countMap[cached.Schema.ID]
		}

		response = append(response, schemaData)
	}

	c.JSON(http.StatusOK, gin.H{"schemas": response})
}

func SchemaDetails(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := schemaRegistry.GetSchema(schemaType)
	if !ok {
		var schema models.ItemTypeSchema
		if err := utils.DB.Where("name = ?", schemaType).First(&schema).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
			return
		}

		var fields []models.ItemTypeField
		utils.DB.Where("schema_id = ?", schema.ID).Order("`order` ASC").Find(&fields)

		response := buildSchemaDetailResponse(&schema, fields)
		c.JSON(http.StatusOK, response)
		return
	}

	fields := make([]map[string]interface{}, 0, len(cached.Fields))
	for _, field := range cached.Fields {
		fieldData := map[string]interface{}{
			"key":        field.Key,
			"label":      field.Label,
			"field_type": field.FieldType,
			"required":   field.Required,
			"order":      field.Order,
			"options":    parseFieldOptionsValue(field.Options),
			"validation": parseFieldValidationValue(field.Validation),
			"display":    parseFieldDisplayValue(field.Display),
		}

		if field.Group != nil {
			fieldData["group"] = *field.Group
		}

		fields = append(fields, fieldData)
	}

	var itemCount int64
	utils.DB.Model(&models.Item{}).Where("schema_id = ?", cached.Schema.ID).Count(&itemCount)

	var allVersions []models.SchemaVersion
	utils.DB.Where("schema_id = ?", cached.Schema.ID).Order("version ASC").Find(&allVersions)

	response := map[string]interface{}{
		"name":          cached.Schema.Name,
		"display_name":  cached.Schema.DisplayName,
		"plural_name":   cached.Schema.PluralName,
		"icon":          cached.Schema.Icon,
		"color":         cached.Schema.Color,
		"is_active":     cached.Schema.IsActive,
		"unique_fields": cached.UniqueFields,
		"version":       0,
		"version_hash":  cached.VersionHash,
		"item_count":    itemCount,
		"fields":        fields,
		"versions":      serializeVersions(allVersions),
	}

	if cached.Version != nil {
		response["version"] = cached.Version.Version
	}

	etagHeader := c.GetHeader("If-None-Match")
	if etagHeader != "" && etagHeader == cached.VersionHash {
		c.Status(http.StatusNotModified)
		return
	}

	c.Header("Cache-Control", "public, max-age=300")
	c.Header("ETag", cached.VersionHash)
	c.JSON(http.StatusOK, response)
}

func buildSchemaDetailResponse(schema *models.ItemTypeSchema, fields []models.ItemTypeField) map[string]interface{} {
	fieldsData := make([]map[string]interface{}, 0, len(fields))
	for _, field := range fields {
		fieldData := map[string]interface{}{
			"key":        field.Key,
			"label":      field.Label,
			"field_type": field.FieldType,
			"required":   field.Required,
			"order":      field.Order,
			"options":    parseFieldOptionsValue(field.Options),
			"validation": parseFieldValidationValue(field.Validation),
			"display":    parseFieldDisplayValue(field.Display),
		}
		if field.Group != nil {
			fieldData["group"] = *field.Group
		}
		fieldsData = append(fieldsData, fieldData)
	}

	var versionHash string
	var version int
	var schemaVersion models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND is_active = ?", schema.ID, true).First(&schemaVersion).Error; err == nil {
		version = schemaVersion.Version
		versionHash = services.GenerateVersionHash(&schemaVersion)
	}

	var itemCount int64
	utils.DB.Model(&models.Item{}).Where("schema_id = ?", schema.ID).Count(&itemCount)

	var allVersions []models.SchemaVersion
	utils.DB.Where("schema_id = ?", schema.ID).Order("version ASC").Find(&allVersions)

	var uniqueFields []string
	if schema.UniqueFields != "" {
		json.Unmarshal([]byte(schema.UniqueFields), &uniqueFields)
	}

	return map[string]interface{}{
		"name":          schema.Name,
		"display_name":  schema.DisplayName,
		"plural_name":   schema.PluralName,
		"icon":          schema.Icon,
		"color":         schema.Color,
		"is_active":     schema.IsActive,
		"unique_fields": uniqueFields,
		"version":       version,
		"version_hash":  versionHash,
		"item_count":    itemCount,
		"fields":        fieldsData,
		"versions":      serializeVersions(allVersions),
	}
}

func SchemaCreate(c *gin.Context) {
	var body struct {
		Name         string                   `json:"name"`
		DisplayName  string                   `json:"display_name"`
		PluralName   string                   `json:"plural_name"`
		Icon         string                   `json:"icon"`
		Color        string                   `json:"color"`
		UniqueFields []string                 `json:"unique_fields"`
		Fields       []map[string]interface{} `json:"fields"`
	}

	if err := c.Bind(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if body.Name == "" || body.DisplayName == "" || body.PluralName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "name, display_name, and plural_name are required"})
		return
	}

	var existingCount int64
	utils.DB.Model(&models.ItemTypeSchema{}).Where("name = ?", body.Name).Count(&existingCount)
	if existingCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Schema with this name already exists"})
		return
	}

	schema := models.ItemTypeSchema{
		Name:        body.Name,
		DisplayName: body.DisplayName,
		PluralName:  body.PluralName,
		Icon:        body.Icon,
		Color:       body.Color,
		IsActive:    true,
	}

	if len(body.UniqueFields) > 0 {
		uniqueFieldsJSON, err := json.Marshal(body.UniqueFields)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process unique fields"})
			return
		}
		schema.UniqueFields = string(uniqueFieldsJSON)
	} else {
		schema.UniqueFields = "[]"
	}

	tx := utils.DB.Begin()

	if err := tx.Create(&schema).Error; err != nil {
		tx.Rollback()
		if strings.Contains(err.Error(), "Duplicate") || strings.Contains(err.Error(), "UNIQUE") {
			c.JSON(http.StatusConflict, gin.H{"error": "A schema with this name already exists"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create schema"})
		return
	}

	for i, fieldData := range body.Fields {
		field := models.ItemTypeField{
			SchemaID:  schema.ID,
			Key:       getStringField(fieldData, "key"),
			Label:     getStringField(fieldData, "label"),
			FieldType: models.FieldType(getStringField(fieldData, "field_type")),
			Required:  getBoolField(fieldData, "required"),
			Order:     i,
		}

		if validation, ok := fieldData["validation"].(map[string]interface{}); ok {
			validationJSON, _ := json.Marshal(validation)
			s := string(validationJSON)
			field.Validation = &s
		}

		if display, ok := fieldData["display"].(map[string]interface{}); ok {
			displayJSON, _ := json.Marshal(display)
			s := string(displayJSON)
			field.Display = &s
		}

		if options, ok := fieldData["options"].([]interface{}); ok {
				optionsStr := make([]string, 0, len(options))
				for _, opt := range options {
					switch v := opt.(type) {
					case string:
						optionsStr = append(optionsStr, v)
					case map[string]interface{}:
						if val, found := v["value"]; found {
							if str, ok := val.(string); ok {
								optionsStr = append(optionsStr, str)
							}
						}
					}
				}
				optionsJSON, _ := json.Marshal(optionsStr)
				s := string(optionsJSON)
				field.Options = &s
			}

		if group, ok := fieldData["group"].(string); ok {
			field.Group = &group
		}

		if err := tx.Create(&field).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create field: " + field.Key})
			return
		}
	}

	version := models.SchemaVersion{
		SchemaID: schema.ID,
		Version:  1,
		IsActive: true,
	}

	fieldsJSON, err := json.Marshal(body.Fields)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process schema fields"})
		return
	}
	version.Fields = string(fieldsJSON)

	if err := tx.Create(&version).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create schema version"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to commit transaction"})
		return
	}

	if err := schemaRegistry.RefreshSchema(body.Name); err != nil {
		log.Printf("WARNING: failed to refresh schema cache for '%s': %v", body.Name, err)
	}

	c.JSON(http.StatusOK, schema)
}

func SchemaUpdate(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := schemaRegistry.GetSchema(schemaType)
	if !ok {
		var schema models.ItemTypeSchema
		if err := utils.DB.Where("name = ?", schemaType).First(&schema).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
			return
		}

		processSchemaUpdate(c, schema.ID, schema.Name)
		return
	}

	processSchemaUpdate(c, cached.Schema.ID, cached.Schema.Name)
}

func processSchemaUpdate(c *gin.Context, schemaID uint, schemaName string) {
	var body struct {
		DisplayName  string                   `json:"display_name"`
		PluralName   string                   `json:"plural_name"`
		Icon         string                   `json:"icon"`
		Color        string                   `json:"color"`
		IsActive     *bool                    `json:"is_active"`
		UniqueFields []string                 `json:"unique_fields"`
		Fields       []map[string]interface{} `json:"fields"`
	}

	if err := c.Bind(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	tx := utils.DB.Begin()

	updates := map[string]interface{}{}
	if body.DisplayName != "" {
		updates["display_name"] = body.DisplayName
	}
	if body.PluralName != "" {
		updates["plural_name"] = body.PluralName
	}
	if body.Icon != "" {
		updates["icon"] = body.Icon
	}
	if body.Color != "" {
		updates["color"] = body.Color
	}
	if body.IsActive != nil {
		updates["is_active"] = *body.IsActive
	}
	if body.UniqueFields != nil {
		uniqueFieldsJSON, err := json.Marshal(body.UniqueFields)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process unique fields"})
			return
		}
		updates["unique_fields"] = string(uniqueFieldsJSON)
	}
	if len(updates) > 0 {
		if err := tx.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Updates(updates).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update schema"})
			return
		}
	}

	if body.Fields != nil {
		if len(body.Fields) == 0 {
			// Empty fields array: delete all existing fields for this schema
			if err := tx.Where("schema_id = ?", schemaID).Delete(&models.ItemTypeField{}).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to delete existing fields"})
				return
			}
		} else {
			var currentVersion int
			tx.Model(&models.SchemaVersion{}).Where("schema_id = ?", schemaID).Select("MAX(version)").Scan(&currentVersion)
			newVersion := currentVersion + 1

			tx.Model(&models.SchemaVersion{}).Where("schema_id = ?", schemaID).Update("is_active", false)

			version := models.SchemaVersion{
				SchemaID: schemaID,
				Version:  newVersion,
				IsActive: true,
			}

			fieldsJSON, err := json.Marshal(body.Fields)
			if err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process schema fields"})
				return
			}
			version.Fields = string(fieldsJSON)

			if err := tx.Create(&version).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create schema version"})
				return
			}

			newKeys := make([]string, len(body.Fields))
			for i, fieldData := range body.Fields {
				fieldKey := getStringField(fieldData, "key")
				newKeys[i] = fieldKey

				var existingField models.ItemTypeField
				err := tx.Where("schema_id = ? AND `key` = ?", schemaID, fieldKey).First(&existingField).Error

				field := models.ItemTypeField{
					SchemaID:  schemaID,
					Key:       fieldKey,
					Label:     getStringField(fieldData, "label"),
					FieldType: models.FieldType(getStringField(fieldData, "field_type")),
					Required:  getBoolField(fieldData, "required"),
					Order:     i,
				}

				if validation, ok := fieldData["validation"].(map[string]interface{}); ok {
					validationJSON, _ := json.Marshal(validation)
					s := string(validationJSON)
					field.Validation = &s
				}

				if display, ok := fieldData["display"].(map[string]interface{}); ok {
					displayJSON, _ := json.Marshal(display)
					s := string(displayJSON)
					field.Display = &s
				}

				if options, ok := fieldData["options"].([]interface{}); ok {
					optionsStr := make([]string, 0, len(options))
					for _, opt := range options {
						switch v := opt.(type) {
						case string:
							optionsStr = append(optionsStr, v)
						case map[string]interface{}:
							if val, found := v["value"]; found {
								if str, ok := val.(string); ok {
									optionsStr = append(optionsStr, str)
								}
							}
						}
					}
					optionsJSON, _ := json.Marshal(optionsStr)
					s := string(optionsJSON)
					field.Options = &s
				}

				if group, ok := fieldData["group"].(string); ok {
					field.Group = &group
				}

				if err == nil {
					tx.Model(&existingField).Updates(map[string]interface{}{
						"label":      field.Label,
						"field_type": field.FieldType,
						"required":   field.Required,
						"order":      field.Order,
						"validation": field.Validation,
						"display":    field.Display,
						"options":    field.Options,
						"group":      field.Group,
					})
				} else {
					if err := tx.Create(&field).Error; err != nil {
						tx.Rollback()
						c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create field: " + field.Key})
						return
					}
				}
			}

			// Delete orphaned fields not present in the new field set
			if len(newKeys) > 0 {
				if err := tx.Where("schema_id = ? AND `key` NOT IN ?", schemaID, newKeys).Delete(&models.ItemTypeField{}).Error; err != nil {
					tx.Rollback()
					c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to delete orphaned fields"})
					return
				}
			}
		}
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to commit transaction"})
		return
	}

	if err := schemaRegistry.RefreshSchema(schemaName); err != nil {
		log.Printf("WARNING: failed to refresh schema cache for '%s': %v", schemaName, err)
	}

	var updatedSchema models.ItemTypeSchema
	utils.DB.Where("id = ?", schemaID).First(&updatedSchema)
	var fields []models.ItemTypeField
	utils.DB.Where("schema_id = ?", schemaID).Order("`order` ASC").Find(&fields)

	c.JSON(http.StatusOK, gin.H{
		"message": "Schema updated successfully",
		"schema":  buildSchemaDetailResponse(&updatedSchema, fields),
	})
}

func SchemaDelete(c *gin.Context) {
	schemaType := c.Param("type")

	cached, ok := schemaRegistry.GetSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	var itemCount int64
	utils.DB.Model(&models.Item{}).Where("schema_id = ?", cached.Schema.ID).Count(&itemCount)
	if itemCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete schema with existing items. Delete items first or deactivate the schema."})
		return
	}

	tx := utils.DB.Begin()

	if err := tx.Where("schema_id = ?", cached.Schema.ID).Delete(&models.ItemTypeField{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to delete schema fields"})
		return
	}

	if err := tx.Where("schema_id = ?", cached.Schema.ID).Delete(&models.SchemaVersion{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to delete schema versions"})
		return
	}

	if err := tx.Delete(&models.ItemTypeSchema{}, "id = ?", cached.Schema.ID).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to delete schema"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to commit transaction"})
		return
	}

	schemaRegistry.InvalidateSchema(schemaType)

	c.JSON(http.StatusOK, gin.H{"message": "Schema deleted successfully"})
}

func SchemaVersionHistory(c *gin.Context) {
	schemaType := c.Param("type")
	versionStr := c.Param("version")

	version, err := strconv.Atoi(versionStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid version number"})
		return
	}

	cached, ok := schemaRegistry.GetSchema(schemaType)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema not found"})
		return
	}

	var schemaVersion models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", cached.Schema.ID, version).First(&schemaVersion).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Schema version not found"})
		return
	}

	var fields []map[string]interface{}
	if err := json.Unmarshal([]byte(schemaVersion.Fields), &fields); err != nil {
		fields = []map[string]interface{}{}
	}

	c.JSON(http.StatusOK, gin.H{
		"version":     schemaVersion.Version,
		"fields":      fields,
		"is_active":   schemaVersion.IsActive,
		"created_at":  schemaVersion.CreatedAt,
	})
}

func serializeVersions(versions []models.SchemaVersion) []map[string]interface{} {
	result := make([]map[string]interface{}, len(versions))
	for i, v := range versions {
		var fields []map[string]interface{}
		if err := json.Unmarshal([]byte(v.Fields), &fields); err != nil {
			fields = []map[string]interface{}{}
		}
		result[i] = map[string]interface{}{
			"id":         v.ID,
			"schema_id":  v.SchemaID,
			"version":    v.Version,
			"fields":     fields,
			"is_active":  v.IsActive,
			"created_at": v.CreatedAt,
			"updated_at": v.UpdatedAt,
		}
	}
	return result
}

func getStringField(data map[string]interface{}, key string) string {
	if v, ok := data[key].(string); ok {
		return v
	}
	return ""
}

func getBoolField(data map[string]interface{}, key string) bool {
	if v, ok := data[key].(bool); ok {
		return v
	}
	return false
}
