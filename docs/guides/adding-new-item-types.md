# Adding New Item Types - Complete Platform Guide

**Last Updated:** January 2025  
**Current Item Types:** Cheese, Gin, Wine, Coffee, Chili Sauce  
**Total Time:** ~2 hours (Backend: 65 min | Client: 50 min | Admin: 5 min)

This guide covers the complete process of adding a new item type (e.g., wine, beer, coffee) to the À la carte platform across all three applications.

---

## 🎯 Overview

### What You'll Build
- ✅ Backend API with full CRUD + admin endpoints
- ✅ Frontend with complete user interface and forms
- ✅ Admin panel with management capabilities
- ✅ Rating system integration (works automatically!)
- ✅ Privacy settings integration (works automatically!)
- ✅ Search and filtering
- ✅ Complete French/English localization

### Prerequisites
- Backend: Go 1.21+, MySQL running
- Frontend: Flutter 3.27+, Backend API running
- Admin: Node.js 18+, Backend API running
- Seed data prepared (JSON file with 10-30 items)

### Time Estimates
- **Backend (API):** ~65 minutes
- **Frontend (Client):** ~50 minutes  
- **Admin Panel:** ~5 minutes (config + color, navigation is automatic!)
- **Total:** ~2 hours

---

## 📋 Implementation Path

### Phase 1: Backend Implementation (~65 min)

> **See also:** Backend authentication and privacy implementations are documented in [/docs/api/authentication-system.md](/docs/api/authentication-system.md) and [/docs/api/privacy-model.md](/docs/api/privacy-model.md).

The backend uses GORM's polymorphic associations to support multiple item types with a single Rating table.

#### Step 1: Create Model (~5 min)

**File:** `apps/api/models/[itemType]Model.go`

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
    ImageURL    *string  `json:"image_url,omitempty"`  // Required for image support!
    Ratings     []Rating `gorm:"polymorphic:Item;"`  // Required!
}

// GetImageURL implements ItemWithImage interface
func (w *Wine) GetImageURL() *string {
    return w.ImageURL
}

// SetImageURL implements ItemWithImage interface
func (w *Wine) SetImageURL(url *string) {
    w.ImageURL = url
}
```

**Key points:**
- `gorm.Model` adds ID, timestamps, soft delete
- `gorm:"unique"` on Name prevents duplicates
- `gorm:"polymorphic:Item;"` enables rating system
- JSON tags lowercase match frontend expectations
- **ImageURL field required** for image upload support
- **Implement ItemWithImage interface** (GetImageURL/SetImageURL methods)

#### Step 2: Create Controller (~25 min)

**File:** `apps/api/controllers/[itemType]Controller.go`

**⚠️ Critical:** ALL body struct fields MUST have JSON tags matching the frontend's snake_case field names. Without JSON tags, fields won't bind correctly from the frontend payload.

```go
var body struct {
    Name     string `json:"name"`      // ← Must have json tags!
    Producer string `json:"producer"`  // ← Must match frontend exactly
    Organic  bool   `json:"organic"`   // ← Critical for booleans!
}
```

Implement 9 functions:
1. **Public CRUD** (5 functions, ~10 min):
   - `WineCreate` - POST with JSON binding (with json tags!)
   - `WineIndex` - GET all items
   - `WineDetails` - GET single item by ID
   - `WineEdit` - PUT with updates (with json tags!)
   - `WineRemove` - DELETE by ID

2. **Admin Endpoints** (4 functions, ~15 min):
   - `GetWineDeleteImpact` - Show affected ratings/users before delete
   - `DeleteWine` - Cascade delete with transactions
   - `SeedWines` - Bulk import from remote URL
   - `ValidateWines` - Validate JSON without importing

**Template:** Copy `coffeeController.go` (has correct JSON tags) and replace coffee fields with wine fields

#### Step 3: Register Routes (~8 min)

**File:** `apps/api/main.go`

Add two route groups:

```go
// Public routes
wineItem := api.Group("/wine")
wineItem.Use(utils.RequireAuth())
{
    wineItem.POST("/new", controllers.WineCreate)
    wineItem.GET("/all", controllers.WineIndex)
    wineItem.GET("/:id", controllers.WineDetails)
    wineItem.PUT("/:id", controllers.WineEdit)
    wineItem.DELETE("/:id", controllers.WineRemove)
    // Image management
    wineItem.POST("/:id/image", func(c *gin.Context) {
        c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "wine"})
        controllers.UploadItemImage(c)
    })
    wineItem.DELETE("/:id/image", func(c *gin.Context) {
        c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "wine"})
        controllers.DeleteItemImage(c)
    })
}

