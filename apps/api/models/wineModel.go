package models

import "gorm.io/gorm"

type Wine struct {
	gorm.Model
	Name        string    `gorm:"type:varchar(255);not null" json:"name"`
	Producer    string    `gorm:"type:varchar(255)" json:"producer"`
	Country     string    `gorm:"type:varchar(255);not null" json:"country"`
	Region      string    `gorm:"type:varchar(255)" json:"region"`
	Color       WineColor `gorm:"not null" json:"color"`
	Grape       string    `gorm:"type:varchar(255)" json:"grape"`
	Alcohol     float64   `json:"alcohol"`
	Description string    `gorm:"type:text" json:"description"`
	Designation string    `gorm:"type:varchar(255)" json:"designation"`
	Sugar       float64   `json:"sugar"`
	Organic     bool      `json:"organic" gorm:"default:false"`
	ImageURL    *string   `json:"image_url,omitempty"`
	Ratings     []Rating  `gorm:"polymorphic:Item;"`
}

// BeforeCreate hook to enforce composite unique constraint
func (w *Wine) BeforeCreate(tx *gorm.DB) error {
	// Check if a wine with the same name and color already exists
	var count int64
	tx.Model(&Wine{}).Where("name = ? AND color = ?", w.Name, w.Color).Count(&count)
	if count > 0 {
		return gorm.ErrDuplicatedKey
	}
	return nil
}

// GetImageURL implements ItemWithImage interface
func (w *Wine) GetImageURL() *string {
	return w.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (w *Wine) SetImageURL(url *string) {
	w.ImageURL = url
}
