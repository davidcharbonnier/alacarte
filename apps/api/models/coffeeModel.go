package models

import (
	"database/sql/driver"
	"encoding/json"
	"gorm.io/gorm"
)

type Coffee struct {
	gorm.Model
	// Required fields
	Name    string `gorm:"type:varchar(255);not null" json:"name"`
	Roaster string `gorm:"type:varchar(255);not null" json:"roaster"`

	// Origin information (all optional)
	Country  string `gorm:"type:varchar(255)" json:"country"`
	Region   string `gorm:"type:varchar(255)" json:"region"`
	Farm     string `gorm:"type:varchar(255)" json:"farm"`
	Altitude string `gorm:"type:varchar(50)" json:"altitude"`

	// Bean characteristics (all optional)
	Species          CoffeeSpecies          `json:"species"`
	Variety          string                 `gorm:"type:varchar(100)" json:"variety"`
	ProcessingMethod CoffeeProcessingMethod `json:"processing_method"`
	Decaffeinated    bool                   `gorm:"default:false" json:"decaffeinated"`

	// Roasting (optional)
	RoastLevel CoffeeRoastLevel `json:"roast_level"`

	// Flavor profile (all optional)
	TastingNotes StringArray          `gorm:"type:json" json:"tasting_notes"`
	Acidity      CoffeeIntensityLevel `json:"acidity"`
	Body         CoffeeIntensityLevel `json:"body"`
	Sweetness    CoffeeIntensityLevel `json:"sweetness"`

	// Certifications
	Organic   bool `gorm:"default:false" json:"organic"`
	FairTrade bool `gorm:"default:false" json:"fair_trade"`

	// Description and image (optional)
	Description string  `gorm:"type:text" json:"description"`
	ImageURL    *string `json:"image_url,omitempty"`

	// Relations
	Ratings []Rating `gorm:"polymorphic:Item;"`
}

// BeforeCreate hook to enforce composite unique constraint
func (c *Coffee) BeforeCreate(tx *gorm.DB) error {
	// Check if a coffee with the same name and roaster already exists
	var count int64
	tx.Model(&Coffee{}).Where("name = ? AND roaster = ?", c.Name, c.Roaster).Count(&count)
	if count > 0 {
		return gorm.ErrDuplicatedKey
	}
	return nil
}

// GetImageURL implements ItemWithImage interface
func (c *Coffee) GetImageURL() *string {
	return c.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (c *Coffee) SetImageURL(url *string) {
	c.ImageURL = url
}

// StringArray is a custom type for storing arrays of strings in JSON format
type StringArray []string

// Value implements the driver.Valuer interface for database storage
func (a StringArray) Value() (driver.Value, error) {
	if a == nil {
		return nil, nil
	}
	return json.Marshal(a)
}

// Scan implements the sql.Scanner interface for database retrieval
func (a *StringArray) Scan(value interface{}) error {
	if value == nil {
		*a = nil
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return gorm.ErrInvalidData
	}

	return json.Unmarshal(bytes, a)
}
