# Internationalization (i18n) Setup for À la carte

## Overview
À la carte supports French (primary) and English (fallback) languages using Flutter's built-in internationalization system. The application is fully translated across all screens, widgets, and user interactions.

## Current Status: 100% Translated

### ✅ Complete Translation Coverage
- **All Screens**: User management, item browsing, item details, settings
- **All Widgets**: Rating components, connectivity indicators, form elements
- **All User Interactions**: Buttons, tooltips, error messages, validation
- **Dynamic Content**: Parameterized translations for counts, names, and contextual messages

### 🇫🇷 French-First Experience
- **Primary Language**: French and English; the default setting is `auto` (device locale)
- **Professional French**: Natural phrasing for food/rating domain
- **Contextual Grammar**: Proper French pluralization and agreement
- **Domain-Specific Terms**: Cheese terminology, rating vocabulary

## Quick Setup Steps

### 1. Install Dependencies
```bash
cd apps/client
flutter pub get
```

### 2. Generate Localization Files
```bash
flutter gen-l10n
```

### 3. Test the Application
```bash
flutter run -d linux
```

## Architecture

### Translation File Structure
```
lib/
├── l10n/
│   ├── app_en.arb              # English translations (template)
│   ├── app_fr.arb              # French translations
│   └── (manual ARB files)
├── flutter_gen/gen_l10n/
│   ├── app_localizations.dart  # Generated main file
│   ├── app_localizations_en.dart
│   ├── app_localizations_fr.dart
│   └── (auto-generated files)
├── providers/
│   └── locale_provider.dart    # Language selection state
└── utils/
    ├── localization_utils.dart  # Helper utilities & extensions
    └── appbar_helper.dart       # Standard app-bar actions (user menu)

l10n.yaml                       # Localization configuration
```

### Key Components

#### **1. LocalizationExtension (localization_utils.dart)**
```dart
// Easy access to translations in any widget
Text(context.l10n.welcomeTitle)  // "Bienvenue sur À la carte"

// Check current language
if (context.isFrench) { /* French-specific logic */ }
```

#### **2. ItemTypeLocalizer (localization_utils.dart)**
```dart
// Localized item type names
ItemTypeLocalizer.getLocalizedItemType(context, 'cheese') // "Fromage"
ItemTypeLocalizer.getAllItemsText(context, 'cheese')      // "Tous les Fromages"
ItemTypeLocalizer.getAddItemText(context, 'cheese')       // "Ajouter Fromage"
```

### Language Switching

#### **User Interface**
- **Language selector dialog**: `LanguageSelector` (`lib/widgets/settings/language_selector.dart`) — a dialog with radio choices `auto` (device locale), `french`, `english`
- **Location**: Settings screen; no app-bar toggle anymore

#### **Persistence & Resolution**
```dart
// Preference persisted via localeProvider; default is auto (device locale)
enum LocalePreference { auto, french, english }

// Current language check
final isFrench = ref.read(localeProvider).languageCode == 'fr';
```

The locale is resolved from the preference: `auto` follows the device locale (French if the device is French, otherwise English), the other values force a language.

### **🚀 App Initialization Translations**

À la carte includes specialized translations for the async initialization system:

#### **Initialization Messages**
```dart
// Loading states
context.l10n.initializingApp              // "Initialisation d'À la carte..."
context.l10n.initializationTakingLonger   // "Ceci prend plus de temps que prévu..."

// Error recovery messages
context.l10n.profileDataCorrupted         // "Données du profil corrompues..."
context.l10n.profileNotFoundOnServer      // "Votre profil n'a pas été trouvé..."
```

#### **Professional French Error Messages**
- **Profile corruption**: Uses technical but user-friendly French
- **Server validation errors**: Natural French phrasing
- **Progressive loading**: Contextual patience messaging
- **All errors actionable**: Clear instructions for user resolution

## Translation Implementation Patterns

