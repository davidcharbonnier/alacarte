package models

import (
	"gorm.io/gorm"
)

type FieldType string

const (
	FieldTypeText     FieldType = "text"
	FieldTypeTextarea FieldType = "textarea"
	FieldTypeNumber   FieldType = "number"
	FieldTypeSelect   FieldType = "select"
	FieldTypeCheckbox FieldType = "checkbox"
	FieldTypeEnum     FieldType = "enum"
)

type ItemTypeSchema struct {
	gorm.Model
	Name        string          `gorm:"type:varchar(50);uniqueIndex;not null" json:"name"`
	DisplayName string          `gorm:"type:varchar(100);not null" json:"display_name"`
	PluralName  string          `gorm:"type:varchar(100);not null" json:"plural_name"`
	Icon        string          `gorm:"type:varchar(50);not null" json:"icon"`
	Color       string          `gorm:"type:varchar(7);not null" json:"color"`
	IsActive    bool            `gorm:"default:true" json:"is_active"`
	Fields      []ItemTypeField `gorm:"foreignKey:SchemaID" json:"fields,omitempty"`
	Versions    []SchemaVersion `gorm:"foreignKey:SchemaID" json:"versions,omitempty"`
	Items       []Item          `gorm:"foreignKey:SchemaID" json:"items,omitempty"`
}

func (ItemTypeSchema) TableName() string {
	return "item_type_schemas"
}

type ItemTypeField struct {
	gorm.Model
	SchemaID   uint           `gorm:"not null;index:idx_order" json:"schema_id"`
	Key        string         `gorm:"type:varchar(50);not null" json:"key"`
	Label      string         `gorm:"type:varchar(100);not null" json:"label"`
	FieldType  FieldType      `gorm:"type:enum('text','textarea','number','select','checkbox','enum');not null" json:"field_type"`
	Required   bool           `gorm:"default:false" json:"required"`
	Order      int            `gorm:"not null;default:0;index:idx_order" json:"order"`
	Group      *string        `gorm:"type:varchar(50)" json:"group,omitempty"`
	Validation string         `gorm:"type:json" json:"validation,omitempty"`
	Display    string         `gorm:"type:json" json:"display,omitempty"`
	Options    string         `gorm:"type:json" json:"options,omitempty"`
	Schema     ItemTypeSchema `gorm:"foreignKey:SchemaID;constraint:OnDelete:CASCADE" json:"-"`
}

func (ItemTypeField) TableName() string {
	return "item_type_fields"
}

type SchemaVersion struct {
	gorm.Model
	SchemaID   uint            `gorm:"not null;uniqueIndex:uk_schema_version" json:"schema_id"`
	Version    int             `gorm:"not null;uniqueIndex:uk_schema_version" json:"version"`
	Fields     string          `gorm:"type:json;not null" json:"fields"`
	IsActive   bool            `gorm:"default:true" json:"is_active"`
	MigratedAt *gorm.DeletedAt `gorm:"index" json:"migrated_at,omitempty"`
	Schema     ItemTypeSchema  `gorm:"foreignKey:SchemaID;constraint:OnDelete:CASCADE" json:"-"`
}

func (SchemaVersion) TableName() string {
	return "schema_versions"
}
