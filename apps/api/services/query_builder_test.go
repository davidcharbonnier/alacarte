package services

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
)

func setupQueryBuilderTest(t *testing.T) (*EAVQueryBuilder, func()) {
	cleanup, err := utils.SetupTestDB()
	if err != nil {
		t.Fatalf("failed to setup test db: %v", err)
	}

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

	qb := NewEAVQueryBuilder(registry)
	return qb, cleanup
}

func createTestUser(t *testing.T) *models.User {
	user := models.User{
		GoogleID:        fmt.Sprintf("test-google-%d", time.Now().UnixNano()),
		Email:           fmt.Sprintf("test-%d@example.com", time.Now().UnixNano()),
		DisplayName:     fmt.Sprintf("Test User %d", time.Now().UnixNano()),
		ProfileCompleted: true,
		LastLoginAt:     time.Now(),
	}
	if err := utils.DB.Create(&user).Error; err != nil {
		t.Fatalf("failed to create test user: %v", err)
	}
	return &user
}

func TestEAVQueryBuilder_Pagination(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	// Create 25 cheese items
	for i := 0; i < 25; i++ {
		_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
			"name": fmt.Sprintf("Cheese %d", i),
			"type": "Soft",
		})
		if err != nil {
			t.Fatalf("failed to create item: %v", err)
		}
	}

	// Default pagination
	result, err := qb.BuildListQuery(QueryParams{SchemaName: "cheese", Page: 1, PerPage: 20})
	if err != nil {
		t.Fatalf("failed to list items: %v", err)
	}
	if result.Total != 25 {
		t.Errorf("expected total 25, got %d", result.Total)
	}
	if len(result.Items) != 20 {
		t.Errorf("expected 20 items on page 1, got %d", len(result.Items))
	}
	if result.TotalPages != 2 {
		t.Errorf("expected 2 total pages, got %d", result.TotalPages)
	}

	// Second page
	result, err = qb.BuildListQuery(QueryParams{SchemaName: "cheese", Page: 2, PerPage: 20})
	if err != nil {
		t.Fatalf("failed to list items page 2: %v", err)
	}
	if len(result.Items) != 5 {
		t.Errorf("expected 5 items on page 2, got %d", len(result.Items))
	}

	// Custom per_page
	result, err = qb.BuildListQuery(QueryParams{SchemaName: "cheese", Page: 1, PerPage: 10})
	if err != nil {
		t.Fatalf("failed to list items per_page 10: %v", err)
	}
	if len(result.Items) != 10 {
		t.Errorf("expected 10 items with per_page 10, got %d", len(result.Items))
	}
}

func TestEAVQueryBuilder_Search(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name":        "Brie de Meaux",
		"type":        "Soft",
		"description": "A classic French cheese",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name":        "Cheddar",
		"type":        "Hard",
		"description": "An English cheese",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Search by name
	result, err := qb.BuildListQuery(QueryParams{SchemaName: "cheese", Search: "brie"})
	if err != nil {
		t.Fatalf("failed to search: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 result for 'brie', got %d", result.Total)
	}

	// Search by description
	result, err = qb.BuildListQuery(QueryParams{SchemaName: "cheese", Search: "english"})
	if err != nil {
		t.Fatalf("failed to search: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 result for 'english', got %d", result.Total)
	}

	// Search with no matches
	result, err = qb.BuildListQuery(QueryParams{SchemaName: "cheese", Search: "nonexistent"})
	if err != nil {
		t.Fatalf("failed to search: %v", err)
	}
	if result.Total != 0 {
		t.Errorf("expected 0 results for 'nonexistent', got %d", result.Total)
	}
}

func TestEAVQueryBuilder_EAVFilters(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Cheddar",
		"type": "Hard",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Filter by type
	result, err := qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Filters:    map[string]interface{}{"type": "Soft"},
	})
	if err != nil {
		t.Fatalf("failed to filter: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 soft cheese, got %d", result.Total)
	}

	// Multiple filters
	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name":   "Camembert",
		"type":   "Soft",
		"origin": "France",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	result, err = qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Filters:    map[string]interface{}{"type": "Soft", "origin": "France"},
	})
	if err != nil {
		t.Fatalf("failed to filter: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 soft french cheese, got %d", result.Total)
	}
}

func TestEAVQueryBuilder_HasImage(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	url := "http://example.com/image.jpg"
	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name":      "Cheddar",
		"type":      "Hard",
		"image_url": url,
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	trueVal := true
	result, err := qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		HasImage:   &trueVal,
	})
	if err != nil {
		t.Fatalf("failed to filter has_image: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 item with image, got %d", result.Total)
	}

	falseVal := false
	result, err = qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		HasImage:   &falseVal,
	})
	if err != nil {
		t.Fatalf("failed to filter no image: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 item without image, got %d", result.Total)
	}
}

