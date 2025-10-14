# Quick Reference: Adding a New Item Type (Frontend)

**Use this checklist when implementing a new item type frontend**

**Time Estimate:** ~71 minutes (with Strategy Pattern)  
**Last Updated:** January 2025

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

## 📋 Complete Implementation Checklist

### **Prerequisites**
- [ ] Backend implementation complete (`/api/wine` endpoints)
- [ ] Backend running with seed data
- [ ] API endpoints tested and working

---

### **1. Create Model** (~15 min)
**File:** `lib/models/wine_item.dart`

- [ ] File created
- [ ] **Import added:** `import '../utils/localization_utils.dart';`
- [ ] Implements `RateableItem` interface with ALL required getters:
  - [ ] `itemType` → returns 'wine'
  - [ ] `displayTitle` → returns name
  - [ ] `displaySubtitle` → formatted subtitle (e.g., "Color • Producer • Country")
  - [ ] `isNew` → returns `id == null`
  - [ ] `searchableText` → combines all searchable fields
  - [ ] `categories` → returns filterable categories map
  - [ ] `detailFields` → **EXCLUDE name field** (already shown in title)
- [ ] ⚠️ **JSON mapping uses 'ID' (uppercase):**
  ```dart
  factory WineItem.fromJson(Map<String, dynamic> json) {
    return WineItem(
      id: json['ID'] as int?,  // ← Must be uppercase!
      name: json['name'] as String? ?? '',
      // ... other fields lowercase
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ID': id,  // ← Must be uppercase!
      'name': name,
      // ... other fields lowercase
    };
  }
  ```
- [ ] **getLocalizedDetailFields() method created:**
  ```dart
  List<DetailField> getLocalizedDetailFields(BuildContext context) {
    return [
      DetailField(
        label: context.l10n.colorLabel,  // ← Localized!
        value: color,
        icon: Icons.palette,
      ),
      // ... all other fields with context.l10n labels
    ];
  }
  ```
- [ ] Extension methods for filtering created (getUniqueColors, etc.)
- [ ] `copyWith()` accepts `Map<String, dynamic>` parameter (required by interface)

**Template:** Copy `gin_item.dart`

**⚠️ Critical:**
- GORM backend sends 'ID' (uppercase), not 'id'
- Exclude name from detailFields (duplicate with title)
- Must have getLocalizedDetailFields() method

---

### **2. Create Service** (~12 min)
**File:** `lib/services/item_service.dart` (add to end of file)

- [ ] **Import added at TOP of file:** `import '../models/wine_item.dart';`
- [ ] `WineItemService` class created
- [ ] Extends `ItemService<WineItem>`
- [ ] Singleton pattern with factory constructor
- [ ] 5-minute caching with expiry check
- [ ] `getAllItems()` override with cache logic
- [ ] `clearCache()` method
- [ ] Static validation method: `_validateWineItem()`
- [ ] Filter helper methods created:
  - [ ] `getWineColors()`
  - [ ] `getWineCountries()`
  - [ ] `getWineRegions()` (or appropriate for your item)
- [ ] Service provider registered at end

**Template:** Copy `GinItemService` from same file

**⚠️ Don't forget the import at the very top of the file!**

---

### **3. Register Provider** (~7 min)
**File:** `lib/providers/item_provider.dart`

- [ ] **Import added at TOP of file:** `import '../models/wine_item.dart';`
- [ ] `wineItemProvider` StateNotifierProvider created
- [ ] `WineItemProvider` class created extending `ItemProvider<WineItem>`
- [ ] `_loadFilterOptions()` implemented with wine-specific filters
- [ ] Filter methods added (setColorFilter, setCountryFilter, setRegionFilter, setProducerFilter)
- [ ] Computed providers added at end:
  - [ ] `filteredWineItemsProvider`
  - [ ] `hasWineItemDataProvider`
- [ ] **Cache clearing updated in createItem() method:**
  ```dart
  } else if (_itemService is WineItemService) {
    (_itemService as WineItemService).clearCache();
  }
  ```

**Template:** Copy gin provider sections from same file

**⚠️ Critical:**
- Import at top of file
- Update cache clearing in existing createItem() method

---

### **4. Create Form Strategy** (~10 min) ⭐
**File:** `lib/forms/strategies/wine_form_strategy.dart`

- [ ] File created
- [ ] Implements `ItemFormStrategy<WineItem>`
- [ ] `getFormFields()` returns wine-specific field configs
  - Use `FormFieldConfig.text()` for text fields
  - Use `FormFieldConfig.multiline()` for description
  - Use `FormFieldConfig.dropdown()` for enums/fixed values
  - Use `FormFieldConfig.checkbox()` for boolean fields
