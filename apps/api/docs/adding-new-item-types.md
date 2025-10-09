# Adding New Item Types - Backend Guide

**Document Created:** September 30, 2025  
**Item Types Implemented:** Cheese (original), Gin (added)

This document provides the complete backend implementation guide for adding new item types to the A la carte REST API.

---

## 🎯 **Overview**

The A la carte backend uses GORM's polymorphic associations to support multiple item types (cheese, gin, wine, beer, etc.) with a single Rating table. This guide documents the complete process based on our gin implementation.

---

## 📊 **Data Model Design**

### **Key Principle: Parallel Structure**

All item types should follow consistent field structure for maintainability:

| Common Fields | Purpose | Example (Cheese) | Example (Gin) |
|---------------|---------|------------------|---------------|
| **name** | Product name | "Oka" | "Ungava" |
| **producer** | Maker/creator | "Fromagerie d'Oka" | "Les Spiritueux Ungava" |
| **origin** | Geographic source | "Oka" | "Quebec" |
| **type/profile** | Category/style | "Pâte pressée cuite" | "Forestier / boréal" |
| **description** | Details (optional) | Tasting notes | Flavor description |

### **Field Naming Best Practices**

**✅ Use `origin` (not `region`):**
- Supports international expansion
- "Quebec", "London, UK", "Osaka, Japan" all work
- Consistent across item types
- Future-proof for global products

**✅ Use domain-appropriate category fields:**
- Cheese: `type` (Pâte molle, Pâte dure, etc.)
- Gin: `profile` (Forestier / boréal, Floral, Épicé)
- Wine: `varietal` (Chardonnay, Pinot Noir)
- Beer: `style` (IPA, Lager, Stout)

**✅ Keep descriptions optional:**
- Not all items need detailed descriptions
- Can be added later
- User-generated content can supplement

---

## 🗄️ **Backend Implementation Steps**

### **Time Estimate: ~45 minutes**

---

## **Step 1: Create Model** (~5 min)

**File:** `models/ginModel.go`

```go
package models

import (
	"gorm.io/gorm"
)

type Gin struct {
	gorm.Model
	Name        string   `gorm:"unique" json:"name"`
	Producer    string   `json:"producer"`
	Origin      string   `json:"origin"`
	Profile     string   `json:"profile"`
	Description string   `json:"description"`
	Ratings     []Rating `gorm:"polymorphic:Item;"`
}
```

**Critical Points:**
- `gorm.Model` - Adds ID, CreatedAt, UpdatedAt, DeletedAt
- `gorm:"unique"` on Name - Prevents duplicate entries
- `json:"name"` lowercase - Matches frontend expectations
- `gorm:"polymorphic:Item;"` - **REQUIRED** for ratings to work

**Polymorphic Ratings:**
```go
// Rating model already supports this
type Rating struct {
    ItemID   int    `json:"item_id"`
    ItemType string `json:"item_type"`  // "cheese", "gin", etc.
}
```

Ratings automatically work with any item type!

---

## **Step 2: Create Controller** (~10 min)

**File:** `controllers/ginController.go`

**Pattern:** Copy `cheeseController.go` exactly, update fields

```go
package controllers

import (
	"net/http"
	"github.com/davidcharbonnier/rest-api/models"
	"github.com/davidcharbonnier/rest-api/utils"
	"github.com/gin-gonic/gin"
)

func GinCreate(c *gin.Context) {
	var body struct {
		Name        string
		Producer    string
		Origin      string
		Profile     string
		Description string
	}
	c.Bind(&body)

	ginItem := models.Gin{
		Name:        body.Name,
		Producer:    body.Producer,
		Origin:      body.Origin,
		Profile:     body.Profile,
		Description: body.Description,
	}

	if err := utils.DB.Create(&ginItem).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinIndex(c *gin.Context) {
	var gins []models.Gin

	if err := utils.DB.Find(&gins).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, gins)
}

func GinDetails(c *gin.Context) {
	id := c.Param("id")
	var ginItem = models.Gin{}

	if err := utils.DB.First(&ginItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinEdit(c *gin.Context) {
	id := c.Param("id")

	var body struct {
		Name        string
		Producer    string
		Origin      string
		Profile     string
		Description string
	}
	c.Bind(&body)

	var ginItem = models.Gin{}

	if err := utils.DB.First(&ginItem, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if err := utils.DB.Model(&ginItem).Updates(models.Gin{
		Name:        body.Name,
		Producer:    body.Producer,
		Origin:      body.Origin,
		Profile:     body.Profile,
		Description: body.Description,
	}).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.JSON(http.StatusOK, ginItem)
}

func GinRemove(c *gin.Context) {
	id := c.Param("id")

	if err := utils.DB.Delete(&models.Gin{}, id).Error; err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	c.Status(http.StatusOK)
}
```

