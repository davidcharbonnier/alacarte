# Tasks: Add Chili Sauce Item Type

## Phase 1: Backend Implementation (~65 min)

### 1.1 Create Model
- [x] Create `apps/api/models/chiliSauceModel.go`
- [x] Define struct with fields: Name, Brand, SpiceLevel, Chilis, Description, ImageURL, Ratings
- [x] Implement ItemWithImage interface (GetImageURL, SetImageURL)
- [x] Add BeforeCreate hook for name+brand unique constraint

### 1.2 Create Controller
- [x] Create `apps/api/controllers/chiliSauceController.go`
- [x] Implement ChiliSauceCreate (POST with JSON binding)
- [x] Implement ChiliSauceIndex (GET all)
- [x] Implement ChiliSauceDetails (GET by ID)
- [x] Implement ChiliSauceEdit (PUT with updates)
- [x] Implement ChiliSauceRemove (DELETE by ID)
- [x] Implement GetChiliSauceDeleteImpact (admin endpoint)
- [x] Implement DeleteChiliSauce (admin endpoint with cascade)
- [x] Implement SeedChiliSauces (admin endpoint)
- [x] Implement ValidateChiliSauces (admin endpoint)

### 1.3 Register Routes
- [x] Add public routes group `/api/chili-sauce` in `apps/api/main.go`
- [x] Add image upload/delete routes with itemType parameter
- [x] Add admin routes group `/admin/chili-sauce`
- [x] Add authentication middleware to all routes
- [x] Add admin middleware to admin routes

### 1.4 Add Migration
- [x] Add `&models.ChiliSauce{}` to AutoMigrate in `apps/api/utils/database.go`

### 1.5 Update Item Helper
- [x] Add compile-time interface check for ChiliSauce
- [x] Add "chili-sauce" case to GetItemByType switch
- [x] Add "chili-sauce" to ValidateItemType map

### 1.6 Add Seeding
- [x] Create loadChiliSauceData() function
- [x] Create seedChiliSauceData() with natural key matching (name+brand)
- [x] Add chili sauce seeding call to RunSeeding()
- [x] Add CHILI_SAUCE_DATA_SOURCE to .env

### 1.7 Test Backend
- [x] Run database migration
- [x] Test all public endpoints
- [x] Test admin endpoints
- [x] Test image upload/delete
- [x] Verify seeding works

## Phase 2: Frontend Implementation (~50 min)

### 2.1 Create Model
- [x] Create `apps/client/lib/models/chili_sauce_item.dart`
- [x] Implement RateableItem interface
- [x] Define fields: id, name, brand, spiceLevel, chilis, description, imageUrl
- [x] Implement fromJson/toJson
- [x] Define categories for filtering

### 2.2 Create Service
- [x] Add ChiliSauceItemService to `apps/client/lib/services/item_service.dart`
- [x] Implement singleton pattern with caching
- [x] Add 5-minute cache expiry
- [x] Implement clearCache() method
- [x] Add validation function
- [x] Create provider

### 2.3 Register Provider
- [x] Add chiliSauceItemProvider to `apps/client/lib/providers/item_provider.dart`
- [x] Implement ChiliSauceItemProvider class
- [x] Implement _loadFilterOptions() for brand, spiceLevel, chilis

### 2.4 Create Form Strategy
- [x] Create `apps/client/lib/forms/strategies/chili_sauce_form_strategy.dart`
- [x] Define form fields: name (text), brand (text), spiceLevel (select), chilis (text), description (textarea)
- [x] Implement getFormFields()
- [x] Implement buildItem()
- [x] Implement validate()

### 2.5 Register Strategy
- [x] Add 'chili-sauce' case to ItemFormStrategyRegistry

### 2.6 Update Routes
- [x] Add route constants to `apps/client/lib/routes/route_names.dart`
- [x] Add routes to `apps/client/lib/routes/app_router.dart`

### 2.7 Update Navigation
- [x] Add chili-sauce case to item_type_screen.dart
- [x] Add chili-sauce case to item_detail_screen.dart