### **Basic Text Translation**
```dart
// Before
Text('Welcome to À la carte')

// After
Text(context.l10n.welcomeTitle)
```

### **Parameterized Translations**
```dart
// Before
Text('$count items available')

// After  
Text(context.l10n.itemsAvailable(count))  // "42 articles disponibles"
```

### **Conditional Translations**
```dart
// Before
Text(widget.mode == Mode.create ? 'Create' : 'Edit')

// After
Text(widget.mode == Mode.create ? context.l10n.create : context.l10n.edit)
```

### **Item Type Translations**
```dart
// Before
Text('Add ${itemType}')

// After
Text(ItemTypeLocalizer.getAddItemText(context, itemType))  // "Ajouter Fromage"
```

### **Error Message Handling**
```dart
// Before
Text('Profile data is corrupted')

// After
Text(context.l10n.profileDataCorrupted)

```

## French Translation Quality

### **Key French Terms Used**
- **"Articles"** for items (more natural than "éléments")
- **"Évaluations"** for ratings (formal/professional)
- **"Liste de référence"** for preference list
- **"Hors ligne"** for offline (standard French tech term)
- **"Origine"** for origin (proper French spelling)
- **"Producteur"** for producer (correct French term)

### **Domain-Specific French**
- **"Fromage"** for cheese (obviously)
- **"Pâte pressée cuite"** for cheese types (authentic French cheese terminology)
- **"Fromagerie"** for producers (proper French cheese-making term)

### **Grammatical Considerations**
- **Proper pluralization**: "évaluation" vs "évaluations"
- **Gender agreement**: Maintained throughout UI elements
- **Formal tone**: Professional language appropriate for food rating context

## Usage Patterns

### **Screen Implementation**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.screenTitle),
      ),
      body: Column([
        Text(context.l10n.bodyText),
        ElevatedButton(
          onPressed: () => doAction(),
          child: Text(context.l10n.actionButton),
        ),
      ]),
    );
  }
}
```

### **Form Validation**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: context.l10n.name,
    hintText: context.l10n.nameHint,
  ),
  validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.nameRequired : null, // illustrative
)
```

### **Dynamic Content**
```dart
// Item type specific content
Text(ItemTypeLocalizer.getAddItemText(context, 'cheese'))  // "Ajouter Fromage"
Text(context.l10n.itemsAvailable(count))                   // "42 articles disponibles"
```

## Adding New Translations

### 1. Add to English Template (`lib/l10n/app_en.arb`)
```json
{
  "newKey": "English text",
  "@newKey": {
    "description": "Description of when this text is used"
  }
}
```

### 2. Add to French (`lib/l10n/app_fr.arb`)
```json
{
  "newKey": "Texte français"
}
```

### 3. Regenerate Localization
```bash
flutter gen-l10n
```

### 4. Use in Code
```dart
Text(context.l10n.newKey)
```

## Advanced Translation Features

### **Parameterized Translations**
```json
// English ARB
"itemsAvailable": "{count} items available",
"@itemsAvailable": {
  "placeholders": {
    "count": {"type": "int"}
  }
}

// Usage
Text(context.l10n.itemsAvailable(42))  // "42 items available"
```

### **Pluralization Support**
```json
// English ARB
"ratingsCount": "{count} {count, plural, =1{rating} other{ratings}}",

// Usage
Text(context.l10n.ratingsCount(1))  // "1 rating"
Text(context.l10n.ratingsCount(5))  // "5 ratings"
```

### **Complex Parameters**
```json
// English ARB
"deleteConfirmation": "Are you sure you want to delete {itemName}?",

// Usage
Text(context.l10n.deleteConfirmation(item.name))
```

## Translation Coverage

### **✅ Fully Translated Components**