// Admin routes
wineAdmin := admin.Group("/wine")
wineAdmin.Use(utils.RequireAuth(), utils.RequireAdmin())
{
    wineAdmin.GET("/:id/delete-impact", controllers.GetWineDeleteImpact)
    wineAdmin.DELETE("/:id", controllers.DeleteWine)
    wineAdmin.POST("/seed", controllers.SeedWines)
    wineAdmin.POST("/validate", controllers.ValidateWines)
}
```

#### Step 4: Add Migration (~2 min)

**File:** `apps/api/utils/database.go`

```go
func RunMigrations() {
    err := DB.AutoMigrate(
        &models.User{},
        &models.Cheese{},
        &models.Gin{},
        &models.Wine{},  // ADD THIS
        &models.Rating{},
    )
}
```

#### Step 5: Update Item Helper (~3 min)

**File:** `apps/api/utils/item_helper.go`

Add wine support in three places:

```go
// 1. Add compile-time interface check
var (
    _ ItemWithImage = (*models.Cheese)(nil)
    _ ItemWithImage = (*models.Gin)(nil)
    _ ItemWithImage = (*models.Wine)(nil)  // ADD THIS
)

// 2. Add case to GetItemByType
func GetItemByType(itemType string, itemID string) (ItemWithImage, error) {
    var model interface{}
    
    switch itemType {
    case "cheese":
        model = &models.Cheese{}
    case "gin":
        model = &models.Gin{}
    case "wine":  // ADD THIS
        model = &models.Wine{}
    default:
        return nil, fmt.Errorf("invalid item type: %s", itemType)
    }
    // ... rest of function
}

// 3. Add to ValidateItemType
func ValidateItemType(itemType string) bool {
    validTypes := map[string]bool{
        "cheese": true,
        "gin":    true,
        "wine":   true,  // ADD THIS
    }
    return validTypes[itemType]
}
```

**Why this matters:**
- Enables generic image upload/delete endpoints
- Type validation for image operations
- Compile-time safety ensures interface compliance

#### Step 6: Add Seeding (~15 min)

**File:** `apps/api/utils/database.go`

Add three functions:
1. Update `RunSeeding()` to call wine seeding
2. Create `seedWineData()` with natural key matching (name + origin)
3. Create `loadWineData()` to fetch JSON from URL or file

**Natural key strategy:**
```go
result := DB.Where("name = ? AND origin = ?", wine.Name, wine.Origin).First(&existing)
if result.Error == gorm.ErrRecordNotFound {
    DB.Create(&wine)  // Only add if doesn't exist
}
```

#### Step 7: Configure Environment (~2 min)

**File:** `apps/api/.env`

```bash
WINE_DATA_SOURCE=../alacarte-seed/wines.json
RUN_SEEDING=true
```

#### Step 8: Test Backend (~8 min)

```bash
# Reset and seed
go run scripts/reset_database.go
RUN_SEEDING=true go run main.go

# Test endpoints
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/wine/all
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/admin/wine/1/delete-impact

# Test image upload
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -F "image=@wine.jpg" \
  http://localhost:8080/api/wine/1/image