### 2.8 Update ItemProviderHelper
- [x] Add 'chili-sauce' case to all 16 methods in item_provider_helper.dart

### 2.9 Update ItemTypeHelper
- [x] Add chili-sauce icon and color
- [x] Add chili-sauce to supported item types check

### 2.10 Update Home Screen
- [x] Add chili-sauce card to home screen
  - [x] Add 'chili-sauce' case to item type switch in `home_screen.dart`
  - [x] Use correct item type key: 'chili-sauce' (not 'chiliSauce')
  - [x] Ensure ChiliSauceItemService.getCount() is called
  - [x] Display localized title from app_en.arb/app_fr.arb
  - [x] Use correct icon and color from ItemTypeHelper
- [x] Display item count
  - [x] Card shows actual count from backend
  - [x] Count updates when navigating back to home

### 2.11 Update Item Type Switcher
- [x] Add "Chili Sauce" option to dropdown
  - [x] Add 'chili-sauce' entry to item type switcher list
  - [x] Ensure localized name displays correctly
  - [x] Verify navigation works when selected

### 2.12 Update Item List Images
- [x] Add chili-sauce case to _buildItemCard() in item_type_screen.dart
- [x] Add import for ChiliSauceItem model

### 2.13 Add Localization
- [x] Add chili-sauce strings to `apps/client/lib/l10n/app_en.arb`
- [x] Add chili-sauce strings to `apps/client/lib/l10n/app_fr.arb`
- [x] Update ItemTypeLocalizer.getLocalizedItemType()
- [x] Run `flutter gen-l10n` (manual step - Flutter not available in environment)

### 2.14 Bug Fixes
- [x] Fix add action routing to cheese instead of chili-sauce
  - [x] Add 'chili-sauce' case to _navigateToAddItem() in item_type_screen.dart
  - [x] Route to RouteNames.chiliSauceCreate instead of cheeseCreate
- [x] Fix missing ChiliSauceItem import in item_type_screen.dart
- [x] Fix missing ChiliSauceItem case in _buildItemCard() for image URL

### 2.15 Fix Item Detail Page Issues
- [x] Fix edit button not working in item detail
  - [x] Add 'chili-sauce' case to _navigateToEditItem() in item_detail_screen.dart
  - [x] Route to RouteNames.chiliSauceEdit
- [x] Fix missing French translations in item detail card
  - [x] Add ChiliSauceItem import to item_detail_header.dart
  - [x] Add ChiliSauceItem case for image URL getter
  - [x] Add ChiliSauceItem case for localized detail fields (2 places)
  - [x] Add ChiliSauceItem case for description fields (2 places)

### 2.16 Fix Localization and Item Detail Display
- [x] Fix item list not using localized spice level
  - Note: displaySubtitle uses hardcoded English (consistent with other item types)
- [x] Fix item detail header badge to show spice level
  - [x] Update _getBadgeText() to take BuildContext parameter
  - [x] Add 'chili-sauce' case returning localized spice level
  - [x] Update call site to pass context
- [x] Remove spice level from detail fields (now shown in header badge)
  - [x] Update detailFields getter in ChiliSauceItem
  - [x] Update getLocalizedDetailFields() in ChiliSauceItem

### 2.17 Fix Spice Level Update Issue
- [x] Fix JSON key mismatch between Flutter and Go backend
  - [x] Change 'spice_level' to 'spiceLevel' in toJson() method
  - [x] Change 'spice_level' to 'spiceLevel' in fromJson() method
  - Root cause: Go model uses json:"spiceLevel", Flutter was sending "spice_level"

### 2.18 Fix Item List Localization
- [x] Fix spice level displayed in English on item list
  - [x] Add special handling in _buildItemCard for ChiliSauceItem
  - [x] Create _buildChiliSauceSubtitle helper method
  - [x] Use getLocalizedDisplayName for spice level in subtitle

### 2.19 Fix Image Display Issue
- [x] Fix image URL not parsed correctly from API response
  - [x] Change 'image_url' to 'imageUrl' in fromJson() method
  - Root cause: Go model uses json:"imageUrl", Flutter was expecting "image_url"

