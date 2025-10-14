# Implementing Enums for Item Fields

**Created:** January 2025  
**Example:** Wine Color (Rouge, Blanc, Rosé, Mousseux, Orange)

This guide shows how to implement enums for item fields that should have predefined values across all three platforms.

---

## 🎯 When to Use Enums

Use enums for fields that:
- ✅ Have a fixed set of valid values
- ✅ Should be enforced at the API level
- ✅ Need dropdown selection in forms
- ✅ Prevent data inconsistency
- ✅ Improve filtering/categorization

**Examples:**
- Wine color: Rouge, Blanc, Rosé, Mousseux, Orange
- Cheese type: Soft, Hard, Semi-soft, Blue
- Item status: Active, Archived, Draft
- Size: Small, Medium, Large

---

## 📋 Implementation Checklist

### **Backend (Go) - ~10 min**

**1. Create Enum File** (`models/[field]Enum.go`)

```go
package models

import (
	"database/sql/driver"
	"fmt"
)

type WineColor string

const (
	WineColorRouge    WineColor = "Rouge"
	WineColorBlanc    WineColor = "Blanc"
	WineColorRose     WineColor = "Rosé"
	WineColorMousseux WineColor = "Mousseux"
	WineColorOrange   WineColor = "Orange"
)

func (c WineColor) IsValid() bool {
	switch c {
	case WineColorRouge, WineColorBlanc, WineColorRose, WineColorMousseux, WineColorOrange:
		return true
	default:
		return false
	}
}

func (c WineColor) Value() (driver.Value, error) {
	if !c.IsValid() {
		return nil, fmt.Errorf("invalid wine color: %s", c)
	}
	return string(c), nil
}

func (c *WineColor) Scan(value interface{}) error {
	str, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan wine color")
	}
	*c = WineColor(str)
	if !c.IsValid() {
		return fmt.Errorf("invalid wine color: %s", *c)
	}
	return nil
}
```

**2. Update Model**
```go
type Wine struct {
    // ... other fields
    Color WineColor `gorm:"not null" json:"color"`
}
```

**3. Add Validation in Controllers**
```go
// In Create and Edit endpoints
wineColor := models.WineColor(body.Color)
if !wineColor.IsValid() {
    c.JSON(400, gin.H{"error": "Invalid color. Must be: Rouge, Blanc, Rosé, Mousseux, Orange"})
    return
}
```

---

### **Admin Panel (Next.js) - ~2 min**

**Update Item Config:**

```typescript
{
  key: 'color',
  label: 'Color',
  type: 'select',  // Changed from 'text'
  required: true,
  options: [
    { value: 'Rouge', label: 'Rouge' },
    { value: 'Blanc', label: 'Blanc' },
    { value: 'Rosé', label: 'Rosé' },
    { value: 'Mousseux', label: 'Mousseux' },
    { value: 'Orange', label: 'Orange' },
  ],
  helperText: 'Wine color/type',
}
```

**Note:** Admin panel is read-only, so this just documents the field structure.

---

### **Client (Flutter) - ~15 min**

**1. Create Enum File** (`lib/models/[field]_enum.dart`)

```dart
enum WineColor {
  rouge('Rouge'),
  blanc('Blanc'),
  rose('Rosé'),
  mousseux('Mousseux'),
  orange('Orange');

  final String value;
  const WineColor(this.value);

  static WineColor? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    
    try {
      return WineColor.values.firstWhere(
        (color) => color.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  String toJson() => value;
  static WineColor? fromJson(String? json) => fromString(json);

  @override
  String toString() => value;
}
```

**2. Update Model**

```dart
import 'wine_color.dart';

class WineItem {
  final WineColor color;  // Changed from String
  
  // fromJson
  color: WineColor.fromString(json['color'] as String?) ?? WineColor.rouge,
  
  // toJson
  'color': color.value,
  
  // categories
  'color': color.value,
  
  // searchableText
  '... ${color.value} ...'.toLowerCase()
  
  // displaySubtitle
  parts.add(color.value);
}
```

