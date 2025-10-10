# Quick Reference: Adding a New Item Type (Frontend)

**Use this checklist when implementing a new item type frontend**

**Time Estimate:** ~50 minutes (with Strategy Pattern)  
**Last Updated:** October 2025

**⭐ What Works Automatically:** Rating system, Privacy settings, Item type filtering, Navigation, Offline support, Community stats

---

## 🎉 October 2025 Improvements

Thanks to recent refactorings, these features **require ZERO code** for new item types:

✅ **Rating System** - Create/edit/delete/share ratings (generic since Oct 2025)  
✅ **Privacy Settings** - Manage shared ratings and privacy (generic since Oct 2025)  
✅ **Search & Filtering** - Full search and category filtering (generic since Oct 2025)  
✅ **Item Type Filters** - Auto-populate in privacy settings  
✅ **Progressive Loading** - Missing items load automatically  
✅ **Navigation** - All routing works generically  
✅ **Community Stats** - Aggregate ratings work  

**You only implement the basics - advanced features work automatically!**

---

## 📋 Implementation Checklist

### **Prerequisites**
- [ ] Backend implementation complete (`/api/wine` endpoints)
- [ ] Backend running with seed data
- [ ] API endpoints tested and working

---

### **1. Create Model** (~10 min)
**File:** `lib/models/wine_item.dart`

- [ ] File created
- [ ] Implements `RateableItem` interface
- [ ] Has all required fields + item-specific fields
- [ ] JSON serialization matches backend format
- [ ] Extension methods for filtering created
- [ ] `getLocalizedDetailFields()` method included

**Template:** Copy `gin_item.dart`, replace gin-specific fields

---

### **2. Create Service** (~10 min)
**File:** `lib/services/item_service.dart` (add to end)

- [ ] Import added at top: `import '../models/wine_item.dart';`
- [ ] `WineItemService` class created
- [ ] Extends `ItemService<WineItem>`
- [ ] 5-minute caching implemented
- [ ] Validation method created
- [ ] Filter helper methods created (producers, origins, etc.)
- [ ] Service provider registered

**Template:** Copy `GinItemService` from same file

---

### **3. Register Provider** (~5 min)
**File:** `lib/providers/item_provider.dart`

- [ ] Import added: `import '../models/wine_item.dart';`
- [ ] Wine provider registered
- [ ] `WineItemProvider` class created
- [ ] `_loadFilterOptions()` implemented
- [ ] Filter methods added (setProducerFilter, etc.)
- [ ] Computed providers added (filteredWineItemsProvider, hasWineItemDataProvider)
- [ ] Cache clearing updated in `createItem()` method

**Template:** Copy gin provider from same file

---

### **4. Create Form Strategy** (~10 min) ⭐
**File:** `lib/forms/strategies/wine_form_strategy.dart`

- [ ] File created
- [ ] Implements `ItemFormStrategy<WineItem>`
- [ ] `getFormFields()` returns wine-specific fields
- [ ] `initializeControllers()` handles wine data
- [ ] `buildItem()` constructs WineItem from controllers
- [ ] `getProvider()` returns wineItemProvider
- [ ] `validate()` provides localized error messages
- [ ] All localization uses builder functions

**Template:** Copy `gin_form_strategy.dart`

---

### **5. Register Strategy** (~1 min)
**File:** `lib/forms/strategies/item_form_strategy_registry.dart`

- [ ] Import added: `import 'wine_form_strategy.dart';`
- [ ] Strategy registered in `_strategies` map

**One line to add:**
```dart
'wine': WineFormStrategy(),
```

---

### **6. Create Form Screens** (~2 min)
**File:** `lib/screens/wine/wine_form_screens.dart`

- [ ] Directory created: `lib/screens/wine/`
- [ ] File created: `wine_form_screens.dart`
- [ ] `WineCreateScreen` implemented
- [ ] `WineEditScreen` implemented
- [ ] All references updated (gin → wine)

**Template:** Copy `lib/screens/gin/gin_form_screens.dart`

---

### **7. Update Routes** (~2 min)

