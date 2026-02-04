package models

import (
	"gorm.io/gorm"
)

// SpiceLevel represents the heat level of a chili sauce
type SpiceLevel string

const (
	Mild     SpiceLevel = "Mild"
	Medium   SpiceLevel = "Medium"
	Hot      SpiceLevel = "Hot"
	ExtraHot SpiceLevel = "Extra Hot"
	Extreme  SpiceLevel = "Extreme"
)

// ChiliSauce represents a chili sauce consumable item
type ChiliSauce struct {
	gorm.Model
	Name        string     `gorm:"type:varchar(255);not null" json:"name"`
	Brand       string     `gorm:"type:varchar(255);not null" json:"brand"`
	SpiceLevel  SpiceLevel `gorm:"type:varchar(50);not null" json:"spiceLevel"`
	Chilis      string     `gorm:"type:varchar(500)" json:"chilis"`
	Description string     `gorm:"type:text" json:"description"`
	ImageURL    *string    `json:"image_url,omitempty"`
	Ratings     []Rating   `gorm:"polymorphic:Item;"`
}

// BeforeCreate hook to enforce unique constraint on name + brand combination
func (c *ChiliSauce) BeforeCreate(tx *gorm.DB) error {
	var count int64
	err := tx.Model(&ChiliSauce{}).
		Where("name = ? AND brand = ?", c.Name, c.Brand).
		Count(&count).Error

	if err != nil {
		return err
	}

	if count > 0 {
		return gorm.ErrDuplicatedKey
	}

	return nil
}

// GetImageURL implements the ItemWithImage interface
func (c *ChiliSauce) GetImageURL() *string {
	return c.ImageURL
}

// SetImageURL implements the ItemWithImage interface
func (c *ChiliSauce) SetImageURL(url *string) {
	c.ImageURL = url
}
