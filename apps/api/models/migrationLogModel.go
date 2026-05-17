package models

import "gorm.io/gorm"

// MigrationLog tracks item ID mappings during schema migration for rollback support
type MigrationLog struct {
	gorm.Model
	OldItemID   int    `json:"old_item_id"`
	NewItemID   int    `json:"new_item_id"`
	ItemType    string `json:"item_type"`
}
