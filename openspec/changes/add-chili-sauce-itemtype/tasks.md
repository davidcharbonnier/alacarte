# Tasks: Add Chili Sauce Item Type

## Phase 1: Backend Implementation (~65 min)

### 1.1 Create Model
- [ ] Create `apps/api/models/chiliSauceModel.go`
- [ ] Define struct with fields: Name, Brand, SpiceLevel, Chilis, Description, ImageURL, Ratings
- [ ] Implement ItemWithImage interface (GetImageURL, SetImageURL)
- [ ] Add BeforeCreate hook for name+brand unique constraint

### 1.2 Create Controller
- [ ] Create `apps/api/controllers/chiliSauceController.go`
- [ ] Implement ChiliSauceCreate (POST with JSON binding)
- [ ] Implement ChiliSauceIndex (GET all)
- [ ] Implement ChiliSauceDetails (GET by ID)
- [ ] Implement ChiliSauceEdit (PUT with updates)
- [ ] Implement ChiliSauceRemove (DELETE by ID)
- [ ] Implement GetChiliSauceDeleteImpact (admin endpoint)
- [ ] Implement DeleteChiliSauce (admin endpoint with cascade)
- [ ] Implement SeedChiliSauces (admin endpoint)
- [ ] Implement ValidateChiliSauces (admin endpoint)

### 1.3 Register Routes
- [ ] Add public routes group `/api/chili-sauce` in `apps/api/main.go`
- [ ] Add image upload/delete routes with itemType parameter
- [ ] Add admin routes group `/admin/chili-sauce`
- [ ] Add authentication middleware to all routes
- [ ] Add admin middleware to admin routes

### 1.4 Add Migration
- [ ] Add `&models.ChiliSauce{}` to AutoMigrate in `apps/api/utils/database.go`

### 1.5 Update Item Helper
- [ ] Add compile-time interface check for ChiliSauce
- [ ] Add "chili-sauce" case to GetItemByType switch
- [ ] Add "chili-sauce" to ValidateItemType map

### 1.6 Add Seeding
- [ ] Create loadChiliSauceData() function
- [ ] Create seedChiliSauceData() with natural key matching (name+brand)
- [ ] Add chili sauce seeding call to RunSeeding()
- [ ] Add CHILI_SAUCE_DATA_SOURCE to .env

### 1.7 Test Backend
- [ ] Run database migration
- [ ] Test all public endpoints
- [ ] Test admin endpoints
- [ ] Test image upload/delete
- [ ] Verify seeding works

## Phase 2: Frontend Implementation (~50 min)

### 2.1 Create Model
- [ ] Create `apps/client/lib/models/chili_sauce_item.dart`
- [ ] Implement RateableItem interface
- [ ] Define fields: id, name, brand, spiceLevel, chilis, description, imageUrl
- [ ] Implement fromJson/toJson
- [ ] Define categories for filtering

### 2.2 Create Service
- [ ] Add ChiliSauceItemService to `apps/client/lib/services/item_service.dart`
- [ ] Implement singleton pattern with caching
- [ ] Add 5-minute cache expiry
- [ ] Implement clearCache() method
- [ ] Add validation function
- [ ] Create provider

### 2.3 Register Provider
- [ ] Add chiliSauceItemProvider to `apps/client/lib/providers/item_provider.dart`
- [ ] Implement ChiliSauceItemProvider class
- [ ] Implement _loadFilterOptions() for brand, spiceLevel, chilis

### 2.4 Create Form Strategy
- [ ] Create `apps/client/lib/forms/strategies/chili_sauce_form_strategy.dart`
- [ ] Define form fields: name (text), brand (text), spiceLevel (select), chilis (text), description (textarea)
- [ ] Implement getFormFields()
- [ ] Implement buildItem()
- [ ] Implement validate()

### 2.5 Register Strategy
- [ ] Add 'chili-sauce' case to ItemFormStrategyRegistry

### 2.6 Update Routes
- [ ] Add route constants to `apps/client/lib/routes/route_names.dart`
- [ ] Add routes to `apps/client/lib/routes/app_router.dart`

### 2.7 Update Navigation
- [ ] Add chili-sauce case to item_type_screen.dart
- [ ] Add chili-sauce case to item_detail_screen.dart

### 2.8 Update ItemProviderHelper
- [ ] Add 'chili-sauce' case to all 16 methods in item_provider_helper.dart

### 2.9 Update ItemTypeHelper
- [ ] Add chili-sauce icon and color
- [ ] Add chili-sauce to supported item types check

### 2.10 Update Home Screen
- [ ] Add chili-sauce card to home screen
- [ ] Display item count

### 2.11 Update Item Type Switcher
- [ ] Add "Chili Sauce" option to dropdown

### 2.12 Update Item List Images
- [ ] Add chili-sauce case to _buildItemCard() in item_type_screen.dart
- [ ] Add import for ChiliSauceItem model

### 2.13 Add Localization
- [ ] Add chili-sauce strings to `apps/client/lib/l10n/app_en.arb`
- [ ] Add chili-sauce strings to `apps/client/lib/l10n/app_fr.arb`
- [ ] Update ItemTypeLocalizer.getLocalizedItemType()
- [ ] Run `flutter gen-l10n`

### 2.14 Test Frontend
- [ ] Test chili-sauce card on home screen
- [ ] Test list view
- [ ] Test detail view
- [ ] Test create/edit forms
- [ ] Test rating creation (automatic)
- [ ] Test privacy settings (automatic)
- [ ] Test search and filtering

## Phase 3: Admin Panel Implementation (~5 min)

### 3.1 Add to Config
- [ ] Add chili-sauce config to `apps/admin/lib/config/item-types.ts`
- [ ] Define fields: name, brand, spice_level, chilis, description
- [ ] Configure table columns
- [ ] Configure searchable fields
- [ ] Configure API endpoints

### 3.2 Add Color to Design System
- [ ] Add chili-sauce color to `apps/admin/lib/config/design-system.ts`
- [ ] Choose distinctive color (e.g., #F44336 red)
- [ ] Define hex, rgb, hsl, className

### 3.3 Test Admin Panel
- [ ] Verify sidebar shows "Chili Sauces"
- [ ] Test list view
- [ ] Test detail view
- [ ] Test delete with impact assessment
- [ ] Test seed form
- [ ] Verify dashboard shows "Total Chili Sauces"

## Phase 4: Documentation

### 4.1 Update Guides
- [ ] Update "Current Item Types" in adding-new-item-types.md
- [ ] Add chili-sauce examples to guide

### 4.2 Verification
- [ ] Run `openspec validate add-chili-sauce-itemtype --strict`
- [ ] Fix any validation errors
- [ ] Ensure all tasks complete

## Total Estimated Time: ~2 hours