#### **Screens**
- **HomeScreen**: Welcome messages, preference lists, item type cards
- **AppInitializationScreen**: Loading messages, extended loading indicators
- **AuthScreen / DisplayNameSetupScreen**: Sign-in and display-name setup
- **UserSettingsScreen**: Management options, confirmations, warnings
- **ItemTypeScreen**: Tabs, empty states, item cards, rating indicators
- **ItemDetailScreen**: Headers, rating sections, action buttons
- **LoadingScreen**: App title, loading messages, offline banners

#### **Widgets**
- **ItemDetailHeader**: Field labels (Origin, Producer, Description)
- **MyRatingSection**: Rating display, notes, edit buttons
- **RatingSummaryCard**: Community statistics, pluralized counts
- **SharedRatingsList**: Shared ratings display, empty states

#### **Utilities**
- **Form validation**: messages come from `context.l10n.*` keys
- **Error States**: Loading, network, app initialization, and data errors
- **Navigation**: Tooltips and accessibility labels

### **🎯 Translation Quality Measures**

#### **Consistency**
- **Unified terminology**: Same French terms used throughout app
- **Professional tone**: Appropriate for food rating context
- **Technical accuracy**: Proper French cheese and rating vocabulary

#### **User Experience**
- **Contextual messages**: Different offline messages per screen type
- **Natural phrasing**: French text reads naturally, not like translation
- **Cultural adaptation**: French conventions for UI text

#### **Technical Implementation**
- **Type safety**: Compile-time checking for translation keys
- **Performance**: Translations loaded at startup, no runtime overhead
- **Maintainability**: Clear separation between English template and French text

## Debugging Translation Issues

### **Common Issues**
1. **Missing translations**: Check both .arb files have the same keys
2. **Generation errors**: Run `flutter clean && flutter gen-l10n`
3. **Context not available**: Ensure widget has `BuildContext` parameter
4. **Parameters not working**: Check .arb syntax for placeholders
5. **Const issues**: Remove `const` from widgets containing `context.l10n.*`

### **Debug Commands**
```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter gen-l10n

# Check generated files
ls lib/flutter_gen/gen_l10n/

# Run with verbose output
flutter run -d linux --verbose
```

### **Debugging Specific Issues**

#### **Widget-Level Translation Issues**
```dart
// Problem: Using context.l10n in const widget
const Text(context.l10n.myText)  // ❌ Error

// Solution: Remove const
Text(context.l10n.myText)        // ✅ Works
```

#### **Model-Level Translation Issues**
```dart
// Problem: Models can't access BuildContext
class MyModel {
  String get label => context.l10n.myLabel;  // ❌ No context
}

// Solution: Create context-aware method
class MyModel {
  String get label => 'English fallback';
  String getLocalizedLabel(BuildContext context) => context.l10n.myLabel;
}
```

## File Structure
```
lib/
├── l10n/
│   ├── app_en.arb              # English translations (template)
│   ├── app_fr.arb              # French translations
│   └── (manual translation files)
├── flutter_gen/gen_l10n/
│   ├── app_localizations.dart  # Generated main file
│   ├── app_localizations_en.dart
│   ├── app_localizations_fr.dart
│   └── (auto-generated by flutter gen-l10n)
├── providers/
│   └── locale_provider.dart    # Language selection state management
├── utils/
│   ├── localization_utils.dart # Extensions and item type helpers
│   └── appbar_helper.dart      # Standard app-bar actions (user menu)
└── models/

l10n.yaml                       # Localization configuration
pubspec.yaml                    # Dependencies: flutter_localizations, intl
```

## Implementation Examples

### **Complete Screen Translation Pattern**
```dart
class ExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.screenTitle)),
      body: Column(children: [
        Text(context.l10n.itemsAvailable(itemCount)),
        ElevatedButton(
          onPressed: () => createItem(),
          child: Text(context.l10n.save),
        ),
      ]),
    );
  }
}
```