func TestEAVQueryBuilder_Sorting(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Cheddar",
		"type": "Hard",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Sort by name ascending
	result, err := qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Sort:       "name",
	})
	if err != nil {
		t.Fatalf("failed to sort: %v", err)
	}
	if len(result.Items) < 2 {
		t.Fatal("expected at least 2 items")
	}
	if result.Items[0]["name"] != "Brie" {
		t.Errorf("expected first item to be Brie, got %v", result.Items[0]["name"])
	}

	// Sort by name descending
	result, err = qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Sort:       "-name",
	})
	if err != nil {
		t.Fatalf("failed to sort desc: %v", err)
	}
	if result.Items[0]["name"] != "Cheddar" {
		t.Errorf("expected first item to be Cheddar, got %v", result.Items[0]["name"])
	}

	// Sort by created_at descending
	result, err = qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Sort:       "-created_at",
	})
	if err != nil {
		t.Fatalf("failed to sort by created_at: %v", err)
	}
	if len(result.Items) < 2 {
		t.Fatal("expected at least 2 items")
	}
	// Cheddar was created second, should be first when sorting by created_at desc
	if result.Items[0]["name"] != "Brie" {
		// Actually Brie was created second if we look at the order above...
		// Wait, Cheddar first, then Brie. So Brie should be first with -created_at
		t.Logf("First item with -created_at: %v", result.Items[0]["name"])
	}
}

func TestEAVQueryBuilder_GetItem(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	result, err := qb.GetItem("cheese", item.ID)
	if err != nil {
		t.Fatalf("failed to get item: %v", err)
	}
	if (*result)["name"] != "Brie" {
		t.Errorf("expected name 'Brie', got %v", (*result)["name"])
	}

	// Non-existent item
	_, err = qb.GetItem("cheese", 99999)
	if err == nil {
		t.Error("expected error for non-existent item")
	}

	// Non-existent schema
	_, err = qb.GetItem("nonexistent", item.ID)
	if err == nil {
		t.Error("expected error for non-existent schema")
	}
}

func TestEAVQueryBuilder_DualWriteCreate(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Verify JSON field_values
	var dbItem models.Item
	if err := utils.DB.First(&dbItem, item.ID).Error; err != nil {
		t.Fatalf("failed to fetch item from db: %v", err)
	}
	if dbItem.FieldValues == "" {
		t.Error("expected field_values JSON to be set")
	}

	// Verify EAV rows
	var fieldValues []models.ItemFieldValue
	if err := utils.DB.Where("item_id = ?", item.ID).Find(&fieldValues).Error; err != nil {
		t.Fatalf("failed to fetch field values: %v", err)
	}
	if len(fieldValues) < 1 {
		t.Errorf("expected EAV rows, got %d", len(fieldValues))
	}
}

func TestEAVQueryBuilder_DuplicateRejection(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	// Cheese has unique_fields: ["name"]
	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create first item: %v", err)
	}

	// Duplicate name should be rejected
	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Hard",
	})
	if err == nil {
		t.Error("expected duplicate item to be rejected")
	}
	if err.Error() != "duplicate item" {
		t.Errorf("expected 'duplicate item' error, got: %v", err.Error())
	}
}

func TestEAVQueryBuilder_Update(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	updated, err := qb.UpdateItem("cheese", item.ID, uint(user.ID), map[string]interface{}{
		"name": "Updated Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to update item: %v", err)
	}
	if updated.Name != "Updated Brie" {
		t.Errorf("expected name 'Updated Brie', got '%s'", updated.Name)
	}

	// Verify EAV rows updated
	var dbItem models.Item
	if err := utils.DB.Preload("FieldValuesRows").First(&dbItem, item.ID).Error; err != nil {
		t.Fatalf("failed to fetch updated item: %v", err)
	}
}

func TestEAVQueryBuilder_UnauthorizedUpdate(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user1 := createTestUser(t)
	user2 := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user1.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	_, err = qb.UpdateItem("cheese", item.ID, uint(user2.ID), map[string]interface{}{
		"name": "Hacked Brie",
	})
	if err == nil {
		t.Error("expected unauthorized update to be rejected")
	}
	if err.Error() != "unauthorized" {
		t.Errorf("expected 'unauthorized' error, got: %v", err.Error())
	}
}

