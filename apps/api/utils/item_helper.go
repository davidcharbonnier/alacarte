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

// Compile-time interface checks to ensure models implement ItemWithImage
var (
	_ ItemWithImage = (*models.Cheese)(nil)
	_ ItemWithImage = (*models.Gin)(nil)
	_ ItemWithImage = (*models.Wine)(nil)
)

// GetItemByType fetches an item by type and ID
// Returns the item and any error
func GetItemByType(itemType string, itemID string) (ItemWithImage, error) {
	var item ItemWithImage
	var model interface{}

	switch itemType {
	case "cheese":
		model = &models.Cheese{}
	case "gin":
		model = &models.Gin{}
	case "wine":
		model = &models.Wine{}
	default:
		return nil, fmt.Errorf("invalid item type: %s", itemType)
	}

	// Fetch from database
	if err := DB.First(model, itemID).Error; err != nil {
		return nil, err
	}

	item = model.(ItemWithImage)
	return item, nil
}

// SaveItem saves an item to the database
func SaveItem(item ItemWithImage) error {
	return DB.Save(item).Error
}

// ValidateItemType checks if item type is supported
func ValidateItemType(itemType string) bool {
	validTypes := map[string]bool{
		"cheese": true,
		"gin":    true,
		"wine":   true,
	}
	return validTypes[itemType]
}
