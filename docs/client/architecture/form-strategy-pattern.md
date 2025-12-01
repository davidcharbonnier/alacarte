# Form Strategy Pattern - Item CRUD System

**Last Updated:** October 2025  
**Status:** ✅ Production Ready  
**Item Types:** Cheese, Gin (Wine, Beer, Coffee ready to add)

---

## 🎯 Overview

À la carte uses the **Strategy Pattern** for item forms, allowing unlimited item types to be added with minimal code changes. The generic form contains **zero item-type conditionals** - all type-specific logic is encapsulated in strategy classes.

---

## 🏗️ Architecture

### **File Structure**
```
lib/forms/
├── strategies/
│   ├── form_field_config.dart              # Field configuration model
│   ├── item_form_strategy.dart             # Abstract strategy interface
│   ├── cheese_form_strategy.dart           # Cheese implementation
│   ├── gin_form_strategy.dart              # Gin implementation
│   ├── item_form_strategy_registry.dart    # Central registry
│   └── [future]_form_strategy.dart         # Wine, beer, coffee, etc.
└── generic_item_form_screen.dart           # Generic form (uses strategies)
```

### **Component Responsibilities**

**FormFieldConfig:** Defines a single form field with localization
**ItemFormStrategy:** Encapsulates all item-specific form logic
**ItemFormStrategyRegistry:** Type-safe access to strategies
**GenericItemFormScreen:** Renders forms using strategy configurations

---

## 📋 Core Components

### **1. FormFieldConfig**

Configuration model for individual form fields with built-in localization:

```dart
FormFieldConfig.text(
  key: 'name',                                      // Controller key
  labelBuilder: (context) => context.l10n.name,    // Localized label
  hintBuilder: (context) => context.l10n.enterGinName,  // Localized hint
  helperTextBuilder: (context) => context.l10n.profileHint,  // Optional helper
  icon: Icons.label,                                // Visual icon
  required: true,                                   // Validation
)
```

**Field Types:**
- **text:** Single-line text input
- **multiline:** Multi-line text area (e.g., description)

**Localization:**
All UI strings use builder functions that receive `BuildContext` for runtime localization.

---

### **2. ItemFormStrategy Interface**

Abstract interface defining the contract for item-type strategies:

```dart
abstract class ItemFormStrategy<T extends RateableItem> {
  String get itemType;  // 'cheese', 'gin', etc.
  
  // Configuration
  List<FormFieldConfig> getFormFields();
  
  // Controller lifecycle
  Map<String, TextEditingController> initializeControllers(T? initialItem);
  void disposeControllers(Map<String, TextEditingController> controllers);
  
  // Data handling
  T buildItem(Map<String, TextEditingController> controllers, int? itemId);
  
  // Integration
  StateNotifierProvider<ItemProvider<T>, ItemState<T>> getProvider();
  
  // Validation
  List<String> validate(BuildContext context, T item);
}
```

---

### **3. Concrete Strategies**

#### **Cheese vs Gin - Field Differences**

| Aspect | Cheese | Gin |
|--------|--------|-----|
| **Unique Field** | `type` (Hard, Soft, Blue) | `profile` (Forestier, Floral, Épicé) |
| **Icon** | Icons.category | Icons.local_bar |
| **Hint (EN)** | "e.g. Soft, Hard, Semi-soft, Blue" | "e.g., Forestier / boréal, Floral, Épicé" |
| **Hint (FR)** | "ex: Mou, Dur, Mi-dur, Bleu" | "ex: Forestier / boréal, Floral, Épicé" |
| **Common Fields** | name, origin, producer, description | name, origin, producer, description |

#### **CheeseFormStrategy Example**

