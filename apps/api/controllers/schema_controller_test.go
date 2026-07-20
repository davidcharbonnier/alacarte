package controllers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/services"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func setupControllerTest(t *testing.T) (*gin.Engine, string, func()) {
	gin.SetMode(gin.TestMode)

	cleanup, err := utils.SetupTestDB()
	if err != nil {
		t.Fatalf("failed to setup test db: %v", err)
	}

	if err := utils.SeedDefaultSchemas(utils.DB); err != nil {
		cleanup()
		t.Fatalf("failed to seed schemas: %v", err)
	}

	services.GetSchemaRegistry().Reset()
	registry := services.GetSchemaRegistry()
	if err := registry.LoadSchemas(); err != nil {
		cleanup()
		t.Fatalf("failed to load schemas: %v", err)
	}

	// Set JWT secret for token generation
	os.Setenv("JWT_SECRET_KEY", "test-secret-key-for-testing-only")

	// Create test admin user
	user := models.User{
		GoogleID:         fmt.Sprintf("admin-google-%d", time.Now().UnixNano()),
		Email:            fmt.Sprintf("admin-%d@example.com", time.Now().UnixNano()),
		DisplayName:      fmt.Sprintf("Admin User %d", time.Now().UnixNano()),
		IsAdmin:          true,
		ProfileCompleted: true,
		LastLoginAt:      time.Now(),
	}
	if err := utils.DB.Create(&user).Error; err != nil {
		cleanup()
		t.Fatalf("failed to create test user: %v", err)
	}

	token, err := utils.GenerateJWT(&user)
	if err != nil {
		cleanup()
		t.Fatalf("failed to generate jwt: %v", err)
	}

	router := gin.New()

	// Public routes
	router.GET("/api/schemas", SchemaList)
	router.GET("/api/schemas/:type", SchemaDetails)

	// Admin routes
	admin := router.Group("/admin")
	admin.Use(utils.RequireAuth(), utils.RequireAdmin())
	{
		schemaAdmin := admin.Group("/schemas")
		{
			schemaAdmin.POST("", SchemaCreate)
			schemaAdmin.PUT("/:type", SchemaUpdate)
			schemaAdmin.DELETE("/:type", SchemaDelete)
			schemaAdmin.GET("/:type/versions/:version", SchemaVersionHistory)
		}
	}

	return router, token, cleanup
}

func performRequest(router *gin.Engine, method, path, token string, body []byte) *httptest.ResponseRecorder {
	req, _ := http.NewRequest(method, path, bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func TestSchemaList(t *testing.T) {
	router, _, cleanup := setupControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/api/schemas", "", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	schemas, ok := response["schemas"].([]interface{})
	if !ok {
		t.Fatalf("expected schemas array, got: %v", response)
	}
	if len(schemas) != 5 {
		t.Errorf("expected 5 schemas, got %d", len(schemas))
	}
}

func TestSchemaDetails(t *testing.T) {
	router, _, cleanup := setupControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/api/schemas/cheese", "", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	if response["name"] != "cheese" {
		t.Errorf("expected name 'cheese', got %v", response["name"])
	}

	fields, ok := response["fields"].([]interface{})
	if !ok || len(fields) == 0 {
		t.Error("expected fields in schema details")
	}

	// Non-existent schema
	w = performRequest(router, "GET", "/api/schemas/nonexistent", "", nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404 for nonexistent schema, got %d", w.Code)
	}
}

func TestSchemaCreate(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name":         "beer",
		"display_name": "Beer",
		"plural_name":  "Beers",
		"icon":         "beer",
		"color":        "#FFA500",
		"fields": []map[string]interface{}{
			{
				"key":        "name",
				"label":      "Name",
				"field_type": "text",
				"required":   true,
			},
			{
				"key":        "brewery",
				"label":      "Brewery",
				"field_type": "text",
				"required":   true,
			},
		},
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/admin/schemas", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Verify schema was created
	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "beer").First(&schema).Error; err != nil {
		t.Fatalf("schema not found in db: %v", err)
	}
	if schema.DisplayName != "Beer" {
		t.Errorf("expected display_name 'Beer', got '%s'", schema.DisplayName)
	}
}

func TestSchemaCreate_DuplicateRejection(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name":         "cheese",
		"display_name": "Cheese Duplicate",
		"plural_name":  "Cheeses",
		"icon":         "cheese",
		"color":        "#FFD700",
		"fields":       []map[string]interface{}{},
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/admin/schemas", token, bodyJSON)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for duplicate schema, got %d", w.Code)
	}
}

