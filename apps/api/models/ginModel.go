package models

import (
	"gorm.io/gorm"
)

type Gin struct {
	gorm.Model
	Name        string   `gorm:"type:varchar(255);not null" json:"name"`
	Producer    string   `gorm:"type:varchar(255);not null" json:"producer"`
	Origin      string   `gorm:"type:varchar(255)" json:"origin"`
	Profile     string   `gorm:"type:varchar(255);not null" json:"profile"`
	Description string   `gorm:"type:text" json:"description"`
	ImageURL    *string  `json:"image_url,omitempty"`
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}

// BeforeCreate hook to enforce composite unique constraint
func (g *Gin) BeforeCreate(tx *gorm.DB) error {
	// Check if a gin with the same name and producer already exists
	var count int64
	tx.Model(&Gin{}).Where("name = ? AND producer = ?", g.Name, g.Producer).Count(&count)
	if count > 0 {
		return gorm.ErrDuplicatedKey
	}
	return nil
}

// GetImageURL implements ItemWithImage interface
func (g *Gin) GetImageURL() *string {
	return g.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (g *Gin) SetImageURL(url *string) {
	g.ImageURL = url
}
