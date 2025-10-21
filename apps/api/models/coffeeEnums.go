package models

import (
	"database/sql/driver"
	"fmt"
)

// CoffeeSpecies represents the species of coffee plant
type CoffeeSpecies string

const (
	CoffeeSpeciesArabica  CoffeeSpecies = "Arabica"
	CoffeeSpeciesRobusta  CoffeeSpecies = "Robusta"
	CoffeeSpeciesLiberica CoffeeSpecies = "Libérica"
	CoffeeSpeciesExcelsa  CoffeeSpecies = "Excelsa"
)

// ValidCoffeeSpecies returns all valid coffee species values
func ValidCoffeeSpecies() []CoffeeSpecies {
	return []CoffeeSpecies{
		CoffeeSpeciesArabica,
		CoffeeSpeciesRobusta,
		CoffeeSpeciesLiberica,
		CoffeeSpeciesExcelsa,
	}
}

// IsValid checks if the coffee species is valid
func (s CoffeeSpecies) IsValid() bool {
	switch s {
	case CoffeeSpeciesArabica, CoffeeSpeciesRobusta, CoffeeSpeciesLiberica, CoffeeSpeciesExcelsa:
		return true
	default:
		return false
	}
}

// String returns the string representation of the coffee species
func (s CoffeeSpecies) String() string {
	return string(s)
}

// Value implements the driver.Valuer interface for database storage
func (s CoffeeSpecies) Value() (driver.Value, error) {
	if s == "" {
		return nil, nil // Allow empty values since it's optional
	}
	if !s.IsValid() {
		return nil, fmt.Errorf("invalid coffee species: %s", s)
	}
	return string(s), nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (s *CoffeeSpecies) Scan(value interface{}) error {
	if value == nil {
		*s = ""
		return nil
	}

	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan coffee species")
	}

	*s = CoffeeSpecies(str)
	if *s != "" && !s.IsValid() {
		return fmt.Errorf("invalid coffee species: %s", *s)
	}

	return nil
}

// CoffeeProcessingMethod represents how the coffee cherry was processed
type CoffeeProcessingMethod string

const (
	CoffeeProcessingWashed            CoffeeProcessingMethod = "Lavé"
	CoffeeProcessingNatural           CoffeeProcessingMethod = "Nature"
	CoffeeProcessingHoney             CoffeeProcessingMethod = "Honey"
	CoffeeProcessingAnaerobic         CoffeeProcessingMethod = "Anaérobie"
	CoffeeProcessingCarbonicMaceration CoffeeProcessingMethod = "Macération Carbonique"
	CoffeeProcessingWetHulled         CoffeeProcessingMethod = "Décortiqué Humide"
	CoffeeProcessingPulpedNatural     CoffeeProcessingMethod = "Nature Dépulpé"
)

// ValidCoffeeProcessingMethods returns all valid processing method values
func ValidCoffeeProcessingMethods() []CoffeeProcessingMethod {
	return []CoffeeProcessingMethod{
		CoffeeProcessingWashed,
		CoffeeProcessingNatural,
		CoffeeProcessingHoney,
		CoffeeProcessingAnaerobic,
		CoffeeProcessingCarbonicMaceration,
		CoffeeProcessingWetHulled,
		CoffeeProcessingPulpedNatural,
	}
}

// IsValid checks if the processing method is valid
func (p CoffeeProcessingMethod) IsValid() bool {
	switch p {
	case CoffeeProcessingWashed, CoffeeProcessingNatural, CoffeeProcessingHoney,
		CoffeeProcessingAnaerobic, CoffeeProcessingCarbonicMaceration,
		CoffeeProcessingWetHulled, CoffeeProcessingPulpedNatural:
		return true
	default:
		return false
	}
}

// String returns the string representation of the processing method
func (p CoffeeProcessingMethod) String() string {
	return string(p)
}