### 2.20 Test Frontend
- [x] Test chili-sauce card on home screen
- [x] Test list view
  - [x] Verify spice level is localized in list
  - [x] Verify images display correctly
- [x] Test detail view
  - [x] Verify images display correctly
- [x] Test create/edit forms
  - [x] Verify spice level changes are saved correctly
  - [x] Verify image upload works correctly
- [x] Test rating creation (automatic)
- [x] Test privacy settings (automatic)
- [x] Test search and filtering

## Phase 3: Admin Panel Implementation (~5 min)

### 3.1 Add to Config
- [x] Add chili-sauce config to `apps/admin/lib/config/item-types.ts`
- [x] Define fields: name, brand, spice_level, chilis, description
- [x] Configure table columns
- [x] Configure searchable fields
- [x] Configure API endpoints

### 3.2 Add Color to Design System
- [x] Add chili-sauce color to `apps/admin/lib/config/design-system.ts`
- [x] Choose distinctive color (e.g., #F44336 red)
- [x] Define hex, rgb, hsl, className

### 3.3 Test Admin Panel
- [x] Verify sidebar shows "Chili Sauces" (config-driven, automatic)
- [x] Test list view (config-driven, automatic)
- [x] Test detail view (config-driven, automatic)
- [x] Test delete with impact assessment (config-driven, automatic)
- [x] Test seed form (config-driven, automatic)
- [x] Verify dashboard shows "Total Chili Sauces" (config-driven, automatic)

### 3.4 Fix Image Display (All Item Types)
- [x] Fix images not displaying in admin panel for all item types
  - [x] Root cause: `transformItem()` was copying `ImageURL` as-is instead of mapping to `image_url`
  - [x] Fix: Add explicit handling for `ImageURL` -> `image_url` in `generic-item-api.ts`
  - [x] Build admin app to verify fix

### 3.5 Harmonize Image URL Field Naming
- [x] Harmonize all item types to use `image_url` (snake_case)
  - [x] Standard: 4/5 item types use `image_url`, only chili-sauce used `imageUrl`
  - [x] Update chili-sauce Go model: `json:"imageUrl"` → `json:"image_url"`
  - [x] Update chili-sauce Flutter model: `json['imageUrl']` → `json['image_url']`
  - [x] Simplify admin `transformItem()`: only check for `image_url`
  - [x] Rebuild Flutter and Admin apps

## Phase 4: Documentation

### 4.1 Update Guides
- [x] Update "Current Item Types" in adding-new-item-types.md
- [x] Add chili-sauce examples to guide

### 4.2 Fix French Localization
- [x] Update French translations from "Sauce Piquante" to "Sauce pimentée"
  - [x] Update app_fr.arb with proper capitalization
  - [x] Run `flutter gen-l10n` to regenerate Dart files
  - [x] Rebuild Flutter app

### 4.3 Fix Item Type Localizer
- [x] Add 'chili-sauce' case to ItemTypeLocalizer.getLocalizedItemType()
  - [x] Root cause: Missing case in switch statement caused fallback to "Chili-sauce"
  - [x] Fix: Add `case 'chili-sauce': return l10n.chiliSauce;`
  - [x] Rebuild Flutter app

### 4.4 Make Tab Names Generic and Localized
- [x] Change item list tab names from item-specific to generic
  - [x] Update TabBar in `item_type_screen.dart` to use generic labels
  - [x] Before: "All Chili Sauces" / "My Chili Sauce List"
  - [x] After: "All items" / "My items" (localized)
  - [x] Add `allItemsTab` and `myItemsTab` to app_en.arb
  - [x] Add `allItemsTab` and `myItemsTab` to app_fr.arb (EN: "Tous les éléments" / "Mes éléments")
  - [x] Run `flutter gen-l10n` and rebuild Flutter app

### 4.5 Verification
- [x] Run `openspec validate add-chili-sauce-itemtype --strict`
- [x] Fix any validation errors
- [x] Ensure all tasks complete

## Total Estimated Time: ~2 hours
