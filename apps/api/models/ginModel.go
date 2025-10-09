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
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}
