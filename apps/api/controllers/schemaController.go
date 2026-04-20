package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

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

func DebugOptions(c *gin.Context) {
	var field models.ItemTypeField
	if err := utils.DB.Where("`key` = ? AND schema_id = (SELECT id FROM item_type_schemas WHERE name = ?)", "color", "wine").First(&field).Error; err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{
		"options_ptr": fmt.Sprintf("%p", field.Options),
		"options_val": *field.Options,
		"options_hex": fmt.Sprintf("%x", *field.Options),
	})
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

func SchemaList(c *gin.Context) {
	includeCounts := c.Query("include_counts") == "true"
	includeInactive := c.Query("include_inactive") == "true"

	var response []map[string]interface{}

	if includeInactive {
		schemas, err := schemaRegistry.GetAllSchemasIncludingInactive()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load schemas"})
			return
		}

		for _, schema := range schemas {
			var fields []models.ItemTypeField
			utils.DB.Where("schema_id = ?", schema.ID).Order("`order` ASC").Find(&fields)

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

			schemaData := map[string]interface{}{
				"id":           schema.ID,
				"name":         schema.Name,
				"display_name": schema.DisplayName,
				"plural_name":  schema.PluralName,
				"icon":         schema.Icon,
				"color":        schema.Color,
				"is_active":    schema.IsActive,
				"fields":       fieldsData,
			}

			if includeCounts {
				var count int64
				utils.DB.Model(&models.Item{}).Where("schema_id = ?", schema.ID).Count(&count)
				schemaData["item_count"] = count
			}

			response = append(response, schemaData)
		}
	} else {
		schemas := schemaRegistry.GetAllSchemas()

		for _, cached := range schemas {
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
				"id":           cached.Schema.ID,
				"name":         cached.Schema.Name,
				"display_name": cached.Schema.DisplayName,
				"plural_name":  cached.Schema.PluralName,
				"icon":         cached.Schema.Icon,
				"color":        cached.Schema.Color,
				"is_active":    cached.Schema.IsActive,
				"fields":       fields,
			}

			if includeCounts {
				var count int64
				utils.DB.Model(&models.Item{}).Where("schema_id = ?", cached.Schema.ID).Count(&count)
				schemaData["item_count"] = count
			}

			response = append(response, schemaData)
		}
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
	}

	if cached.Version != nil {
		response["version"] = cached.Version.Version
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
		hashData := fmt.Sprintf("%d-%d-%s", schemaVersion.SchemaID, schemaVersion.Version, schemaVersion.Fields)
		versionHash = fmt.Sprintf("%x", hashData)
	}

	var itemCount int64
	utils.DB.Model(&models.Item{}).Where("schema_id = ?", schema.ID).Count(&itemCount)

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
		uniqueFieldsJSON, _ := json.Marshal(body.UniqueFields)
		schema.UniqueFields = string(uniqueFieldsJSON)
	}

	tx := utils.DB.Begin()

	if err := tx.Create(&schema).Error; err != nil {
		tx.Rollback()
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
			optionsStr := make([]string, len(options))
			for j, opt := range options {
				if str, ok := opt.(string); ok {
					optionsStr[j] = str
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

	fieldsJSON, _ := json.Marshal(body.Fields)
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

		processSchemaUpdate(c, schema.ID, schema.Name, true)
		return
	}

	processSchemaUpdate(c, cached.Schema.ID, cached.Schema.Name, false)
}

func processSchemaUpdate(c *gin.Context, schemaID uint, schemaName string, isInactive bool) {
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

	if body.DisplayName != "" {
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("display_name", body.DisplayName)
	}
	if body.PluralName != "" {
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("plural_name", body.PluralName)
	}
	if body.Icon != "" {
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("icon", body.Icon)
	}
	if body.Color != "" {
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("color", body.Color)
	}
	if body.IsActive != nil {
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("is_active", *body.IsActive)
	}
	if body.UniqueFields != nil {
		uniqueFieldsJSON, _ := json.Marshal(body.UniqueFields)
		utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", schemaID).Update("unique_fields", string(uniqueFieldsJSON))
	}

	if body.Fields != nil {
		var currentVersion int
		utils.DB.Model(&models.SchemaVersion{}).Where("schema_id = ?", schemaID).Select("MAX(version)").Scan(&currentVersion)
		newVersion := currentVersion + 1

		utils.DB.Model(&models.SchemaVersion{}).Where("schema_id = ?", schemaID).Update("is_active", false)

		version := models.SchemaVersion{
			SchemaID: schemaID,
			Version:  newVersion,
			IsActive: true,
		}

		fieldsJSON, _ := json.Marshal(body.Fields)
		version.Fields = string(fieldsJSON)

		if err := tx.Create(&version).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create schema version"})
			return
		}

		for i, fieldData := range body.Fields {
			fieldKey := getStringField(fieldData, "key")

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
				optionsStr := make([]string, len(options))
				for j, opt := range options {
					if str, ok := opt.(string); ok {
						optionsStr[j] = str
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
				utils.DB.Model(&existingField).Updates(map[string]interface{}{
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
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to commit transaction"})
		return
	}

	schemaRegistry.InvalidateSchema(schemaName)
	if err := schemaRegistry.RefreshSchema(schemaName); err != nil {
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

	c.JSON(http.StatusOK, gin.H{
		"version":     schemaVersion.Version,
		"fields":      schemaVersion.Fields,
		"is_active":   schemaVersion.IsActive,
		"migrated_at": schemaVersion.MigratedAt,
		"created_at":  schemaVersion.CreatedAt,
	})
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
