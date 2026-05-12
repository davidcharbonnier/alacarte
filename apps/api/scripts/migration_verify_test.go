package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sync/atomic"
	"testing"
	"time"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func setupTestDB(t *testing.T) {
	if _, err := os.Stat(".env"); err == nil {
		utils.LoadEnvVars()
	}

	// Ensure test database environment is set
	if os.Getenv("MYSQL_HOST") == "" {
		os.Setenv("MYSQL_HOST", "localhost")
	}
	if os.Getenv("MYSQL_PORT") == "" {
		os.Setenv("MYSQL_PORT", "3306")
	}
	if os.Getenv("MYSQL_USERNAME") == "" {
		os.Setenv("MYSQL_USERNAME", "rest_api")
	}
	if os.Getenv("MYSQL_PASSWORD") == "" {
		os.Setenv("MYSQL_PASSWORD", "rest_api")
	}
	if os.Getenv("MYSQL_DATABASE") == "" {
		os.Setenv("MYSQL_DATABASE", "rest_api")
	}

	utils.MySQLConnect()
	utils.RunMigrations()
}

func cleanupTestData(t *testing.T) {
	// Hard delete migrated data using raw SQL to bypass soft delete and unique constraints
	tables := []string{
		"item_field_values", "items", "schema_versions",
		"item_type_fields", "item_type_schemas",
		"cheeses", "gins", "wines", "coffees", "chili_sauces",
	}
	for _, table := range tables {
		if err := utils.DB.Exec("DELETE FROM " + table).Error; err != nil {
			t.Logf("Warning: failed to delete from %s: %v", table, err)
		}
	}
	// Also clean up ratings that might reference old items
	if err := utils.DB.Exec("DELETE FROM ratings WHERE item_type IN ?", []string{"cheese", "gin", "wine", "coffee", "chili_sauce", "Item"}).Error; err != nil {
		t.Logf("Warning: failed to delete ratings: %v", err)
	}
}

var nameCounter int64

func uniqueName(t *testing.T, base string) string {
	counter := atomic.AddInt64(&nameCounter, 1)
	return fmt.Sprintf("%s-%d-%d", base, time.Now().UnixNano(), counter)
}

func createTestCheese(t *testing.T) models.Cheese {
	cheese := models.Cheese{
		Name:        uniqueName(t, "Test Brie"),
		Type:        "Soft",
		Origin:      "France",
		Producer:    "Test Dairy",
		Description: "A test cheese",
	}
	if err := utils.DB.Create(&cheese).Error; err != nil {
		t.Fatalf("Failed to create test cheese: %v", err)
	}
	return cheese
}

func createTestGin(t *testing.T) models.Gin {
	gin := models.Gin{
		Name:        uniqueName(t, "Test Gin"),
		Producer:    "Test Distillery",
		Origin:      "UK",
		Profile:     "Dry",
		Description: "A test gin",
	}
	if err := utils.DB.Create(&gin).Error; err != nil {
		t.Fatalf("Failed to create test gin: %v", err)
	}
	return gin
}

func createTestWine(t *testing.T) models.Wine {
	color := models.WineColor("Rouge")
	wine := models.Wine{
		Name:        uniqueName(t, "Test Wine"),
		Producer:    "Test Winery",
		Country:     "France",
		Region:      "Bordeaux",
		Color:       color,
		Grape:       "Merlot",
		Alcohol:     13.5,
		Designation: "AOC",
		Sugar:       2.5,
		Organic:     true,
		Description: "A test wine",
	}
	if err := utils.DB.Create(&wine).Error; err != nil {
		t.Fatalf("Failed to create test wine: %v", err)
	}
	return wine
}