**Standard CRUD Operations:**
- Create - POST with JSON binding
- Index - GET all items
- Details - GET single item by ID
- Edit - PUT with updates
- Remove - DELETE by ID

**Error Handling:**
- Returns HTTP 400 on errors
- Returns HTTP 200 with data on success

---

## **Step 3: Register Routes** (~5 min)

**File:** `main.go`

Add routes in the protected API group:

```go
api := router.Group("/api")
api.Use(utils.RequireAuth())
{
    // cheese (existing)
    cheese := api.Group("/cheese")
    {
        cheese.POST("/new", controllers.CheeseCreate)
        cheese.GET("/all", controllers.CheeseIndex)
        cheese.GET("/:id", controllers.CheeseDetails)
        cheese.PUT("/:id", controllers.CheeseEdit)
        cheese.DELETE("/:id", controllers.CheeseRemove)
    }

    // gin (NEW)
    ginItem := api.Group("/gin")
    {
        ginItem.POST("/new", controllers.GinCreate)
        ginItem.GET("/all", controllers.GinIndex)
        ginItem.GET("/:id", controllers.GinDetails)
        ginItem.PUT("/:id", controllers.GinEdit)
        ginItem.DELETE("/:id", controllers.GinRemove)
    }

    // rating (existing - works with all item types)
    rating := api.Group("/rating")
    {
        // ... rating endpoints
    }
}
```

**Important:**
- Use `ginItem` variable name (not `gin` - conflicts with framework)
- All routes require authentication
- Follows RESTful conventions

---

## **Step 4: Add Migration** (~2 min)

**File:** `utils/database.go`

Update `RunMigrations()` function:

```go
func RunMigrations() {
	log.Println("Running database migrations...")
	
	err := DB.AutoMigrate(
		&models.User{},
		&models.Cheese{},
		&models.Gin{},      // ADD THIS LINE
		&models.Rating{},
	)
	
	if err != nil {
		log.Fatal("Database migration failed:", err)
	}
	
	log.Println("Database migrations completed successfully")
}
```

**What Happens:**
- GORM creates `gins` table automatically
- Runs on application startup
- Safe additive migrations only
- No manual SQL scripts needed

**Table Structure:**
```sql
gins (
    id, created_at, updated_at, deleted_at,  -- from gorm.Model
    name, producer, origin, profile, description
)
```

---

## **Step 5: Add Seeding Logic** (~15 min)

**File:** `utils/database.go`

### **5a. Update RunSeeding() orchestrator:**

```go
func RunSeeding() {
	log.Println("Starting data seeding...")
	
	// Seed cheese (existing)
	source := os.Getenv("CHEESE_DATA_SOURCE")
	if source != "" {
		if err := seedCheeseData(source); err != nil {
			log.Printf("Cheese seeding failed (continuing anyway): %v", err)
		}
	}
	
	// Seed gin (NEW)
	ginSource := os.Getenv("GIN_DATA_SOURCE")
	if ginSource != "" {
		if err := seedGinData(ginSource); err != nil {
			log.Printf("Gin seeding failed (continuing anyway): %v", err)
		}
	} else {
		log.Println("GIN_DATA_SOURCE not set, skipping gin seeding")
	}
	
	log.Println("Data seeding completed successfully")
}
```

### **5b. Add seedGinData() function:**