```dart
class CheeseFormStrategy extends ItemFormStrategy<CheeseItem> {
  @override
  List<FormFieldConfig> getFormFields() {
    return [
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterItemName('cheese'),
        icon: Icons.label,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'type',  // Cheese-specific
        labelBuilder: (context) => context.l10n.type,
        hintBuilder: (context) => context.l10n.cheeseTypeHint,
        icon: Icons.category,
        required: true,
      ),
      // ... origin, producer, description
    ];
  }
  
  @override
  CheeseItem buildItem(controllers, itemId) {
    return CheeseItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      type: controllers['type']!.text.trim(),
      origin: controllers['origin']!.text.trim(),
      producer: controllers['producer']!.text.trim(),
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }
  
  @override
  StateNotifierProvider<ItemProvider<CheeseItem>, ItemState<CheeseItem>> 
      getProvider() => cheeseItemProvider;
      
  @override
  List<String> validate(BuildContext context, CheeseItem cheese) {
    final errors = <String>[];
    if (cheese.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Cheese'));
    }
    if (cheese.type.trim().isEmpty) {
      errors.add(context.l10n.typeRequired);
    }
    // ... more validation
    return errors;
  }
}
```

---

### **4. Strategy Registry**

Central registry providing type-safe access to strategies:

```dart
class ItemFormStrategyRegistry {
  static final Map<String, ItemFormStrategy> _strategies = {
    'cheese': CheeseFormStrategy(),
    'gin': GinFormStrategy(),
  };
  
  static ItemFormStrategy<T> getStrategy<T extends RateableItem>(String itemType) {
    final strategy = _strategies[itemType];
    if (strategy == null) {
      throw UnsupportedError('No form strategy for: $itemType');
    }
    return strategy as ItemFormStrategy<T>;
  }
  
  static bool hasStrategy(String itemType) => _strategies.containsKey(itemType);
  static List<String> getSupportedItemTypes() => _strategies.keys.toList();
}
```

**Usage:**
```dart
// Get strategy
final strategy = ItemFormStrategyRegistry.getStrategy<CheeseItem>('cheese');

// Check if exists
if (ItemFormStrategyRegistry.hasStrategy('wine')) { ... }

// List all
final types = ItemFormStrategyRegistry.getSupportedItemTypes();
```

---

### **5. Generic Form Screen**

The generic form delegates to strategies - **zero item-type conditionals:**

```dart
class _GenericItemFormScreenState<T extends RateableItem> {
  late final ItemFormStrategy<T> _strategy;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    // Get strategy - this is the ONLY item-type specific code!
    _strategy = ItemFormStrategyRegistry.getStrategy<T>(widget.itemType);
    // Strategy handles everything else
    _controllers = _strategy.initializeControllers(widget.initialItem);
    _setupChangeListeners();
  }

  Future<void> _submitForm() async {
    // Strategy builds item
    final item = _strategy.buildItem(_controllers, widget.itemId);
    // Strategy validates
    final errors = _strategy.validate(context, item);
    if (errors.isNotEmpty) { /* show error */ }
    // Strategy provides provider
    final provider = _strategy.getProvider();
    // Standard CRUD
    await ref.read(provider.notifier).createItem(item);
  }

  List<Widget> _buildFormFields() {
    // Strategy provides field configs - just render them!
    return _strategy.getFormFields()
        .map((field) => _buildFieldWidget(field))
        .toList();
  }
}
```

**Key Point:** The form has NO knowledge of cheese vs gin vs wine - it just asks the strategy for everything!

---

## ➕ Adding a New Item Type

### **Time Estimate: ~15 minutes**

### **Step 1: Create Strategy** (10 min)

Copy `gin_form_strategy.dart` as template, update:

```dart
// lib/forms/strategies/wine_form_strategy.dart
class WineFormStrategy extends ItemFormStrategy<WineItem> {
  @override
  String get itemType => 'wine';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterWineName,
        icon: Icons.label,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'varietal',  // Wine-specific field
        labelBuilder: (context) => context.l10n.varietalLabel,
        hintBuilder: (context) => context.l10n.enterVarietal,
        helperTextBuilder: (context) => context.l10n.varietalHint,
        icon: Icons.wine_bar,
        required: true,
      ),
      // ... origin, producer, description (copy from gin)
    ];
  }

  @override
  Map<String, TextEditingController> initializeControllers(WineItem? item) {
    return {
      'name': TextEditingController(text: item?.name ?? ''),
      'varietal': TextEditingController(text: item?.varietal ?? ''),
      'origin': TextEditingController(text: item?.origin ?? ''),
      'producer': TextEditingController(text: item?.producer ?? ''),
      'description': TextEditingController(text: item?.description ?? ''),
    };
  }

  @override
  WineItem buildItem(controllers, itemId) {
    return WineItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      varietal: controllers['varietal']!.text.trim(),
      origin: controllers['origin']!.text.trim(),
      producer: controllers['producer']!.text.trim(),
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  @override
  StateNotifierProvider<ItemProvider<WineItem>, ItemState<WineItem>> 
      getProvider() => wineItemProvider;

  @override
  List<String> validate(BuildContext context, WineItem wine) {
    final errors = <String>[];
    if (wine.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Wine'));
    }
    if (wine.varietal.trim().isEmpty) {
      errors.add(context.l10n.varietalRequired);
    }
    // ... more validation
    return errors;
  }
}
```