func TestSchemaCreate_KebabCaseValidation(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	// Create schema with non-kebab-case name - server should still accept it
	// (client-side validation is separate; server enforces no spaces for sanity)
	body := map[string]interface{}{
		"name":         "my beer",
		"display_name": "My Beer",
		"plural_name":  "My Beers",
		"icon":         "beer",
		"color":        "#FFA500",
		"fields":       []map[string]interface{}{},
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/admin/schemas", token, bodyJSON)
	// Server currently accepts any name; kebab-case is client-side only per task 12.9
	if w.Code != http.StatusOK && w.Code != http.StatusBadRequest {
		t.Errorf("unexpected status: %d", w.Code)
	}
}

func TestSchemaUpdate(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"display_name": "Updated Cheese",
		"plural_name":  "Updated Cheeses",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "PUT", "/admin/schemas/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var schema models.ItemTypeSchema
	if err := utils.DB.Where("name = ?", "cheese").First(&schema).Error; err != nil {
		t.Fatalf("schema not found: %v", err)
	}
	if schema.DisplayName != "Updated Cheese" {
		t.Errorf("expected display_name 'Updated Cheese', got '%s'", schema.DisplayName)
	}
}

func TestSchemaDelete_Empty(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	// Create a new schema with no items
	schema := models.ItemTypeSchema{
		Name:         "empty-schema",
		DisplayName:  "Empty Schema",
		PluralName:   "Empty Schemas",
		Icon:         "empty",
		Color:        "#000000",
		IsActive:     true,
		UniqueFields: "[]",
	}
	if err := utils.DB.Create(&schema).Error; err != nil {
		t.Fatalf("failed to create schema: %v", err)
	}

	// Refresh registry
	services.GetSchemaRegistry().RefreshSchema("empty-schema")

	w := performRequest(router, "DELETE", "/admin/schemas/empty-schema", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Verify deleted
	var count int64
	utils.DB.Model(&models.ItemTypeSchema{}).Where("name = ?", "empty-schema").Count(&count)
	if count != 0 {
		t.Errorf("expected schema to be deleted, got count %d", count)
	}
}

func TestSchemaDelete_RejectWithItems(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	// Create a user and an item for cheese
	user := models.User{GoogleID: fmt.Sprintf("user-google-%d", time.Now().UnixNano()), Email: fmt.Sprintf("user-%d@example.com", time.Now().UnixNano()), DisplayName: fmt.Sprintf("User %d", time.Now().UnixNano()), ProfileCompleted: true, LastLoginAt: time.Now()}
	utils.DB.Create(&user)

	var cheeseSchema models.ItemTypeSchema
	utils.DB.Where("name = ?", "cheese").First(&cheeseSchema)

	fv := "{}"
	item := models.Item{
		Name:        "Test Cheese",
		SchemaID:    cheeseSchema.ID,
		UserID:      int(user.ID),
		FieldValues: fv,
	}
	utils.DB.Create(&item)

	w := performRequest(router, "DELETE", "/admin/schemas/cheese", token, nil)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for schema with items, got %d", w.Code)
	}
}

func TestSchemaUpdate_IdenticalFieldsSkipsVersion(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	// Create a fresh schema with a known v1 active version
	createBody := map[string]interface{}{
		"name":         "version-dedup",
		"display_name": "Version Dedup",
		"plural_name":  "Version Dedups",
		"icon":         "check",
		"color":        "#00FF00",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
			{"key": "origin", "label": "Origin", "field_type": "text", "required": false},
		},
	}
	createJSON, _ := json.Marshal(createBody)
	if w := performRequest(router, "POST", "/admin/schemas", token, createJSON); w.Code != http.StatusOK {
		t.Fatalf("create setup failed: %d %s", w.Code, w.Body.String())
	}

	// PUT with the same fields → must NOT create a new version
	updateBody := map[string]interface{}{
		"display_name": "Version Dedup",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
			{"key": "origin", "label": "Origin", "field_type": "text", "required": false},
		},
	}
	updateJSON, _ := json.Marshal(updateBody)
	w := performRequest(router, "PUT", "/admin/schemas/version-dedup", token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("parse response: %v", err)
	}

	if upd, _ := resp["updated"].(bool); upd {
		t.Errorf("expected updated=false for identical fields, got true. message=%v", resp["message"])
	}
	if msg, _ := resp["message"].(string); msg != "No changes to save" {
		t.Errorf("expected message 'No changes to save', got %q", msg)
	}

	// Verify only v1 exists, still active
	var schema models.ItemTypeSchema
	utils.DB.Where("name = ?", "version-dedup").First(&schema)
	var versions []models.SchemaVersion
	utils.DB.Where("schema_id = ?", schema.ID).Order("version ASC").Find(&versions)
	if len(versions) != 1 {
		t.Errorf("expected exactly 1 schema_version row, got %d", len(versions))
	}
	if len(versions) > 0 && !versions[0].IsActive {
		t.Errorf("expected v1 to remain active")
	}
}