```

**✅ Backend Complete!** See [Backend Checklist](backend-checklist.md) for detailed steps.

---

### Phase 2: Frontend Implementation (~50 min)

The frontend uses a **Strategy Pattern** for forms and **generic architecture** for most features.

#### What Works Automatically

Thanks to October 2025 refactorings:
- ✅ Rating system (create, edit, delete, share)
- ✅ Privacy settings (manage shared ratings)
- ✅ Search & filtering (all item types)
- ✅ Navigation and routing
- ✅ Offline support
- ✅ Community statistics

**You only implement:** Model, Service, Provider, Form Strategy, Helpers, Localization

#### Step 1: Create Model (~10 min)

**File:** `apps/client/lib/models/wine_item.dart`

**⚠️ Important:** Do NOT add extension methods like `getUniqueProducers()`, `getUniqueOrigins()`, etc. These are deprecated and unused. See [Filtering System Documentation](/docs/features/filtering-system.md#deprecated-pattern---do-not-use) for details.

```dart
class WineItem implements RateableItem {
  final int? id;
  final String name;
  final String producer;
  final String origin;
  final String varietal;  // Wine-specific
  final String? description;

  @override
  String get itemType => 'wine';

  @override
  String get displayTitle => '$name ($varietal)';

  @override
  Map<String, String> get categories => {
    'producer': producer,
    'origin': origin,
    'varietal': varietal,
  };

  // JSON serialization, etc.
}
```

#### Step 2: Create Service (~10 min)

**File:** `apps/client/lib/services/item_service.dart` (add to end)

**⚠️ Important:** Do NOT add filter option methods like `getWineProducers()`, `getWineOrigins()`, etc. These are deprecated. Filter options are automatically generated from items in the provider state. See [Filtering System Documentation](/docs/features/filtering-system.md#deprecated-pattern---do-not-use) for details.

```dart
class WineItemService extends ItemService<WineItem> {
  // Singleton pattern to preserve cache
  static final WineItemService _instance = WineItemService._internal();
  
  factory WineItemService() => _instance;
  
  WineItemService._internal();
  
  // Cache for 5-minute expiry
  ApiResponse<List<WineItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  @override
  String get itemTypeEndpoint => '/api/wine';

  @override
  WineItem Function(dynamic) get fromJson =>
      (dynamic json) => WineItem.fromJson(json as Map<String, dynamic>);

  @override
  List<String> Function(WineItem) get validateItem => _validateWineItem;
  
  @override
  Future<ApiResponse<List<WineItem>>> getAllItems() async {
    // Check cache
    if (_cachedResponse != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheExpiry) {
        return _cachedResponse!;
      }
    }
    
    // Fetch and cache
    final response = await handleListResponse<WineItem>(
      get('$itemTypeEndpoint/all'),
      fromJson,
    );
    
    if (response is ApiSuccess<List<WineItem>>) {
      _cachedResponse = response;
      _cacheTime = DateTime.now();
    }
    
    return response;
  }
  
  void clearCache() {
    _cachedResponse = null;
    _cacheTime = null;
  }

  static List<String> _validateWineItem(WineItem wine) {
    final errors = <String>[];
    if (wine.name.trim().isEmpty) errors.add('Name is required');
    if (wine.varietal.trim().isEmpty) errors.add('Varietal is required');
    if (wine.producer.trim().isEmpty) errors.add('Producer is required');
    if (wine.origin.trim().isEmpty) errors.add('Origin is required');
    return errors;
  }
}

final wineItemServiceProvider = Provider<WineItemService>(
  (ref) => WineItemService(), // Factory returns singleton
);
```

**Key points:**
- Singleton pattern ensures cache persists across navigation
- Factory constructor returns the same instance
- 5-minute cache with automatic expiry
- `clearCache()` method for cache invalidation

#### Step 3: Register Provider (~5 min)

**File:** `apps/client/lib/providers/item_provider.dart` (add to end)

```dart
final wineItemProvider = StateNotifierProvider<WineItemProvider, ItemState<WineItem>>(
  (ref) => WineItemProvider(ref.read(wineItemServiceProvider)),
);