### **Step 2: Register Strategy** (1 min)

```dart
// lib/forms/strategies/item_form_strategy_registry.dart

// Add import
import 'wine_form_strategy.dart';

// Add to map
static final Map<String, ItemFormStrategy> _strategies = {
  'cheese': CheeseFormStrategy(),
  'gin': GinFormStrategy(),
  'wine': WineFormStrategy(),  // ← Add this line!
};
```

### **Step 3: Create Form Screens** (2 min)

Copy `gin_form_screens.dart` and replace gin with wine throughout.

### **Step 4: Add Routes** (2 min)

Update `route_names.dart` and `app_router.dart` (follow gin pattern).

**Total:** ~15 minutes for complete CRUD forms!

---

## ✨ Key Benefits

### **1. Zero Conditionals in Generic Form**
```dart
// Before Strategy Pattern (BAD):
if (itemType == 'cheese') {
  _typeController = TextEditingController(text: cheese.type);
} else if (itemType == 'gin') {
  _profileController = TextEditingController(text: gin.profile);
} else if (itemType == 'wine') {
  _varietalController = TextEditingController(text: wine.varietal);
}
// ... repeated 8 times throughout the file!

// After Strategy Pattern (GOOD):
_controllers = _strategy.initializeControllers(widget.initialItem);
// Strategy handles all type-specific logic!
```

### **2. Full Localization Support**
```dart
// Localization built into field config
FormFieldConfig.text(
  key: 'profile',
  labelBuilder: (context) => context.l10n.profileLabel,  // "Profile" / "Profil"
  hintBuilder: (context) => context.l10n.enterProfile,   // Localized hint
  helperTextBuilder: (context) => context.l10n.profileHint,  // Localized helper
)
```

**Works seamlessly with:**
- Language switching (FR ↔ EN)
- Device locale detection
- Future language additions

### **3. Easy Testing**
```dart
// Test strategy in isolation
test('WineFormStrategy builds correct item', () {
  final strategy = WineFormStrategy();
  final controllers = {
    'name': TextEditingController(text: 'Bordeaux'),
    'varietal': TextEditingController(text: 'Merlot'),
  };
  
  final wine = strategy.buildItem(controllers, null);
  
  expect(wine.name, 'Bordeaux');
  expect(wine.varietal, 'Merlot');
});
```

### **4. Type Safety**
```dart
// Compile-time guarantees
final strategy = ItemFormStrategyRegistry.getStrategy<CheeseItem>('cheese');
// ✅ Type-safe: strategy is ItemFormStrategy<CheeseItem>

final cheese = strategy.buildItem(controllers, itemId);
// ✅ Type-safe: cheese is CheeseItem
```

---

## 📊 Code Metrics

### **Before Strategy Pattern**
- Generic form: ~600 lines
- Item-type conditionals: 8 instances
- Code duplication: High
- Adding new type: Modify 8+ locations

### **After Strategy Pattern** ✅
- Generic form: ~450 lines (-25%)
- Item-type conditionals: 0 (ZERO!)
- Code duplication: None
- Adding new type: Create strategy + register (2 locations)

---

## 🎓 Design Patterns Used

### **Strategy Pattern**
**Problem:** Different item types need different form fields and validation  
**Solution:** Encapsulate type-specific logic in strategy classes  
**Benefit:** Open/Closed Principle - open for extension, closed for modification

