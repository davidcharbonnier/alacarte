package utils

import (
	"fmt"

	"github.com/davidcharbonnier/alacarte-api/models"
)

// ItemWithImage interface - all item models must implement this
type ItemWithImage interface {
	GetImageURL() *string
	SetImageURL(url *string)
}

// GetItemByType fetches a dynamic item by schema name and item ID string.
// This replaces the old switch-case that looked up legacy models.
func GetItemByType(itemType string, itemID string) (ItemWithImage, error) {
	var id uint
	if _, err := fmt.Sscanf(itemID, "%d", &id); err != nil {
		return nil, fmt.Errorf("invalid item ID: %s", itemID)
	}
	return GetDynamicItem(itemType, id)
}

// GetDynamicItem fetches a dynamic item by schema name and ID
// Returns the item and any error
func GetDynamicItem(schemaName string, itemID uint) (ItemWithImage, error) {
	var item models.Item

	if err := DB.Joins("JOIN item_type_schemas ON item_type_schemas.id = items.schema_id").
		Where("items.id = ? AND item_type_schemas.name = ?", itemID, schemaName).
		First(&item).Error; err != nil {
		return nil, err
	}

	return &item, nil
}

// SaveItem saves an item to the database
func SaveItem(item ItemWithImage) error {
	return DB.Save(item).Error
}

// ValidateItemType checks if item type is supported via schema lookup
func ValidateItemType(itemType string) bool {
	var count int64
	DB.Model(&models.ItemTypeSchema{}).Where("name = ? AND is_active = ?", itemType, true).Count(&count)
	return count > 0
}