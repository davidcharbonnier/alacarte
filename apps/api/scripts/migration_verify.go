//go:build ignore
// +build ignore

package main

import (
	"fmt"
	"log"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

// VerifyMigrationResult holds the results of a migration verification
type VerifyMigrationResult struct {
	SchemaCount      int64
	FieldCount       int64
	VersionCount     int64
	ItemCount        int64
	FieldValueCount  int64
	RatingCount      int64
	CheeseCount      int64
	GinCount         int64
	WineCount        int64
	CoffeeCount      int64
	ChiliSauceCount  int64
	OldItemsTotal    int64
	MigrationMatch   bool
}

// VerifyMigration checks the integrity of the migration by counting records
// in both old and new tables and comparing them.
func VerifyMigration() VerifyMigrationResult {
	fmt.Println("\n🔍 Verifying migration integrity...")

	var result VerifyMigrationResult

	utils.DB.Model(&models.ItemTypeSchema{}).Count(&result.SchemaCount)
	fmt.Printf("   Schemas: %d (expected: 5)\n", result.SchemaCount)

	utils.DB.Model(&models.ItemTypeField{}).Count(&result.FieldCount)
	fmt.Printf("   Total fields: %d\n", result.FieldCount)

	utils.DB.Model(&models.SchemaVersion{}).Count(&result.VersionCount)
	fmt.Printf("   Schema versions: %d (expected: 5)\n", result.VersionCount)

	utils.DB.Model(&models.Item{}).Count(&result.ItemCount)
	fmt.Printf("   Items migrated: %d\n", result.ItemCount)

	utils.DB.Model(&models.ItemFieldValue{}).Count(&result.FieldValueCount)
	fmt.Printf("   Field values: %d\n", result.FieldValueCount)

	utils.DB.Model(&models.Rating{}).Where("item_type = ?", "Item").Count(&result.RatingCount)
	fmt.Printf("   Ratings migrated: %d\n", result.RatingCount)

	result.CheeseCount = CountItemsBySchema("cheese")
	result.GinCount = CountItemsBySchema("gin")
	result.WineCount = CountItemsBySchema("wine")
	result.CoffeeCount = CountItemsBySchema("coffee")
	result.ChiliSauceCount = CountItemsBySchema("chili-sauce")

	fmt.Printf("\n   Items per schema:\n")
	fmt.Printf("      Cheese: %d\n", result.CheeseCount)
	fmt.Printf("      Gin: %d\n", result.GinCount)
	fmt.Printf("      Wine: %d\n", result.WineCount)
	fmt.Printf("      Coffee: %d\n", result.CoffeeCount)
	fmt.Printf("      Chili Sauce: %d\n", result.ChiliSauceCount)

	result.OldItemsTotal = CountOldItems()
	result.MigrationMatch = result.ItemCount == result.OldItemsTotal && result.ItemCount > 0

	fmt.Printf("\n   Old tables total: %d\n", result.OldItemsTotal)
	fmt.Printf("   Migration match: %v\n", result.MigrationMatch)

	return result
}

// CountItemsBySchema returns the number of items for a given schema name.
func CountItemsBySchema(schemaName string) int64 {
	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", schemaName).First(&schema).Error; err != nil {
		return 0
	}
	var count int64
	utils.DB.Model(&models.Item{}).Where("schema_id = ?", schema.ID).Count(&count)
	return count
}

// CountOldItems returns the total count of items across all legacy tables.
func CountOldItems() int64 {
	var cheeseCount, ginCount, wineCount, coffeeCount, chiliSauceCount int64
	utils.DB.Model(&models.Cheese{}).Count(&cheeseCount)
	utils.DB.Model(&models.Gin{}).Count(&ginCount)
	utils.DB.Model(&models.Wine{}).Count(&wineCount)
	utils.DB.Model(&models.Coffee{}).Count(&coffeeCount)
	utils.DB.Model(&models.ChiliSauce{}).Count(&chiliSauceCount)
	return cheeseCount + ginCount + wineCount + coffeeCount + chiliSauceCount
}

// PerformRollback deletes all migrated data from the new schema tables.
func PerformRollback() {
	fmt.Println("⚠️  Performing rollback with raw SQL...")

	tables := []string{
		"ratings", "item_field_values", "items",
		"schema_versions", "item_type_fields", "item_type_schemas",
	}
	for _, table := range tables {
		result := utils.DB.Exec("DELETE FROM " + table)
		if result.Error != nil {
			log.Printf("   ✗ Failed to delete from %s: %v", table, result.Error)
		} else {
			rows := result.RowsAffected
			fmt.Printf("   Deleted %d rows from %s\n", rows, table)
		}
	}

	fmt.Println("✅ Rollback completed")
}

// VerifySchemaFields checks that each schema has the expected fields.
func VerifySchemaFields() map[string]int64 {
	fmt.Println("\n🔍 Verifying schema fields...")

	schemas := []string{"cheese", "gin", "wine", "coffee", "chili-sauce"}
	expectedFields := map[string]int{
		"cheese":      5,
		"gin":         5,
		"wine":        11,
		"coffee":      18,
		"chili-sauce": 5,
	}

	results := make(map[string]int64)
	for _, schemaName := range schemas {
		var schema models.ItemTypeSchema
		if err := utils.DB.Where("name = ?", schemaName).First(&schema).Error; err != nil {
			log.Printf("   ✗ Schema '%s' not found: %v", schemaName, err)
			results[schemaName] = 0
			continue
		}

		var fieldCount int64
		utils.DB.Model(&models.ItemTypeField{}).Where("schema_id = ?", schema.ID).Count(&fieldCount)
		results[schemaName] = fieldCount

		expected := int64(expectedFields[schemaName])
		if fieldCount == expected {
			fmt.Printf("   ✓ Schema '%s' has %d fields (expected %d)\n", schemaName, fieldCount, expected)
		} else {
			fmt.Printf("   ✗ Schema '%s' has %d fields (expected %d)\n", schemaName, fieldCount, expected)
		}
	}

	return results
}

// VerifyItemFieldValues checks that every item has corresponding EAV field values.
func VerifyItemFieldValues() (itemsWithValues int64, itemsWithoutValues int64) {
	fmt.Println("\n🔍 Verifying item field values...")

	var items []models.Item
	utils.DB.Find(&items)

	for _, item := range items {
		var count int64
		utils.DB.Model(&models.ItemFieldValue{}).Where("item_id = ?", item.ID).Count(&count)
		if count > 0 {
			itemsWithValues++
		} else {
			itemsWithoutValues++
		}
	}

	fmt.Printf("   Items with field values: %d\n", itemsWithValues)
	fmt.Printf("   Items without field values: %d\n", itemsWithoutValues)

	return itemsWithValues, itemsWithoutValues
}

// VerifyRatingsMigrated checks that ratings were properly migrated to the new item type.
func VerifyRatingsMigrated() (migratedCount int64, oldCount int64) {
	fmt.Println("\n🔍 Verifying ratings migration...")

	utils.DB.Model(&models.Rating{}).Where("item_type = ?", "Item").Count(&migratedCount)
	utils.DB.Model(&models.Rating{}).Where("item_type IN ?", []string{"cheese", "gin", "wine", "coffee", "chili_sauce"}).Count(&oldCount)

	fmt.Printf("   Migrated ratings (item_type='Item'): %d\n", migratedCount)
	fmt.Printf("   Old ratings (legacy item_type): %d\n", oldCount)

	return migratedCount, oldCount
}