```go
func seedGinData(source string) error {
	gins, err := loadGinData(source)
	if err != nil {
		return fmt.Errorf("failed to load gin data: %w", err)
	}
	
	log.Printf("Loaded %d gins from: %s", len(gins), source)
	
	// Natural key: name + origin (user-safe, only add new items)
	addedCount := 0
	skippedCount := 0
	
	for _, gin := range gins {
		var existing models.Gin
		result := DB.Where("name = ? AND origin = ?", gin.Name, gin.Origin).First(&existing)
		
		if result.Error == gorm.ErrRecordNotFound {
			DB.Create(&gin)
			addedCount++
		} else {
			skippedCount++
		}
	}
	
	log.Printf("Gin seeding complete: %d added, %d skipped (already exist)", addedCount, skippedCount)
	return nil
}
```

### **5c. Add loadGinData() function:**

```go
func loadGinData(source string) ([]models.Gin, error) {
	var data []byte
	var err error
	
	// Support both remote URLs and local files
	if strings.HasPrefix(source, "http://") || strings.HasPrefix(source, "https://") {
		log.Printf("Fetching gin data from URL: %s", source)
		resp, err := http.Get(source)
		if err != nil {
			return nil, fmt.Errorf("failed to fetch remote data: %w", err)
		}
		defer resp.Body.Close()
		
		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("HTTP error: %s", resp.Status)
		}
		
		data, err = io.ReadAll(resp.Body)
	} else {
		log.Printf("Loading gin data from file: %s", source)
		data, err = os.ReadFile(source)
	}
	
	if err != nil {
		return nil, err
	}
	
	// Parse JSON
	type GinData struct {
		Gins []models.Gin `json:"gins"`
	}
	
	var ginData GinData
	if err := json.Unmarshal(data, &ginData); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}
	
	return ginData.Gins, nil
}
```

**Key Features:**
- Supports remote URLs and local files
- Natural key matching (name + origin)
- User-safe (never overwrites existing data)
- Error resilient (logs but continues)

---

## **Step 6: Configure Environment** (~2 min)

**File:** `.env`

```bash
# Existing variables...
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=alacarte
JWT_SECRET_KEY=your-secret-key

# Data Seeding
CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json
GIN_DATA_SOURCE=../alacarte-seed/gins.json       # ADD THIS
RUN_SEEDING=true  # Enable for initial bootstrap
```

**Options:**

**Local Development:**
```bash
GIN_DATA_SOURCE=../alacarte-seed/gins.json
```

**Production:**
```bash
GIN_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/gins.json
```

---

## **Step 7: Create Seed Data** (~varies)

**File:** `alacarte-seed/gins.json` (separate repository)

```json
{
  "gins": [
    {
      "name": "Ungava",
      "producer": "Les Spiritueux Ungava",
      "origin": "Quebec",
      "profile": "Forestier / boréal",
      "description": "Ungava révèle un style à la fois vif, moelleux, frais et floral..."
    },
    {
      "name": "Romeo's Gin",
      "producer": "Michel Jodoin",
      "origin": "Montreal",
      "profile": "Herbacé / végétal",
      "description": "Au sommet des ventes des gins de la province..."
    }
  ]
}
```

**Data Collection Time:**
- Manual (30 items): 2-3 hours
- Semi-automated (240 items): 5-8 hours
- **Recommended:** Start with 10-30 curated items

---

## **Step 8: Add Admin Endpoints** (~15 min)

Admin endpoints provide item management capabilities for the admin panel. They should be added to the same controller file as the public endpoints.

**File:** `controllers/ginController.go`

Add these functions after the CRUD operations:

