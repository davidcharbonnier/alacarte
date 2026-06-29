package utils

import (
	"fmt"

	"github.com/davidcharbonnier/alacarte-api/models"
)

// GetItemByType fetches a dynamic item by schema name and item ID string.
func GetItemByType(itemType string, itemID string) (*models.Item, error) {
	var id uint
	if _, err := fmt.Sscanf(itemID, "%d", &id); err != nil {
		return nil, fmt.Errorf("invalid item ID: %s", itemID)
	}
	return GetDynamicItem(itemType, id)
}

// GetDynamicItem fetches a dynamic item by schema name and ID
func GetDynamicItem(schemaName string, itemID uint) (*models.Item, error) {
	var item models.Item

	if err := DB.Joins("JOIN item_type_schemas ON item_type_schemas.id = items.schema_id").
		Where("items.id = ? AND item_type_schemas.name = ?", itemID, schemaName).
		First(&item).Error; err != nil {
		return nil, err
	}

	return &item, nil
}

// SaveItem saves an item to the database
func SaveItem(item *models.Item) error {
	return DB.Save(item).Error
}

// ValidateItemType checks if item type is supported via schema lookup
func ValidateItemType(itemType string) bool {
	var count int64
	DB.Model(&models.ItemTypeSchema{}).Where("name = ? AND is_active = ?", itemType, true).Count(&count)
	return count > 0
}