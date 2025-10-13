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
    Name        string   `gorm:"not null" json:"name"`
    Producer    string   `json:"producer"`
    Country     string   `gorm:"not null" json:"country"`
    Region      string   `json:"region"`
    Color       string   `gorm:"not null" json:"color"`
    Grape       string   `json:"grape"`
    Alcohol     float64  `json:"alcohol"`
    Description string   `json:"description"`
    Designation string   `json:"designation"`
    Sugar       float64  `json:"sugar"`
    Organic     bool     `json:"organic" gorm:"default:false"`
    Ratings     []Rating `gorm:"polymorphic:Item;"`
}
```

**Checklist:**
- [ ] Create `models/[itemtype]Model.go`
- [ ] Fields match data source structure
- [ ] Required fields have `gorm:"not null"`
- [ ] Polymorphic ratings: `gorm:"polymorphic:Item;"`
- [ ] JSON tags lowercase
- [ ] Support for both required and optional fields

---

### **2. Create Controller** (~25 min)
**File:** `controllers/[itemtype]Controller.go`

**Implement 9 endpoints:**

**Public CRUD (5 endpoints):**
- `WineCreate` - POST with JSON binding
- `WineIndex` - GET all items
- `WineDetails` - GET single item by ID
- `WineEdit` - PUT with updates
- `WineRemove` - DELETE by ID

**Admin Endpoints (4 endpoints):**
- `GetWineDeleteImpact` - Show affected ratings/users before delete
- `DeleteWine` - Cascade delete with transactions
- `SeedWines` - Bulk import from URL or direct file upload (uses `utils.GetSeedData()`)
- `ValidateWines` - Validate JSON without importing (uses `utils.GetSeedData()`)

**Example (using generic helper):**
```go
func SeedWines(c *gin.Context) {
    // Use generic helper to get data from either URL or direct upload
    data, err := utils.GetSeedData(c)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // Parse wine-specific JSON structure
    var jsonData struct {
        Wines []models.Wine `json:"wines"`
    }
    if err := json.Unmarshal(data, &jsonData); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
        return
    }
    
    // Import wines with natural key logic
    result := utils.SeedResult{Errors: []string{}}
    
    for _, wineItem := range jsonData.Wines {
        // Natural key: name + color
        var existing models.Wine
        err := utils.DB.Where("name = ? AND color = ?", wineItem.Name, wineItem.Color).First(&existing).Error
        
        if err == nil {
            result.Skipped++
            continue
        }
        
        if err := utils.DB.Create(&wineItem).Error; err != nil {
            result.Errors = append(result.Errors, fmt.Sprintf("Failed to create %s: %v", wineItem.Name, err))
            continue
        }
        result.Added++
    }
    
    c.JSON(http.StatusOK, gin.H{
        "added":   result.Added,
        "skipped": result.Skipped,
        "errors":  result.Errors,
    })
}
```

**Checklist:**
- [ ] Create `controllers/[itemtype]Controller.go`
- [ ] Copy gin or cheese controller as template
- [ ] Implement all 5 public CRUD endpoints
- [ ] Implement all 4 admin endpoints
- [ ] Use `utils.GetSeedData()` for seed/validate (supports URL + file upload)
- [ ] Define natural key for duplicate detection
- [ ] Update struct binding fields to match model
- [ ] Update validation logic for required fields

---

### **3. Register Routes** (~8 min)
**File:** `main.go`

**Public routes:**
```go
wineItem := api.Group("/wine")
wineItem.Use(utils.RequireAuth())
{
    wineItem.POST("/new", controllers.WineCreate)
    wineItem.GET("/all", controllers.WineIndex)
    wineItem.GET("/:id", controllers.WineDetails)
    wineItem.PUT("/:id", controllers.WineEdit)
    wineItem.DELETE("/:id", controllers.WineRemove)
}
```

**Admin routes:**
```go
wineAdmin := admin.Group("/wine")
wineAdmin.Use(utils.RequireAuth(), utils.RequireAdmin())
{
    wineAdmin.GET("/:id/delete-impact", controllers.GetWineDeleteImpact)
    wineAdmin.DELETE("/:id", controllers.DeleteWine)
    wineAdmin.POST("/seed", controllers.SeedWines)
    wineAdmin.POST("/validate", controllers.ValidateWines)
}
```

**Checklist:**
- [ ] Public routes added to `/api` group
- [ ] Admin routes added to `/admin` group
- [ ] Authentication middleware applied
- [ ] All 5 CRUD endpoints registered
- [ ] All 4 admin endpoints registered

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

### **5. Seeding is Handled by Admin Panel** ✅

**No backend seeding code needed!** Seeding is done through the admin panel using:
- `POST /admin/wine/seed` - Accepts `{"url": "..."}` OR `{"data": {...}}`
- `POST /admin/wine/validate` - Validates before importing

The generic `utils.GetSeedData()` helper handles both URL and direct file upload automatically.

**Checklist:**
- [ ] ✅ Seed/Validate endpoints use `utils.GetSeedData()`
- [ ] ✅ No manual seeding code needed in utils/database.go

---

### **6. Skip Environment Config** ✅

No environment variables needed! Seeding is handled through the admin panel.

**Checklist:**
- [ ] ✅ No .env configuration required for seeding

---

### **7. Create Seed Data** (~varies)
**File:** `alacarte-seed/wines.json` (separate location)

```json
{
  "wines": [
    {
      "name": "Mas Bruguière L'Arbouse Pic Saint-Loup",
      "producer": "Mas Bruguière",
      "country": "France",
      "region": "Languedoc-Roussillon",
      "color": "Rouge",
      "grape": "Syrah 50%, Grenache 25%, Mourvèdre 25%",
      "alcohol": 13.5,
      "description": "Vin rouge biologique...",
      "designation": "Pic Saint-Loup AOC",
      "sugar": 2.0,
      "organic": true
    }
  ]
}
```

**Checklist:**
- [ ] JSON file created
- [ ] 10-30 items for initial launch
- [ ] All required fields populated (name, color, country)
- [ ] Optional fields included where available
- [ ] Data in appropriate language
- [ ] Natural key values unique (name + color)
- [ ] Data source documented

---

### **8. Removed - Admin endpoints now in step 2** ✅

---

### **9. Removed - Admin routes now in step 3** ✅

---

### **8. Test Backend** (~10 min)

```bash
# Start API
go run main.go

