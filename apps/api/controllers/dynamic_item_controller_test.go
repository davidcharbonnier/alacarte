package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/services"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-gonic/gin"
)

func setupDynamicItemControllerTest(t *testing.T) (*gin.Engine, string, func()) {
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

	// API routes (require auth)
	api := router.Group("/api")
	api.Use(utils.RequireAuth())
	{
		items := api.Group("/items")
		{
			items.GET("/:type", DynamicItemList)
			items.GET("/:type/:id", DynamicItemDetails)
			items.POST("/:type", DynamicItemCreate)
			items.PUT("/:type/:id", DynamicItemUpdate)
			items.DELETE("/:type/:id", DynamicItemDelete)
		}

		stats := api.Group("/stats")
		{
			stats.GET("/type/:type", GetTypeStats)
		}
	}

	// Admin routes
	admin := router.Group("/admin")
	admin.Use(utils.RequireAuth(), utils.RequireAdmin())
	{
		itemAdmin := admin.Group("/items")
		{
			itemAdmin.GET("/:type/:id/delete-impact", DynamicItemDeleteImpact)
		}
	}

	return router, token, cleanup
}

func TestDynamicItemCreate(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "Test Brie",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}
	if response["name"] != "Test Brie" {
		t.Errorf("expected name 'Test Brie', got %v", response["name"])
	}
}

func TestDynamicItemCreate_DuplicateRejection(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "Duplicate Brie",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 for first create, got %d: %s", w.Code, w.Body.String())
	}

	w = performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for duplicate, got %d: %s", w.Code, w.Body.String())
	}
}

func TestDynamicItemList_Pagination(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	// Create multiple items
	for i := 0; i < 5; i++ {
		body := map[string]interface{}{
			"name": fmt.Sprintf("Cheese %d", i),
			"type": "Soft",
		}
		bodyJSON, _ := json.Marshal(body)
		w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
		if w.Code != http.StatusOK {
			t.Fatalf("failed to create item %d: %d %s", i, w.Code, w.Body.String())
		}
	}

	w := performRequest(router, "GET", "/api/items/cheese?page=1&per_page=2", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	items, ok := response["items"].([]interface{})
	if !ok {
		t.Fatalf("expected items array, got: %v", response)
	}
	if len(items) != 2 {
		t.Errorf("expected 2 items per page, got %d", len(items))
	}

	if response["total"] != float64(5) {
		t.Errorf("expected total 5, got %v", response["total"])
	}
}

func TestDynamicItemDetails(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "Detail Test",
		"type": "Hard",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	w = performRequest(router, "GET", "/api/items/cheese/"+itemID, token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var detailResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &detailResp)
	if detailResp["name"] != "Detail Test" {
		t.Errorf("expected name 'Detail Test', got %v", detailResp["name"])
	}
}

func TestDynamicItemUpdate(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "Original",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	updateBody := map[string]interface{}{
		"name": "Updated",
		"type": "Hard",
	}
	updateJSON, _ := json.Marshal(updateBody)

	w = performRequest(router, "PUT", "/api/items/cheese/"+itemID, token, updateJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var updateResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &updateResp)
	if updateResp["name"] != "Updated" {
		t.Errorf("expected name 'Updated', got %v", updateResp["name"])
	}
}

func TestDynamicItemUpdate_Unauthorized(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "Protected",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	// Create another user
	otherUser := models.User{GoogleID: fmt.Sprintf("other-google-%d", time.Now().UnixNano()), Email: fmt.Sprintf("other-%d@example.com", time.Now().UnixNano()), DisplayName: fmt.Sprintf("Other User %d", time.Now().UnixNano()), ProfileCompleted: true, LastLoginAt: time.Now()}
	utils.DB.Create(&otherUser)
	otherToken, _ := utils.GenerateJWT(&otherUser)

	updateBody := map[string]interface{}{"name": "Hacked"}
	updateJSON, _ := json.Marshal(updateBody)

	w = performRequest(router, "PUT", "/api/items/cheese/"+itemID, otherToken, updateJSON)
	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403 for unauthorized update, got %d", w.Code)
	}
}