- [ ] `initializeControllers()` handles all wine fields including numbers and enums
- [ ] `buildItem()` constructs WineItem:
  - Use `double.tryParse()` for numbers
  - Use `WineColor.fromString()` for enum parsing
  - Use `controller.text == 'true'` for booleans
- [ ] `getProvider()` returns wineItemProvider
- [ ] `validate()` provides localized error messages
- [ ] All localization uses builder functions: `(context) => context.l10n.label`

**Template:** Copy `gin_form_strategy.dart`

**Field Types Available:**
```dart
// Text input
FormFieldConfig.text(
  key: 'name',
  labelBuilder: (context) => context.l10n.name,
  hintBuilder: (context) => context.l10n.enterWineName,
  icon: Icons.label,
  required: true,
)

// Dropdown (for enums)
FormFieldConfig.dropdown(
  key: 'color',
  labelBuilder: (context) => context.l10n.colorLabel,
  hintBuilder: (context) => context.l10n.selectColor,
  options: [
    DropdownOption(value: 'Rouge', labelBuilder: (_) => 'Rouge'),
    DropdownOption(value: 'Blanc', labelBuilder: (_) => 'Blanc'),
  ],
  icon: Icons.palette,
  required: true,
)

// Checkbox (for booleans)
FormFieldConfig.checkbox(
  key: 'organic',
  labelBuilder: (context) => context.l10n.organicLabel,
  helperTextBuilder: (context) => context.l10n.organicHelper,
)

// Multiline text
FormFieldConfig.multiline(
  key: 'description',
  labelBuilder: (context) => context.l10n.description,
  hintBuilder: (context) => context.l10n.enterDescription,
  maxLines: 3,
  maxLength: 1000,
)
```

**⚠️ Important:**
- Dropdown options can be localized or static (use `labelBuilder: (_) => 'Static'` for data values)
- Checkbox stores 'true'/'false' as string in controller
- Boolean display shows localized Yes/No with subtle icons automatically

---

### **5. Register Strategy** (~1 min)
**File:** `lib/forms/strategies/item_form_strategy_registry.dart`

- [ ] **Import added:** `import 'wine_form_strategy.dart';`
- [ ] Strategy registered in `_strategies` map:
  ```dart
  static final Map<String, ItemFormStrategy> _strategies = {
    'cheese': CheeseFormStrategy(),
    'gin': GinFormStrategy(),
    'wine': WineFormStrategy(),  // ← ADD THIS
  };
  ```

---

### **6. Create Form Screens** (~3 min)
**File:** `lib/screens/wine/wine_form_screens.dart`

- [ ] Directory created: `lib/screens/wine/`
- [ ] File created with proper imports
- [ ] `WineCreateScreen` implemented (ConsumerWidget, no parameters)
- [ ] `WineEditScreen` implemented (ConsumerStatefulWidget with wineId)
- [ ] Edit screen loads wine from cache or API
- [ ] Edit screen handles loading/error states
- [ ] Uses `GenericItemFormScreen<WineItem>` correctly

**Template:** Copy `lib/screens/gin/gin_form_screens.dart` exactly

**⚠️ Important:**
- CreateScreen: no itemId, no initialItem parameters
- EditScreen: loads item first, then passes to GenericItemFormScreen

---

### **7. Update Routes** (~3 min)

**File:** `lib/routes/route_names.dart`
- [ ] `wineCreate` and `wineEdit` added to RouteNames class
- [ ] `wineId` added to RouteParams class
- [ ] `wineCreate` and `wineEdit` paths added to RoutePaths class

**File:** `lib/routes/app_router.dart`
- [ ] **Import added:** `import '../screens/wine/wine_form_screens.dart';`
- [ ] `wineCreate` route added with path and builder
- [ ] `wineEdit` route added with path, parameter parsing, and builder

---

### **8. Update Navigation** (~3 min)

**File:** `lib/screens/items/item_type_screen.dart`
- [ ] Wine case added to `_navigateToAddItem()` method

**File:** `lib/screens/items/item_detail_screen.dart`
- [ ] Wine case added to `_navigateToEditItem()` method

---

### **9. Update ItemProviderHelper** (~5 min)
**File:** `lib/utils/item_provider_helper.dart`

- [ ] **Import added at TOP:** `import '../models/wine_item.dart';`