class WineItemProvider extends ItemProvider<WineItem> {
  // Implement filter options and filter methods
  @override
  Future<void> _loadFilterOptions() async {
    // Extract unique producers, origins, varietals
  }
}
```

#### Step 4: Create Form Strategy (~10 min) ⭐

**File:** `apps/client/lib/forms/strategies/wine_form_strategy.dart`

```dart
class WineFormStrategy extends ItemFormStrategy<WineItem> {
  @override
  List<FormFieldConfig> getFormFields() {
    return [
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'varietal',
        labelBuilder: (context) => context.l10n.varietalLabel,
        required: true,
      ),
      // ... producer, origin, description
    ];
  }

  @override
  WineItem buildItem(controllers, itemId) {
    return WineItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      varietal: controllers['varietal']!.text.trim(),
      // ...
    );
  }
}
```

**Template:** Copy `gin_form_strategy.dart`

#### Step 5: Register Strategy (~1 min)

**File:** `apps/client/lib/forms/strategies/item_form_strategy_registry.dart`

```dart
static final Map<String, ItemFormStrategy> _strategies = {
  'cheese': CheeseFormStrategy(),
  'gin': GinFormStrategy(),
  'wine': WineFormStrategy(),  // ← ADD THIS LINE
};
```

#### Step 6-11: Standard Updates (~16 min)

- **Routes:** Add wineCreate, wineEdit to route_names.dart and app_router.dart
- **Navigation:** Add wine cases to item_type_screen.dart and item_detail_screen.dart
- **ItemProviderHelper:** Add 'wine' case to all 16 methods
- **ItemTypeHelper:** Add wine icon, color, and supported check
- **Home Screen:** Add wine card with item count
- **Item Type Switcher:** Add wine option to dropdown
- **Item List Images:** Add wine case to `_buildItemCard()` in item_type_screen.dart:
  ```dart
  // Add import at top
  import '../../models/wine_item.dart';
  
  // In _buildItemCard method:
  String? imageUrl;
  if (item is CheeseItem) {
    imageUrl = item.imageUrl;
  } else if (item is GinItem) {
    imageUrl = item.imageUrl;
  } else if (item is WineItem) {  // ← ADD THIS
    imageUrl = item.imageUrl;
  }
  ```

#### Step 12: Add Localization (~5 min) ⚠️

**Files:** `apps/client/lib/l10n/app_en.arb` and `app_fr.arb`

Add wine-specific strings:
```json
{
  "wine": "Wine",
  "wines": "Wines",
  "varietalLabel": "Varietal",
  "enterWineName": "Enter wine name",
  "wineCreated": "Wine created!",
  // ... ~20 more strings
}
```

**⚠️ CRITICAL:** Update `ItemTypeLocalizer.getLocalizedItemType()`:

**File:** `apps/client/lib/utils/localization_utils.dart`

```dart
switch (itemType.toLowerCase()) {
  case 'cheese': return l10n.cheese;
  case 'gin': return l10n.gin;
  case 'wine': return l10n.wine;  // ← MUST ADD THIS
  default: return itemType;
}
```

Run: `flutter gen-l10n`

#### Step 13: Test Frontend (~3 min)

```bash
flutter run -d linux

