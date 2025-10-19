package models

import "gorm.io/gorm"

type Wine struct {
	gorm.Model
	Name        string    `gorm:"not null" json:"name"`
	Producer    string    `json:"producer"`
	Country     string    `gorm:"not null" json:"country"`
	Region      string    `json:"region"`
	Color       WineColor `gorm:"not null" json:"color"`
	Grape       string    `json:"grape"`
	Alcohol     float64   `json:"alcohol"`
	Description string    `json:"description"`
	Designation string    `json:"designation"`
	Sugar       float64   `json:"sugar"`
	Organic     bool      `json:"organic" gorm:"default:false"`
	ImageURL    *string   `json:"image_url,omitempty"`
	Ratings     []Rating  `gorm:"polymorphic:Item;"`
}

// GetImageURL implements ItemWithImage interface
func (w *Wine) GetImageURL() *string {
	return w.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (w *Wine) SetImageURL(url *string) {
	w.ImageURL = url
}
