package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"gorm.io/gorm"
)

var (
	MigratedItems   int
	MigratedRatings int
	ErrorItems      int
)

func CreateSchemaDefinitions() {
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
		err := utils.DB.Where("name = ?", s.name).First(&existing).Error
		if err == nil {
			// Check if schema already has the correct number of fields
			var fieldCount int64
			utils.DB.Model(&models.ItemTypeField{}).Where("schema_id = ?", existing.ID).Count(&fieldCount)

			// Check if any expected fields are missing
			var missingFields []string
			for _, f := range s.fields {
				var existingField models.ItemTypeField
				err := utils.DB.Where("schema_id = ? AND `key` = ?", existing.ID, f.key).First(&existingField).Error
				if err != nil {
					missingFields = append(missingFields, f.key)
				}
			}

			// Update unique_fields if needed
			if len(s.uniqueFields) > 0 {
				uniqueFieldsJSON, _ := json.Marshal(s.uniqueFields)
				utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", existing.ID).Update("unique_fields", string(uniqueFieldsJSON))
			}

			if len(missingFields) == 0 {
				fmt.Printf("   ⊘ Schema '%s' already exists with all %d fields, skipping\n", s.name, fieldCount)
				continue
			}

			// Schema exists but has missing fields - create missing fields
			fmt.Printf("   → Schema '%s' exists with %d fields, adding missing: %v\n", s.name, fieldCount, missingFields)
			for _, f := range s.fields {
				var existingField models.ItemTypeField
				err := utils.DB.Where("schema_id = ? AND `key` = ?", existing.ID, f.key).First(&existingField).Error
				if err == nil {
					continue // Field already exists, skip
				}
				group := f.group
				var validation, options *string
				if f.validation != "" {
					validation = &f.validation
				}
				if f.options != "" {
					options = &f.options
				}
				field := models.ItemTypeField{
					SchemaID:   existing.ID,
					Key:        f.key,
					Label:      f.label,
					FieldType:  f.fieldType,
					Required:   f.required,
					Order:      f.order,
					Group:      &group,
					Validation: validation,
					Options:    options,
				}
				if err := utils.DB.Create(&field).Error; err != nil {
					log.Printf("   ✗ Failed to create field '%s' for schema '%s': %v", f.key, s.name, err)
				}
			}
			fmt.Printf("   ✓ Added missing fields for schema '%s'\n", s.name)
			continue
		}

		if err != gorm.ErrRecordNotFound {
			log.Printf("   ✗ Error checking schema '%s': %v", s.name, err)
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

		if err := utils.DB.Create(&schema).Error; err != nil {
			log.Printf("   ✗ Failed to create schema '%s': %v", s.name, err)
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

			if err := utils.DB.Create(&field).Error; err != nil {
				log.Printf("   ✗ Failed to create field '%s' for schema '%s': %v", f.key, s.name, err)
			}
		}

		fmt.Printf("   ✓ Created schema '%s' with %d fields\n", s.name, len(s.fields))
	}
}

func CreateSchemaVersions() {
	var schemas []models.ItemTypeSchema
	if err := utils.DB.Preload("Fields").Find(&schemas).Error; err != nil {
		log.Printf("Failed to load schemas: %v", err)
		return
	}

	for _, schema := range schemas {
		var existing models.SchemaVersion
		err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&existing).Error
		if err == nil {
			fmt.Printf("   ⊘ Schema version 1 for '%s' already exists, skipping\n", schema.Name)
			continue
		}

		fieldsJSON, err := json.Marshal(schema.Fields)
		if err != nil {
			log.Printf("   ✗ Failed to marshal fields for schema '%s': %v", schema.Name, err)
			continue
		}

		version := models.SchemaVersion{
			SchemaID: schema.ID,
			Version:  1,
			Fields:   string(fieldsJSON),
			IsActive: true,
		}

		if err := utils.DB.Create(&version).Error; err != nil {
			log.Printf("   ✗ Failed to create version for schema '%s': %v", schema.Name, err)
			continue
		}

		fmt.Printf("   ✓ Created version 1 for schema '%s'\n", schema.Name)
	}
}

