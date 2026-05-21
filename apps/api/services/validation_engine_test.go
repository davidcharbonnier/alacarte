package services

import (
	"testing"

	"github.com/davidcharbonnier/alacarte-api/models"
)

func createTestRegistry() *SchemaRegistry {
	ResetGlobalRegistry()
	r := GetSchemaRegistry()

	cheeseSchema := &CachedSchema{
		Schema: &models.ItemTypeSchema{
			Name:        "cheese",
			DisplayName: "Cheese",
			IsActive:    true,
		},
		Fields: []*models.ItemTypeField{
			{Key: "name", Label: "Name", FieldType: models.FieldTypeText, Required: true},
			{Key: "type", Label: "Type", FieldType: models.FieldTypeText, Required: true},
			{Key: "origin", Label: "Origin", FieldType: models.FieldTypeText, Required: false},
			{Key: "description", Label: "Description", FieldType: models.FieldTypeTextarea, Required: false},
			{Key: "age", Label: "Age", FieldType: models.FieldTypeNumber, Required: false},
			{Key: "style", Label: "Style", FieldType: models.FieldTypeSelect, Required: false},
			{Key: "color", Label: "Color", FieldType: models.FieldTypeEnum, Required: false},
			{Key: "organic", Label: "Organic", FieldType: models.FieldTypeCheckbox, Required: false},
		},
	}

	// Add validation rules
	v := `{"minLength":2,"maxLength":100}`
	cheeseSchema.Fields[0].Validation = &v // name
	v2 := `{"min":0,"max":100}`
	cheeseSchema.Fields[4].Validation = &v2 // age
	v3 := `{"pattern":"^\\d{4}$"}`
	cheeseSchema.Fields[5].Validation = &v3 // style (actually this is select, but we'll test pattern on text field later)

	// Add options for select/enum
	o := `["Fresh","Soft","Semi-Hard","Hard","Blue"]`
	cheeseSchema.Fields[5].Options = &o // style (select)
	o2 := `["White","Yellow","Orange","Blue"]`
	cheeseSchema.Fields[6].Options = &o2 // color (enum)

	r.schemas["cheese"] = cheeseSchema

	return r
}

func TestValidationEngine_Required(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Missing required field
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"type": "Brie",
	})
	if result.Valid {
		t.Error("expected validation to fail for missing required name")
	}
	if len(result.Errors) != 1 || result.Errors[0].Code != "required" {
		t.Errorf("expected required error, got: %+v", result.Errors)
	}

	// Empty string fails required
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "",
		"type": "Brie",
	})
	if result.Valid {
		t.Error("expected validation to fail for empty name")
	}

	// Whitespace-only fails required
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "   ",
		"type": "Brie",
	})
	if result.Valid {
		t.Error("expected validation to fail for whitespace-only name")
	}

	// Valid input passes
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if !result.Valid {
		t.Errorf("expected validation to pass, got: %+v", result.Errors)
	}
}

func TestValidationEngine_Length(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Below min length
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "A",
		"type": "Brie",
	})
	if result.Valid {
		t.Error("expected validation to fail for below min length")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "min_length" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected min_length error, got: %+v", result.Errors)
	}

	// Above max length
	longName := make([]byte, 101)
	for i := range longName {
		longName[i] = 'a'
	}
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name": string(longName),
		"type": "Brie",
	})
	if result.Valid {
		t.Error("expected validation to fail for above max length")
	}
	found = false
	for _, e := range result.Errors {
		if e.Code == "max_length" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected max_length error, got: %+v", result.Errors)
	}
}

func TestValidationEngine_Range(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Below minimum
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
		"age":  -1,
	})
	if result.Valid {
		t.Error("expected validation to fail for below min")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "min_value" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected min_value error, got: %+v", result.Errors)
	}

	// Above maximum
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
		"age":  101,
	})
	if result.Valid {
		t.Error("expected validation to fail for above max")
	}
	found = false
	for _, e := range result.Errors {
		if e.Code == "max_value" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected max_value error, got: %+v", result.Errors)
	}
}