func createTestCoffee(t *testing.T) models.Coffee {
	coffee := models.Coffee{
		Name:             uniqueName(t, "Test Coffee"),
		Roaster:          "Test Roaster",
		Country:          "Ethiopia",
		Region:           "Yirgacheffe",
		Farm:             "Test Farm",
		Altitude:         "1800m",
		Species:          "Arabica",
		Variety:          "Heirloom",
		ProcessingMethod: "Lavé",
		Decaffeinated:    false,
		RoastLevel:       "Moyen",
		TastingNotes:     []string{"Floral", "Citrus"},
		Acidity:          "Élevé",
		Body:             "Moyen",
		Sweetness:        "Élevé",
		Organic:          true,
		FairTrade:        false,
		Description:      "A test coffee",
	}
	if err := utils.DB.Create(&coffee).Error; err != nil {
		t.Fatalf("Failed to create test coffee: %v", err)
	}
	return coffee
}

func createTestChiliSauce(t *testing.T) models.ChiliSauce {
	spiceLevel := models.SpiceLevel("Hot")
	chiliSauce := models.ChiliSauce{
		Name:        uniqueName(t, "Test Sauce"),
		Brand:       "Test Brand",
		SpiceLevel:  spiceLevel,
		Chilis:      "Habanero",
		Description: "A test sauce",
	}
	if err := utils.DB.Create(&chiliSauce).Error; err != nil {
		t.Fatalf("Failed to create test chili sauce: %v", err)
	}
	return chiliSauce
}

func runMigration(t *testing.T) {
	CreateSchemaDefinitions()
	CreateSchemaVersions()
	MigrateData()
}

func TestVerifyMigration_Integrity(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	// Create test data
	createTestCheese(t)
	createTestGin(t)
	createTestWine(t)
	createTestCoffee(t)
	createTestChiliSauce(t)

	// Run migration
	runMigration(t)

	// Verify migration
	result := VerifyMigration()

	if result.SchemaCount != 5 {
		t.Errorf("Expected 5 schemas, got %d", result.SchemaCount)
	}
	if result.VersionCount != 5 {
		t.Errorf("Expected 5 versions, got %d", result.VersionCount)
	}
	if result.ItemCount != 5 {
		t.Errorf("Expected 5 items, got %d", result.ItemCount)
	}
	if !result.MigrationMatch {
		t.Errorf("Migration match failed: old=%d, new=%d", result.OldItemsTotal, result.ItemCount)
	}
}

func TestVerifyMigration_ItemCountsPerSchema(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	// Create multiple items per type
	createTestCheese(t)
	createTestCheese(t)
	createTestGin(t)

	// Run migration
	runMigration(t)

	if count := CountItemsBySchema("cheese"); count != 2 {
		t.Errorf("Expected 2 cheeses, got %d", count)
	}
	if count := CountItemsBySchema("gin"); count != 1 {
		t.Errorf("Expected 1 gin, got %d", count)
	}
	if count := CountItemsBySchema("wine"); count != 0 {
		t.Errorf("Expected 0 wines, got %d", count)
	}
}

func TestVerifySchemaFields(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	createTestCheese(t)
	runMigration(t)

	results := VerifySchemaFields()

	expectedFields := map[string]int64{
		"cheese":      5,
		"gin":         5,
		"wine":        11,
		"coffee":      18,
		"chili-sauce": 5,
	}

	for schemaName, expected := range expectedFields {
		if actual, ok := results[schemaName]; !ok {
			t.Errorf("Schema '%s' not found in results", schemaName)
		} else if actual != expected {
			t.Errorf("Schema '%s': expected %d fields, got %d", schemaName, expected, actual)
		}
	}
}

func TestVerifyItemFieldValues(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	createTestCheese(t)
	createTestGin(t)
	runMigration(t)

	withValues, withoutValues := VerifyItemFieldValues()

	if withValues != 2 {
		t.Errorf("Expected 2 items with field values, got %d", withValues)
	}
	if withoutValues != 0 {
		t.Errorf("Expected 0 items without field values, got %d", withoutValues)
	}
}

func TestCountOldItems(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	if count := CountOldItems(); count != 0 {
		t.Errorf("Expected 0 old items, got %d", count)
	}

	createTestCheese(t)
	createTestWine(t)

	if count := CountOldItems(); count != 2 {
		t.Errorf("Expected 2 old items, got %d", count)
	}
}

