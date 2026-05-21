package services

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"gorm.io/gorm"
)

type EAVQueryBuilder struct {
	registry *SchemaRegistry
}

func NewEAVQueryBuilder(registry *SchemaRegistry) *EAVQueryBuilder {
	return &EAVQueryBuilder{
		registry: registry,
	}
}

type QueryParams struct {
	SchemaName string
	Page       int
	PerPage    int
	Sort       string
	Search     string
	Filters    map[string]interface{}
	HasImage   *bool
}

type ListResult struct {
	Items      []map[string]interface{}
	Total      int64
	Page       int
	PerPage    int
	TotalPages int
}

func (qb *EAVQueryBuilder) getCachedSchema(schemaName string) (*CachedSchema, error) {
	cached, ok := qb.registry.GetActiveSchema(schemaName)
	if !ok {
		if err := qb.registry.RefreshSchema(schemaName); err != nil {
			return nil, fmt.Errorf("schema '%s' not found", schemaName)
		}
		cached, ok = qb.registry.GetActiveSchema(schemaName)
		if !ok {
			return nil, fmt.Errorf("schema '%s' not found", schemaName)
		}
	}
	return cached, nil
}

func (qb *EAVQueryBuilder) BuildListQuery(params QueryParams) (*ListResult, error) {
	cached, err := qb.getCachedSchema(params.SchemaName)
	if err != nil {
		return nil, err
	}

	if params.Page < 1 {
		params.Page = 1
	}
	if params.PerPage < 1 {
		params.PerPage = 20
	}
	if params.PerPage > 100 {
		params.PerPage = 100
	}

	var total int64
	var items []models.Item

	err = utils.DB.Transaction(func(tx *gorm.DB) error {
		query := tx.Model(&models.Item{}).Where("schema_id = ?", cached.Schema.ID)

		if params.HasImage != nil {
			if *params.HasImage {
				query = query.Where("image_url IS NOT NULL AND image_url != ''")
			} else {
				query = query.Where("image_url IS NULL OR image_url = ''")
			}
		}

		if params.Search != "" {
			searchTerm := strings.ToLower(params.Search)
			eavSubquery := tx.Model(&models.ItemFieldValue{}).
				Select("item_id").
				Where("field_id IN (?)",
					tx.Model(&models.ItemTypeField{}).
						Select("id").
						Where("schema_id = ? AND display LIKE ?", cached.Schema.ID, "%\"searchable\":true%"))
			query = query.Where("id IN (?) OR LOWER(field_values) LIKE ?", eavSubquery, "%"+searchTerm+"%")
		}

		if params.Filters != nil {
			for key, value := range params.Filters {
				field, found := qb.registry.GetFieldByKey(params.SchemaName, key)
				if !found {
					continue
				}

				eavQuery := tx.Model(&models.ItemFieldValue{}).
					Select("item_id").
					Where("field_id = ?", field.ID)

				switch v := value.(type) {
				case string:
					if v != "" {
						eavQuery = eavQuery.Where("value = ?", v)
					}
				case []string:
					if len(v) > 0 {
						eavQuery = eavQuery.Where("value IN (?)", v)
					}
				default:
					eavQuery = eavQuery.Where("value = ?", fmt.Sprintf("%v", v))
				}

				query = query.Where("id IN (?)", eavQuery)
			}
		}

		if err := query.Count(&total).Error; err != nil {
			return err
		}

		sortField := "name"
		sortDir := "ASC"
		if params.Sort != "" {
			if strings.HasPrefix(params.Sort, "-") {
				sortDir = "DESC"
				sortField = strings.TrimPrefix(params.Sort, "-")
			} else {
				sortField = params.Sort
			}
		}

		switch sortField {
		case "created_at", "updated_at", "name":
			query = query.Order(fmt.Sprintf("%s %s", sortField, sortDir))
		default:
			if field, found := qb.registry.GetFieldByKey(params.SchemaName, sortField); found {
				query = query.
					Joins("LEFT JOIN item_field_values ON items.id = item_field_values.item_id AND item_field_values.field_id = ?", field.ID).
					Order(fmt.Sprintf("item_field_values.value %s", sortDir))
			} else {
				query = query.Order("name ASC")
			}
		}

		offset := (params.Page - 1) * params.PerPage
		query = query.Offset(offset).Limit(params.PerPage)

		if err := query.Preload("FieldValuesRows").Find(&items).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to query items: %w", err)
	}

	resultItems := make([]map[string]interface{}, len(items))
	for i, item := range items {
		resultItems[i] = qb.buildItemMap(&item, cached)
	}

	totalPages := int(total) / params.PerPage
	if int(total)%params.PerPage > 0 {
		totalPages++
	}

	return &ListResult{
		Items:      resultItems,
		Total:      total,
		Page:       params.Page,
		PerPage:    params.PerPage,
		TotalPages: totalPages,
	}, nil
}

func (qb *EAVQueryBuilder) GetItem(schemaName string, itemID uint) (*map[string]interface{}, error) {
	cached, err := qb.getCachedSchema(schemaName)
	if err != nil {
		return nil, err
	}

	var item models.Item
	if err := utils.DB.
		Preload("FieldValuesRows").
		Where("id = ? AND schema_id = ?", itemID, cached.Schema.ID).
		First(&item).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("item not found")
		}
		return nil, fmt.Errorf("failed to get item: %w", err)
	}

	result := qb.buildItemMap(&item, cached)
	return &result, nil
}