**3. Update Form Strategy**

```dart
// In getFormFields()
FormFieldConfig.dropdown(
  key: 'color',
  labelBuilder: (context) => context.l10n.colorLabel,
  hintBuilder: (context) => context.l10n.selectColor,
  options: [
    DropdownOption(value: 'Rouge', labelBuilder: (_) => 'Rouge'),
    DropdownOption(value: 'Blanc', labelBuilder: (_) => 'Blanc'),
    DropdownOption(value: 'Rosé', labelBuilder: (_) => 'Rosé'),
    DropdownOption(value: 'Mousseux', labelBuilder: (_) => 'Mousseux'),
    DropdownOption(value: 'Orange', labelBuilder: (_) => 'Orange'),
  ],
  icon: Icons.palette,
  required: true,
)

// In initializeControllers()
'color': TextEditingController(text: initialItem?.color.value ?? ''),

// In buildItem()
final colorValue = controllers['color']!.text.trim();
final wineColor = WineColor.fromString(colorValue) ?? WineColor.rouge;

return WineItem(
  // ...
  color: wineColor,
);
```

**4. Update Service Validation**

```dart
static List<String> _validateWineItem(WineItem wine) {
  final errors = <String>[];
  
  // ... name, country validation
  
  // Color validation not needed - enum type guarantees validity
  
  return errors;
}

// Filter methods
.map((wine) => wine.color.value)  // Use .value for string
```

**5. Add Localization** (optional for dropdown hint)

```json
{
  "selectColor": "Select color",
  "@selectColor": {
    "description": "Hint text for color dropdown"
  }
}
```

---

## 🎨 Form UI Results

### **Dropdown Field:**
- Shows dropdown with predefined options
- Can't enter invalid values
- Clean, professional UI
- Localized labels (if using labelBuilder with context)

### **Display in Detail View:**
- Shows enum value as regular text
- Appears in badge (for distinguishing field)
- Can be filtered

---

## 💡 Pro Tips

### **Data Values vs Display Labels**

**Option 1: Keep values in one language (recommended for data consistency)**
```dart
// Values stay in French (database values)
DropdownOption(value: 'Rouge', labelBuilder: (_) => 'Rouge'),

// Display is same in both languages
English: Rouge, Blanc, Rosé
French: Rouge, Blanc, Rosé
```

**Option 2: Localize display (for user-facing categories)**
```dart
// Values in English (internal)
DropdownOption(value: 'red', labelBuilder: (context) => context.l10n.colorRed),

// Display changes with language
English: Red, White, Rosé
French: Rouge, Blanc, Rosé
```

**Wine uses Option 1** - Values are French (SAQ standard), display stays French.

### **Enum vs String Trade-offs**

**Enum Pros:**
- ✅ Type safety
- ✅ Compile-time validation
- ✅ No typos possible
- ✅ Better IDE autocomplete
- ✅ Dropdown UI enforces values

**Enum Cons:**
- ❌ Migration needed for existing data
- ❌ Adding values requires code change
- ❌ More complex than simple strings

**Use enums when:** Values are truly fixed and unlikely to change frequently

**Use strings when:** Values are dynamic, user-defined, or frequently changing

---

## 🔄 Migration Strategy

### **For New Item Types:**
- Start with enum from day one
- No migration needed

### **For Existing Item Types:**
1. Drop and reseed data (development)
2. Create migration script (production)
3. Add validation progressively

---

## 📚 Related Documentation

- [Adding New Item Types](adding-new-item-types.md) - Complete guide
- [Backend Checklist](backend-checklist.md) - Backend steps
- [Client Checklist](client-checklist.md) - Frontend steps
- [Admin Checklist](admin-checklist.md) - Admin panel steps

---

**Last Updated:** January 2025  
**Example Implementation:** Wine color enum
