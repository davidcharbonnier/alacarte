package models

import (
	"database/sql/driver"
	"fmt"
)

// WineColor represents the color/type of wine
type WineColor string

const (
	WineColorRouge    WineColor = "Rouge"    // Red
	WineColorBlanc    WineColor = "Blanc"    // White
	WineColorRose     WineColor = "Rosé"     // Rosé/Pink
	WineColorMousseux WineColor = "Mousseux" // Sparkling
	WineColorOrange   WineColor = "Orange"   // Orange
)

// ValidWineColors returns all valid wine color values
func ValidWineColors() []WineColor {
	return []WineColor{
		WineColorRouge,
		WineColorBlanc,
		WineColorRose,
		WineColorMousseux,
		WineColorOrange,
	}
}

// IsValid checks if the wine color is valid
func (c WineColor) IsValid() bool {
	switch c {
	case WineColorRouge, WineColorBlanc, WineColorRose, WineColorMousseux, WineColorOrange:
		return true
	default:
		return false
	}
}

// String returns the string representation of the wine color
func (c WineColor) String() string {
	return string(c)
}

// Value implements the driver.Valuer interface for database storage
func (c WineColor) Value() (driver.Value, error) {
	if !c.IsValid() {
		return nil, fmt.Errorf("invalid wine color: %s", c)
	}
	return string(c), nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (c *WineColor) Scan(value interface{}) error {
	if value == nil {
		return fmt.Errorf("wine color cannot be null")
	}

	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan wine color")
	}

	*c = WineColor(str)
	if !c.IsValid() {
		return fmt.Errorf("invalid wine color: %s", *c)
	}

	return nil
}