Add `case 'wine':` to **ALL 16 methods:**
- [ ] `getItems()` → return wine items from wineItemProvider
- [ ] `getFilteredItems()` → return filtered wines
- [ ] `isLoading()` → check wine loading state
- [ ] `hasLoadedOnce()` → check wine loaded state
- [ ] `getErrorMessage()` → return wine error
- [ ] `getSearchQuery()` → return wine search query
- [ ] `getActiveFilters()` → return wine filters
- [ ] `getFilterOptions()` → return wine filter options
- [ ] `loadItems()` → load wines
- [ ] `refreshItems()` → refresh wines
- [ ] `clearFilters()` → clear wine filters
- [ ] `clearTabSpecificFilters()` → clear wine tab filters
- [ ] `updateSearchQuery()` → update wine search
- [ ] `setCategoryFilter()` → set wine category filter
- [ ] `getItemById()` → get wine by ID from wineItemService
- [ ] `loadSpecificItems()` → load specific wine items

**⚠️ Missing ANY method causes runtime errors!**

---

### **10. Update ItemTypeHelper** (~3 min)
**File:** `lib/models/rateable_item.dart` (ItemTypeHelper class at bottom)

- [ ] Wine added to `getItemTypeDisplayName()` switch
- [ ] Wine icon already exists in `getItemTypeIcon()`: `Icons.wine_bar` ✅
- [ ] Wine color already exists in `getItemTypeColor()`: `Colors.purple` ✅
- [ ] 'wine' added to `isItemTypeSupported()` supported types list

**Note:** ItemTypeHelper is defined in rateable_item.dart, NOT a separate file!

---

### **11. Add to Home Screen** (~3 min)
**File:** `lib/screens/home/home_screen.dart`

- [ ] Wine state watcher added: `final wineItemState = ref.watch(wineItemProvider);`
- [ ] Wine data loading logic added in build()
- [ ] Wine card added to UI with `_buildItemTypeCard()`
- [ ] Refresh handler updated to include wine:
  ```dart
  onRefresh: () async {
    ref.read(cheeseItemProvider.notifier).refreshItems();
    ref.read(ginItemProvider.notifier).refreshItems();
    ref.read(wineItemProvider.notifier).refreshItems();  // ← ADD
    ref.read(ratingProvider.notifier).refreshRatings();
  }
  ```

---

### **12. Update Item Type Switcher** (~2 min)
**File:** `lib/screens/items/item_type_screen.dart`

- [ ] Wine PopupMenuItem added to `_buildItemTypeSwitcher()` with:
  - Proper icon (Icons.wine_bar)
  - Proper color
  - Localized name
  - Selection highlighting

---

### **13. Add Localization** (~10 min)

