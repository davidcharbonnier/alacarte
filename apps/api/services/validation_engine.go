package services

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/models"
)

type ValidationError struct {
	Field   string                 `json:"field"`
	Label   string                 `json:"label,omitempty"`
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

type ValidationResult struct {
	Valid  bool              `json:"valid"`
	Errors []ValidationError `json:"errors,omitempty"`
}

type ValidationEngine struct {
	registry *SchemaRegistry
}

func NewValidationEngine(registry *SchemaRegistry) *ValidationEngine {
	return &ValidationEngine{
		registry: registry,
	}
}

func (e *ValidationEngine) ValidateCreate(schemaName string, fields map[string]interface{}) *ValidationResult {
	result := &ValidationResult{Valid: true, Errors: []ValidationError{}}

	cached, ok := e.registry.GetSchema(schemaName)
	if !ok {
		result.Valid = false
		result.Errors = append(result.Errors, ValidationError{
			Code:    "unknown_schema",
			Message: fmt.Sprintf("Schema '%s' not found", schemaName),
		})
		return result
	}

	for _, field := range cached.Fields {
		value, exists := fields[field.Key]

		if field.Required {
			if !exists || value == nil || (field.FieldType == models.FieldTypeText || field.FieldType == models.FieldTypeTextarea) && strings.TrimSpace(fmt.Sprintf("%v", value)) == "" {
				result.Valid = false
				result.Errors = append(result.Errors, ValidationError{
					Field:   field.Key,
					Label:   field.Label,
					Code:    "required",
					Message: fmt.Sprintf("%s is required", field.Label),
				})
				continue
			}
		}

		if !exists || value == nil {
			continue
		}

		validation, err := ParseFieldValidation(field)
		if err != nil {
			continue
		}

		valueStr := fmt.Sprintf("%v", value)

		switch field.FieldType {
		case models.FieldTypeText, models.FieldTypeTextarea:
			if errs := e.validateString(field, valueStr, validation); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, errs...)
			}

		case models.FieldTypeNumber:
			if errs := e.validateNumber(field, value, validation); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, errs...)
			}

		case models.FieldTypeSelect, models.FieldTypeEnum:
			if errs := e.validateOptions(field, valueStr); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, *errs)
			}

		case models.FieldTypeCheckbox:
			if errs := e.validateCheckbox(field, value); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, *errs)
			}
		}
	}

	for providedKey := range fields {
		if _, found := e.findField(cached.Fields, providedKey); !found {
			result.Valid = false
			result.Errors = append(result.Errors, ValidationError{
				Field:   providedKey,
				Code:    "unknown_field",
				Message: fmt.Sprintf("Field '%s' is not defined in schema '%s'", providedKey, schemaName),
			})
		}
	}

	return result
}

func (e *ValidationEngine) ValidateUpdate(schemaName string, fields map[string]interface{}) *ValidationResult {
	result := &ValidationResult{Valid: true, Errors: []ValidationError{}}

	cached, ok := e.registry.GetSchema(schemaName)
	if !ok {
		result.Valid = false
		result.Errors = append(result.Errors, ValidationError{
			Code:    "unknown_schema",
			Message: fmt.Sprintf("Schema '%s' not found", schemaName),
		})
		return result
	}

	for key, value := range fields {
		field, fieldFound := e.findField(cached.Fields, key)
		if !fieldFound {
			result.Valid = false
			result.Errors = append(result.Errors, ValidationError{
				Field:   key,
				Code:    "unknown_field",
				Message: fmt.Sprintf("Field '%s' is not defined in schema '%s'", key, schemaName),
			})
			continue
		}

		if value == nil || (field.FieldType != models.FieldTypeCheckbox && strings.TrimSpace(fmt.Sprintf("%v", value)) == "") {
			if field.Required {
				result.Valid = false
				result.Errors = append(result.Errors, ValidationError{
					Field:   field.Key,
					Label:   field.Label,
					Code:    "required",
					Message: fmt.Sprintf("%s is required", field.Label),
				})
			}
			continue
		}

		validation, err := ParseFieldValidation(field)
		if err != nil {
			continue
		}

		valueStr := fmt.Sprintf("%v", value)

		switch field.FieldType {
		case models.FieldTypeText, models.FieldTypeTextarea:
			if errs := e.validateString(field, valueStr, validation); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, errs...)
			}

		case models.FieldTypeNumber:
			if errs := e.validateNumber(field, value, validation); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, errs...)
			}

		case models.FieldTypeSelect, models.FieldTypeEnum:
			if errs := e.validateOptions(field, valueStr); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, *errs)
			}

		case models.FieldTypeCheckbox:
			if errs := e.validateCheckbox(field, value); errs != nil {
				result.Valid = false
				result.Errors = append(result.Errors, *errs)
			}
		}
	}

	return result
}

