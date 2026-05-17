# Adding New Item Types - Dynamic Schema Guide

**Last Updated:** May 2026
**Status:** ✅ Dynamic Schema System Active

This guide covers how to add new consumable types to the À la carte platform using the dynamic schema system. **No code changes are required** for most item types.

---

## 🎯 Overview

### The Old Way (Deprecated)

Previously, adding a new item type required coordinated changes across three codebases:
- **Backend:** New Go model, controller, routes, migrations (~65 min)
- **Frontend:** New Dart model, service, provider, form strategy, localization (~50 min)
- **Admin:** Config entry, color definition (~5 min)
- **Total:** ~2 hours of development time

### The New Way (Current)

With the dynamic schema system, adding a new item type is done entirely through the **admin panel UI**:
- **Admin Panel:** Create schema, define fields, set validation (~5-10 min)
- **Backend:** Automatic - no code changes
- **Frontend:** Automatic - no code changes
- **Total:** ~5-10 minutes

### When Code Changes Are Still Needed

Code changes are only needed for:
- **Custom field types** not supported by the schema system (text, textarea, number, select, checkbox, enum)
- **Custom validation logic** beyond min/max/length/pattern/enum
- **Custom client-side rendering** beyond the standard field renderers
- **Integration with external APIs** or data sources

---

## 📋 Quick Start: Adding a New Item Type

### Step 1: Plan Your Schema

Before opening the admin panel, plan:

1. **What fields does this item type need?**
   - Name (always required, stored as first-class column)
   - Description (optional, stored as first-class column)
   - Custom fields (e.g., ABV, Style, Origin, Organic)

2. **What field type for each?**
   - Text: Names, short labels
   - Textarea: Descriptions, tasting notes
   - Number: Quantities, percentages, ages
   - Select: Fixed categories (IPA, Stout, Pilsner)
   - Checkbox: Boolean flags (Organic, Gluten-Free)
   - Enum: Status fields

3. **Which fields are required?**
   - Name is always required
   - Choose 2-3 more that are essential

4. **What makes items unique?**
   - Define `unique_fields` to prevent duplicates
   - Example: For beer, `name` + `brewery`

5. **How should items display?**
   - Badge field: Shows as a colored pill on cards
   - Primary field: Main subtitle (e.g., Style)
   - Secondary field: Fallback subtitle (e.g., Brewery)

### Step 2: Create the Schema in Admin Panel

1. Log in to the admin panel at `/admin`
2. Navigate to **Schema Management** → **New Schema**
3. Fill in schema settings:
   - **Name:** `craft-beer` (kebab-case, permanent)
   - **Display Name:** `Craft Beer`
   - **Plural Name:** `Craft Beers`
   - **Icon:** `Beer` (or any Material icon name)
   - **Color:** `#FFA726` (choose a distinct color)

4. Add fields:
   | Key | Label | Type | Required | Validation | Display |
   |-----|-------|------|----------|------------|---------|
   | `name` | Name | text | ✅ | min:1, max:100 | - |
   | `brewery` | Brewery | text | ✅ | min:1, max:100 | secondary |
   | `style` | Style | select | ✅ | options: [IPA, Stout, Pilsner, Wheat] | primary |
   | `abv` | ABV (%) | number | ❌ | min:0, max:20 | - |
   | `origin` | Origin | text | ❌ | - | - |
   | `organic` | Organic | checkbox | ❌ | - | - |
   | `description` | Description | textarea | ❌ | max:500 | - |

5. Set unique fields: `name` + `brewery`
6. Click **Create Schema**

### Step 3: Verify in API

```bash
# List schemas
curl http://localhost:8080/api/schemas

# Get schema details
curl http://localhost:8080/api/schemas/craft-beer

# Create an item
curl -X POST http://localhost:8080/api/items/craft-beer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hazy IPA",
    "field_values": {
      "brewery": "Mountain Brew Co",
      "style": "IPA",
      "abv": 6.5,
      "origin": "Vermont",
      "organic": true
    }
  }'

# List items
curl http://localhost:8080/api/items/craft-beer \
  -H "Authorization: Bearer $TOKEN"
```