**File:** `lib/routes/route_names.dart`
- [ ] wineCreate and wineEdit added to RouteNames
- [ ] wineId added to RouteParams
- [ ] wineCreate and wineEdit paths added to RoutePaths

**File:** `lib/routes/app_router.dart`
- [ ] Import added: `import '../screens/wine/wine_form_screens.dart';`
- [ ] wineCreate route added
- [ ] wineEdit route added

---

### **8. Update Navigation** (~3 min)

**File:** `lib/screens/items/item_type_screen.dart`
- [ ] Wine case added to `_navigateToAddItem()`

**File:** `lib/screens/items/item_detail_screen.dart`
- [ ] Wine case added to `_navigateToEditItem()`

---

### **9. Update ItemProviderHelper** (~5 min)
**File:** `lib/utils/item_provider_helper.dart`

Add `case 'wine':` to **ALL 15 methods:**
- [ ] `getItems()`
- [ ] `getFilteredItems()`
- [ ] `isLoading()`
- [ ] `hasLoadedOnce()`
- [ ] `getErrorMessage()`
- [ ] `getSearchQuery()`
- [ ] `getActiveFilters()`
- [ ] `getFilterOptions()`
- [ ] `loadItems()`
- [ ] `refreshItems()`
- [ ] `clearFilters()`
- [ ] `clearTabSpecificFilters()`
- [ ] `updateSearchQuery()`
- [ ] `setCategoryFilter()`
- [ ] `getItemById()`

---

### **10. Update ItemTypeHelper** (~3 min)
**File:** `lib/models/rateable_item.dart`

- [ ] Wine icon added to `getItemTypeIcon()`
- [ ] Wine color added to `getItemTypeColor()`
- [ ] 'wine' added to `isItemTypeSupported()` list

---

### **11. Add to Home Screen** (~2 min)
**File:** `lib/screens/home/home_screen.dart`

- [ ] Wine state watcher added
- [ ] Wine data loading added
- [ ] Wine card added to grid
- [ ] Refresh handler updated with wine

---

### **12. Add Item Type Switcher** (~1 min)
**File:** `lib/screens/items/item_type_screen.dart`

- [ ] Wine option added to `_buildItemTypeSwitcher()` popup menu

---

### **13. Add Localization** (~5 min)