func MigrateData() {
	MigrateCheese()
	MigrateGin()
	MigrateWine()
	MigrateCoffee()
	MigrateChiliSauce()
}

func MigrateCheese() {
	fmt.Println("\n   🧀 Migrating cheeses...")

	var cheeses []models.Cheese
	if err := utils.DB.Find(&cheeses).Error; err != nil {
		log.Printf("      ✗ Failed to load cheeses: %v", err)
		return
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "cheese").First(&schema).Error; err != nil {
		log.Printf("      ✗ Cheese schema not found: %v", err)
		return
	}

	var version models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
		log.Printf("      ✗ Cheese schema version not found: %v", err)
		return
	}

	fieldMap := BuildFieldMap(schema.ID)

	for _, cheese := range cheeses {
		fieldValues := BuildFieldValues(fieldMap, map[string]interface{}{
			"name":        cheese.Name,
			"type":        cheese.Type,
			"origin":      cheese.Origin,
			"producer":    cheese.Producer,
			"description": cheese.Description,
		})

		item := models.Item{
			Name:            cheese.Name,
			SchemaID:        schema.ID,
			ImageURL:        cheese.ImageURL,
			FieldValues:     fieldValues,
			UserID:          1,
			SchemaVersionID: &version.ID,
		}

		if err := utils.DB.Create(&item).Error; err != nil {
			log.Printf("      ✗ Failed to migrate cheese '%s': %v", cheese.Name, err)
			ErrorItems++
			continue
		}

		MigrateFieldValues(item.ID, fieldMap, map[string]interface{}{
			"type":        cheese.Type,
			"origin":      cheese.Origin,
			"producer":    cheese.Producer,
			"description": cheese.Description,
		})

		MigrateRatings(item.ID, cheese.ID, "cheese")
		MigratedItems++
	}

	fmt.Printf("      ✓ Migrated %d cheeses\n", len(cheeses))
}

func MigrateGin() {
	fmt.Println("\n   🍸 Migrating gins...")

	var gins []models.Gin
	if err := utils.DB.Find(&gins).Error; err != nil {
		log.Printf("      ✗ Failed to load gins: %v", err)
		return
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "gin").First(&schema).Error; err != nil {
		log.Printf("      ✗ Gin schema not found: %v", err)
		return
	}

	var version models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
		log.Printf("      ✗ Gin schema version not found: %v", err)
		return
	}

	fieldMap := BuildFieldMap(schema.ID)

	for _, gin := range gins {
		fieldValues := BuildFieldValues(fieldMap, map[string]interface{}{
			"name":        gin.Name,
			"producer":    gin.Producer,
			"origin":      gin.Origin,
			"profile":     gin.Profile,
			"description": gin.Description,
		})

		item := models.Item{
			Name:            gin.Name,
			SchemaID:        schema.ID,
			ImageURL:        gin.ImageURL,
			FieldValues:     fieldValues,
			UserID:          1,
			SchemaVersionID: &version.ID,
		}

		if err := utils.DB.Create(&item).Error; err != nil {
			log.Printf("      ✗ Failed to migrate gin '%s': %v", gin.Name, err)
			ErrorItems++
			continue
		}

		MigrateFieldValues(item.ID, fieldMap, map[string]interface{}{
			"producer":    gin.Producer,
			"origin":      gin.Origin,
			"profile":     gin.Profile,
			"description": gin.Description,
		})

		MigrateRatings(item.ID, gin.ID, "gin")
		MigratedItems++
	}

	fmt.Printf("      ✓ Migrated %d gins\n", len(gins))
}