**Files:** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`

Add ~30 wine-specific strings (adjust based on your fields):

**Core Item Type Strings:**
- [ ] `wine` / `vin`
- [ ] `wines` / `vins`

**Field Labels (match your model):**
- [ ] `colorLabel`, `country`, `region`, `grapeLabel`, `designationLabel`
- [ ] `alcoholLabel`, `sugarLabel`, `organicLabel`

**Form Placeholders:**
- [ ] `enterWineName`, `enterColor`, `enterCountry`, `enterRegion`
- [ ] `enterGrape`, `enterDesignation`, `enterAlcohol`, `enterSugar`

**Hints:**
- [ ] `colorHint` (e.g., "Rouge, Blanc, Rosé...")
- [ ] `grapeHint` (e.g., "Syrah 50%, Grenache 25%")
- [ ] `designationHint` (e.g., "AOC, DOC, Rioja")

**Validation:**
- [ ] `colorRequired`, `countryRequired`

**Success Messages:**
- [ ] `wineCreated`, `wineUpdated`, `wineDeleted`

**Actions:**
- [ ] `createWine`, `editWine`, `addWine`

**Generate Translations:**
- [ ] `flutter gen-l10n` executed
- [ ] No errors, new strings available

---

### **14. Update ItemTypeLocalizer** (~1 min) ⚠️ CRITICAL

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

- [ ] Wine case added to `getLocalizedItemType()`

**⚠️ Why this is CRITICAL:**
- Without this, search hints show wrong item type
- Tab titles won't localize properly
- All UI text using ItemTypeLocalizer will fail
- French users will see English names

---

### **15. Update ItemDetailHeader** (~3 min) ⚠️ MISSING FROM ORIGINAL

**File:** `lib/widgets/items/item_detail_header.dart`

- [ ] **Import added:** `import '../../models/wine_item.dart';`
- [ ] Badge logic updated in `_getBadgeText()`:
  ```dart
  case 'wine':
    return item.categories['color'] ?? 'Unknown';  // ← Shows color in badge
  ```
- [ ] Localized fields support added in build():
  ```dart
  } else if (item is WineItem) {
    return (item as WineItem).getLocalizedDetailFields(context);
  }
  ```

**Why this matters:**
- Badge shows the distinguishing characteristic (color for wine, type for cheese, profile for gin)
- Ensures detail fields use localized labels

---

### **16. Update Filter Localization** (~2 min) ⚠️ MISSING FROM ORIGINAL

**File:** `lib/widgets/common/item_search_filter.dart`

Add wine category localizations to `_getLocalizedCategoryName()`:

```dart
String _getLocalizedCategoryName(String categoryKey) {
  switch (categoryKey.toLowerCase()) {
    case 'type':
      return context.l10n.type;
    case 'origin':
      return context.l10n.origin;
    case 'producer':
      return context.l10n.producer;
    case 'profile':
      return context.l10n.profileLabel;
    case 'color':  // ← ADD WINE CATEGORIES
      return context.l10n.colorLabel;
    case 'country':
      return context.l10n.country;
    case 'region':
      return context.l10n.region;
    default:
      return categoryKey;
  }
}
```

- [ ] Wine categories added (color, country, region, etc.)

**Why:** Filter chip labels appear as "color" instead of "Couleur"/"Color" without this.

---

## ✅ Testing Checklist (~15 min)

### **Run Localization Generator:**
```bash
flutter gen-l10n
```
- [ ] No errors
- [ ] New strings accessible

### **Backend Running:**
```bash
cd apps/api
go run main.go
```

### **Start Frontend:**
```bash
cd apps/client
flutter run -d linux  # or chrome, android, etc.
```

### **Complete Test Flow:**
- [ ] Home screen shows wine card with correct item count
- [ ] Click wine card → navigates to `/items/wine`
- [ ] "All Wines" tab loads items from API
- [ ] Items display with correct subtitle and details
- [ ] Badge shows color (Rouge, Blanc, etc.)
- [ ] "My Wine List" tab shows empty state
- [ ] Click "Add Wine" FAB → create form opens
- [ ] All form fields present and localized
- [ ] Create wine → saves successfully
- [ ] Wine appears in list immediately (cache cleared)
- [ ] Click wine → detail screen loads
- [ ] Detail fields show localized labels
- [ ] Name NOT duplicated in detail fields
- [ ] Click edit → edit form loads with data
- [ ] Edit wine → saves successfully
- [ ] Click "Rate Wine" → rating form opens ✅ (automatic)
- [ ] Create rating → saves ✅ (automatic)
- [ ] Rating appears in "My Wine List" ✅ (automatic)
- [ ] Privacy settings → wine ratings appear ✅ (automatic)
- [ ] Share wine rating → dialog works ✅ (automatic)
- [ ] Filter chips show localized labels (Couleur, Pays, Région)
- [ ] Filter by color → works correctly
- [ ] Search wines → works correctly
- [ ] Switch language FR ↔ EN → all strings translate
- [ ] Item type switcher shows "Vin" in French
- [ ] Switch between cheese/gin/wine → all work
- [ ] Pull-to-refresh works on all screens
- [ ] Offline mode works (cached data)

---

## 🎉 Success Criteria

Your new item type is complete when:

✅ **Full CRUD** - Create, read, update, delete operations work  
✅ **Rating Integration** - Can rate items and see ratings  
✅ **Sharing Works** - Can share ratings with other users  
✅ **Navigation** - All navigation flows work correctly  
✅ **Localization** - French and English translations complete  
✅ **No Duplication** - Name not shown twice, color only in badge  
✅ **Filter Localization** - All filter labels localized  
✅ **Offline Support** - Works offline with cached data  
✅ **No Errors** - No console errors or warnings  
✅ **Type Safety** - No runtime type errors  

---

## ⏱️ Accurate Time Breakdown

- Model creation: **15 min** (includes getLocalizedDetailFields, proper JSON mapping)
- Service creation: **12 min** (includes import at top of large file)
- Provider registration: **7 min** (includes import + cache clearing)
- Form strategy: **10 min**
- Strategy registration: **1 min**
- Form screens: **3 min** (proper pattern matching)
- Routes: **3 min**
- Navigation updates: **3 min**
- Helper updates: **5 min** (16 methods + import)
- ItemTypeHelper: **3 min**
- Home screen: **3 min**
- Item switcher: **2 min**
- Localization strings: **10 min** (~30 strings EN/FR)
- **ItemDetailHeader:** **3 min** (missing from original)
- **Filter localization:** **2 min** (missing from original)
- Testing & debugging: **15 min** (finding missing imports, ID mapping issues)

**Total: ~96 minutes** (realistic estimate including debugging)

---

## 🐛 Common Issues & Solutions

### **Compilation Errors**

**"WineItem is not defined"**
→ Missing import in service, provider, or helper file. Check TOP of each file.

**"No form strategy registered for item type: wine"**
→ Add 'wine': WineFormStrategy() to registry map + import

**"The method 'colorLabel' isn't defined"**
→ Missing localization strings in .arb files. Run `flutter gen-l10n`

### **Runtime Errors**

**"Null check operator used on a null value" on item.id**
→ JSON mapping uses 'id' instead of 'ID' - backend sends uppercase

**"Provider not found: wineItemProvider"**
→ Wine provider not registered in item_provider.dart

**"Type 'WineItemService' is not a subtype of type 'CheeseItemService'"**
→ Cache clearing not updated in createItem() method

### **UI Issues**

**Wine card doesn't appear on home screen**
→ Missing state watcher OR missing card in UI OR missing data loading logic

**Search hints show "Wine" instead of "Vin" in French**
→ Forgot to add wine case to ItemTypeLocalizer.getLocalizedItemType()

**Badge shows wrong field (type instead of color)**
→ Update _getBadgeText() in ItemDetailHeader

**Name shown twice in detail screen**
→ Remove name field from detailFields array

**Detail field labels in English when app is French**
→ ItemDetailHeader not calling getLocalizedDetailFields() for wine

**Filter chips show "color" instead of "Couleur"**
→ Update _getLocalizedCategoryName() in item_search_filter.dart

**Edit/Create buttons navigate to wrong screens**
→ Routes not registered OR navigation switch statement missing wine case

---

## 📚 Reference Files to Copy

**Essential templates:**
- **Model:** `lib/models/gin_item.dart` - Complete implementation
- **Service:** Look for `GinItemService` class in `lib/services/item_service.dart`
- **Provider:** Look for `ginItemProvider` sections in `lib/providers/item_provider.dart`
- **Strategy:** `lib/forms/strategies/gin_form_strategy.dart`
- **Screens:** `lib/screens/gin/gin_form_screens.dart`

**Files to update (search for 'gin' and add 'wine' cases):**
- `lib/utils/item_provider_helper.dart` - 16 methods
- `lib/screens/items/item_type_screen.dart` - Navigation + dropdown
- `lib/screens/items/item_detail_screen.dart` - Edit navigation
- `lib/screens/home/home_screen.dart` - Home card
- `lib/widgets/items/item_detail_header.dart` - Badge + fields
- `lib/widgets/common/item_search_filter.dart` - Filter labels

---

## 🎓 Understanding the Architecture

### **Why So Many Files?**

**Data Layer:**
- Model: Data structure + serialization
- Service: API communication + caching
- Provider: State management + filtering

**UI Layer:**
- Strategy: Form definition (fields, validation)
- Screens: Create/Edit wrappers
- Widgets: Reusable display components

**Glue Layer:**
- ItemProviderHelper: Type-agnostic access to providers
- ItemTypeHelper: Item type metadata (icons, colors)
- ItemTypeLocalizer: Localization for item types

### **The Magic:**

Generic screens have NO item-type conditionals because:
1. **Strategy Pattern** - Form logic encapsulated per type
2. **Helper Pattern** - Generic access via switch statements in ONE place
3. **Interface Pattern** - RateableItem ensures consistency

**Result:** Add wine in 16 places (helpers/switches), everything else just works!

---

## 💡 Pro Tips

1. **Work sequentially** - Complete each step fully before moving to next
2. **Add imports first** - Add all imports before writing code
3. **Copy-paste is your friend** - Use gin/wine as template, find/replace carefully
4. **Test incrementally** - Test after major steps (model, service, provider, forms)
5. **Check ALL switch statements** - Easy to miss one case statement
6. **Use IDE search** - Search "case 'gin':" to find all places to add new type
7. **Localization last** - Add strings as you encounter missing ones
8. **Cache clearing matters** - New items won't appear without it
9. **Use dropdown for enums** - Much better UX than text input
10. **Use checkbox for booleans** - Clearer than text 'true'/'false'
11. **Exclude name from detailFields** - Already shown in title
12. **Use enum.value for filtering** - Don't forget .value when using enums

---

## 🔍 Verification Commands

```bash
# Check all imports exist
grep -r "import.*wine_item" apps/client/lib/

# Find all places wine needs to be added
grep -r "case 'gin':" apps/client/lib/

# Verify localization generated
flutter gen-l10n && echo "✅ Success"

# Check no hardcoded English in UI
grep -r "label: '" apps/client/lib/models/wine_item.dart
```

---

**Last Updated:** January 2025  
**Status:** ✅ Complete (All missing steps from wine implementation integrated)