func (qb *EAVQueryBuilder) buildItemMap(item *models.Item, cached *CachedSchema) map[string]interface{} {
	result := map[string]interface{}{
		"id":          item.ID,
		"name":        item.Name,
		"schema_type": cached.Schema.Name,
		"image_url":   item.ImageURL,
		"user_id":     item.UserID,
		"created_at":  item.CreatedAt,
		"updated_at":  item.UpdatedAt,
	}

	if item.FieldValues != "" {
		var fieldValues map[string]interface{}
		if err := json.Unmarshal([]byte(item.FieldValues), &fieldValues); err == nil {
			result["field_values"] = fieldValues
		}
	}

	for _, fv := range item.FieldValuesRows {
		for _, field := range cached.Fields {
			if field.ID == fv.FieldID && fv.Value != nil {
				if _, exists := result[field.Key]; !exists {
					switch field.FieldType {
					case models.FieldTypeNumber:
						if num, err := strconv.ParseFloat(*fv.Value, 64); err == nil {
							result[field.Key] = num
						} else {
							result[field.Key] = *fv.Value
						}
					case models.FieldTypeCheckbox:
						result[field.Key] = *fv.Value == "true" || *fv.Value == "1"
					default:
						result[field.Key] = *fv.Value
					}
				}
			}
		}
	}

	return result
}

func (qb *EAVQueryBuilder) checkUniqueness(cached *CachedSchema, fields map[string]interface{}, excludeItemID *uint) (bool, error) {
	if len(cached.UniqueFields) == 0 {
		return true, nil
	}

	uniqueFieldValues := make(map[string]interface{})
	hasAllFields := true
	for _, fieldKey := range cached.UniqueFields {
		if value, exists := fields[fieldKey]; exists && value != nil {
			uniqueFieldValues[fieldKey] = fmt.Sprintf("%v", value)
		} else {
			hasAllFields = false
			break
		}
	}

	if !hasAllFields || len(uniqueFieldValues) == 0 {
		return true, nil
	}

	query := utils.DB.Model(&models.Item{}).Where("schema_id = ?", cached.Schema.ID)

	if excludeItemID != nil {
		query = query.Where("id != ?", *excludeItemID)
	}

	for fieldKey, value := range uniqueFieldValues {
		if fieldKey == "name" {
			query = query.Where("name = ?", value)
		} else {
			field, found := qb.registry.GetFieldByKey(cached.Schema.Name, fieldKey)
			if !found {
				continue
			}

			subquery := utils.DB.Model(&models.ItemFieldValue{}).
				Select("item_id").
				Where("field_id = ? AND value = ?", field.ID, value)

			query = query.Where("id IN (?)", subquery)
		}
	}

	var count int64
	if err := query.Count(&count).Error; err != nil {
		return false, fmt.Errorf("failed to check uniqueness: %w", err)
	}

	return count == 0, nil
}