// Value implements the driver.Valuer interface for database storage
func (p CoffeeProcessingMethod) Value() (driver.Value, error) {
	if p == "" {
		return nil, nil // Allow empty values since it's optional
	}
	if !p.IsValid() {
		return nil, fmt.Errorf("invalid coffee processing method: %s", p)
	}
	return string(p), nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (p *CoffeeProcessingMethod) Scan(value interface{}) error {
	if value == nil {
		*p = ""
		return nil
	}

	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan coffee processing method")
	}

	*p = CoffeeProcessingMethod(str)
	if *p != "" && !p.IsValid() {
		return fmt.Errorf("invalid coffee processing method: %s", *p)
	}

	return nil
}

// CoffeeRoastLevel represents the roast level of the coffee
type CoffeeRoastLevel string

const (
	CoffeeRoastLight  CoffeeRoastLevel = "Pâle"
	CoffeeRoastMedium CoffeeRoastLevel = "Moyen"
	CoffeeRoastDark   CoffeeRoastLevel = "Foncé"
)

// ValidCoffeeRoastLevels returns all valid roast level values
func ValidCoffeeRoastLevels() []CoffeeRoastLevel {
	return []CoffeeRoastLevel{
		CoffeeRoastLight,
		CoffeeRoastMedium,
		CoffeeRoastDark,
	}
}

// IsValid checks if the roast level is valid
func (r CoffeeRoastLevel) IsValid() bool {
	switch r {
	case CoffeeRoastLight, CoffeeRoastMedium, CoffeeRoastDark:
		return true
	default:
		return false
	}
}

// String returns the string representation of the roast level
func (r CoffeeRoastLevel) String() string {
	return string(r)
}

// Value implements the driver.Valuer interface for database storage
func (r CoffeeRoastLevel) Value() (driver.Value, error) {
	if r == "" {
		return nil, nil // Allow empty values since it's optional
	}
	if !r.IsValid() {
		return nil, fmt.Errorf("invalid coffee roast level: %s", r)
	}
	return string(r), nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (r *CoffeeRoastLevel) Scan(value interface{}) error {
	if value == nil {
		*r = ""
		return nil
	}

	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan coffee roast level")
	}

	*r = CoffeeRoastLevel(str)
	if *r != "" && !r.IsValid() {
		return fmt.Errorf("invalid coffee roast level: %s", *r)
	}

	return nil
}

// CoffeeIntensityLevel represents intensity levels (used for acidity, body, sweetness)
type CoffeeIntensityLevel string

const (
	CoffeeIntensityLow    CoffeeIntensityLevel = "Faible"
	CoffeeIntensityMedium CoffeeIntensityLevel = "Moyen"
	CoffeeIntensityHigh   CoffeeIntensityLevel = "Élevé"
)

// ValidCoffeeIntensityLevels returns all valid intensity level values
func ValidCoffeeIntensityLevels() []CoffeeIntensityLevel {
	return []CoffeeIntensityLevel{
		CoffeeIntensityLow,
		CoffeeIntensityMedium,
		CoffeeIntensityHigh,
	}
}

// IsValid checks if the intensity level is valid
func (i CoffeeIntensityLevel) IsValid() bool {
	switch i {
	case CoffeeIntensityLow, CoffeeIntensityMedium, CoffeeIntensityHigh:
		return true
	default:
		return false
	}
}

// String returns the string representation of the intensity level
func (i CoffeeIntensityLevel) String() string {
	return string(i)
}

// Value implements the driver.Valuer interface for database storage
func (i CoffeeIntensityLevel) Value() (driver.Value, error) {
	if i == "" {
		return nil, nil // Allow empty values since it's optional
	}
	if !i.IsValid() {
		return nil, fmt.Errorf("invalid coffee intensity level: %s", i)
	}
	return string(i), nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (i *CoffeeIntensityLevel) Scan(value interface{}) error {
	if value == nil {
		*i = ""
		return nil
	}

	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan coffee intensity level")
	}

	*i = CoffeeIntensityLevel(str)
	if *i != "" && !i.IsValid() {
		return fmt.Errorf("invalid coffee intensity level: %s", *i)
	}

	return nil
}
