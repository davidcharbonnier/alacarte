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
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}