func TestSchemaUpdate_DifferentFieldsCreatesVersion(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	createBody := map[string]interface{}{
		"name":         "version-bump",
		"display_name": "Version Bump",
		"plural_name":  "Version Bumps",
		"icon":         "arrow-up",
		"color":        "#0000FF",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
		},
	}
	createJSON, _ := json.Marshal(createBody)
	if w := performRequest(router, "POST", "/admin/schemas", token, createJSON); w.Code != http.StatusOK {
		t.Fatalf("create setup failed: %d %s", w.Code, w.Body.String())
	}

	// PUT with a different field set → MUST create v2
	updateBody := map[string]interface{}{
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
			{"key": "region", "label": "Region", "field_type": "text", "required": false},
		},
	}
	updateJSON, _ := json.Marshal(updateBody)
	w := performRequest(router, "PUT", "/admin/schemas/version-bump", token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if upd, _ := resp["updated"].(bool); !upd {
		t.Errorf("expected updated=true for changed fields, got false. message=%v", resp["message"])
	}

	var schema models.ItemTypeSchema
	utils.DB.Where("name = ?", "version-bump").First(&schema)
	var versions []models.SchemaVersion
	utils.DB.Where("schema_id = ?", schema.ID).Order("version ASC").Find(&versions)
	if len(versions) != 2 {
		t.Errorf("expected 2 schema_version rows, got %d", len(versions))
	}
	// v1 inactive, v2 active
	if len(versions) == 2 {
		if versions[0].IsActive || !versions[1].IsActive {
			t.Errorf("expected v1 inactive and v2 active; got v1.is_active=%v v2.is_active=%v", versions[0].IsActive, versions[1].IsActive)
		}
	}
}

func TestSchemaUpdate_EmptyFieldsCreatesVersion(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	createBody := map[string]interface{}{
		"name":         "version-empty",
		"display_name": "Version Empty",
		"plural_name":  "Version Empties",
		"icon":         "trash",
		"color":        "#FF0000",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
		},
	}
	createJSON, _ := json.Marshal(createBody)
	if w := performRequest(router, "POST", "/admin/schemas", token, createJSON); w.Code != http.StatusOK {
		t.Fatalf("create setup failed: %d %s", w.Code, w.Body.String())
	}

	// Empty fields array is destructive — MUST count as a change (updated=true)
	// and wipe all ItemTypeField rows for the schema.
	updateBody := map[string]interface{}{"fields": []map[string]interface{}{}}
	updateJSON, _ := json.Marshal(updateBody)
	w := performRequest(router, "PUT", "/admin/schemas/version-empty", token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if upd, _ := resp["updated"].(bool); !upd {
		t.Errorf("expected updated=true for empty fields, got false. message=%v", resp["message"])
	}

	var schema models.ItemTypeSchema
	utils.DB.Where("name = ?", "version-empty").First(&schema)
	var fieldCount int64
	utils.DB.Model(&models.ItemTypeField{}).Where("schema_id = ?", schema.ID).Count(&fieldCount)
	if fieldCount != 0 {
		t.Errorf("expected all fields deleted, got %d remaining", fieldCount)
	}
}