func (qb *EAVQueryBuilder) CreateItem(schemaName string, userID uint, fields map[string]interface{}) (*models.Item, error) {
	cached, err := qb.getCachedSchema(schemaName)
	if err != nil {
		return nil, err
	}

	unique, err := qb.checkUniqueness(cached, fields, nil)
	if err != nil {
		return nil, err
	}
	if !unique {
		return nil, fmt.Errorf("duplicate item")
	}

	item := &models.Item{
		SchemaID: cached.Schema.ID,
		UserID:   int(userID),
	}

	if name, ok := fields["name"].(string); ok {
		item.Name = name
	}

	if imageURL, ok := fields["image_url"].(string); ok {
		item.ImageURL = &imageURL
	}

	if cached.Version != nil {
		item.SchemaVersionID = &cached.Version.ID
	}

	fieldValuesJSON, err := json.Marshal(fields)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal field values: %w", err)
	}
	item.FieldValues = string(fieldValuesJSON)

	tx := utils.DB.Begin()

	if err := tx.Create(item).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to create item: %w", err)
	}

	for _, field := range cached.Fields {
		if value, exists := fields[field.Key]; exists {
			var valueStr *string
			if value != nil {
				str := fmt.Sprintf("%v", value)
				valueStr = &str
			}

			fv := models.ItemFieldValue{
				ItemID:  item.ID,
				FieldID: field.ID,
				Value:   valueStr,
			}
			if err := tx.Create(&fv).Error; err != nil {
				tx.Rollback()
				return nil, fmt.Errorf("failed to create field value: %w", err)
			}
		}
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return item, nil
}

func (qb *EAVQueryBuilder) UpdateItem(schemaName string, itemID uint, userID uint, fields map[string]interface{}) (*models.Item, error) {
	cached, err := qb.getCachedSchema(schemaName)
	if err != nil {
		return nil, err
	}

	var item models.Item
	if err := utils.DB.Where("id = ? AND schema_id = ?", itemID, cached.Schema.ID).First(&item).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("item not found")
		}
		return nil, fmt.Errorf("failed to get item: %w", err)
	}

	if userID != uint(item.UserID) {
		return nil, fmt.Errorf("unauthorized")
	}

	unique, err := qb.checkUniqueness(cached, fields, &itemID)
	if err != nil {
		return nil, err
	}
	if !unique {
		return nil, fmt.Errorf("duplicate item")
	}

	if name, ok := fields["name"].(string); ok {
		item.Name = name
	}

	if imageURL, ok := fields["image_url"].(string); ok {
		item.ImageURL = &imageURL
	}

	tx := utils.DB.Begin()

	for _, field := range cached.Fields {
		if value, exists := fields[field.Key]; exists {
			var valueStr *string
			if value != nil {
				str := fmt.Sprintf("%v", value)
				valueStr = &str
			}

			var fv models.ItemFieldValue
			err := tx.Where("item_id = ? AND field_id = ?", item.ID, field.ID).First(&fv).Error
			if err == gorm.ErrRecordNotFound {
				if valueStr != nil {
					fv = models.ItemFieldValue{
						ItemID:  item.ID,
						FieldID: field.ID,
						Value:   valueStr,
					}
					if err := tx.Create(&fv).Error; err != nil {
						tx.Rollback()
						return nil, fmt.Errorf("failed to create field value: %w", err)
					}
				}
			} else {
				if valueStr != nil {
					fv.Value = valueStr
					if err := tx.Save(&fv).Error; err != nil {
						tx.Rollback()
						return nil, fmt.Errorf("failed to update field value: %w", err)
					}
				} else {
					if err := tx.Delete(&fv).Error; err != nil {
						tx.Rollback()
						return nil, fmt.Errorf("failed to delete field value: %w", err)
					}
				}
			}
		}
	}

	// Rebuild field_values JSON from all EAV rows to ensure completeness after partial updates
	var allFieldValues []models.ItemFieldValue
	if err := tx.Where("item_id = ?", item.ID).Find(&allFieldValues).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to read field values: %w", err)
	}
	fieldValuesJSON, err := BuildFieldValuesJSON(allFieldValues, cached.Fields)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to build field values JSON: %w", err)
	}
	item.FieldValues = fieldValuesJSON
	if err := tx.Save(&item).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to update item: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &item, nil
}