```go
// ===== ADMIN ENDPOINTS =====

// GetGinDeleteImpact shows what will be affected if gin is deleted
func GetGinDeleteImpact(c *gin.Context) {
	ginID := c.Param("id")

	// Check if gin exists
	var ginItem models.Gin
	if err := utils.DB.First(&ginItem, ginID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Gin not found"})
		return
	}

	// Get all ratings for this gin
	var ratings []models.Rating
	utils.DB.Preload("User").Where("item_type = ? AND item_id = ?", "gin", ginID).Find(&ratings)

	// Count unique users affected
	userMap := make(map[uint]bool)
	userDetails := make(map[uint]struct {
		ID           uint
		DisplayName  string
		RatingsCount int
	})

	for _, rating := range ratings {
		userMap[uint(rating.UserID)] = true
		if user, exists := userDetails[uint(rating.UserID)]; exists {
			user.RatingsCount++
			userDetails[uint(rating.UserID)] = user
		} else {
			userDetails[uint(rating.UserID)] = struct {
				ID           uint
				DisplayName  string
				RatingsCount int
			}{
				ID:           rating.User.ID,
				DisplayName:  rating.User.DisplayName,
				RatingsCount: 1,
			}
		}
	}

	// Count total sharings
	var sharingsCount int64
	for _, rating := range ratings {
		var count int64
		utils.DB.Table("rating_viewers").Where("rating_id = ?", rating.ID).Count(&count)
		sharingsCount += count
	}

	// Build affected users list
	affectedUsers := []gin.H{}
	for _, user := range userDetails {
		affectedUsers = append(affectedUsers, gin.H{
			"id":            user.ID,
			"display_name":  user.DisplayName,
			"ratings_count": user.RatingsCount,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"can_delete": true,
		"warnings": []string{
			"This will permanently delete all ratings for this item",
			"Users who rated this item will lose their ratings",
		},
		"impact": gin.H{
			"ratings_count":  len(ratings),
			"users_affected": len(userMap),
			"sharings_count": sharingsCount,
			"affected_users": affectedUsers,
		},
	})
}

// DeleteGin deletes a gin and all associated ratings (cascade)
func DeleteGin(c *gin.Context) {
	ginID := c.Param("id")

	// Check if gin exists
	var ginItem models.Gin
	if err := utils.DB.First(&ginItem, ginID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Gin not found"})
		return
	}

	// Start transaction
	tx := utils.DB.Begin()

	// Get all ratings for this gin
	var ratings []models.Rating
	tx.Where("item_type = ? AND item_id = ?", "gin", ginID).Find(&ratings)

	// Delete rating viewers (sharing relationships)
	for _, rating := range ratings {
		tx.Exec("DELETE FROM rating_viewers WHERE rating_id = ?", rating.ID)
	}

	// Delete ratings
	tx.Where("item_type = ? AND item_id = ?", "gin", ginID).Delete(&models.Rating{})

	// Delete the gin
	if err := tx.Delete(&ginItem).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete gin"})
		return
	}

	// Commit transaction
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"message": "Gin deleted successfully"})
}

// SeedGins bulk imports gins from remote URL
func SeedGins(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required"})
		return
	}

	// Fetch JSON from URL
	resp, err := http.Get(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to fetch URL: %v", err)})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to fetch URL: status %d", resp.StatusCode)})
		return
	}

	// Read body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read response"})
		return
	}

	// Parse JSON
	var data struct {
		Gins []models.Gin `json:"gins"`
	}
	if err := json.Unmarshal(body, &data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	// Import gins
	added := 0
	skipped := 0
	errors := []string{}

	for _, ginItem := range data.Gins {
		// Check if gin already exists (natural key: name + origin)
		var existing models.Gin
		err := utils.DB.Where("name = ? AND origin = ?", ginItem.Name, ginItem.Origin).First(&existing).Error

		if err == nil {
			// Already exists - skip
			skipped++
			continue
		}

		// Create new gin
		if err := utils.DB.Create(&ginItem).Error; err != nil {
			errors = append(errors, fmt.Sprintf("Failed to create %s: %v", ginItem.Name, err))
			continue
		}
		added++
	}

	c.JSON(http.StatusOK, gin.H{
		"added":   added,
		"skipped": skipped,
		"errors":  errors,
	})
}

// ValidateGins validates JSON structure without importing
func ValidateGins(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required"})
		return
	}

	// Fetch JSON from URL
	resp, err := http.Get(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to fetch URL: %v", err)})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to fetch URL: status %d", resp.StatusCode)})
		return
	}

	// Read body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read response"})
		return
	}

	// Parse JSON
	var data struct {
		Gins []models.Gin `json:"gins"`
	}
	if err := json.Unmarshal(body, &data); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"valid":      false,
			"errors":     []string{fmt.Sprintf("Invalid JSON format: %v", err)},
			"item_count": 0,
			"duplicates": 0,
		})
		return
	}

	// Validate structure and find duplicates
	validationErrors := []string{}
	seen := make(map[string]bool)
	duplicates := 0

	for i, ginItem := range data.Gins {
		// Check required fields
		if ginItem.Name == "" {
			validationErrors = append(validationErrors, fmt.Sprintf("Item %d: missing name", i+1))
		}
		if ginItem.Origin == "" {
			validationErrors = append(validationErrors, fmt.Sprintf("Item %d: missing origin", i+1))
		}

		// Check for duplicates within file
		key := ginItem.Name + "|" + ginItem.Origin
		if seen[key] {
			duplicates++
		}
		seen[key] = true
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":      len(validationErrors) == 0,
		"errors":     validationErrors,
		"item_count": len(data.Gins),
		"duplicates": duplicates,
	})
}
```