### **Item Type Localization Pattern**
```dart
// For any item type (cheese, future categories)
final localizedType = ItemTypeLocalizer.getLocalizedItemType(context, itemType);
final tabTitle = ItemTypeLocalizer.getAllItemsText(context, itemType);
final buttonText = ItemTypeLocalizer.getAddItemText(context, itemType);

// Results in French:
// "Fromage" (Cheese)
// "Tous les Fromages" (All Cheeses) 
// "Ajouter Fromage" (Add Cheese)
```

### **Form Validation Pattern**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: context.l10n.name,
    hintText: context.l10n.nameHint,  // "Entrez votre nom"
  ),
  validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.nameRequired : null, // illustrative
  // Validation errors automatically in French:
  // "Le nom est requis"
  // "Le nom doit contenir au moins 2 caractères"
)
```

## Performance Considerations
- **Startup Loading**: All translations loaded at app initialization
- **Memory Usage**: ARB files bundled with app (minimal impact)
- **Language Switching**: Requires widget rebuild (expected Flutter behavior)
- **No Network Calls**: All translations stored locally
- **Locale-Aware Sorting**: Uses `diacritic` package for efficient accent normalization

## Locale-Aware String Comparison

### Overview

To properly support French language with accented characters, the client sorts filter option lists with accent-insensitive comparison. Item lists themselves are sorted by the server (`ORDER BY name ASC`), not by this helper.

### Problem with Standard Sorting

**Standard Dart String Comparison:**
```dart
list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

// Results in incorrect sorting for French:
// Americano
// Brewmance  
// Latte
// Équilibre  ← Accented characters sorted at the end!
```

**Issue:** Dart's default `compareTo` treats accented characters as separate from their base letters, sorting them after all non-accented characters.

### Solution: Diacritic Package

The app uses the `diacritic` package to normalize strings by removing accents before comparison:

```dart
import 'package:diacritic/diacritic.dart';

// Sort with locale-aware comparison
list.sort((a, b) => _compareLocaleAware(a, b));

// Helper method
static int _compareLocaleAware(String a, String b) {
  return removeDiacritics(a).toLowerCase().compareTo(
    removeDiacritics(b).toLowerCase()
  );
}

// Results in correct French sorting:
// Americano
// Brewmance
// Équilibre  ← Sorted correctly with 'E' items!
// Latte
```

### How It Works

**Diacritic Normalization:**
- `removeDiacritics()` strips all accent marks from characters
- Converts "Équilibre" → "Equilibre" for comparison
- Then performs standard lowercase comparison
- Simple and comprehensive approach

**Accented Character Handling:**
- **é, è, ê, ë** → Normalized to 'e', sorts with 'e'
- **à, â** → Normalized to 'a', sorts with 'a'
- **ç** → Normalized to 'c', sorts with 'c'
- **ô** → Normalized to 'o', sorts with 'o'
- **û, ù** → Normalized to 'u', sorts with 'u'
- **ï, î** → Normalized to 'i', sorts with 'i'

### Implementation Locations

Locale-aware sorting is implemented in one place:

**Item Filter Helper** (`lib/utils/item_filter_helper.dart`, the only place `removeDiacritics` is used):
```dart
import 'package:diacritic/diacritic.dart';

static Map<String, List<String>> getAvailableFilters<T>(...) {
  return filterOptions.map(
    (key, valueSet) {
      final sortedList = valueSet.toList();
      sortedList.sort((a, b) => _compareLocaleAware(a, b));
      return MapEntry(key, sortedList);
    },
  );
}