**Files:** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`

**English (app_en.arb):**
- [ ] wine, wines
- [ ] varietalLabel, vintageLabel
- [ ] enterWineName, enterVarietal, enterVintage
- [ ] varietalHint, vintageHelperText
- [ ] wineCreated, wineUpdated, wineDeleted
- [ ] createWine, editWine, addWine
- [ ] allWines, myWineList
- [ ] filterByVarietal, filterByVintage
- [ ] noWinesFound, loadingWines
- [ ] varietalRequired

**French (app_fr.arb):**
- [ ] All same keys with French translations

**Generate:**
- [ ] `flutter gen-l10n` executed
- [ ] No errors

**⚠️ CRITICAL: Update ItemTypeLocalizer**

**File:** `lib/utils/localization_utils.dart`

Add wine case to `getLocalizedItemType()` method:

```dart
switch (itemType.toLowerCase()) {
  case 'cheese':
    return l10n.cheese;
  case 'gin':
    return l10n.gin;
  case 'wine':  // ← ADD THIS!
    return l10n.wine;
  default:
    return itemType.isNotEmpty
        ? '${itemType[0].toUpperCase()}${itemType.substring(1)}'
        : itemType;
}
```

**Why this matters:**
- Without this, search hints show wrong item type
- Ensures proper localization in all languages
- Required for tab titles, buttons, and all UI text

- [ ] Wine case added to ItemTypeLocalizer.getLocalizedItemType()

---

## ✅ Testing Checklist (~10 min)

### **Backend Running:**
```bash
cd alacarte-api
RUN_SEEDING=true WINE_DATA_SOURCE=../alacarte-seed/wines.json go run main.go
```

### **Frontend Tests:**
- [ ] Home screen shows wine card with item count
- [ ] Click wine → navigates to `/items/wine`
- [ ] "All Wines" tab loads items
- [ ] "My Wine List" tab shows empty state
- [ ] Click wine → detail screen loads
- [ ] All fields display (name, producer, origin, varietal, vintage, description)
- [ ] Community stats display correctly
- [ ] Click "Rate Wine" FAB → rating form opens (✅ works automatically!)
- [ ] Create rating → saves successfully (✅ generic rating system)
- [ ] Rating appears in "My Wine List"
- [ ] Navigate to Privacy Settings → wine ratings appear (✅ works automatically!)
- [ ] Filter by item type → "Wine" filter appears (✅ works automatically!)
- [ ] Manage wine rating sharing → dialog works (✅ works automatically!)
- [ ] Click edit in wine detail → edit form loads with data
- [ ] Edit wine → saves successfully
- [ ] Click "Add Wine" FAB → create form opens
- [ ] Create new wine → wine appears in list
- [ ] Share wine rating → sharing dialog works
- [ ] Switch language FR ↔ EN → all strings translate
- [ ] Item type switcher shows wine in dropdown
- [ ] Switch cheese/gin/wine → all work correctly
- [ ] Pull-to-refresh works on all screens
- [ ] Offline mode works (shows cached data)

---

## 🎉 Success Criteria

Your new item type is complete when:

✅ **Full CRUD** - Create, read, update, delete operations work  
✅ **Rating Integration** - Can rate items and see ratings  
✅ **Sharing Works** - Can share ratings with other users  
✅ **Navigation** - All navigation flows work correctly  
✅ **Localization** - French and English translations complete  
✅ **Offline Support** - Works offline with cached data  
✅ **No Errors** - No console errors or warnings  
✅ **Type Safety** - No runtime type errors  

---

## ⏱️ Time Breakdown

- Model creation: 10 min
- Service creation: 10 min
- Provider registration: 5 min
- Form strategy: 10 min
- Strategy registration: 1 min
- Form screens: 2 min
- Routes: 2 min
- Navigation updates: 3 min
- Helper updates: 5 min
- Home screen: 2 min
- Item switcher: 1 min
- Localization: 5 min
- Testing: 10 min

**Total: ~66 minutes** (includes testing)

---

## 🐛 Common Issues

**"No form strategy registered for item type: wine"**
→ Did you add the strategy to the registry map?

**"The method 'varietalLabel' isn't defined for the type 'AppLocalizations'"**
→ Add missing keys to .arb files and run `flutter gen-l10n`

**"Provider not found"**
→ Check wine provider is registered in `item_provider.dart`

**Wine card doesn't appear on home screen**
→ Verify you added state watcher and _buildItemTypeCard call

**Edit/Create buttons don't work**
→ Check routes are registered and navigation methods updated

**Forms show wrong fields**
→ Verify field keys in strategy match your WineItem properties

**Search hints showing wrong item type (always shows "cheese" or capitalized type)**
→ Did you add the new item type case to `ItemTypeLocalizer.getLocalizedItemType()` in `localization_utils.dart`?

**Item type not properly localized in French**
→ Add the case to `ItemTypeLocalizer.getLocalizedItemType()` - without it, French users see English names

---

## 📚 Reference Files

**Copy these as templates:**
- Model: `lib/models/gin_item.dart`
- Service: Look for `GinItemService` in `lib/services/item_service.dart`
- Provider: Look for `ginItemProvider` in `lib/providers/item_provider.dart`
- Strategy: `lib/forms/strategies/gin_form_strategy.dart`
- Screens: `lib/screens/gin/gin_form_screens.dart`

---

## 🎓 Understanding the Pattern

**Why this works:**

1. **Strategy Pattern** - Form logic encapsulated per item type
2. **ItemProviderHelper** - Screens work generically via helper
3. **Generic Components** - Reusable widgets for common functionality
4. **Type Safety** - Generics ensure compile-time correctness

**The magic:**
- Generic screens have NO item-type conditionals
- Strategy defines fields, validation, data handling
- Helper provides type-specific data to generic screens
- Everything just works!

---

**Last Updated:** October 2025  
**Status:** ✅ Current (Post-Strategy Pattern Refactoring)