func MigrateWine() {
	fmt.Println("\n   🍷 Migrating wines...")

	var wines []models.Wine
	if err := utils.DB.Find(&wines).Error; err != nil {
		log.Printf("      ✗ Failed to load wines: %v", err)
		return
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "wine").First(&schema).Error; err != nil {
		log.Printf("      ✗ Wine schema not found: %v", err)
		return
	}

	var version models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
		log.Printf("      ✗ Wine schema version not found: %v", err)
		return
	}

	fieldMap := BuildFieldMap(schema.ID)

	for _, wine := range wines {
		colorStr := string(wine.Color)
		alcohol := wine.Alcohol
		sugar := wine.Sugar

		fieldValues := BuildFieldValues(fieldMap, map[string]interface{}{
			"name":        wine.Name,
			"producer":    wine.Producer,
			"country":     wine.Country,
			"region":      wine.Region,
			"color":       colorStr,
			"grape":       wine.Grape,
			"alcohol":     alcohol,
			"designation": wine.Designation,
			"sugar":       sugar,
			"organic":     wine.Organic,
			"description": wine.Description,
		})

		item := models.Item{
			Name:            wine.Name,
			SchemaID:        schema.ID,
			ImageURL:        wine.ImageURL,
			FieldValues:     fieldValues,
			UserID:          1,
			SchemaVersionID: &version.ID,
		}

		if err := utils.DB.Create(&item).Error; err != nil {
			log.Printf("      ✗ Failed to migrate wine '%s': %v", wine.Name, err)
			ErrorItems++
			continue
		}

		MigrateFieldValues(item.ID, fieldMap, map[string]interface{}{
			"producer":    wine.Producer,
			"country":     wine.Country,
			"region":      wine.Region,
			"color":       colorStr,
			"grape":       wine.Grape,
			"alcohol":     alcohol,
			"designation": wine.Designation,
			"sugar":       sugar,
			"organic":     wine.Organic,
			"description": wine.Description,
		})

		MigrateRatings(item.ID, wine.ID, "wine")
		MigratedItems++
	}

	fmt.Printf("      ✓ Migrated %d wines\n", len(wines))
}

func MigrateCoffee() {
	fmt.Println("\n   ☕ Migrating coffees...")

	var coffees []models.Coffee
	if err := utils.DB.Find(&coffees).Error; err != nil {
		log.Printf("      ✗ Failed to load coffees: %v", err)
		return
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "coffee").First(&schema).Error; err != nil {
		log.Printf("      ✗ Coffee schema not found: %v", err)
		return
	}

	var version models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
		log.Printf("      ✗ Coffee schema version not found: %v", err)
		return
	}

	fieldMap := BuildFieldMap(schema.ID)

	for _, coffee := range coffees {
		tastingNotes := ""
		if len(coffee.TastingNotes) > 0 {
			tastingNotes = coffee.TastingNotes[0]
		}

		fieldValues := BuildFieldValues(fieldMap, map[string]interface{}{
			"name":              coffee.Name,
			"roaster":           coffee.Roaster,
			"country":           coffee.Country,
			"region":            coffee.Region,
			"farm":              coffee.Farm,
			"altitude":          coffee.Altitude,
			"species":           coffee.Species,
			"variety":           coffee.Variety,
			"processing_method": coffee.ProcessingMethod,
			"decaffeinated":     coffee.Decaffeinated,
			"roast_level":       coffee.RoastLevel,
			"tasting_notes":     tastingNotes,
			"acidity":           coffee.Acidity,
			"body":              coffee.Body,
			"sweetness":         coffee.Sweetness,
			"organic":           coffee.Organic,
			"fair_trade":        coffee.FairTrade,
			"description":       coffee.Description,
		})

		item := models.Item{
			Name:            coffee.Name,
			SchemaID:        schema.ID,
			ImageURL:        coffee.ImageURL,
			FieldValues:     fieldValues,
			UserID:          1,
			SchemaVersionID: &version.ID,
		}

		if err := utils.DB.Create(&item).Error; err != nil {
			log.Printf("      ✗ Failed to migrate coffee '%s': %v", coffee.Name, err)
			ErrorItems++
			continue
		}

		MigrateFieldValues(item.ID, fieldMap, map[string]interface{}{
			"roaster":           coffee.Roaster,
			"country":           coffee.Country,
			"region":            coffee.Region,
			"farm":              coffee.Farm,
			"altitude":          coffee.Altitude,
			"species":           coffee.Species,
			"variety":           coffee.Variety,
			"processing_method": coffee.ProcessingMethod,
			"decaffeinated":     coffee.Decaffeinated,
			"roast_level":       coffee.RoastLevel,
			"tasting_notes":     tastingNotes,
			"acidity":           coffee.Acidity,
			"body":              coffee.Body,
			"sweetness":         coffee.Sweetness,
			"organic":           coffee.Organic,
			"fair_trade":        coffee.FairTrade,
			"description":       coffee.Description,
		})

		MigrateRatings(item.ID, coffee.ID, "coffee")
		MigratedItems++
	}

	fmt.Printf("      ✓ Migrated %d coffees\n", len(coffees))
}

