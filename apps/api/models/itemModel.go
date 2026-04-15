package models

import (
	"gorm.io/gorm"
)

type Item struct {
	gorm.Model
	SchemaID        uint             `gorm:"not null;index:idx_schema_name" json:"schema_id"`
	Name            string           `gorm:"type:varchar(255);not null;index:idx_schema_name" json:"name"`
	Description     *string          `gorm:"type:text" json:"description,omitempty"`
	ImageURL        *string          `gorm:"type:varchar(500)" json:"image_url,omitempty"`
	FieldValues     string           `gorm:"type:json" json:"field_values,omitempty"`
	UserID          int              `gorm:"not null;index" json:"user_id"`
	SchemaVersionID *uint            `gorm:"index" json:"schema_version_id,omitempty"`
	Schema          ItemTypeSchema   `gorm:"foreignKey:SchemaID;constraint:OnDelete:CASCADE" json:"-"`
	User            User             `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
	FieldValuesRows []ItemFieldValue `gorm:"foreignKey:ItemID;constraint:OnDelete:CASCADE" json:"-"`
	Ratings         []Rating         `gorm:"polymorphic:Item;" json:"ratings,omitempty"`
}

func (Item) TableName() string {
	return "items"
}

func (i *Item) GetImageURL() *string {
	return i.ImageURL
}

func (i *Item) SetImageURL(url *string) {
	i.ImageURL = url
}

type ItemFieldValue struct {
	gorm.Model
	ItemID  uint          `gorm:"not null;uniqueIndex:uk_item_field" json:"item_id"`
	FieldID uint          `gorm:"not null;uniqueIndex:uk_item_field;index:idx_field_value" json:"field_id"`
	Value   *string       `gorm:"type:text" json:"value,omitempty"`
	Item    Item          `gorm:"foreignKey:ItemID;constraint:OnDelete:CASCADE" json:"-"`
	Field   ItemTypeField `gorm:"foreignKey:FieldID;constraint:OnDelete:CASCADE" json:"-"`
}

func (ItemFieldValue) TableName() string {
	return "item_field_values"
}