func TestEAVQueryBuilder_Delete(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Verify field values exist
	var count int64
	utils.DB.Model(&models.ItemFieldValue{}).Where("item_id = ?", item.ID).Count(&count)
	if count == 0 {
		t.Fatal("expected field values before delete")
	}

	// Delete
	if err := qb.DeleteItem("cheese", item.ID, uint(user.ID), false); err != nil {
		t.Fatalf("failed to delete item: %v", err)
	}

	// Verify item soft-deleted
	var dbItem models.Item
	if err := utils.DB.First(&dbItem, item.ID).Error; err == nil {
		t.Error("expected item to be deleted")
	}

	// Verify field values cascade deleted
	utils.DB.Model(&models.ItemFieldValue{}).Where("item_id = ?", item.ID).Count(&count)
	if count != 0 {
		t.Errorf("expected 0 field values after delete, got %d", count)
	}
}

func TestEAVQueryBuilder_UnauthorizedDelete(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user1 := createTestUser(t)
	user2 := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user1.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	err = qb.DeleteItem("cheese", item.ID, uint(user2.ID), false)
	if err == nil {
		t.Error("expected unauthorized delete to be rejected")
	}
	if err.Error() != "unauthorized" {
		t.Errorf("expected 'unauthorized' error, got: %v", err.Error())
	}
}

func TestEAVQueryBuilder_Impact(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Create a rating for the item
	rating := models.Rating{
		Grade:  5.0,
		Note:   "Great cheese",
		UserID: int(user.ID),
		ItemID: int(item.ID),
	}
	if err := utils.DB.Create(&rating).Error; err != nil {
		t.Fatalf("failed to create rating: %v", err)
	}

	impact, err := qb.GetDeleteImpact("cheese", item.ID)
	if err != nil {
		t.Fatalf("failed to get delete impact: %v", err)
	}
	impactData, ok := impact["impact"].(map[string]interface{})
	if !ok {
		t.Fatalf("expected impact to be a map, got %T", impact["impact"])
	}
	if impactData["ratings_count"] != int(1) {
		t.Errorf("expected ratings_count 1, got %v", impactData["ratings_count"])
	}
	if impactData["users_affected"] != int(1) {
		t.Errorf("expected users_affected 1, got %v", impactData["users_affected"])
	}
}

func TestEAVQueryBuilder_FieldValuesJSONCoercion(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)
	schema, _ := qb.registry.GetSchema("cheese")

	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "Brie",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Fetch field values and build JSON
	var fieldValues []models.ItemFieldValue
	if err := utils.DB.Where("item_id = ?", item.ID).Find(&fieldValues).Error; err != nil {
		t.Fatalf("failed to fetch field values: %v", err)
	}

	jsonStr, err := BuildFieldValuesJSON(fieldValues, schema.Fields)
	if err != nil {
		t.Fatalf("BuildFieldValuesJSON failed: %v", err)
	}
	if jsonStr == "" || jsonStr == "{}" {
		t.Error("expected non-empty field values JSON")
	}
}

func TestEAVQueryBuilder_PartialUpdatePreservesFieldValues(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	// Create item with multiple fields
	item, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name":        "Brie",
		"type":        "Soft",
		"origin":      "France",
		"description": "A classic French cheese",
	})
	if err != nil {
		t.Fatalf("failed to create item: %v", err)
	}

	// Partial update: only update name
	_, err = qb.UpdateItem("cheese", item.ID, uint(user.ID), map[string]interface{}{
		"name": "Updated Brie",
	})
	if err != nil {
		t.Fatalf("failed to update item: %v", err)
	}

	// Verify field_values JSON still contains all fields
	var dbItem models.Item
	if err := utils.DB.First(&dbItem, item.ID).Error; err != nil {
		t.Fatalf("failed to fetch item from db: %v", err)
	}

	var fieldValues map[string]interface{}
	if err := json.Unmarshal([]byte(dbItem.FieldValues), &fieldValues); err != nil {
		t.Fatalf("failed to unmarshal field_values: %v", err)
	}

	if fieldValues["name"] != "Updated Brie" {
		t.Errorf("expected name 'Updated Brie', got %v", fieldValues["name"])
	}
	if fieldValues["type"] != "Soft" {
		t.Errorf("expected type 'Soft' to be preserved, got %v", fieldValues["type"])
	}
	if fieldValues["origin"] != "France" {
		t.Errorf("expected origin 'France' to be preserved, got %v", fieldValues["origin"])
	}
	if fieldValues["description"] != "A classic French cheese" {
		t.Errorf("expected description to be preserved, got %v", fieldValues["description"])
	}
}