# Test:
# - Wine card appears on home screen
# - Click wine → list loads
# - Click item → detail shows
# - Rate wine → form works (automatic!)
# - Share rating → dialog works (automatic!)
# - Privacy settings → wine ratings appear (automatic!)
```

**✅ Frontend Complete!** See [Client Checklist](client-checklist.md) for detailed steps.

---

### Phase 3: Admin Panel Implementation (~5 min)

The admin panel uses a **config-driven architecture** where everything works automatically from a single config entry plus a color definition. The sidebar navigation is now dynamic and updates automatically!

#### Step 1: Add to Config (~3 min)

**File:** `apps/admin/lib/config/item-types.ts`

```typescript
wine: {
  name: 'wine',
  labels: { singular: 'Wine', plural: 'Wines' },
  icon: 'Wine',
  color: itemTypeColors.wine.hex,  // ← ADD THIS (from design-system.ts)
  
  fields: [
    { key: 'name', label: 'Name', type: 'text', required: true },
    { key: 'varietal', label: 'Varietal', type: 'text', required: true },
    { key: 'producer', label: 'Producer', type: 'text', required: true },
    { key: 'origin', label: 'Origin', type: 'text', required: true },
    { key: 'description', label: 'Description', type: 'textarea' },
  ],
  
  table: {
    columns: ['name', 'varietal', 'producer', 'origin'],
    searchableFields: ['name', 'varietal', 'origin'],
  },
  
  apiEndpoints: {
    list: '/api/wine/all',
    detail: (id) => `/api/wine/${id}`,
    deleteImpact: (id) => `/admin/wine/${id}/delete-impact`,
    delete: (id) => `/admin/wine/${id}`,
    seed: '/admin/wine/seed',
    validate: '/admin/wine/validate',
  },
}
```

#### Step 2: Add Color to Design System (~2 min)

**File:** `apps/admin/lib/config/design-system.ts`

Add the new color to the `itemTypeColors` object:

```typescript
export const itemTypeColors = {
  cheese: {
    hex: '#673AB7',
    rgb: 'rgb(103, 58, 183)',
    hsl: 'hsl(262, 52%, 47%)',
    className: 'text-[#673AB7] bg-[#673AB7]/10',
  },
  gin: {
    hex: '#009688',
    rgb: 'rgb(0, 150, 136)',
    hsl: 'hsl(174, 100%, 29%)',
    className: 'text-[#009688] bg-[#009688]/10',
  },
  wine: {
    hex: '#8E24AA',
    rgb: 'rgb(142, 36, 170)',
    hsl: 'hsl(288, 65%, 40%)',
    className: 'text-[#8E24AA] bg-[#8E24AA]/10',
  },
  beer: {  // ← ADD YOUR NEW ITEM TYPE
    hex: '#FFA726',        // Choose a color that doesn't conflict
    rgb: 'rgb(255, 167, 38)',
    hsl: 'hsl(36, 100%, 57%)',
    className: 'text-[#FFA726] bg-[#FFA726]/10',
  },
} as const;
```

**Color Selection Tips:**
- Choose colors that stand out from existing ones
- Ensure good contrast for accessibility
- Test in both light and dark modes
- Common choices: Orange (#FFA726), Blue (#2196F3), Red (#F44336), Amber (#FFC107)

#### Step 3: ~~Update Navigation~~ **Automatic!** 🎉

**No action needed!** The sidebar now dynamically loads item types from your config.

Your new item type will automatically appear in the sidebar with:
- Correct icon and color
- Proper routing
- Active states
- Hover effects

**✅ Admin Complete!** All features work automatically:
- List view with table
- Detail view
- Delete with impact assessment
- Bulk seed import
- Dashboard stats card
- **Sidebar navigation** (automatic!)

See [Admin Checklist](admin-checklist.md) for details.

---

## ✅ Verification Checklist

### Backend
- [ ] Model created with polymorphic ratings
- [ ] Model implements ItemWithImage interface (GetImageURL/SetImageURL)
- [ ] All 9 endpoints working (5 public + 4 admin)
- [ ] Image upload/delete endpoints working
- [ ] Item helper updated (compile check, GetItemByType, ValidateItemType)
- [ ] Migration creates table on startup
- [ ] Seeding loads data with natural key matching
- [ ] Admin endpoints require authentication

### Frontend
- [ ] Model implements RateableItem interface
- [ ] Service with 5-minute caching
- [ ] Provider registered in item_provider.dart
- [ ] Form strategy registered in registry
- [ ] ItemProviderHelper updated (15 methods)
- [ ] ItemTypeHelper updated (icon, color, support)
- [ ] ItemTypeLocalizer updated (localization)
- [ ] Home screen shows item card
- [ ] Rating system works (automatic!)
- [ ] Privacy settings work (automatic!)
- [ ] Localization complete (FR/EN)

### Admin Panel
- [ ] Config entry added to item-types.ts
- [ ] Color added to design-system.ts
- [ ] ~~Navigation updated in sidebar~~ (automatic!)
- [ ] List view works at /wine
- [ ] Detail view works
- [ ] Delete impact works
- [ ] Seed form works
- [ ] Dashboard shows "Total Wines" card

---

## 🎯 What Works Automatically

Thanks to the generic architecture and October 2025 refactorings:

### Frontend
- ✅ Rating CRUD (create, edit, delete, share)
- ✅ Privacy settings (manage shared ratings, bulk actions)
- ✅ Search & filtering (by all categories)
- ✅ Item type filtering in privacy settings
- ✅ Progressive item loading
- ✅ Navigation (all routing)
- ✅ Offline support
- ✅ Community statistics
- ✅ Theme support (light/dark)

### Admin Panel
- ✅ List view with table
- ✅ Detail view with all fields
- ✅ Delete impact assessment
- ✅ Bulk seed import
- ✅ JSON validation
- ✅ Dashboard stat cards
- ✅ Search and filtering
- ✅ Loading states
- ✅ Error handling

---

## 📚 Quick Reference

### Checklists
- [Backend Checklist](backend-checklist.md) - Detailed backend steps
- [Client Checklist](client-checklist.md) - Detailed frontend steps
- [Admin Checklist](admin-checklist.md) - Detailed admin steps

### Chili Sauce Example (Enum Fields)

For item types with enum/select fields like **Spice Level**, follow this pattern:

**Backend Model:**
```go
type ChiliSauce struct {
    gorm.Model
    Name        string   `gorm:"uniqueIndex:idx_chili_name_brand" json:"name"`
    Brand       string   `gorm:"uniqueIndex:idx_chili_name_brand" json:"brand"`
    SpiceLevel  string   `gorm:"not null" json:"spice_level"`  // Mild, Medium, Hot, Extra Hot, Extreme
    Chilis      string   `json:"chilis"`  // e.g., "Habanero, Ghost Pepper"
    Description string   `json:"description"`
    ImageURL    *string  `json:"image_url,omitempty"`
    Ratings     []Rating `gorm:"polymorphic:Item;"`
}
```

**Frontend Form Strategy (Select Field):**
```dart
FormFieldConfig.select(
  key: 'spice_level',
  labelBuilder: (context) => context.l10n.spiceLevelLabel,
  required: true,
  options: [
    SelectOption(value: 'Mild', labelBuilder: (context) => context.l10n.spiceLevelMild),
    SelectOption(value: 'Medium', labelBuilder: (context) => context.l10n.spiceLevelMedium),
    SelectOption(value: 'Hot', labelBuilder: (context) => context.l10n.spiceLevelHot),
    SelectOption(value: 'Extra Hot', labelBuilder: (context) => context.l10n.spiceLevelExtraHot),
    SelectOption(value: 'Extreme', labelBuilder: (context) => context.l10n.spiceLevelExtreme),
  ],
),
```

**Key Points:**
- Use `FormFieldConfig.select()` for enum fields
- Provide localized labels for each option
- Store the value (e.g., "Hot") not the label
- Add validation in the strategy's `validate()` method

### Related Documentation
- [Form Strategy Pattern](/docs/client/architecture/form-strategy-pattern.md) - Strategy Pattern explained
- [Rating System](/docs/features/rating-system.md) - How ratings work
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [Filtering System](/docs/features/filtering-system.md) - Search and filtering

---

## 💡 Pro Tips

1. **Work sequentially:** Backend → Frontend → Admin
2. **Test incrementally:** Don't wait until everything is done
3. **Copy templates:** Use gin files as templates (most recent)
4. **Natural keys:** Always use name + origin for seeding
5. **Localization:** Run `flutter gen-l10n` after adding .arb strings
6. **Strategy pattern:** All form logic in one place (wine_form_strategy.dart)
7. **Cache clearing:** Clear wine cache in `createItem()`, `updateItem()`, and `deleteItem()` using `clearCache()`
8. **Singleton services:** Use factory constructors that return singleton instances for caching

---

## 🐛 Common Issues

**Backend:**
- "Duplicate entry" → Normal, seeding skips existing items
- "404 on /api/wine/all" → Check routes registered, restart API

**Frontend:**
- "No form strategy registered" → Add to item_form_strategy_registry.dart
- "Method 'wine' isn't defined" → Add wine to app_en.arb/app_fr.arb + run gen-l10n
- "Search hints showing wrong type" → Update ItemTypeLocalizer.getLocalizedItemType()
- "Images not displaying in item list" → Add wine case to _buildItemCard() in item_type_screen.dart with import
- "Routes not working / 404 errors" → Check RouteNames constants have leading slash (e.g., '/wine/create' not 'wineCreate')

**Admin:**
- Config not loading → Check syntax in item-types.ts
- Routes 404 → Backend endpoints must exist first

---

**Total implementation time: ~2 hours | Maintainable, scalable, production-ready** 🚀
