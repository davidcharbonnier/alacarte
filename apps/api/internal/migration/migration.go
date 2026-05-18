package migration

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

// MigrationStats tracks migration progress (per-instance only, not thread-safe)
var (
	MigratedItems   int
	MigratedRatings int
	ErrorItems      int
)

// getBatchSize returns the batch size from env var or default
func getBatchSize() int {
	if size := os.Getenv("MIGRATION_BATCH_SIZE"); size != "" {
		if n, err := strconv.Atoi(size); err == nil && n > 0 {
			return n
		}
	}
	return 100 // default
}

// RunSelfHealingMigration executes the full migration pipeline with automatic rollback on failure.
func RunSelfHealingMigration() error {
	fmt.Println("🚀 Starting self-healing dynamic schema migration...")
	fmt.Printf("   Batch size: %d items\n", getBatchSize())
	fmt.Println()

	// Step 1: Create schema definitions
	fmt.Println("📋 Step 1: Creating schema definitions...")
	if err := CreateSchemaDefinitions(); err != nil {
		return fmt.Errorf("failed to create schema definitions: %w", err)
	}

	// Step 2: Create schema versions
	fmt.Println("\n📋 Step 2: Creating initial schema versions...")
	if err := CreateSchemaVersions(); err != nil {
		return fmt.Errorf("failed to create schema versions: %w", err)
	}

	// Step 3: Migrate data with batch processing
	fmt.Println("\n📋 Step 3: Migrating data with batch processing...")
	if err := migrateAllData(); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	fmt.Println("\n✅ Migration completed successfully!")
	fmt.Printf("   Items migrated: %d\n", MigratedItems)
	fmt.Printf("   Ratings migrated: %d\n", MigratedRatings)
	if ErrorItems > 0 {
		fmt.Printf("   Items with errors: %d\n", ErrorItems)
	}
	return nil
}

type fieldDef struct {
	key        string
	label      string
	fieldType  models.FieldType
	required   bool
	order      int
	group      string
	validation string
	options    string
}

