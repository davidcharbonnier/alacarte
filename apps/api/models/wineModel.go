package models

import "gorm.io/gorm"

type Wine struct {
	gorm.Model
	Name        string   `gorm:"not null" json:"name"`
	Producer    string   `json:"producer"`
	Country     string   `gorm:"not null" json:"country"`
	Region      string   `json:"region"`
	Color       string   `gorm:"not null" json:"color"`
	Grape       string   `json:"grape"`
	Alcohol     float64  `json:"alcohol"`
	Description string   `json:"description"`
	Designation string   `json:"designation"`
	Sugar       float64  `json:"sugar"`
	Organic     bool     `json:"organic" gorm:"default:false"`
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}