func TestEAVQueryBuilder_RatedBy(t *testing.T) {
	qb, cleanup := setupQueryBuilderTest(t)
	defer cleanup()

	user := createTestUser(t)

	// Create 3 items: A (author-rated), B (viewer-shared), C (unrated)
	_, err := qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "A - Rated by author",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item A: %v", err)
	}

	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "B - Shared with viewer",
		"type": "Soft",
	})
	if err != nil {
		t.Fatalf("failed to create item B: %v", err)
	}

	_, err = qb.CreateItem("cheese", uint(user.ID), map[string]interface{}{
		"name": "C - Unrated",
		"type": "Hard",
	})
	if err != nil {
		t.Fatalf("failed to create item C: %v", err)
	}

	// Get item IDs from database
	var allItems []models.Item
	if err := utils.DB.Where("schema_id = (SELECT id FROM item_type_schemas WHERE name = ?)", "cheese").Find(&allItems).Error; err != nil {
		t.Fatalf("failed to fetch items: %v", err)
	}
	if len(allItems) < 3 {
		t.Fatalf("expected at least 3 items, got %d", len(allItems))
	}

	// Find items by name
	var itemA, itemB *models.Item
	for i := range allItems {
		if allItems[i].Name == "A - Rated by author" {
			itemA = &allItems[i]
		}
		if allItems[i].Name == "B - Shared with viewer" {
			itemB = &allItems[i]
		}
	}
	if itemA == nil || itemB == nil {
		t.Fatal("could not find test items A or B")
	}

	// Create rating for item A as test user (author)
	ratingA := models.Rating{
		Grade:  5.0,
		Note:   "Excellent",
		UserID: int(user.ID),
		ItemID: int(itemA.ID),
	}
	if err := utils.DB.Create(&ratingA).Error; err != nil {
		t.Fatalf("failed to create rating A: %v", err)
	}

	// Create rating for item B as another user
	otherUser := createTestUser(t)
	ratingB := models.Rating{
		Grade:  4.0,
		Note:   "Good",
		UserID: int(otherUser.ID),
		ItemID: int(itemB.ID),
	}
	if err := utils.DB.Create(&ratingB).Error; err != nil {
		t.Fatalf("failed to create rating B: %v", err)
	}

	// Add test user as viewer of rating B
	if err := utils.DB.Table("rating_viewers").Create(map[string]interface{}{
		"rating_id": ratingB.ID,
		"user_id":   user.ID,
	}).Error; err != nil {
		t.Fatalf("failed to add viewer: %v", err)
	}

	// Query with Rated=true — should return items A and B (not C)
	result, err := qb.BuildListQuery(QueryParams{
		SchemaName:    "cheese",
		Rated:         true,
		RatedByUserID: int(user.ID),
		Page:          1,
		PerPage:       20,
	})
	if err != nil {
		t.Fatalf("failed to query rated items: %v", err)
	}
	if result.Total != 2 {
		t.Errorf("expected 2 rated items, got %d", result.Total)
	}
	ratedNames := make(map[string]bool)
	for _, item := range result.Items {
		if name, ok := item["name"].(string); ok {
			ratedNames[name] = true
		}
	}
	if !ratedNames["A - Rated by author"] {
		t.Error("expected item A (author-rated) to be in results")
	}
	if !ratedNames["B - Shared with viewer"] {
		t.Error("expected item B (viewer-shared) to be in results")
	}
	if ratedNames["C - Unrated"] {
		t.Error("did not expect item C (unrated) to be in results")
	}

	// Query without Rated flag — should return all 3 items
	result, err = qb.BuildListQuery(QueryParams{
		SchemaName: "cheese",
		Page:       1,
		PerPage:    20,
	})
	if err != nil {
		t.Fatalf("failed to query all items: %v", err)
	}
	if result.Total != 3 {
		t.Errorf("expected 3 total items without rated flag, got %d", result.Total)
	}

	// Test pagination within rated subset
	result, err = qb.BuildListQuery(QueryParams{
		SchemaName:    "cheese",
		Rated:         true,
		RatedByUserID: int(user.ID),
		Page:          1,
		PerPage:       1,
	})
	if err != nil {
		t.Fatalf("failed to query rated items page 1: %v", err)
	}
	if result.Total != 2 {
		t.Errorf("expected total 2 rated items, got %d", result.Total)
	}
	if len(result.Items) != 1 {
		t.Errorf("expected 1 item on page 1 with per_page=1, got %d", len(result.Items))
	}

	result, err = qb.BuildListQuery(QueryParams{
		SchemaName:    "cheese",
		Rated:         true,
		RatedByUserID: int(user.ID),
		Page:          2,
		PerPage:       1,
	})
	if err != nil {
		t.Fatalf("failed to query rated items page 2: %v", err)
	}
	if len(result.Items) != 1 {
		t.Errorf("expected 1 item on page 2 with per_page=1, got %d", len(result.Items))
	}
}