### **Registry Pattern**
**Problem:** Need type-safe access to strategies  
**Solution:** Central registry with generic lookup method  
**Benefit:** Single source of truth, easy to maintain

### **Builder Pattern**
**Problem:** Localization requires context at render time  
**Solution:** Functions that build strings when called with context  
**Benefit:** Deferred evaluation, proper localization

---

## 🔄 Migration Guide

### **From Old Generic Form to Strategy Pattern**

**Old Approach (Deprecated):**
```dart
// Hardcoded conditionals everywhere
if (widget.itemType == 'cheese') {
  final cheese = CheeseItem(...);
  await ref.read(cheeseItemProvider.notifier).createItem(cheese);
} else if (widget.itemType == 'gin') {
  final gin = GinItem(...);
  await ref.read(ginItemProvider.notifier).createItem(gin);
}
```

**New Approach (Current):**
```dart
// Strategy handles everything
final item = _strategy.buildItem(_controllers, widget.itemId);
final provider = _strategy.getProvider();
await ref.read(provider.notifier).createItem(item);
```

**Benefits:**
- Single code path for all item types
- No conditional logic needed
- Easy to add new types

---

## 📝 Example: Adding Wine

### **Complete Wine Strategy**

```dart
// lib/forms/strategies/wine_form_strategy.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wine_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

class WineFormStrategy extends ItemFormStrategy<WineItem> {
  @override
  String get itemType => 'wine';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterWineName,
        icon: Icons.label,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'varietal',
        labelBuilder: (context) => context.l10n.varietalLabel,
        hintBuilder: (context) => context.l10n.enterVarietal,
        helperTextBuilder: (context) => context.l10n.varietalHint,
        icon: Icons.wine_bar,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'vintage',
        labelBuilder: (context) => context.l10n.vintageLabel,
        hintBuilder: (context) => context.l10n.enterVintage,
        icon: Icons.calendar_today,
        required: false,
      ),
      FormFieldConfig.text(
        key: 'origin',
        labelBuilder: (context) => context.l10n.origin,
        hintBuilder: (context) => context.l10n.enterOrigin,
        icon: Icons.public,
        required: true,
      ),
      FormFieldConfig.text(
        key: 'producer',
        labelBuilder: (context) => context.l10n.producer,
        hintBuilder: (context) => context.l10n.enterProducer,
        icon: Icons.business,
        required: true,
      ),
      FormFieldConfig.multiline(
        key: 'description',
        labelBuilder: (context) => context.l10n.description,
        hintBuilder: (context) => context.l10n.enterDescription,
        helperTextBuilder: (context) => context.l10n.optionalFieldHelper(500),
        maxLines: 3,
        maxLength: 500,
      ),
    ];
  }

  @override
  Map<String, TextEditingController> initializeControllers(WineItem? item) {
    return {
      'name': TextEditingController(text: item?.name ?? ''),
      'varietal': TextEditingController(text: item?.varietal ?? ''),
      'vintage': TextEditingController(text: item?.vintage ?? ''),
      'origin': TextEditingController(text: item?.origin ?? ''),
      'producer': TextEditingController(text: item?.producer ?? ''),
      'description': TextEditingController(text: item?.description ?? ''),
    };
  }

  @override
  WineItem buildItem(Map<String, TextEditingController> controllers, int? itemId) {
    return WineItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      varietal: controllers['varietal']!.text.trim(),
      vintage: controllers['vintage']!.text.trim(),
      origin: controllers['origin']!.text.trim(),
      producer: controllers['producer']!.text.trim(),
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  @override
  StateNotifierProvider<ItemProvider<WineItem>, ItemState<WineItem>> 
      getProvider() => wineItemProvider;

  @override
  List<String> validate(BuildContext context, WineItem wine) {
    final errors = <String>[];
    
    if (wine.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Wine'));
    }
    if (wine.varietal.trim().isEmpty) {
      errors.add(context.l10n.varietalRequired);
    }
    if (wine.origin.trim().isEmpty) {
      errors.add(context.l10n.originRequired);
    }
    if (wine.producer.trim().isEmpty) {
      errors.add(context.l10n.producerRequired);
    }
    
    return errors;
  }
}
```