**Add required imports:**
```go
import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	// ... existing imports
)
```

**Admin Functions:**
- **GetGinDeleteImpact**: Shows affected ratings, users, and sharing relationships before deletion
- **DeleteGin**: Cascade deletes gin with all ratings and sharing relationships using transactions
- **SeedGins**: Bulk imports gins from remote JSON URL with natural key matching
- **ValidateGins**: Validates JSON structure and finds duplicates without importing

---

## **Step 9: Register Admin Routes** (~3 min)

**File:** `main.go`

Add admin routes after the public API group:

```go
// Admin routes (requires admin privileges)
admin := router.Group("/admin")
admin.Use(utils.RequireAuth(), utils.RequireAdmin())
{
	// Cheese admin (existing)
	cheese := admin.Group("/cheese")
	{
		cheese.GET("/:id/delete-impact", controllers.GetCheeseDeleteImpact)
		cheese.DELETE("/:id", controllers.DeleteCheese)
		cheese.POST("/seed", controllers.SeedCheeses)
		cheese.POST("/validate", controllers.ValidateCheeses)
	}

	// Gin admin (NEW)
	ginAdmin := admin.Group("/gin")
	{
		ginAdmin.GET("/:id/delete-impact", controllers.GetGinDeleteImpact)
		ginAdmin.DELETE("/:id", controllers.DeleteGin)
		ginAdmin.POST("/seed", controllers.SeedGins)
		ginAdmin.POST("/validate", controllers.ValidateGins)
	}
}
```

**Important:**
- Admin routes protected by `RequireAuth()` + `RequireAdmin()` middleware
- Separate route group prevents conflicts with public endpoints
- Use `ginAdmin` variable name (not `gin`)

---

## 🧪 **Testing the Backend**

### **1. Reset Database (Development)**

```bash
cd alacarte-api
go run scripts/reset_database.go
```

**Expected output:**
```
🚨 DEVELOPMENT ONLY: Resetting database...
⚠️  This will drop all tables and data!
Note: Could not drop ratings table: ...
Note: Could not drop cheeses table: ...
Note: Could not drop gins table: ...
✅ Tables dropped - restart your app to recreate schema via AutoMigrate
```

### **2. Start API with Seeding**

```bash
RUN_SEEDING=true \
  CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
  GIN_DATA_SOURCE=../alacarte-seed/gins.json \
  go run main.go
```

**Expected output:**
```
Running database migrations...
Database migrations completed successfully
🌱 Starting background seeding process...
📁 Loading cheese data from file: ../alacarte-seed/cheeses.json
Loaded 45 cheeses from: ../alacarte-seed/cheeses.json
✅ Cheese seeding complete: 45 added, 0 skipped
📁 Loading gin data from file: ../alacarte-seed/gins.json
Loaded 10 gins from: ../alacarte-seed/gins.json
✅ Gin seeding complete: 10 added, 0 skipped
🌱 Background seeding process completed
[GIN] Listening and serving on :8080
```

### **3. Test API Endpoints**