func (qb *EAVQueryBuilder) DeleteItem(schemaName string, itemID uint, userID uint, isAdmin bool) error {
	cached, err := qb.getCachedSchema(schemaName)
	if err != nil {
		return err
	}

	var item models.Item
	if err := utils.DB.Where("id = ? AND schema_id = ?", itemID, cached.Schema.ID).First(&item).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("item not found")
		}
		return fmt.Errorf("failed to get item: %w", err)
	}

	if !isAdmin && uint(item.UserID) != userID {
		return fmt.Errorf("unauthorized")
	}

	tx := utils.DB.Begin()

	if err := tx.Delete(&models.ItemFieldValue{}, "item_id = ?", itemID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to delete field values: %w", err)
	}

	if err := tx.Delete(&item).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to delete item: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

func (qb *EAVQueryBuilder) GetDeleteImpact(schemaName string, itemID uint) (map[string]interface{}, error) {
	cached, err := qb.getCachedSchema(schemaName)
	if err != nil {
		return nil, err
	}

	var item models.Item
	if err := utils.DB.Where("id = ? AND schema_id = ?", itemID, cached.Schema.ID).First(&item).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("item not found")
		}
		return nil, fmt.Errorf("failed to get item: %w", err)
	}

	// Get all ratings for this item with user data
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_id = ?", itemID).Find(&ratings)

	// Count unique users affected and build user details
	userMap := make(map[uint]bool)
	userDetails := make(map[uint]struct {
		ID           uint
		DisplayName  string
		RatingsCount int
	})

	// Batch query sharing counts to avoid N+1
	ratingIDs := make([]uint, len(ratings))
	for i, rating := range ratings {
		ratingIDs[i] = rating.ID
	}

	type sharingCount struct {
		RatingID uint
		Count    int64
	}
	var sharingCounts []sharingCount
	utils.DB.Table("rating_viewers").
		Select("rating_id, COUNT(*) as count").
		Where("rating_id IN (?)", ratingIDs).
		Group("rating_id").
		Find(&sharingCounts)

	countMap := make(map[uint]int64, len(sharingCounts))
	for _, sc := range sharingCounts {
		countMap[sc.RatingID] = sc.Count
	}

	var sharingsCount int64
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

		sharingsCount += countMap[rating.ID]
	}

	// Build affected users list
	affectedUsers := []map[string]interface{}{}
	for _, user := range userDetails {
		affectedUsers = append(affectedUsers, map[string]interface{}{
			"id":            user.ID,
			"display_name":  user.DisplayName,
			"ratings_count": user.RatingsCount,
		})
	}

	return map[string]interface{}{
		"can_delete": true,
		"warnings": []string{
			"This will permanently delete all ratings for this item",
			"Users who rated this item will lose their ratings",
		},
		"impact": map[string]interface{}{
			"ratings_count":  len(ratings),
			"users_affected": len(userMap),
			"sharings_count": sharingsCount,
			"affected_users": affectedUsers,
		},
	}, nil
}

func BuildFieldValuesJSON(fieldValues []models.ItemFieldValue, fields []*models.ItemTypeField) (string, error) {
	result := make(map[string]interface{})

	fieldMap := make(map[uint]*models.ItemTypeField)
	for _, f := range fields {
		fieldMap[f.ID] = f
	}

	for _, fv := range fieldValues {
		if field, ok := fieldMap[fv.FieldID]; ok && fv.Value != nil {
			switch field.FieldType {
			case models.FieldTypeNumber:
				if num, err := strconv.ParseFloat(*fv.Value, 64); err == nil {
					result[field.Key] = num
				} else {
					result[field.Key] = *fv.Value
				}
			case models.FieldTypeCheckbox:
				result[field.Key] = *fv.Value == "true" || *fv.Value == "1"
			default:
				result[field.Key] = *fv.Value
			}
		}
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}