func TestDynamicItemDelete(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "ToDelete",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	w = performRequest(router, "DELETE", "/api/items/cheese/"+itemID, token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Verify item is gone
	w = performRequest(router, "GET", "/api/items/cheese/"+itemID, token, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404 after delete, got %d", w.Code)
	}
}

func TestDynamicItemDelete_Unauthorized(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "ProtectedDelete",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	// Create another user
	otherUser := models.User{GoogleID: fmt.Sprintf("other2-google-%d", time.Now().UnixNano()), Email: fmt.Sprintf("other2-%d@example.com", time.Now().UnixNano()), DisplayName: fmt.Sprintf("Other2 User %d", time.Now().UnixNano()), ProfileCompleted: true, LastLoginAt: time.Now()}
	utils.DB.Create(&otherUser)
	otherToken, _ := utils.GenerateJWT(&otherUser)

	w = performRequest(router, "DELETE", "/api/items/cheese/"+itemID, otherToken, nil)
	if w.Code != http.StatusForbidden {
		t.Errorf("expected 403 for unauthorized delete, got %d", w.Code)
	}
}

func TestDynamicItemDeleteImpact(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body := map[string]interface{}{
		"name": "ImpactTest",
		"type": "Soft",
	}
	bodyJSON, _ := json.Marshal(body)

	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := fmt.Sprintf("%v", createResp["id"])

	// Create a rating
	rating := models.Rating{
		Grade:    5.0,
		Note:     "Great",
		UserID:   1,
		ItemID:   int(createResp["id"].(float64)),
		ItemType: "cheese",
	}
	utils.DB.Create(&rating)

	w = performRequest(router, "GET", "/admin/items/cheese/"+itemID+"/delete-impact", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var impact map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &impact)
	impactData, ok := impact["impact"].(map[string]interface{})
	if !ok {
		t.Fatalf("expected impact to be a map, got %T", impact["impact"])
	}
	if impactData["ratings_count"] != float64(1) {
		t.Errorf("expected ratings_count 1, got %v", impactData["ratings_count"])
	}
}

// Filtering and Search Integration Tests (Task 13.11)

func TestDynamicItemList_Filter(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	// Create items with different types
	for _, item := range []map[string]interface{}{
		{"name": "Brie", "type": "Soft"},
		{"name": "Cheddar", "type": "Hard"},
		{"name": "Camembert", "type": "Soft"},
	} {
		bodyJSON, _ := json.Marshal(item)
		w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
		if w.Code != http.StatusOK {
			t.Fatalf("failed to create item: %d %s", w.Code, w.Body.String())
		}
	}

	// Filter by type=Soft
	w := performRequest(router, "GET", "/api/items/cheese?filter[type]=Soft", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	items, _ := response["items"].([]interface{})
	if len(items) != 2 {
		t.Errorf("expected 2 soft cheeses, got %d", len(items))
	}
}

func TestDynamicItemList_HasImageFilter(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	body1 := map[string]interface{}{"name": "NoImage", "type": "Soft"}
	bodyJSON1, _ := json.Marshal(body1)
	performRequest(router, "POST", "/api/items/cheese", token, bodyJSON1)

	body2 := map[string]interface{}{"name": "WithImage", "type": "Hard"}
	bodyJSON2, _ := json.Marshal(body2)
	w2 := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON2)
	if w2.Code != http.StatusOK {
		t.Fatalf("failed to create item with image: %d %s", w2.Code, w2.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w2.Body.Bytes(), &createResp)
	itemID := uint(createResp["id"].(float64))

	// Manually set image_url since it's not a schema field
	imgURL := "http://example.com/img.jpg"
	utils.DB.Model(&models.Item{}).Where("id = ?", itemID).Update("image_url", &imgURL)

	w := performRequest(router, "GET", "/api/items/cheese?filter[has_image]=true", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	items, _ := response["items"].([]interface{})
	if len(items) != 1 {
		t.Errorf("expected 1 item with image, got %d", len(items))
	}
}

func TestDynamicItemList_Search(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	for _, item := range []map[string]interface{}{
		{"name": "Brie de Meaux", "type": "Soft"},
		{"name": "Cheddar", "type": "Hard"},
	} {
		bodyJSON, _ := json.Marshal(item)
		performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	}

	w := performRequest(router, "GET", "/api/items/cheese?search=brie", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	items, _ := response["items"].([]interface{})
	if len(items) != 1 {
		t.Errorf("expected 1 result for 'brie', got %d", len(items))
	}
}

func TestDynamicItemList_Sort(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	for _, item := range []map[string]interface{}{
		{"name": "Cheddar", "type": "Hard"},
		{"name": "Brie", "type": "Soft"},
	} {
		bodyJSON, _ := json.Marshal(item)
		performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	}

	w := performRequest(router, "GET", "/api/items/cheese?sort=name", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	items, _ := response["items"].([]interface{})
	if len(items) < 2 {
		t.Fatal("expected at least 2 items")
	}
	first := items[0].(map[string]interface{})
	if first["name"] != "Brie" {
		t.Errorf("expected first item 'Brie' when sorted by name, got %v", first["name"])
	}
}

func TestDynamicItemList_CombinedFilterSearchSort(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	for _, item := range []map[string]interface{}{
		{"name": "Brie A", "type": "Soft"},
		{"name": "Brie B", "type": "Hard"},
		{"name": "Cheddar", "type": "Hard"},
	} {
		bodyJSON, _ := json.Marshal(item)
		performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	}

	w := performRequest(router, "GET", "/api/items/cheese?search=brie&filter[type]=Hard&sort=-name", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	items, _ := response["items"].([]interface{})
	if len(items) != 1 {
		t.Errorf("expected 1 result for combined filter+search+sort, got %d", len(items))
	}
	if len(items) > 0 {
		first := items[0].(map[string]interface{})
		if first["name"] != "Brie B" {
			t.Errorf("expected 'Brie B', got %v", first["name"])
		}
	}
}

func TestGetTypeStats(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	// Create items
	for _, item := range []map[string]interface{}{
		{"name": "Brie", "type": "Soft"},
		{"name": "Cheddar", "type": "Hard"},
		{"name": "Camembert", "type": "Soft"},
	} {
		bodyJSON, _ := json.Marshal(item)
		w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
		if w.Code != http.StatusOK {
			t.Fatalf("failed to create item: %d %s", w.Code, w.Body.String())
		}
	}

	// Get type stats
	w := performRequest(router, "GET", "/api/stats/type/cheese", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	totalItems, ok := response["total_items"].(float64)
	if !ok {
		t.Fatalf("expected total_items to be a number, got %T", response["total_items"])
	}
	if totalItems != 3 {
		t.Errorf("expected total_items 3, got %v", totalItems)
	}

	userRatedCount, ok := response["user_rated_count"].(float64)
	if !ok {
		t.Fatalf("expected user_rated_count to be a number, got %T", response["user_rated_count"])
	}
	if userRatedCount != 0 {
		t.Errorf("expected user_rated_count 0 (no ratings yet), got %v", userRatedCount)
	}
}

func TestGetTypeStats_NotFound(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/api/stats/type/nonexistent", token, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404 for nonexistent type, got %d", w.Code)
	}
}

func TestGetTypeStats_Unauthenticated(t *testing.T) {
	router, _, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	w := performRequest(router, "GET", "/api/stats/type/cheese", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for unauthenticated, got %d", w.Code)
	}
}

func TestGetTypeStats_WithUserRatings(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	// Create an item
	body := map[string]interface{}{"name": "Rated Brie", "type": "Soft"}
	bodyJSON, _ := json.Marshal(body)
	w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
	if w.Code != http.StatusOK {
		t.Fatalf("failed to create item: %d %s", w.Code, w.Body.String())
	}

	var createResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &createResp)
	itemID := int(createResp["id"].(float64))

	// Create a rating for the item
	rating := models.Rating{
		Grade:  4.0,
		Note:   "Good",
		UserID: 1,
		ItemID: itemID,
	}
	utils.DB.Create(&rating)

	w = performRequest(router, "GET", "/api/stats/type/cheese", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)

	if response["total_items"] != float64(1) {
		t.Errorf("expected total_items 1, got %v", response["total_items"])
	}
	if response["user_rated_count"] != float64(1) {
		t.Errorf("expected user_rated_count 1, got %v", response["user_rated_count"])
	}
}

func TestDynamicItemList_RatedBy(t *testing.T) {
	router, token, cleanup := setupDynamicItemControllerTest(t)
	defer cleanup()

	// Create items
	for _, item := range []map[string]interface{}{
		{"name": "Rated Item", "type": "Soft"},
		{"name": "Shared Item", "type": "Hard"},
		{"name": "Unrated Item", "type": "Soft"},
	} {
		bodyJSON, _ := json.Marshal(item)
		w := performRequest(router, "POST", "/api/items/cheese", token, bodyJSON)
		if w.Code != http.StatusOK {
			t.Fatalf("failed to create item '%s': %d %s", item["name"], w.Code, w.Body.String())
		}
	}

	// Fetch items to get their IDs
	w := performRequest(router, "GET", "/api/items/cheese", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("failed to list items: %d %s", w.Code, w.Body.String())
	}
	var listResp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &listResp)
	items, _ := listResp["items"].([]interface{})
	if len(items) != 3 {
		t.Fatalf("expected 3 items, got %d", len(items))
	}

	var ratedItemID, sharedItemID int
	for _, raw := range items {
		item := raw.(map[string]interface{})
		name := item["name"].(string)
		id := int(item["id"].(float64))
		switch name {
		case "Rated Item":
			ratedItemID = id
		case "Shared Item":
			sharedItemID = id
		}
	}

	// Create rating for "Rated Item" as user 1 (the admin user created by setup)
	rating1 := models.Rating{
		Grade:  5.0,
		Note:   "My rating",
		UserID: 1,
		ItemID: ratedItemID,
	}
	if err := utils.DB.Create(&rating1).Error; err != nil {
		t.Fatalf("failed to create rating: %v", err)
	}

	// Create rating for "Shared Item" as another user, shared with user 1
	otherUser := models.User{
		GoogleID:         "other-google-ratedby",
		Email:            "other@ratedby.com",
		DisplayName:      "Other User",
		ProfileCompleted: true,
		LastLoginAt:      time.Now(),
	}
	if err := utils.DB.Create(&otherUser).Error; err != nil {
		t.Fatalf("failed to create other user: %v", err)
	}
	rating2 := models.Rating{
		Grade:  4.0,
		Note:   "Shared",
		UserID: int(otherUser.ID),
		ItemID: sharedItemID,
	}
	if err := utils.DB.Create(&rating2).Error; err != nil {
		t.Fatalf("failed to create shared rating: %v", err)
	}
	// Add user 1 as viewer
	if err := utils.DB.Table("rating_viewers").Create(map[string]interface{}{
		"rating_id": rating2.ID,
		"user_id":   1,
	}).Error; err != nil {
		t.Fatalf("failed to add viewer: %v", err)
	}

	// Test with rated=true — should return 2 items (rated + shared)
	w = performRequest(router, "GET", "/api/items/cheese?rated=true", token, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	ratedItems, _ := response["items"].([]interface{})
	if len(ratedItems) != 2 {
		t.Errorf("expected 2 rated items, got %d", len(ratedItems))
	}

	// Verify only rated and shared items are returned
	for _, raw := range ratedItems {
		item := raw.(map[string]interface{})
		name := item["name"].(string)
		if name == "Unrated Item" {
			t.Errorf("unrated item should not appear in rated results")
		}
	}

	// Verify total count is correct in response
	if response["total"] != float64(2) {
		t.Errorf("expected total 2, got %v", response["total"])
	}

	// Verify pagination metadata
	page, hasPage := response["page"]
	if hasPage && page != float64(1) {
		t.Errorf("expected page 1, got %v", page)
	}
	totalPages, hasTotalPages := response["total_pages"]
	if hasTotalPages && totalPages != float64(1) {
		t.Errorf("expected 1 total page, got %v", totalPages)
	}
}