# Migration will create wines table automatically

# Test public endpoints (requires JWT token)
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/wine/all
curl -H "Authorization: Bearer $JWT_TOKEN" http://localhost:8080/api/wine/1

# Test admin endpoints (requires admin JWT token)
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/admin/wine/1/delete-impact

curl -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url":"http://example.com/wines.json"}' \
  http://localhost:8080/admin/wine/validate

# Test with direct file data
curl -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"wines":[{...}]}}' \
  http://localhost:8080/admin/wine/seed
```

**Checklist:**
- [ ] Migration creates wines table
- [ ] GET /api/wine/all returns empty array
- [ ] GET /api/wine/:id returns 404 for non-existent
- [ ] POST /api/wine/new creates wine
- [ ] PUT /api/wine/:id updates wine
- [ ] DELETE /api/wine/:id deletes wine
- [ ] GET /admin/wine/:id/delete-impact requires admin
- [ ] GET /admin/wine/:id/delete-impact shows impact
- [ ] DELETE /admin/wine/:id cascade deletes
- [ ] POST /admin/wine/seed works with URL
- [ ] POST /admin/wine/seed works with direct data
- [ ] POST /admin/wine/validate validates JSON

---

## ✅ Success Criteria

Backend is complete when:
- ✅ Model with GORM polymorphic ratings
- ✅ All 5 CRUD endpoints working
- ✅ All 4 admin endpoints working
- ✅ Auto-migration creates table
- ✅ Seed/validate endpoints support both URL and file upload
- ✅ Natural key prevents duplicates
- ✅ API returns correct JSON format
- ✅ Public endpoints require authentication
- ✅ Admin endpoints require admin authentication

---

## 📚 Related Documentation

- **[Complete Backend Guide](adding-new-item-types.md)** - Detailed implementation
- **[Authentication System](authentication-system.md)** - JWT middleware
- **[Privacy Model](privacy-model.md)** - Sharing architecture

---

**Last Updated:** January 2025  
**Status:** Current (includes file upload support)
