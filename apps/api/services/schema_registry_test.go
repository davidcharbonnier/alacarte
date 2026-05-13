package services

import (
	"testing"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func setupSchemaRegistryTest(t *testing.T) func() {
	cleanup, err := utils.SetupTestDB()
	if err != nil {
		t.Fatalf("failed to setup test db: %v", err)
	}

	// Seed default schemas
	if err := utils.SeedDefaultSchemas(utils.DB); err != nil {
		cleanup()
		t.Fatalf("failed to seed schemas: %v", err)
	}

	ResetGlobalRegistry()
	registry := GetSchemaRegistry()
	if err := registry.LoadSchemas(); err != nil {
		cleanup()
		t.Fatalf("failed to load schemas: %v", err)
	}

	return cleanup
}

func TestSchemaRegistry_LoadFromDB(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Should have 5 schemas loaded
	schemas := registry.GetAllSchemas()
	if len(schemas) != 5 {
		t.Errorf("expected 5 schemas, got %d", len(schemas))
	}
}

func TestSchemaRegistry_Get(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Get existing schema
	schema, ok := registry.GetSchema("cheese")
	if !ok {
		t.Fatal("expected cheese schema to exist")
	}
	if schema.Schema.Name != "cheese" {
		t.Errorf("expected name 'cheese', got '%s'", schema.Schema.Name)
	}

	// Get non-existent schema
	_, ok = registry.GetSchema("nonexistent")
	if ok {
		t.Error("expected nonexistent schema to not exist")
	}
}

func TestSchemaRegistry_Ordering(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()
	schemas := registry.GetAllSchemas()

	// Should be ordered by name ascending
	if len(schemas) < 2 {
		t.Fatal("expected at least 2 schemas")
	}
	for i := 1; i < len(schemas); i++ {
		if schemas[i-1].Schema.Name > schemas[i].Schema.Name {
			t.Error("schemas not ordered by name ascending")
		}
	}
}

func TestSchemaRegistry_Refresh(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Modify schema in DB
	utils.DB.Model(&models.ItemTypeSchema{}).Where("name = ?", "cheese").Update("display_name", "Updated Cheese")

	// Refresh
	if err := registry.RefreshSchema("cheese"); err != nil {
		t.Fatalf("failed to refresh schema: %v", err)
	}

	schema, ok := registry.GetSchema("cheese")
	if !ok {
		t.Fatal("expected cheese schema after refresh")
	}
	if schema.Schema.DisplayName != "Updated Cheese" {
		t.Errorf("expected display_name 'Updated Cheese', got '%s'", schema.Schema.DisplayName)
	}
}

func TestSchemaRegistry_Invalidate(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Invalidate
	registry.InvalidateSchema("cheese")

	_, ok := registry.GetSchema("cheese")
	if ok {
		t.Error("expected cheese schema to be invalidated")
	}
}

func TestSchemaRegistry_Exists(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	if !registry.SchemaExists("cheese") {
		t.Error("expected cheese schema to exist")
	}
	if registry.SchemaExists("nonexistent") {
		t.Error("expected nonexistent schema to not exist")
	}
}

func TestSchemaRegistry_FieldLookup(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	field, ok := registry.GetFieldByKey("cheese", "name")
	if !ok {
		t.Fatal("expected name field to exist")
	}
	if field.Label != "Name" {
		t.Errorf("expected label 'Name', got '%s'", field.Label)
	}

	_, ok = registry.GetFieldByKey("cheese", "nonexistent")
	if ok {
		t.Error("expected nonexistent field to not exist")
	}

	_, ok = registry.GetFieldByKey("nonexistent", "name")
	if ok {
		t.Error("expected nonexistent schema to not have fields")
	}
}

func TestSchemaRegistry_UniqueFieldsParsing(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Cheese has unique_fields: ["name"]
	schema, ok := registry.GetSchema("cheese")
	if !ok {
		t.Fatal("expected cheese schema")
	}
	if len(schema.UniqueFields) != 1 || schema.UniqueFields[0] != "name" {
		t.Errorf("expected unique_fields ['name'], got %v", schema.UniqueFields)
	}

	// Gin has unique_fields: ["name", "producer"]
	schema, ok = registry.GetSchema("gin")
	if !ok {
		t.Fatal("expected gin schema")
	}
	if len(schema.UniqueFields) != 2 {
		t.Errorf("expected 2 unique fields for gin, got %v", schema.UniqueFields)
	}
}

func TestSchemaRegistry_Reset(t *testing.T) {
	cleanup := setupSchemaRegistryTest(t)
	defer cleanup()

	registry := GetSchemaRegistry()

	// Verify schemas exist
	if !registry.SchemaExists("cheese") {
		t.Fatal("expected cheese schema before reset")
	}

	// Reset
	registry.Reset()

	// Should be empty
	if registry.SchemaExists("cheese") {
		t.Error("expected cheese schema to be gone after reset")
	}

	schemas := registry.GetAllSchemas()
	if len(schemas) != 0 {
		t.Errorf("expected 0 schemas after reset, got %d", len(schemas))
	}
}