### **Register in Registry**

```dart
// lib/forms/strategies/item_form_strategy_registry.dart
import 'wine_form_strategy.dart';

static final Map<String, ItemFormStrategy> _strategies = {
  'cheese': CheeseFormStrategy(),
  'gin': GinFormStrategy(),
  'wine': WineFormStrategy(),  // ← Add this!
};
```

**That's it!** Wine forms now work completely.

---

## 🧪 Testing

### **Unit Test: Strategy**
```dart
test('WineFormStrategy creates wine with correct data', () {
  final strategy = WineFormStrategy();
  
  final controllers = {
    'name': TextEditingController(text: 'Château Margaux'),
    'varietal': TextEditingController(text: 'Cabernet Sauvignon'),
    'vintage': TextEditingController(text: '2015'),
    'origin': TextEditingController(text: 'Bordeaux'),
    'producer': TextEditingController(text: 'Château Margaux'),
    'description': TextEditingController(text: 'Full-bodied red'),
  };
  
  final wine = strategy.buildItem(controllers, null);
  
  expect(wine.name, 'Château Margaux');
  expect(wine.varietal, 'Cabernet Sauvignon');
  expect(wine.vintage, '2015');
});
```

### **Widget Test: Form**
```dart
testWidgets('Wine form creates wine successfully', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wineItemServiceProvider.overrideWith(MockWineService()),
      ],
      child: MaterialApp(
        home: GenericItemFormScreen<WineItem>(itemType: 'wine'),
      ),
    ),
  );
  
  await tester.enterText(find.byKey(Key('name')), 'Bordeaux');
  await tester.enterText(find.byKey(Key('varietal')), 'Merlot');
  await tester.tap(find.text('Create'));
  await tester.pump();
  
  // Verify wine was created
});
```

---

## 🚀 Future Enhancements

### **Potential Field Types to Add:**

1. **Dropdown Field**
```dart
FormFieldConfig.dropdown(
  key: 'type',
  labelBuilder: (context) => context.l10n.type,
  options: ['Hard', 'Soft', 'Blue'],
  icon: Icons.category,
  required: true,
)
```

2. **Date Picker Field**
```dart
FormFieldConfig.date(
  key: 'vintage',
  labelBuilder: (context) => context.l10n.vintage,
  icon: Icons.calendar_today,
)
```

3. **Number Field**
```dart
FormFieldConfig.number(
  key: 'abv',
  labelBuilder: (context) => context.l10n.alcoholByVolume,
  min: 0,
  max: 100,
  suffix: '%',
)
```

4. **Autocomplete Field**
```dart
FormFieldConfig.autocomplete(
  key: 'producer',
  labelBuilder: (context) => context.l10n.producer,
  optionsProvider: () => getAllProducers(),
)
```

### **Implementation Pattern:**
1. Add field type to `FormFieldType` enum
2. Add parameters to `FormFieldConfig`
3. Add case in `_buildFieldWidget()` in generic form
4. Use in any strategy that needs it

---

## 💡 Best Practices

### **DO:**
✅ Use builder functions for all user-visible strings  
✅ Keep field keys consistent (match model properties)  
✅ Validate in strategy's `validate()` method  
✅ Add helper text for complex fields  
✅ Use appropriate icons for fields  

### **DON'T:**
❌ Hardcode strings in strategies (use context.l10n)  
❌ Add item-type conditionals to generic form  
❌ Bypass the registry (always use `getStrategy()`)  
❌ Forget to register new strategies  
❌ Mix concerns (strategies should only handle form logic)

---

## 📚 Related Documentation

- **[Adding New Item Types](adding-new-item-types.md)** - Complete guide including model, service, provider
- **[New Item Type Checklist](new-item-type-checklist.md)** - Step-by-step checklist
- **[Internationalization](internationalization.md)** - Localization system details

---

**Last Updated:** October 2025  
**Status:** ✅ Production Ready  
**Pattern:** Strategy Pattern with Registry and Builder patterns