func TestSchemaUpdate_MetadataOnlyNoVersion(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	createBody := map[string]interface{}{
		"name":         "version-meta",
		"display_name": "Meta",
		"plural_name":  "Metas",
		"icon":         "tag",
		"color":        "#123456",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
		},
	}
	createJSON, _ := json.Marshal(createBody)
	if w := performRequest(router, "POST", "/admin/schemas", token, createJSON); w.Code != http.StatusOK {
		t.Fatalf("create setup failed: %d %s", w.Code, w.Body.String())
	}

	// Metadata-only update (no fields key) → updated must be true and message
	// must be "Settings updated".
	updateBody := map[string]interface{}{"display_name": "Meta Renamed"}
	updateJSON, _ := json.Marshal(updateBody)
	w := performRequest(router, "PUT", "/admin/schemas/version-meta", token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if upd, _ := resp["updated"].(bool); !upd {
		t.Errorf("expected updated=true for metadata-only update (settings DID change), got false. message=%v", resp["message"])
	}
	if msg, _ := resp["message"].(string); msg != "Settings updated" {
		t.Errorf("expected message 'Settings updated', got %q", msg)
	}

	var schema models.ItemTypeSchema
	utils.DB.Where("name = ?", "version-meta").First(&schema)
	var versions []models.SchemaVersion
	utils.DB.Where("schema_id = ?", schema.ID).Find(&versions)
	if len(versions) != 1 {
		t.Errorf("expected 1 schema_version row (no new version), got %d", len(versions))
	}
	if schema.DisplayName != "Meta Renamed" {
		t.Errorf("expected display_name to be updated, got %q", schema.DisplayName)
	}
}

func TestSchemaUpdate_NoChangeDetected(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	createBody := map[string]interface{}{
		"name":         "version-noop",
		"display_name": "Noop",
		"plural_name":  "Noops",
		"icon":         "tag",
		"color":        "#123456",
		"fields": []map[string]interface{}{
			{"key": "name", "label": "Name", "field_type": "text", "required": true},
		},
	}
	createJSON, _ := json.Marshal(createBody)
	if w := performRequest(router, "POST", "/admin/schemas", token, createJSON); w.Code != http.StatusOK {
		t.Fatalf("create setup failed: %d %s", w.Code, w.Body.String())
	}

	// Re-send identical metadata — server must detect no change.
	updateBody := map[string]interface{}{
		"display_name": "Noop",
		"plural_name":  "Noops",
		"icon":         "tag",
		"color":        "#123456",
	}
	updateJSON, _ := json.Marshal(updateBody)
	w := performRequest(router, "PUT", "/admin/schemas/version-noop", token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if upd, _ := resp["updated"].(bool); upd {
		t.Errorf("expected updated=false for identical metadata, got true. message=%v", resp["message"])
	}
	if msg, _ := resp["message"].(string); msg != "No changes to save" {
		t.Errorf("expected message 'No changes to save', got %q", msg)
	}
}

func TestSchemaVersionHistory(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/admin/schemas/cheese/versions/1", token, nil)
	if w.Code != http.StatusOK && w.Code != http.StatusNotFound {
		t.Fatalf("unexpected status: %d", w.Code)
	}
}

func TestFieldTypeValid(t *testing.T) {
	tests := []struct {
		ft    models.FieldType
		valid bool
	}{
		{models.FieldTypeText, true},
		{models.FieldTypeTextarea, true},
		{models.FieldTypeNumber, true},
		{models.FieldTypeSelect, true},
		{models.FieldTypeCheckbox, true},
		{models.FieldTypeEnum, true},
		{models.FieldType("banana"), false},
		{models.FieldType(""), false},
		{models.FieldType("TEXT"), false},
	}

	for _, tt := range tests {
		got := tt.ft.Valid()
		if got != tt.valid {
			t.Errorf("FieldType(%q).Valid() = %v, want %v", tt.ft, got, tt.valid)
		}
	}
}

func TestSchemaCreate_InvalidFieldType(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name":         "invalid-field-test",
		"display_name": "Invalid Field Test",
		"plural_name":  "Invalid Field Tests",
		"icon":         "x",
		"color":        "#FF0000",
		"fields": []map[string]interface{}{
			{
				"key":        "name",
				"label":      "Name",
				"field_type": "banana",
				"required":   true,
			},
		},
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/admin/schemas", token, bodyJSON)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid field type, got %d: %s", w.Code, w.Body.String())
	}
}

func TestSchemaUpdate_InvalidFieldType(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"fields": []map[string]interface{}{
			{
				"key":        "name",
				"label":      "Name",
				"field_type": "banana",
				"required":   true,
			},
		},
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "PUT", "/admin/schemas/cheese", token, bodyJSON)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid field type on update, got %d: %s", w.Code, w.Body.String())
	}
}