```bash
# Get all gins
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/gin/all

# Expected: Array of 10 gin objects

# Get specific gin
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/gin/1

# Expected: Single gin object with all fields

# Create rating for gin
curl -X POST \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "item_id": 1,
    "item_type": "gin",
    "grade": 4.5,
    "note": "Excellent gin!"
  }' \
  http://localhost:8080/api/rating/new

# Expected: Rating created with ID

# Get community stats for gin
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/stats/community/gin/1

# Expected: { total_ratings, average_rating, rating_distribution }
```

---

## 📝 **Data Seeding Guide**

### **Natural Key Strategy**

**Pattern:** `name + origin` uniquely identifies an item

**Why:**
- User-safe (no data overwrites)
- Handles re-seeding gracefully
- Same name from different origins = different items
- Example: "Romeo's Gin" from "Montreal" vs from "Quebec City"

**Implementation:**
```go
result := DB.Where("name = ? AND origin = ?", item.Name, item.Origin).First(&existing)
if result.Error == gorm.ErrRecordNotFound {
    // Item doesn't exist - create it
    DB.Create(&item)
}
// Otherwise skip (already exists)
```

### **Seeding Behavior**

**✅ User-Safe:**
- Only adds new items
- Never modifies existing data
- Preserves user ratings and relationships

**✅ Error Resilient:**
- Seeding failures don't crash API
- Logs errors but continues
- Background processing (non-blocking)

**✅ Flexible Sources:**
- Local file path: `./seed/gins.json` or `../alacarte-seed/gins.json`
- Remote URL: `https://raw.githubusercontent.com/.../gins.json`
- Same code handles both

### **Data Source Format**

```json
{
  "gins": [
    {
      "name": "Required - product name",
      "producer": "Required - maker/distillery",
      "origin": "Required - geographic source",
      "profile": "Required - category/flavor profile",
      "description": "Optional - tasting notes"
    }
  ]
}
```

**Field Requirements:**
- All fields should be non-empty strings
- Description can be empty/null
- No ID field (auto-generated)
- No timestamps (auto-generated)

---

## 🚀 **Deployment Considerations**

### **Environment Configuration**

**Development:**
```env
RUN_SEEDING=false  # Usually off in development
GIN_DATA_SOURCE=../alacarte-seed/gins.json
```

**Production (Initial Bootstrap):**
```env
RUN_SEEDING=true  # One-time only
GIN_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-seed/main/gins.json
```

**Production (Subsequent Deployments):**
```env
RUN_SEEDING=false  # Data already seeded
```

### **Migration Strategy**

**Automatic Migrations (Startup):**
- Safe additive changes only
- Never drops columns or tables
- Production-safe
- No downtime required

**Manual Migrations (Breaking Changes):**
- Column renames require manual SQL
- Table drops require manual SQL
- Document in migration scripts

---

## 🔍 **Common Issues & Solutions**

### **Issue 1: Duplicate Entry Error**

**Symptom:** Seeding fails with "Duplicate entry" error

**Cause:** Item with same name + origin already exists

**Solution:** This is normal - seeding skips it automatically
```
✅ Gin seeding complete: 5 added, 5 skipped (already exist)
```

### **Issue 2: Foreign Key Constraint**

**Symptom:** Can't delete gin that has ratings

**Cause:** Ratings reference the gin item

**Solution:** Delete ratings first, or use soft deletes (GORM default)

### **Issue 3: Seeding Never Completes**

**Symptom:** API starts but seeding hangs

**Cause:** Remote URL unreachable or invalid JSON

**Solution:**
- Check URL is accessible
- Validate JSON format
- Check logs for specific error

### **Issue 4: Gin Endpoint Not Found**

**Symptom:** 404 on `/api/gin/all`

**Cause:** Routes not registered or typo in endpoint

**Solution:**
- Verify routes in `main.go`
- Check variable name (`ginItem` not `gin`)
- Restart API server

---

## 📦 **Repository Organization**

### **Data Separation Strategy**

**Decision:** No seed JSON files in API repository

**Structure:**
```
alacarte-api/          # This repo - API code only
├── models/
├── controllers/
├── scripts/
│   ├── reset_database.go
│   └── seed.go
└── utils/

alacarte-seed/         # Separate repo - Data only
├── cheeses.json
└── gins.json
```

**Benefits:**
- ✅ Smaller API repository
- ✅ Data updates independent of code
- ✅ Clear separation of concerns
- ✅ Data versioning separate from code

