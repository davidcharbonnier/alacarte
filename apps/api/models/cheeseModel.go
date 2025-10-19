package models

import (
	"gorm.io/gorm"
)

type Cheese struct {
	gorm.Model
	Name        string   `gorm:"unique" json:"name"`
	Type        string   `json:"type"`
	Origin      string   `json:"origin"`
	Producer    string   `json:"producer"`
	Description string   `json:"description"`
	ImageURL    *string  `json:"image_url,omitempty"`
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}

// GetImageURL implements ItemWithImage interface
func (c *Cheese) GetImageURL() *string {
	return c.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (c *Cheese) SetImageURL(url *string) {
	c.ImageURL = url
}