### Step 4: Verify in Client App

1. Open the Flutter client app
2. The new item type appears automatically in the home screen
3. Tap it to see the list view
4. Tap "+" to create a new item with the dynamic form
5. Fields render according to their types (text, select, checkbox, etc.)

### Step 5: Seed Data (Optional)

Prepare a JSON file:

```json
{
  "items": [
    {
      "name": "Hazy IPA",
      "brewery": "Mountain Brew Co",
      "style": "IPA",
      "abv": 6.5,
      "origin": "Vermont",
      "organic": true
    },
    {
      "name": "Imperial Stout",
      "brewery": "Dark Matter Brewing",
      "style": "Stout",
      "abv": 9.2,
      "origin": "Oregon",
      "organic": false
    }
  ]
}
```

Upload to a publicly accessible URL, then use the admin panel's **Seed** feature or API:

```bash
curl -X POST http://localhost:8080/admin/items/craft-beer/seed \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/beers.json"}'
```

---

## 🔧 Advanced: Custom Field Types

If you need a field type not supported by the schema system (e.g., date picker, multi-select, rich text), you need to extend the system.

### Backend Extension

1. Add the new field type to the `FieldType` enum in `apps/api/models/schemaModel.go`
2. Add validation logic in `apps/api/services/validation_engine.go`
3. Add EAV query handling in `apps/api/services/query_builder.go`

### Client Extension

1. Add a new field renderer widget in `apps/client/lib/widgets/forms/`
2. Register it in `DynamicForm` widget
3. Add localization strings for the new field type

### Admin Extension

1. Add the field type to the field type selector in `apps/admin/app/admin/schemas/[type]/page.tsx`
2. Add configuration UI for the field type's specific options

---

## 🔧 Advanced: Custom Validation

For validation beyond the built-in rules (required, length, range, pattern, enum), extend the validation engine.

### Example: Cross-Field Validation

Validate that `abv` is between 0 and 20 only when `style` is "IPA":

1. Add custom validation logic in `apps/api/services/validation_engine.go`
2. Add a new validation rule type to the schema field model
3. Add UI for configuring the rule in the admin panel

---

## 🔧 Advanced: Custom Client Rendering

For custom display beyond the standard field renderers:

### Example: Custom Card Layout

Override the default item card for a specific schema:

1. Create a custom widget in `apps/client/lib/widgets/items/`
2. Register it in `ItemListScreen` based on schema name
3. Use schema display hints to control when to use the custom layout

---

## 📊 Schema Design Best Practices

### Field Naming

- Use descriptive, self-documenting keys
- Be consistent with existing schemas
- Use snake_case: `milk_type`, not `milkType` or `milk type`

### Required Fields

- Keep required fields minimal (name + 2-3 essentials)
- Too many required fields make item creation tedious
- Use validation instead of required for soft constraints

### Unique Fields

- Always configure unique fields before seeding
- Use the minimum set that guarantees uniqueness
- Test with a few manual items before bulk import

### Display Hints

- Choose a distinctive badge field for visual identity
- Primary field should be the most informative subtitle
- Secondary field is a fallback - choose something always present

### Validation

- Set reasonable maxLength (100 for names, 500 for descriptions)
- Use numeric ranges to catch data entry errors
- Use select/enum instead of free text for standardized values

### Color Selection

- Choose colors that stand out from existing types
- Ensure good contrast for accessibility
- Test in both light and dark modes

---

## 🧪 Testing a New Schema

### API Testing