// CreateSchemaDefinitions creates the ItemTypeSchema and ItemTypeField records.
func CreateSchemaDefinitions() error {
	schemas := []struct {
		schema       models.ItemTypeSchema
		uniqueFields []string
		fields       []fieldDef
	}{
		{
			schema:       models.ItemTypeSchema{Name: "cheese", DisplayName: "Cheese", PluralName: "Cheeses", Icon: "cheese", Color: "#FFD700", IsActive: true},
			uniqueFields: []string{"name"},
			fields: []fieldDef{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "type", label: "Type", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "origin", label: "Origin", fieldType: models.FieldTypeText, required: false, order: 2, group: "Basic Info"},
				{key: "producer", label: "Producer", fieldType: models.FieldTypeText, required: false, order: 3, group: "Basic Info"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
		{
			schema:       models.ItemTypeSchema{Name: "gin", DisplayName: "Gin", PluralName: "Gins", Icon: "gin", Color: "#87CEEB", IsActive: true},
			uniqueFields: []string{"name", "producer"},
			fields: []fieldDef{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "producer", label: "Producer", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "origin", label: "Origin", fieldType: models.FieldTypeText, required: false, order: 2, group: "Basic Info"},
				{key: "profile", label: "Profile", fieldType: models.FieldTypeText, required: true, order: 3, group: "Basic Info"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
		{
			schema:       models.ItemTypeSchema{Name: "wine", DisplayName: "Wine", PluralName: "Wines", Icon: "wine", Color: "#722F37", IsActive: true},
			uniqueFields: []string{"name", "color"},
			fields: []fieldDef{
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
			schema:       models.ItemTypeSchema{Name: "coffee", DisplayName: "Coffee", PluralName: "Coffees", Icon: "coffee", Color: "#6F4E37", IsActive: true},
			uniqueFields: []string{"name", "roaster"},
			fields: []fieldDef{
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
			schema:       models.ItemTypeSchema{Name: "chili-sauce", DisplayName: "Chili Sauce", PluralName: "Chili Sauces", Icon: "chili-sauce", Color: "#FF4500", IsActive: true},
			uniqueFields: []string{"name", "brand"},
			fields: []fieldDef{
				{key: "name", label: "Name", fieldType: models.FieldTypeText, required: true, order: 0, group: "Basic Info"},
				{key: "brand", label: "Brand", fieldType: models.FieldTypeText, required: true, order: 1, group: "Basic Info"},
				{key: "spice_level", label: "Spice Level", fieldType: models.FieldTypeEnum, required: true, order: 2, group: "Basic Info", options: `["Mild","Medium","Hot","Extra Hot","Extreme"]`},
				{key: "chilis", label: "Chilis Used", fieldType: models.FieldTypeText, required: false, order: 3, group: "Ingredients"},
				{key: "description", label: "Description", fieldType: models.FieldTypeTextarea, required: false, order: 4, group: "Basic Info"},
			},
		},
	}

	for _, s := range schemas {
		if err := createOrUpdateSchema(&s.schema, s.uniqueFields, s.fields); err != nil {
			return err
		}
	}
	return nil
}

func createOrUpdateSchema(schema *models.ItemTypeSchema, uniqueFields []string, fields []fieldDef) error {
	var existing models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", schema.Name).First(&existing).Error; err == nil {
		var fieldCount int64
		utils.DB.Model(&models.ItemTypeField{}).Where("schema_id = ?", existing.ID).Count(&fieldCount)
		if int(fieldCount) == len(fields) {
			fmt.Printf("   ⊘ Schema '%s' already exists, skipping\n", schema.Name)
			return nil
		}
		for _, f := range fields {
			var existingField models.ItemTypeField
			if err := utils.DB.Where("schema_id = ? AND `key` = ?", existing.ID, f.key).First(&existingField).Error; err != nil {
				if err := createField(existing.ID, &f); err != nil {
					return err
				}
			}
		}
		// Update unique fields if they have changed
		if len(uniqueFields) > 0 {
			uniqueFieldsJSON, _ := json.Marshal(uniqueFields)
			utils.DB.Model(&models.ItemTypeSchema{}).Where("id = ?", existing.ID).Update("unique_fields", string(uniqueFieldsJSON))
		}
		fmt.Printf("   ✓ Updated schema '%s'\n", schema.Name)
		return nil
	}

	if len(uniqueFields) > 0 {
		uniqueFieldsJSON, err := json.Marshal(uniqueFields)
		if err != nil {
			return err
		}
		schema.UniqueFields = string(uniqueFieldsJSON)
	}
	if err := utils.DB.Create(schema).Error; err != nil {
		return err
	}
	for _, f := range fields {
		if err := createField(schema.ID, &f); err != nil {
			return err
		}
	}
	fmt.Printf("   ✓ Created schema '%s'\n", schema.Name)
	return nil
}

func createField(schemaID uint, def *fieldDef) error {
	group := def.group
	field := models.ItemTypeField{
		SchemaID:  schemaID,
		Key:       def.key,
		Label:     def.label,
		FieldType: def.fieldType,
		Required:  def.required,
		Order:     def.order,
		Group:     &group,
	}
	if def.validation != "" {
		field.Validation = &def.validation
	}
	if def.options != "" {
		field.Options = &def.options
	}
	return utils.DB.Create(&field).Error
}

// CreateSchemaVersions creates initial versions for all schemas.
func CreateSchemaVersions() error {
	var schemas []models.ItemTypeSchema
	if err := utils.DB.Preload("Fields").Find(&schemas).Error; err != nil {
		return err
	}
	for _, schema := range schemas {
		var existing models.SchemaVersion
		if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&existing).Error; err == nil {
			continue
		}
		fieldsJSON, _ := json.Marshal(schema.Fields)
		version := models.SchemaVersion{SchemaID: schema.ID, Version: 1, Fields: string(fieldsJSON), IsActive: true}
		if err := utils.DB.Create(&version).Error; err != nil {
			return err
		}
	}
	return nil
}

// migrateAllData migrates all legacy data with batched processing.
func migrateAllData() error {
	// Get schema IDs (these are stable, looked up once)
	schemaMap, err := getSchemaMap()
	if err != nil {
		return err
	}

	// Migrate each type
	if err := migrateInBatches("cheese", schemaMap["cheese"]); err != nil {
		return err
	}
	if err := migrateInBatches("gin", schemaMap["gin"]); err != nil {
			return err
	}
	if err := migrateInBatches("wine", schemaMap["wine"]); err != nil {
		return err
	}
	if err := migrateInBatches("coffee", schemaMap["coffee"]); err != nil {
		return err
	}
	if err := migrateInBatches("chili-sauce", schemaMap["chili-sauce"]); err != nil {
		return err
	}

	// Verify
	return verifyMigration()
}

// schemaInfo holds schema and version info for a type
type schemaInfo struct {
	schemaID  uint
	versionID uint
}

// getSchemaMap looks up schema IDs for all supported types
func getSchemaMap() (map[string]schemaInfo, error) {
	result := make(map[string]schemaInfo)
	types := []string{"cheese", "gin", "wine", "coffee", "chili-sauce"}
	
	for _, t := range types {
		var schema models.ItemTypeSchema
		if err := utils.DB.Where("name = ?", t).First(&schema).Error; err != nil {
			return nil, fmt.Errorf("schema '%s' not found: %w", t, err)
		}
		var version models.SchemaVersion
		if err := utils.DB.Where("schema_id = ? AND version = ?", schema.ID, 1).First(&version).Error; err != nil {
			return nil, fmt.Errorf("version for '%s' not found: %w", t, err)
		}
		result[t] = schemaInfo{schemaID: schema.ID, versionID: version.ID}
	}
	return result, nil
}

// migrateInBatches processes items in batches to control memory usage
func migrateInBatches(itemType string, info schemaInfo) error {
	fmt.Printf("\n   🔄 Migrating %s (batch size: %d)...\n", itemType, getBatchSize())

	batch := 0
	totalMigrated := 0

loop:
	for {
		switch itemType {
		case "cheese":
			var items []models.Cheese
			if err := utils.DB.Limit(getBatchSize()).Offset(batch * getBatchSize()).Find(&items).Error; err != nil {
				return err
			}
			if len(items) == 0 {
				break loop
			}
			for _, item := range items {
				if err := migrateCheeseItem(&item, info.schemaID, info.versionID); err != nil {
					log.Printf("      ✗ Failed: %v", err)
					ErrorItems++
				}
			}
			totalMigrated += len(items)

		case "gin":
			var items []models.Gin
			if err := utils.DB.Limit(getBatchSize()).Offset(batch * getBatchSize()).Find(&items).Error; err != nil {
				return err
			}
			if len(items) == 0 {
				break loop
			}
			for _, item := range items {
				if err := migrateGinItem(&item, info.schemaID, info.versionID); err != nil {
					log.Printf("      ✗ Failed: %v", err)
					ErrorItems++
				}
			}
			totalMigrated += len(items)

		case "wine":
			var items []models.Wine
			if err := utils.DB.Limit(getBatchSize()).Offset(batch * getBatchSize()).Find(&items).Error; err != nil {
				return err
			}
			if len(items) == 0 {
				break loop
			}
			for _, item := range items {
				if err := migrateWineItem(&item, info.schemaID, info.versionID); err != nil {
					log.Printf("      ✗ Failed: %v", err)
					ErrorItems++
				}
			}
			totalMigrated += len(items)

		case "coffee":
			var items []models.Coffee
			if err := utils.DB.Limit(getBatchSize()).Offset(batch * getBatchSize()).Find(&items).Error; err != nil {
				return err
			}
			if len(items) == 0 {
				break loop
			}
			for _, item := range items {
				if err := migrateCoffeeItem(&item, info.schemaID, info.versionID); err != nil {
					log.Printf("      ✗ Failed: %v", err)
					ErrorItems++
				}
			}
			totalMigrated += len(items)

		case "chili-sauce":
			var items []models.ChiliSauce
			if err := utils.DB.Limit(getBatchSize()).Offset(batch * getBatchSize()).Find(&items).Error; err != nil {
				return err
			}
			if len(items) == 0 {
				break loop
			}
			for _, item := range items {
				if err := migrateChiliSauceItem(&item, info.schemaID, info.versionID); err != nil {
					log.Printf("      ✗ Failed: %v", err)
					ErrorItems++
				}
			}
			totalMigrated += len(items)
		}

		batch++
		if batch%10 == 0 {
			fmt.Printf("      ... processed ~%d items\n", batch*getBatchSize())
		}
	}

	fmt.Printf("      ✓ Migrated %d %s\n", totalMigrated, itemType)
	return nil
}

// Individual migration functions for each type

func migrateCheeseItem(item *models.Cheese, schemaID, versionID uint) error {
	fieldValues := map[string]interface{}{
		"name":        item.Name,
		"type":        item.Type,
		"origin":      item.Origin,
		"producer":    item.Producer,
		"description": item.Description,
	}
	return migrateItemToDynamic(item.Name, item.ImageURL, schemaID, versionID, fieldValues, int(item.ID), "cheese")
}

func migrateGinItem(item *models.Gin, schemaID, versionID uint) error {
	fieldValues := map[string]interface{}{
		"name":        item.Name,
		"producer":    item.Producer,
		"origin":      item.Origin,
		"profile":     item.Profile,
		"description": item.Description,
	}
	return migrateItemToDynamic(item.Name, item.ImageURL, schemaID, versionID, fieldValues, int(item.ID), "gin")
}

func migrateWineItem(item *models.Wine, schemaID, versionID uint) error {
	fieldValues := map[string]interface{}{
		"name":        item.Name,
		"producer":    item.Producer,
		"country":     item.Country,
		"region":      item.Region,
		"color":       string(item.Color),
		"grape":       item.Grape,
		"alcohol":     item.Alcohol,
		"designation": item.Designation,
		"sugar":       item.Sugar,
		"organic":     item.Organic,
		"description": item.Description,
	}
	return migrateItemToDynamic(item.Name, item.ImageURL, schemaID, versionID, fieldValues, int(item.ID), "wine")
}

func migrateCoffeeItem(item *models.Coffee, schemaID, versionID uint) error {
	tastingNotes := ""
	if len(item.TastingNotes) > 0 {
		tastingNotes = item.TastingNotes[0]
	}
	fieldValues := map[string]interface{}{
		"name":              item.Name,
		"roaster":           item.Roaster,
		"country":           item.Country,
		"region":            item.Region,
		"farm":              item.Farm,
		"altitude":          item.Altitude,
		"species":           item.Species,
		"variety":           item.Variety,
		"processing_method": item.ProcessingMethod,
		"decaffeinated":     item.Decaffeinated,
		"roast_level":       item.RoastLevel,
		"tasting_notes":     tastingNotes,
		"acidity":           item.Acidity,
		"body":              item.Body,
		"sweetness":         item.Sweetness,
		"organic":           item.Organic,
		"fair_trade":        item.FairTrade,
		"description":       item.Description,
	}
	return migrateItemToDynamic(item.Name, item.ImageURL, schemaID, versionID, fieldValues, int(item.ID), "coffee")
}

func migrateChiliSauceItem(item *models.ChiliSauce, schemaID, versionID uint) error {
	fieldValues := map[string]interface{}{
		"name":        item.Name,
		"brand":       item.Brand,
		"spice_level": string(item.SpiceLevel),
		"chilis":      item.Chilis,
		"description": item.Description,
	}
	return migrateItemToDynamic(item.Name, item.ImageURL, schemaID, versionID, fieldValues, int(item.ID), "chili_sauces")
}

// migrateItemToDynamic migrates a single legacy item to the new dynamic schema
func migrateItemToDynamic(name string, imageURL *string, schemaID, versionID uint, fieldValues map[string]interface{}, oldID int, oldItemType string) error {
	// Check if already migrated
	var existingItem models.Item
	if err := utils.DB.Where("name = ? AND schema_id = ?", name, schemaID).First(&existingItem).Error; err == nil {
		return nil // Already migrated, skip
	}

	// Marshal field values
	fieldValuesJSON, _ := json.Marshal(fieldValues)
	
	newItem := models.Item{
		Name:            name,
		SchemaID:        schemaID,
		ImageURL:        imageURL,
		FieldValues:     string(fieldValuesJSON),
		UserID:          1,
		SchemaVersionID: &versionID,
	}

	if err := utils.DB.Create(&newItem).Error; err != nil {
		return fmt.Errorf("failed to create item: %w", err)
	}
	MigratedItems++

	// Log the mapping for potential rollback
	migrationLog := models.MigrationLog{
		OldItemID: oldID,
		NewItemID: int(newItem.ID),
		ItemType:  oldItemType,
	}
	if err := utils.DB.Create(&migrationLog).Error; err != nil {
		log.Printf("      ⚠️ Failed to log migration mapping: %v", err)
	}

	// Migrate ratings
	return migrateRatings(newItem.ID, oldID, oldItemType)
}

// migrateRatings updates existing ratings in place to point to the new item ID
func migrateRatings(newItemID uint, oldItemID int, oldItemType string) error {
	result := utils.DB.Model(&models.Rating{}).
		Where("item_type = ? AND item_id = ?", oldItemType, oldItemID).
		Update("item_id", int(newItemID))
	
	if result.Error != nil {
		log.Printf("      ✗ Failed to migrate ratings: %v", result.Error)
		return result.Error
	}
	
	if result.RowsAffected > 0 {
		MigratedRatings += int(result.RowsAffected)
	}
	return nil
}

// verifyMigration checks that counts match expected values
func verifyMigration() error {
	var itemCount int64
	utils.DB.Model(&models.Item{}).Count(&itemCount)
	
	oldCount := countOldItems()
	if itemCount != oldCount {
		return fmt.Errorf("count mismatch: expected %d, got %d", oldCount, itemCount)
	}
	fmt.Printf("   ✓ Verification passed: %d items migrated\n", itemCount)
	return nil
}

// countOldItems returns the total count of all legacy items
func countOldItems() int64 {
	var cheeseCount, ginCount, wineCount, coffeeCount, chiliSauceCount int64
	if err := utils.DB.Model(&models.Cheese{}).Count(&cheeseCount).Error; err != nil {
		log.Printf("Warning: failed to count cheeses: %v", err)
	}
	if err := utils.DB.Model(&models.Gin{}).Count(&ginCount).Error; err != nil {
		log.Printf("Warning: failed to count gins: %v", err)
	}
	if err := utils.DB.Model(&models.Wine{}).Count(&wineCount).Error; err != nil {
		log.Printf("Warning: failed to count wines: %v", err)
	}
	if err := utils.DB.Model(&models.Coffee{}).Count(&coffeeCount).Error; err != nil {
		log.Printf("Warning: failed to count coffees: %v", err)
	}
	if err := utils.DB.Model(&models.ChiliSauce{}).Count(&chiliSauceCount).Error; err != nil {
		log.Printf("Warning: failed to count chili sauces: %v", err)
	}
	return cheeseCount + ginCount + wineCount + coffeeCount + chiliSauceCount
}

// PerformRollback restores ratings to their original item IDs and deletes migrated data
func PerformRollback() {
	fmt.Println("⚠️  Performing rollback...")

	// Step 1: Restore ratings to their original item IDs using migration log
	var logs []models.MigrationLog
	if err := utils.DB.Find(&logs).Error; err != nil {
		log.Printf("   ✗ Failed to read migration logs: %v", err)
	} else {
		restoredCount := int64(0)
		for _, logEntry := range logs {
			result := utils.DB.Model(&models.Rating{}).
				Where("item_id = ?", logEntry.NewItemID).
				Update("item_id", logEntry.OldItemID)
			if result.Error != nil {
				log.Printf("   ✗ Failed to restore ratings for item %d: %v", logEntry.NewItemID, result.Error)
			} else {
				restoredCount += result.RowsAffected
			}
		}
		fmt.Printf("   Restored %d ratings to original item IDs\n", restoredCount)
	}

	// Step 2: Delete migrated data from new schema tables
	tables := []string{"migration_logs", "item_field_values", "items", "schema_versions", "item_type_fields", "item_type_schemas"}
	for _, table := range tables {
		result := utils.DB.Exec("DELETE FROM " + table)
		if result.Error != nil {
			log.Printf("   ✗ Failed to delete from %s: %v", table, result.Error)
		} else {
			fmt.Printf("   Deleted %d rows from %s\n", result.RowsAffected, table)
		}
	}
	fmt.Println("✅ Rollback completed")
}
