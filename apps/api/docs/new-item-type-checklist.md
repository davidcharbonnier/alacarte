# Quick Reference: Adding a New Item Type (Backend)

**Use this checklist when implementing a new item type backend**

**Time Estimate:** ~65 minutes

---

## 📋 Backend Implementation Checklist

### **1. Create Model** (~5 min)
**File:** `models/[itemtype]Model.go`

```go
package models

import "gorm.io/gorm"

type Wine struct {
    gorm.Model
    Name        string   `gorm:"unique" json:"name"`
    Producer    string   `json:"producer"`
    Origin      string   `json:"origin"`
    Varietal    string   `json:"varietal"`  // Item-specific field
    Description string   `json:"description"`
    Ratings     []Rating `gorm:"polymorphic:Item;"`
}
```

**Checklist:**
- [ ] Create `models/[itemtype]Model.go`
- [ ] Fields match data source structure
- [ ] `gorm:"unique"` on Name
- [ ] Polymorphic ratings: `gorm:"polymorphic:Item;"`
- [ ] JSON tags lowercase
- [ ] 4-6 core fields + description

---

### **2. Create Controller** (~10 min)
**File:** `controllers/[itemtype]Controller.go`

**Checklist:**
- [ ] Create `controllers/[itemtype]Controller.go`
- [ ] Copy cheese controller pattern
- [ ] Implement: Create, Index, Details, Edit, Remove
- [ ] Update struct binding fields to match model
- [ ] Update validation logic

---

### **3. Add Routes** (~5 min)
**File:** `main.go`

```go
itemType := api.Group("/wine")
itemType.Use(middleware.RequireAuth())
{
    itemType.POST("/new", controllers.WineCreate)
    itemType.GET("/all", controllers.WineIndex)
    itemType.GET("/:id", controllers.WineDetails)
    itemType.PUT("/:id", controllers.WineEdit)
    itemType.DELETE("/:id", controllers.WineRemove)
}
```

**Checklist:**
- [ ] Routes added to `/api` group
- [ ] Authentication middleware applied
- [ ] All 5 CRUD endpoints registered

---

### **4. Add Migration** (~2 min)
**File:** `utils/database.go`

```go
err := DB.AutoMigrate(
    &models.User{},
    &models.Cheese{},
    &models.Gin{},
    &models.Wine{},  // ADD THIS
    &models.Rating{},
)
```

**Checklist:**
- [ ] Model added to AutoMigrate list
- [ ] Runs on app startup

---

### **5. Add Seeding Logic** (~15 min)
**File:** `utils/database.go`

**Add to `RunSeeding()`:**
```go
wineSource := os.Getenv("WINE_DATA_SOURCE")
if wineSource != "" {
    if err := seedWineData(wineSource); err != nil {
        log.Printf("Wine seeding failed (continuing anyway): %v", err)
    }
}
```

**Add seeding functions:**
```go
func seedWineData(source string) error {
    wines, err := loadWineData(source)
    if err != nil {
        return fmt.Errorf("failed to load wine data: %v", err)
    }

    for _, wine := range wines {
        var existing models.Wine
        result := DB.Where("name = ? AND origin = ?", wine.Name, wine.Origin).First(&existing)
        
        if result.Error == gorm.ErrRecordNotFound {
            if err := DB.Create(&wine).Error; err != nil {
                log.Printf("Failed to create wine %s: %v", wine.Name, err)
            }
        }
    }
    return nil
}

func loadWineData(source string) ([]models.Wine, error) {
    var data struct {
        Wines []models.Wine `json:"wines"`
    }
    
    if err := loadJSONData(source, &data); err != nil {
        return nil, err
    }
    
    return data.Wines, nil
}
```

**Checklist:**
- [ ] `seedWineData()` function created
- [ ] `loadWineData()` function created
- [ ] Natural key matching: `name + origin`
- [ ] Called from `RunSeeding()`
- [ ] Handles both file paths and URLs
- [ ] Error handling in place

---

### **6. Configure Environment** (~2 min)
**File:** `.env`

```bash
# Add wine data source
WINE_DATA_SOURCE=../alacarte-seed/wines.json
# Or remote URL for production:
# WINE_DATA_SOURCE=https://raw.githubusercontent.com/user/alacarte-seed/main/wines.json

# Enable seeding
RUN_SEEDING=true
```