**Access Methods:**
1. Local symlinks: `../alacarte-seed/gins.json`
2. Remote URLs: `https://...`
3. Git submodule (alternative)

### **Scripts Organization**

```
scripts/
├── reset_database.go  # Development utility to drop all tables
└── seed.go           # Standalone seeding script
```

**Usage:**
```bash
# Reset database
go run scripts/reset_database.go

# Seed data
CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
GIN_DATA_SOURCE=../alacarte-seed/gins.json \
go run scripts/seed.go
```

**Note:** VS Code may show "main redeclared" linting error - this is harmless and can be ignored. Scripts work perfectly when run individually.

---

## ⚡ **Performance Considerations**

### **Seeding Performance**

**Background Processing:**
```go
if os.Getenv("RUN_SEEDING") == "true" {
    go func() {
        utils.RunSeeding()  // Non-blocking
    }()
}
```

**Benefits:**
- API starts immediately
- Seeding happens in background
- No startup delay for users

**Metrics:**
- 10 items: <1 second
- 100 items: ~2 seconds
- 1000 items: ~10 seconds

### **Database Indexes**

**Current:**
- Unique index on `name` (GORM auto-creates)
- Primary key on `id`

**Future optimization:**
- Add index on `origin` for filtering
- Add index on `profile` for filtering
- Compound index on `name + origin` for natural key queries

---

## 🎯 **Checklist for New Item Type**

Use this when implementing wine, beer, coffee, etc:

### **Backend Files:**
- [ ] Create `models/[itemType]Model.go`
- [ ] Create `controllers/[itemType]Controller.go` (public endpoints)
- [ ] Add admin endpoints to `controllers/[itemType]Controller.go`
- [ ] Update `main.go` (add public routes)
- [ ] Update `main.go` (add admin routes)
- [ ] Update `utils/database.go` (add migration)
- [ ] Update `utils/database.go` (add seeding functions)
- [ ] Update `.env` (add data source variable)
- [ ] Create seed data in `alacarte-seed` repo

### **Testing:**
- [ ] `go run scripts/reset_database.go` works
- [ ] API starts with migration
- [ ] Seeding loads data successfully
- [ ] GET `/api/[itemtype]/all` returns items
- [ ] POST `/api/rating/new` works with new type
- [ ] Community stats work for new type
- [ ] Admin endpoints require authentication
- [ ] GET `/admin/[itemtype]/:id/delete-impact` shows impact
- [ ] DELETE `/admin/[itemtype]/:id` cascade deletes
- [ ] POST `/admin/[itemtype]/seed` bulk imports
- [ ] POST `/admin/[itemtype]/validate` validates JSON

### **Time Estimate:**
- Model + Controller (public): 15 min
- Controller (admin endpoints): 15 min
- Routes (public + admin): 8 min
- Migration: 2 min
- Seeding logic: 15 min
- Testing: 10 min
- **Total: ~65 minutes**

---

## 📚 **Related Documentation**

**API Documentation:**
- Main README - API endpoints and architecture
- `docs/authentication-system.md` - OAuth and JWT
- `docs/privacy-model.md` - Rating privacy architecture

**Item Type Guides:**
- `gin-implementation-status.md` - Current gin implementation
- Frontend guide - See alacarte-client docs

**Development:**
- `scripts/` folder - Development utilities
- `.env.example` - Configuration template

---

## 💡 **Best Practices**

### **Model Design:**
1. Keep fields simple and focused
2. Use domain-appropriate names
3. Make description optional
4. Always include polymorphic ratings

### **Controller Design:**
1. Copy existing pattern exactly
2. Minimal business logic (keep in models)
3. Consistent error handling
4. Standard HTTP status codes

### **Seeding:**
1. Always use natural keys
2. Never overwrite existing data
3. Support both local and remote sources
4. Log progress and errors

### **Testing:**
1. Test migrations first
2. Verify seeding works
3. Test all CRUD endpoints
4. Verify polymorphic ratings work

---

**Backend implementation is straightforward and follows proven patterns. Most complexity is in data collection and frontend integration!** 🎯