```bash
# 1. Verify schema appears in list
curl http://localhost:8080/api/schemas | jq '.schemas[] | select(.name == "craft-beer")'

# 2. Verify schema details
curl http://localhost:8080/api/schemas/craft-beer | jq '.fields'

# 3. Test validation - missing required field
curl -X POST http://localhost:8080/api/items/craft-beer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "field_values": {}}'
# Expected: 400 with validation error for missing brewery/style

# 4. Test validation - invalid type
curl -X POST http://localhost:8080/api/items/craft-beer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "field_values": {"brewery": "Brew", "style": "IPA", "abv": "not-a-number"}}'
# Expected: 400 with validation error for abv

# 5. Test unique constraint
curl -X POST http://localhost:8080/api/items/craft-beer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Hazy IPA", "field_values": {"brewery": "Mountain Brew Co", "style": "IPA"}}'
# Run twice - second should fail with duplicate error

# 6. Test filtering
curl "http://localhost:8080/api/items/craft-beer?filter[style]=IPA" \
  -H "Authorization: Bearer $TOKEN"

# 7. Test search
curl "http://localhost:8080/api/items/craft-beer?search=mountain" \
  -H "Authorization: Bearer $TOKEN"

# 8. Test sorting
curl "http://localhost:8080/api/items/craft-beer?sort=-created_at" \
  -H "Authorization: Bearer $TOKEN"
```

### Client Testing

1. **Home Screen:** New item type card appears with correct icon and color
2. **List View:** Items display with badge, primary, and secondary fields
3. **Detail View:** All fields render with correct types
4. **Create Form:** Fields appear in correct order with validation
5. **Edit Form:** Existing values populate correctly
6. **Image Upload:** Works via standard image picker
7. **Rating:** Rating system works automatically (polymorphic)
8. **Sharing:** Privacy/sharing works automatically

### Admin Testing

1. **Schema List:** New schema appears with item count
2. **Schema Editor:** All fields editable, validation works
3. **Item Table:** Columns match unique fields, filtering works
4. **Seed:** Bulk import works with deduplication
5. **Delete Impact:** Shows correct ratings/users affected

---

## 🔄 Migrating from Legacy Item Types

If you have existing item types created with the old hardcoded approach, migrate them to the dynamic schema system:

### Step 1: Create Schema in Admin Panel

Create a schema that matches the existing item type's fields.

### Step 2: Run Migration Script

Use the migration script at `apps/api/scripts/migrate_to_dynamic.go`:

```bash
cd apps/api
go run scripts/migrate_to_dynamic.go
```

This script:
1. Creates schema records for existing item types
2. Creates field records for each model field
3. Migrates existing items to the new `items` table
4. Creates EAV rows for filterable fields
5. Creates initial schema versions

### Step 3: Verify Migration

```bash
# Check schema exists
curl http://localhost:8080/api/schemas/cheese

# Check items migrated
curl http://localhost:8080/api/items/cheese \
  -H "Authorization: Bearer $TOKEN"

# Check field values
curl http://localhost:8080/api/items/cheese/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Step 4: Clean Up (After Verification)

Once verified, remove old code:
- Old models (`cheeseModel.go`, `ginModel.go`, etc.)
- Old controllers (`cheeseController.go`, `ginController.go`, etc.)
- Old routes from `main.go`
- Old AutoMigrate entries from `database.go`
- Old seeding from `seed.go`

See the [Migration Process Guide](/docs/guides/migration-process.md) for detailed steps.

---

## 📚 Related Documentation

- [Schema Management Guide](/docs/admin/schema-management.md) - Detailed admin UI guide
- [API Endpoints Reference](/docs/api/endpoints.md) - Dynamic schema and item API
- [Dynamic Schema Design](/openspec/changes/dynamic-item-schema/design.md) - Technical architecture
- [Client Architecture](/docs/client/README.md) - Flutter client schema discovery

---

## 💡 Pro Tips

1. **Start simple:** Create a basic schema first, then iterate
2. **Test early:** Create a few items manually before seeding
3. **Use select fields:** Prefer select over text for standardized values
4. **Plan unique fields:** Configure before bulk import to avoid duplicates
5. **Choose colors wisely:** Distinct colors help users identify item types quickly
6. **Leverage display hints:** Badge + primary + secondary make items visually informative
7. **Validate seed data:** Use the validate endpoint before importing
8. **Monitor client cache:** Schema changes take up to 5 minutes to reflect in client apps

---

**Adding a new item type now takes 5-10 minutes instead of 2 hours. No code deployment required.** 🚀
