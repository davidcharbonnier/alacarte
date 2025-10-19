package models

import (
	"gorm.io/gorm"
)

type Gin struct {
	gorm.Model
	Name        string   `gorm:"unique" json:"name"`
	Producer    string   `json:"producer"`
	Origin      string   `json:"origin"`
	Profile     string   `json:"profile"`
	Description string   `json:"description"`
	ImageURL    *string  `json:"image_url,omitempty"`
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}

// GetImageURL implements ItemWithImage interface
func (g *Gin) GetImageURL() *string {
	return g.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (g *Gin) SetImageURL(url *string) {
	g.ImageURL = url
}
