package utils

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/davidcharbonnier/alacarte-api/models"
	"gorm.io/gorm"
)

// SeedDefaultSchemas creates the 5 default item type schemas (cheese, gin, wine, coffee, chili-sauce)
// and their fields in the database. It is safe to call multiple times — existing schemas are skipped.
func SeedDefaultSchemas(db *gorm.DB) error {
	schemas := []struct {
		name         string
		displayName  string
		pluralName   string
		icon         string
		color        string
		uniqueFields []string
		fields       []struct {
			key        string
			label      string
			fieldType  models.FieldType
			required   bool
			order      int
			group      string
			validation string
			options    string
		}
	}{
		{
			name:         "cheese",
			displayName:  "Cheese",
			pluralName:   "Cheeses",
			icon:         "cheese",
			color:        "#FFD700",
			uniqueFields: []string{"name"},
			fields: []struct {
				key        string
				label      string
				fieldType  models.FieldType
				required   bool
				order      int
				group      string
				validation string
				options    string
			}{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "type", label: "Type", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "origin", label: "Origin", fieldType: models.FieldTypeText, required: false, order: 2, group: "Basic Info"},
				{key: "producer", label: "Producer", fieldType: models.FieldTypeText, required: false, order: 3, group: "Basic Info"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
		{
			name:         "gin",
			displayName:  "Gin",
			pluralName:   "Gins",
			icon:         "gin",
			color:        "#87CEEB",
			uniqueFields: []string{"name", "producer"},
			fields: []struct {
				key        string
				label      string
				fieldType  models.FieldType
				required   bool
				order      int
				group      string
				validation string
				options    string
			}{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "producer", label: "Producer", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "origin", label: "Origin", fieldType: models.FieldTypeText, required: false, order: 2, group: "Basic Info"},
				{key: "profile", label: "Profile", fieldType: models.FieldTypeText, required: true, order: 3, group: "Basic Info"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
		{
			name:         "wine",
			displayName:  "Wine",
			pluralName:   "Wines",
			icon:         "wine",
			color:        "#722F37",
			uniqueFields: []string{"name", "color"},
			fields: []struct {
				key        string
				label      string
				fieldType  models.FieldType
				required   bool
				order      int
				group      string
				validation string
				options    string
			}{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "producer", label: "Producer", fieldType: models.FieldTypeText, required: false, order: 1, group: "Basic Info"},
				{key: "country", label: "Country", fieldType: models.FieldTypeText, required: true, order: 2, group: "Basic Info"},
				{key: "region", label: "Region", fieldType: models.FieldTypeText, required: false, order: 3, group: "Basic Info"},
				{key: "color", label: "Color", fieldType: models.FieldTypeEnum, required: true, order: 4, group: "Basic Info", options: `["Rouge","Blanc","Rosé","Mousseux","Orange"]`},
				{key: "grape", label: "Grape", fieldType: models.FieldTypeText, required: false, order: 5, group: "Wine Details"},
				{key: "alcohol", label: "Alcohol (%)", fieldType: models.FieldTypeNumber, required: false, order: 6, group: "Wine Details"},
				{key: "designation", label: "Designation", fieldType: models.FieldTypeText, required: false, order: 7, group: "Wine Details"},
				{key: "sugar", label: "Sugar (g/L)", fieldType: models.FieldTypeNumber, required: false, order: 8, group: "Wine Details"},
				{key: "organic", label: "Organic", fieldType: models.FieldTypeCheckbox, required: false, order: 9, group: "Certifications"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 10, group: "Basic Info"},
			},
		},
		{
			name:         "coffee",
			displayName:  "Coffee",
			pluralName:   "Coffees",
			icon:         "coffee",
			color:        "#6F4E37",
			uniqueFields: []string{"name", "roaster"},
			fields: []struct {
				key        string
				label      string
				fieldType  models.FieldType
				required   bool
				order      int
				group      string
				validation string
				options    string
			}{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "roaster", label: "Roaster", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "country", label: "Country", fieldType: models.FieldTypeText, required: false, order: 2, group: "Origin"},
				{key: "region", label: "Region", fieldType: models.FieldTypeText, required: false, order: 3, group: "Origin"},
				{key: "farm", label: "Farm", fieldType: models.FieldTypeText, required: false, order: 4, group: "Origin"},
				{key: "altitude", label: "Altitude", fieldType: models.FieldTypeText, required: false, order: 5, group: "Origin"},
				{key: "species", label: "Species", fieldType: models.FieldTypeEnum, required: false, order: 6, group: "Bean Characteristics", options: `["Arabica","Robusta","Libérica","Excelsa"]`},
				{key: "variety", label: "Variety", fieldType: models.FieldTypeText, required: false, order: 7, group: "Bean Characteristics"},
				{key: "processing_method", label: "Processing Method", fieldType: models.FieldTypeEnum, required: false, order: 8, group: "Bean Characteristics", options: `["Lavé","Nature","Honey","Anaérobie","Macération Carbonique","Décortiqué Humide","Nature Dépulpé"]`},
				{key: "decaffeinated", label: "Decaffeinated", fieldType: models.FieldTypeCheckbox, required: false, order: 9, group: "Bean Characteristics"},
				{key: "roast_level", label: "Roast Level", fieldType: models.FieldTypeEnum, required: false, order: 10, group: "Roasting", options: `["Pâle","Moyen","Foncé"]`},
				{key: "tasting_notes", label: "Tasting Notes", fieldType: models.FieldTypeText, required: false, order: 11, group: "Flavor Profile"},
				{key: "acidity", label: "Acidity", fieldType: models.FieldTypeEnum, required: false, order: 12, group: "Flavor Profile", options: `["Faible","Moyen","Élevé"]`},
				{key: "body", label: "Body", fieldType: models.FieldTypeEnum, required: false, order: 13, group: "Flavor Profile", options: `["Faible","Moyen","Élevé"]`},
				{key: "sweetness", label: "Sweetness", fieldType: models.FieldTypeEnum, required: false, order: 14, group: "Flavor Profile", options: `["Faible","Moyen","Élevé"]`},
				{key: "organic", label: "Organic", fieldType: models.FieldTypeCheckbox, required: false, order: 15, group: "Certifications"},
				{key: "fair_trade", label: "Fair Trade", fieldType: models.FieldTypeCheckbox, required: false, order: 16, group: "Certifications"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 17, group: "Basic Info"},
			},
		},
		{
			name:         "chili-sauce",
			displayName:  "Chili Sauce",
			pluralName:   "Chili Sauces",
			icon:         "chili-sauce",
			color:        "#FF4500",
			uniqueFields: []string{"name", "brand"},
			fields: []struct {
				key        string
				label      string
				fieldType  models.FieldType
				required   bool
				order      int
				group      string
				validation string
				options    string
			}{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "brand", label: "Brand", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "spice_level", label: "Spice Level", fieldType: models.FieldTypeEnum, required: true, order: 2, group: "Basic Info", options: `["Mild","Medium","Hot","Extra Hot","Extreme"]`},
				{key: "chilis", label: "Chilis Used", fieldType: models.FieldTypeText, required: false, order: 3, group: "Ingredients"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
	}

	for _, s := range schemas {
		var existing models.ItemTypeSchema
		err := db.Where("name = ?", s.name).First(&existing).Error
		if err == nil {
			// Already exists
			continue
		}

		schema := models.ItemTypeSchema{
			Name:        s.name,
			DisplayName: s.displayName,
			PluralName:  s.pluralName,
			Icon:        s.icon,
			Color:       s.color,
			IsActive:    true,
		}

		if len(s.uniqueFields) > 0 {
			uniqueFieldsJSON, _ := json.Marshal(s.uniqueFields)
			schema.UniqueFields = string(uniqueFieldsJSON)
		}

		if err := db.Create(&schema).Error; err != nil {
			log.Printf("Failed to create schema '%s': %v", s.name, err)
			continue
		}

		for _, f := range s.fields {
			group := f.group
			var validation, options *string
			if f.validation != "" {
				validation = &f.validation
			}
			if f.options != "" {
				options = &f.options
			}
			field := models.ItemTypeField{
				SchemaID:   schema.ID,
				Key:        f.key,
				Label:      f.label,
				FieldType:  f.fieldType,
				Required:   f.required,
				Order:      f.order,
				Group:      &group,
				Validation: validation,
				Options:    options,
			}

			if err := db.Create(&field).Error; err != nil {
				log.Printf("Failed to create field '%s' for schema '%s': %v", f.key, s.name, err)
			}
		}
	}

	return nil
}

// BuildFieldMap creates a map of field key to ItemTypeField for a given schema ID.
func BuildFieldMap(db *gorm.DB, schemaID uint) map[string]models.ItemTypeField {
	var fields []models.ItemTypeField
	db.Where("schema_id = ?", schemaID).Find(&fields)

	fieldMap := make(map[string]models.ItemTypeField)
	for _, f := range fields {
		fieldMap[f.Key] = f
	}
	return fieldMap
}

// BuildFieldValuesJSON creates a JSON string from field values, handling checkbox types.
func BuildFieldValuesJSON(fieldMap map[string]models.ItemTypeField, values map[string]interface{}) string {
	result := make(map[string]interface{})
	for key, val := range values {
		if f, ok := fieldMap[key]; ok && f.FieldType == models.FieldTypeCheckbox {
			if b, ok := val.(bool); ok {
				result[key] = b
				continue
			}
		}
		if val != nil && val != "" {
			result[key] = val
		}
	}
	jsonBytes, _ := json.Marshal(result)
	return string(jsonBytes)
}

// CreateFieldValueRecords creates ItemFieldValue records for a given item.
func CreateFieldValueRecords(db *gorm.DB, itemID uint, fieldMap map[string]models.ItemTypeField, values map[string]interface{}) error {
	for key, val := range values {
		field, ok := fieldMap[key]
		if !ok {
			continue
		}

		valStr := ""
		switch v := val.(type) {
		case string:
			valStr = v
		case float64:
			valStr = fmt.Sprintf("%v", v)
		case bool:
			valStr = fmt.Sprintf("%v", v)
		default:
			if v != nil {
				valStr = fmt.Sprintf("%v", v)
			}
		}

		if valStr == "" {
			continue
		}

		fieldValue := models.ItemFieldValue{
			ItemID:  itemID,
			FieldID: field.ID,
			Value:   &valStr,
		}

		if err := db.Create(&fieldValue).Error; err != nil {
			return fmt.Errorf("failed to create field value for %s: %w", key, err)
		}
	}
	return nil
}