func TestValidationEngine_Pattern(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Create a schema with pattern validation
	v := `{"pattern":"^\\d{4}$"}`
	registry.schemas["cheese"].Fields[3].Validation = &v // description

	// Invalid pattern
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name":        "Brie",
		"type":        "Soft",
		"description": "not a year",
	})
	if result.Valid {
		t.Error("expected validation to fail for pattern mismatch")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "pattern" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected pattern error, got: %+v", result.Errors)
	}

	// Valid pattern
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":        "Brie",
		"type":        "Soft",
		"description": "2020",
	})
	if !result.Valid {
		t.Errorf("expected validation to pass, got: %+v", result.Errors)
	}
}

func TestValidationEngine_SelectEnum(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Invalid select option
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name":  "Brie",
		"type":  "Soft",
		"style": "Unknown",
	})
	if result.Valid {
		t.Error("expected validation to fail for invalid select option")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "invalid_option" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected invalid_option error, got: %+v", result.Errors)
	}

	// Valid select option
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":  "Brie",
		"type":  "Soft",
		"style": "Soft",
	})
	if !result.Valid {
		t.Errorf("expected validation to pass, got: %+v", result.Errors)
	}

	// Invalid enum option
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":  "Brie",
		"type":  "Soft",
		"color": "Green",
	})
	if result.Valid {
		t.Error("expected validation to fail for invalid enum option")
	}

	// Valid enum option
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":  "Brie",
		"type":  "Soft",
		"color": "White",
	})
	if !result.Valid {
		t.Errorf("expected validation to pass, got: %+v", result.Errors)
	}
}

func TestValidationEngine_Checkbox(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Non-boolean value
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name":    "Brie",
		"type":    "Soft",
		"organic": "yes",
	})
	if result.Valid {
		t.Error("expected validation to fail for non-boolean checkbox")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "type_mismatch" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected type_mismatch error, got: %+v", result.Errors)
	}

	// Valid boolean
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":    "Brie",
		"type":    "Soft",
		"organic": true,
	})
	if !result.Valid {
		t.Errorf("expected validation to pass, got: %+v", result.Errors)
	}

	// Valid string boolean
	result = engine.ValidateCreate("cheese", map[string]interface{}{
		"name":    "Brie",
		"type":    "Soft",
		"organic": "true",
	})
	if !result.Valid {
		t.Errorf("expected validation to pass for string 'true', got: %+v", result.Errors)
	}
}

func TestValidationEngine_UnknownSchema(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	result := engine.ValidateCreate("nonexistent", map[string]interface{}{
		"name": "Test",
	})
	if result.Valid {
		t.Error("expected validation to fail for unknown schema")
	}
	if len(result.Errors) != 1 || result.Errors[0].Code != "unknown_schema" {
		t.Errorf("expected unknown_schema error, got: %+v", result.Errors)
	}
}

func TestValidationEngine_UnknownField(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name":         "Brie",
		"type":         "Soft",
		"age_months":   12,
	})
	if result.Valid {
		t.Error("expected validation to fail for unknown field")
	}
	found := false
	for _, e := range result.Errors {
		if e.Code == "unknown_field" && e.Field == "age_months" {
			found = true
		}
	}
	if !found {
		t.Errorf("expected unknown_field error for age_months, got: %+v", result.Errors)
	}
}

func TestValidationEngine_CreateVsUpdate(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	// Create requires all required fields
	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "Brie",
	})
	if result.Valid {
		t.Error("expected create to fail for missing type")
	}

	// Update only validates provided fields
	result = engine.ValidateUpdate("cheese", map[string]interface{}{
		"name": "Updated Brie",
	})
	if !result.Valid {
		t.Errorf("expected update to pass for partial fields, got: %+v", result.Errors)
	}

	// Update still validates unknown fields
	result = engine.ValidateUpdate("cheese", map[string]interface{}{
		"name":       "Brie",
		"extra_field": "value",
	})
	if result.Valid {
		t.Error("expected update to fail for unknown field")
	}

	// Update still validates type mismatch on provided fields
	result = engine.ValidateUpdate("cheese", map[string]interface{}{
		"age": "not a number",
	})
	if result.Valid {
		t.Error("expected update to fail for type mismatch")
	}
}

func TestValidationEngine_MultipleErrors(t *testing.T) {
	registry := createTestRegistry()
	engine := NewValidationEngine(registry)

	result := engine.ValidateCreate("cheese", map[string]interface{}{
		"name": "",
		"age":  150,
	})
	if result.Valid {
		t.Error("expected validation to fail")
	}
	if len(result.Errors) < 2 {
		t.Errorf("expected multiple errors, got: %+v", result.Errors)
	}
}
