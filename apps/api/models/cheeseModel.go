package models

import (
	"gorm.io/gorm"
)

type Cheese struct {
	gorm.Model
	Name        string   `gorm:"type:varchar(255);unique;not null" json:"name"`
	Type        string   `gorm:"type:varchar(255);not null" json:"type"`
	Origin      string   `gorm:"type:varchar(255)" json:"origin"`
	Producer    string   `gorm:"type:varchar(255)" json:"producer"`
	Description string   `gorm:"type:text" json:"description"`
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