func (e *ValidationEngine) validateString(field *models.ItemTypeField, value string, validation map[string]interface{}) []ValidationError {
	var errors []ValidationError

	if minLength, ok := validation["minLength"].(float64); ok {
		if int(minLength) > len(value) {
			errors = append(errors, ValidationError{
				Field:   field.Key,
				Label:   field.Label,
				Code:    "min_length",
				Message: fmt.Sprintf("%s must be at least %d characters", field.Label, int(minLength)),
				Details: map[string]interface{}{"min": int(minLength), "actual": len(value)},
			})
		}
	}

	if maxLength, ok := validation["maxLength"].(float64); ok {
		if int(maxLength) < len(value) {
			errors = append(errors, ValidationError{
				Field:   field.Key,
				Label:   field.Label,
				Code:    "max_length",
				Message: fmt.Sprintf("%s must be at most %d characters", field.Label, int(maxLength)),
				Details: map[string]interface{}{"max": int(maxLength), "actual": len(value)},
			})
		}
	}

	if pattern, ok := validation["pattern"].(string); ok {
		matched, _ := regexp.MatchString(pattern, value)
		if !matched {
			errors = append(errors, ValidationError{
				Field:   field.Key,
				Label:   field.Label,
				Code:    "pattern",
				Message: fmt.Sprintf("%s must match pattern %s", field.Label, pattern),
				Details: map[string]interface{}{"pattern": pattern},
			})
		}
	}

	return errors
}

func (e *ValidationEngine) validateNumber(field *models.ItemTypeField, value interface{}, validation map[string]interface{}) []ValidationError {
	var errors []ValidationError

	numValue, err := strconv.ParseFloat(fmt.Sprintf("%v", value), 64)
	if err != nil {
		errors = append(errors, ValidationError{
			Field:   field.Key,
			Label:   field.Label,
			Code:    "type_mismatch",
			Message: fmt.Sprintf("%s must be a number", field.Label),
			Details: map[string]interface{}{"expected": "number", "actual": fmt.Sprintf("%T", value)},
		})
		return errors
	}

	if min, ok := validation["min"].(float64); ok {
		if numValue < min {
			errors = append(errors, ValidationError{
				Field:   field.Key,
				Label:   field.Label,
				Code:    "min_value",
				Message: fmt.Sprintf("%s must be at least %v", field.Label, min),
				Details: map[string]interface{}{"min": min, "actual": numValue},
			})
		}
	}

	if max, ok := validation["max"].(float64); ok {
		if numValue > max {
			errors = append(errors, ValidationError{
				Field:   field.Key,
				Label:   field.Label,
				Code:    "max_value",
				Message: fmt.Sprintf("%s must be at most %v", field.Label, max),
				Details: map[string]interface{}{"max": max, "actual": numValue},
			})
		}
	}

	return errors
}

func (e *ValidationEngine) validateOptions(field *models.ItemTypeField, value string) *ValidationError {
	options, err := ParseFieldOptions(field)
	if err != nil {
		return &ValidationError{
			Field:   field.Key,
			Label:   field.Label,
			Code:    "invalid_option",
			Message: fmt.Sprintf("Invalid options configuration for %s", field.Label),
		}
	}

	for _, opt := range options {
		if opt == value {
			return nil
		}
	}

	return &ValidationError{
		Field:   field.Key,
		Label:   field.Label,
		Code:    "invalid_option",
		Message: fmt.Sprintf("%s must be one of: %s", field.Label, strings.Join(options, ", ")),
		Details: map[string]interface{}{"allowed": options, "actual": value},
	}
}

func (e *ValidationEngine) validateCheckbox(field *models.ItemTypeField, value interface{}) *ValidationError {
	switch v := value.(type) {
	case bool:
		return nil
	case string:
		if v == "true" || v == "false" || v == "1" || v == "0" {
			return nil
		}
	}

	return &ValidationError{
		Field:   field.Key,
		Label:   field.Label,
		Code:    "type_mismatch",
		Message: fmt.Sprintf("%s must be a boolean", field.Label),
		Details: map[string]interface{}{"expected": "boolean", "actual": fmt.Sprintf("%T", value)},
	}
}

func (e *ValidationEngine) findField(fields []*models.ItemTypeField, key string) (*models.ItemTypeField, bool) {
	for _, f := range fields {
		if f.Key == key {
			return f, true
		}
	}
	return nil, false
}