static int _compareLocaleAware(String a, String b) {
  return removeDiacritics(a).toLowerCase().compareTo(
    removeDiacritics(b).toLowerCase()
  );
}
```

### Scope of Application

Locale-aware sorting applies to the **filter option lists** only (via `ItemFilterHelper`). Item lists and search results are ordered by the API.

### Performance Characteristics

**Performance Impact:**
- **Lightweight**: `removeDiacritics()` is a simple string transformation
- **Fast**: Character-by-character mapping with minimal overhead
- **Scalable**: Handles large lists efficiently
- **No caching needed**: Function is pure and efficient

**Memory Usage:**
- Normalized strings are temporary and garbage collected
- No persistent memory overhead
- Safe for frequent sorting operations
- Package size: ~10KB

### Testing Locale-Aware Sorting

**Test Data with Accents:**
```dart
final testItems = [
  CoffeeItem(name: 'Americano'),
  CoffeeItem(name: 'Équilibre'),      // Should sort with 'E'
  CoffeeItem(name: 'Brewmance'),
  CoffeeItem(name: 'À la carte'),     // Should sort with 'A'
  CoffeeItem(name: 'Café Latte'),      // Should sort with 'C'
];

// After sorting with removeDiacritics:
// À la carte
// Americano
// Brewmance
// Café Latte
// Équilibre
```

**What to Verify:**
1. Items with accented characters appear in correct alphabetical position
2. Filter dropdowns show options in proper French alphabetical order
3. Both uppercase and lowercase accented characters sort correctly

### Adding Locale-Aware Sorting to New Code

**When to Use:**
- Any alphabetical sorting of user-visible strings
- Sorting names, titles, categories, etc.
- Filter options, dropdown lists, autocomplete

**How to Implement:**
```dart
import 'package:diacritic/diacritic.dart';

// Instead of:
list.sort((a, b) => a.name.compareTo(b.name));

// Use:
list.sort((a, b) => removeDiacritics(a.name).toLowerCase().compareTo(
  removeDiacritics(b.name).toLowerCase()
));

// Or create a helper method:
static int _compareLocaleAware(String a, String b) {
  return removeDiacritics(a).toLowerCase().compareTo(
    removeDiacritics(b).toLowerCase()
  );
}

list.sort((a, b) => _compareLocaleAware(a.name, b.name));
```

**Best Practices:**
- Use `removeDiacritics()` before comparison
- Always convert to lowercase for case-insensitive sorting
- Create helper methods to avoid repetition
- Test with accented characters in test data

### Language Support

**Currently Supported:**
- **French**: Primary language with full accent support
- **English**: Works correctly (no accents, same helper)

**Future Languages:**
The `diacritic` package maps common Latin accents (not locale-specific rules such as German ß):
- **Spanish**: ñ, á, é, í, ó, ú
- **German**: ä, ö, ü, ß
- **Portuguese**: ã, õ, ç
- **Italian**: à, è, é, ì, ò, ù
- Any other language with locale-specific sorting rules

## Best Practices

### **Translation Keys**
- **Descriptive names**: `userSelectionTitle` not `title1`
- **Consistent prefixes**: `offline*` for offline messages
- **Parameter clarity**: Include type information in @placeholders

### **French Translation Guidelines**
- **Natural phrasing**: Write as native French speaker would
- **Professional tone**: Appropriate for food/rating application
- **Consistent terminology**: Use same French terms throughout
- **Proper grammar**: Attention to gender, number, verb conjugation

### **Code Organization**
- **Context availability**: Ensure BuildContext accessible where needed
- **Const limitations**: Avoid `const` with `context.l10n.*`
- **Helper methods**: Use ItemTypeLocalizer for consistent item type handling

## Maintenance

### **Adding New Translations**
1. Add key to `app_en.arb` with description
2. Add French translation to `app_fr.arb`
3. Run `flutter gen-l10n`
4. Use `context.l10n.newKey` in code
5. Test in both languages

### **Updating Existing Translations**
1. Modify text in ARB files
2. Run `flutter gen-l10n`
3. Test changes in app

### **Quality Assurance**
1. **Complete app walkthrough** in French mode
2. **Form validation testing** with French error messages  
3. **Edge case testing** (empty states, errors, offline mode)
4. **Dynamic content testing** (different counts, user names)

---

## Translation Statistics

**Languages Supported**: French and English (`lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`)

**Built with French users in mind** 🇫🇷