**Checklist:**
- [ ] `WINE_DATA_SOURCE` variable added
- [ ] Points to seed data file or URL
- [ ] `RUN_SEEDING=true` for development

---

### **7. Create Seed Data** (~varies)
**File:** `alacarte-seed/wines.json` (separate repository)

```json
{
  "wines": [
    {
      "name": "Château Example",
      "producer": "Vignoble Example",
      "origin": "Quebec",
      "varietal": "Frontenac",
      "description": "Description from source..."
    }
  ]
}
```

**Checklist:**
- [ ] JSON file created in `alacarte-seed` repo
- [ ] 10-30 items for initial launch
- [ ] All required fields populated
- [ ] Data in appropriate language (authentic)
- [ ] Data source documented

---

### **8. Add Admin Endpoints** (~15 min)
**File:** `controllers/[itemtype]Controller.go`

**Checklist:**
- [ ] Add admin section after public CRUD operations
- [ ] Implement `Get[ItemType]DeleteImpact` - shows affected ratings/users/sharings
- [ ] Implement `Delete[ItemType]` - cascade deletion with transactions
- [ ] Implement `Seed[ItemType]s` - bulk import from remote URL
- [ ] Implement `Validate[ItemType]s` - JSON validation without importing
- [ ] Add required imports: `encoding/json`, `fmt`, `io`

---

### **9. Add Admin Routes** (~3 min)
**File:** `main.go`

```go
// Admin routes (requires admin privileges)
admin := router.Group("/admin")
admin.Use(utils.RequireAuth(), utils.RequireAdmin())
{
	wineAdmin := admin.Group("/wine")
	{
		wineAdmin.GET("/:id/delete-impact", controllers.GetWineDeleteImpact)
		wineAdmin.DELETE("/:id", controllers.DeleteWine)
		wineAdmin.POST("/seed", controllers.SeedWines)
		wineAdmin.POST("/validate", controllers.ValidateWines)
	}
}
```

**Checklist:**
- [ ] Admin route group created
- [ ] `RequireAuth()` + `RequireAdmin()` middleware applied
- [ ] All 4 admin endpoints registered
- [ ] Variable name doesn't conflict (use `wineAdmin` not `wine`)

---

### **10. Test Backend** (~10 min)

```bash
# Reset database
go run scripts/reset_database.go

# Seed data
RUN_SEEDING=true \
  CHEESE_DATA_SOURCE=../alacarte-seed/cheeses.json \
  GIN_DATA_SOURCE=../alacarte-seed/gins.json \
  WINE_DATA_SOURCE=../alacarte-seed/wines.json \
  go run main.go

# Test API endpoints
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/wine/all
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/wine/1
```

**Checklist:**
- [ ] Migration creates wines table
- [ ] Seeding loads all wines
- [ ] GET /api/wine/all returns items
- [ ] GET /api/wine/:id returns single item
- [ ] POST /api/wine/new creates wine
- [ ] PUT /api/wine/:id updates wine
- [ ] DELETE /api/wine/:id deletes wine
- [ ] GET /admin/wine/:id/delete-impact requires admin auth
- [ ] GET /admin/wine/:id/delete-impact shows impact correctly
- [ ] DELETE /admin/wine/:id cascade deletes item
- [ ] POST /admin/wine/seed bulk imports successfully
- [ ] POST /admin/wine/validate validates JSON without importing

---

## ✅ Success Criteria

Backend is complete when:
- ✅ Model with GORM polymorphic ratings
- ✅ All 5 CRUD endpoints working
- ✅ All 4 admin endpoints working
- ✅ Auto-migration creates table
- ✅ Seeding loads data with natural key
- ✅ No duplicate entries on re-seeding
- ✅ API returns correct JSON format
- ✅ Public endpoints tested
- ✅ Admin endpoints require authentication
- ✅ Admin endpoints tested (impact, delete, seed, validate)

---

## 📚 Related Documentation

- **[Complete Backend Guide](adding-new-item-types.md)** - Detailed implementation
- **[Authentication System](authentication-system.md)** - JWT middleware
- **[Privacy Model](privacy-model.md)** - Sharing architecture

---

**Last Updated:** October 1, 2025  
**Status:** Current and accurate