func MigrateChiliSauce() {
	fmt.Println("\n   🌶️  Migrating chili sauces...")

	var chiliSauces []models.ChiliSauce
	if err := utils.DB.Find(&chiliSauces).Error; err != nil {
		log.Printf("      ✗ Failed to load chili sauces: %v", err)
		return
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "chili-sauce").First(&schema).Error; err != nil {
		log.Printf("      ✗ Chili sauce schema not found: %v", err)
		return
	}

	var version models.SchemaVersion
	if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
		log.Printf("      ✗ Chili sauce schema version not found: %v", err)
		return
	}

	fieldMap := BuildFieldMap(schema.ID)

	for _, cs := range chiliSauces {
		spiceLevel := string(cs.SpiceLevel)

		fieldValues := BuildFieldValues(fieldMap, map[string]interface{}{
			"name":        cs.Name,
			"brand":       cs.Brand,
			"spice_level": spiceLevel,
			"chilis":      cs.Chilis,
			"description": cs.Description,
		})

		item := models.Item{
			Name:            cs.Name,
			SchemaID:        schema.ID,
			ImageURL:        cs.ImageURL,
			FieldValues:     fieldValues,
			UserID:          1,
			SchemaVersionID: &version.ID,
		}

		if err := utils.DB.Create(&item).Error; err != nil {
			log.Printf("      ✗ Failed to migrate chili sauce '%s': %v", cs.Name, err)
			ErrorItems++
			continue
		}

		MigrateFieldValues(item.ID, fieldMap, map[string]interface{}{
			"brand":       cs.Brand,
			"spice_level": spiceLevel,
			"chilis":      cs.Chilis,
			"description": cs.Description,
		})

		MigrateRatings(item.ID, cs.ID, "chili_sauce")
		MigratedItems++
	}

	fmt.Printf("      ✓ Migrated %d chili sauces\n", len(chiliSauces))
}

func BuildFieldMap(schemaID uint) map[string]models.ItemTypeField {
	var fields []models.ItemTypeField
	utils.DB.Where("schema_id = ?", schemaID).Find(&fields)

	fieldMap := make(map[string]models.ItemTypeField)
	for _, f := range fields {
		fieldMap[f.Key] = f
	}
	return fieldMap
}

func BuildFieldValues(fieldMap map[string]models.ItemTypeField, values map[string]interface{}) string {
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

func MigrateFieldValues(itemID uint, fieldMap map[string]models.ItemTypeField, values map[string]interface{}) {
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

		utils.DB.Create(&fieldValue)
	}
}

func MigrateRatings(newItemID uint, oldItemID uint, itemType string) {
	var ratings []models.Rating
	if err := utils.DB.Where("item_type = ? AND item_id = ?", itemType, oldItemID).Find(&ratings).Error; err != nil {
		return
	}

	for _, rating := range ratings {
		rating.ID = 0
		rating.ItemType = "Item"
		rating.ItemID = int(newItemID)
		if err := utils.DB.Create(&rating).Error; err != nil {
			log.Printf("      ✗ Failed to migrate rating: %v", err)
			continue
		}
		MigratedRatings++
	}
}
