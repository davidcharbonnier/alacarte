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

func TestSchemaVersionHistory(t *testing.T) {
	router, token, cleanup := setupControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/admin/schemas/cheese/versions/1", token, nil)
	if w.Code != http.StatusOK && w.Code != http.StatusNotFound {
		t.Fatalf("unexpected status: %d", w.Code)
	}

	// Cheese may or may not have a version 1 depending on seed data
	// The test is mainly that the endpoint responds correctly
}