func TestPerformRollback(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	createTestCheese(t)
	runMigration(t)

	// Verify migration happened
	var itemCount int64
	utils.DB.Model(&models.Item{}).Count(&itemCount)
	if itemCount == 0 {
		t.Fatal("Migration did not create any items")
	}

	// Perform rollback
	PerformRollback()

	// Verify rollback cleared new tables
	utils.DB.Model(&models.Item{}).Count(&itemCount)
	if itemCount != 0 {
		t.Errorf("Expected 0 items after rollback, got %d", itemCount)
	}

	var schemaCount int64
	utils.DB.Model(&models.ItemTypeSchema{}).Count(&schemaCount)
	if schemaCount != 0 {
		t.Errorf("Expected 0 schemas after rollback, got %d", schemaCount)
	}

	// Verify old tables still have data
	var cheeseCount int64
	utils.DB.Model(&models.Cheese{}).Count(&cheeseCount)
	if cheeseCount != 1 {
		t.Errorf("Expected 1 cheese in old table after rollback, got %d", cheeseCount)
	}
}

func TestMigration_FieldValuesJSON(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	cheese := createTestCheese(t)
	runMigration(t)

	var item models.Item
	if err := utils.DB.Where("name = ?", cheese.Name).First(&item).Error; err != nil {
		t.Fatalf("Failed to find migrated item: %v", err)
	}

	var fieldValues map[string]interface{}
	if err := json.Unmarshal([]byte(item.FieldValues), &fieldValues); err != nil {
		t.Fatalf("Failed to unmarshal field values: %v", err)
	}

	if fieldValues["type"] != cheese.Type {
		t.Errorf("Expected type '%s', got '%v'", cheese.Type, fieldValues["type"])
	}
	if fieldValues["origin"] != cheese.Origin {
		t.Errorf("Expected origin '%s', got '%v'", cheese.Origin, fieldValues["origin"])
	}
}

func TestMigration_UniqueFields(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	createTestCheese(t)
	runMigration(t)

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "cheese").First(&schema).Error; err != nil {
		t.Fatalf("Failed to find cheese schema: %v", err)
	}

	if schema.UniqueFields == "" {
		t.Error("Expected cheese schema to have unique_fields set")
	}

	var uniqueFields []string
	if err := json.Unmarshal([]byte(schema.UniqueFields), &uniqueFields); err != nil {
		t.Fatalf("Failed to unmarshal unique fields: %v", err)
	}

	if len(uniqueFields) != 1 || uniqueFields[0] != "name" {
		t.Errorf("Expected unique_fields ['name'], got %v", uniqueFields)
	}
}

func TestMigration_RatingsMigration(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	cheese := createTestCheese(t)

	// Create a rating for the old cheese item
	rating := models.Rating{
		ItemType: "cheese",
		ItemID:   int(cheese.ID),
		UserID:   1,
		Grade:    5,
		Note:     "Great cheese!",
	}
	if err := utils.DB.Create(&rating).Error; err != nil {
		t.Fatalf("Failed to create test rating: %v", err)
	}

	runMigration(t)

	migratedCount, oldCount := VerifyRatingsMigrated()

	if migratedCount != 1 {
		t.Errorf("Expected 1 migrated rating, got %d", migratedCount)
	}
	// Old ratings are kept as backup; migration creates new records with item_type='Item'
	if oldCount != 1 {
		t.Errorf("Expected 1 old rating to remain after migration, got %d", oldCount)
	}
}

func TestCountItemsBySchema_NotFound(t *testing.T) {
	setupTestDB(t)
	cleanupTestData(t)
	defer cleanupTestData(t)

	if count := CountItemsBySchema("nonexistent"); count != 0 {
		t.Errorf("Expected 0 items for nonexistent schema, got %d", count)
	}
}

// TestMain handles setup and teardown for the test suite
func TestMain(m *testing.M) {
	// Check if we should skip integration tests
	if os.Getenv("SKIP_INTEGRATION_TESTS") == "1" {
		fmt.Println("Skipping integration tests (SKIP_INTEGRATION_TESTS=1)")
		os.Exit(0)
	}

	code := m.Run()
	os.Exit(code)
}
