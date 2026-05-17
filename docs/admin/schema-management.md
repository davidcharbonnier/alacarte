# Schema Management Guide for Administrators

**Last Updated:** May 2026

This guide covers how to create, edit, and manage item type schemas through the admin panel. Schemas define the structure of consumable types (cheese, gin, wine, beer, coffee, etc.) without requiring code changes.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Accessing Schema Management](#accessing-schema-management)
- [Creating a New Schema](#creating-a-new-schema)
- [Schema Fields](#schema-fields)
- [Field Types](#field-types)
- [Validation Rules](#validation-rules)
- [Display Hints](#display-hints)
- [Unique Fields](#unique-fields)
- [Editing a Schema](#editing-a-schema)
- [Activating and Deactivating](#activating-and-deactivating)
- [Version History](#version-history)
- [Deleting a Schema](#deleting-a-schema)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

A **schema** defines:
- What fields an item type has (e.g., Name, Origin, Style)
- What type each field is (text, number, select, etc.)
- Validation rules (required, length limits, numeric ranges)
- How fields display in the client app (badge, primary, secondary)
- Which fields together must be unique (e.g., Name + Producer)

Once a schema is created, the API and client apps automatically support the new item type without any code deployment.

---

## Accessing Schema Management

1. Log in to the admin panel at `/admin`
2. Navigate to **Schema Management** in the sidebar
3. The schema list page shows all schemas with item counts

---

## Creating a New Schema

### Step 1: Open the Schema Editor

Click **"New Schema"** on the schema list page.

### Step 2: Fill Schema Settings

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Unique kebab-case identifier (cannot change later) | `craft-beer` |
| **Display Name** | Human-readable singular name | `Craft Beer` |
| **Plural Name** | Human-readable plural name | `Craft Beers` |
| **Icon** | Icon name for the client app | `Beer` |
| **Color** | Hex color for branding | `#FFA726` |

**Important:** The `name` field must be unique and use kebab-case (lowercase with hyphens). This becomes part of the API URL: `/api/items/craft-beer`.

### Step 3: Add Fields

Click **"Add Field"** to define each field:

| Property | Description |
|----------|-------------|
| **Key** | Machine-readable identifier (snake_case) |
| **Label** | Human-readable label shown in forms |
| **Field Type** | One of: text, textarea, number, select, checkbox, enum |
| **Required** | Whether the field is mandatory |
| **Order** | Display order in forms and detail views |

### Step 4: Configure Validation (Optional)

Click the validation icon on a field to add rules:

- **Min Length / Max Length** - For text/textarea fields
- **Min / Max** - For number fields
- **Pattern** - Regex pattern for text fields

### Step 5: Configure Display Hints (Optional)

Click the display icon on a field to set:

- **Badge** - Shows as a colored pill on item cards
- **Primary** - Primary subtitle field (shown below title)
- **Secondary** - Secondary subtitle field (fallback)

**Note:** Only one field should have `badge: true`. The badge field is excluded from detail rows.

### Step 6: Set Unique Fields (Optional)

In the **Schema Settings** panel, select which fields together must be unique. This prevents duplicate items.

**Example:** For beer, you might set `name` + `brewery` as unique fields. This allows two beers with the same name from different breweries, but prevents the exact same beer from being added twice.

### Step 7: Save

Click **"Create Schema"**. The schema is immediately available in the API and client apps.

---

## Schema Fields

### Field Keys

Field keys must be:
- Unique within the schema
- snake_case (lowercase with underscores)
- Descriptive and concise

**Good examples:** `milk_type`, `abv_percentage`, `origin_country`
**Bad examples:** `field1`, `MilkType`, `milk type`

### Reserved Keys

The following keys are reserved and handled specially:
- `name` - Stored as a first-class database column (fast queries, always required)
- `description` - Stored as a first-class column

### Field Order

Fields are displayed in forms and detail views in the order you define them. Use drag-and-drop in the schema editor to reorder.

---

## Field Types

### Text

Single-line text input.

**Best for:** Names, short labels, identifiers
**Validation:** minLength, maxLength, pattern

### Textarea

Multi-line text input.

**Best for:** Descriptions, tasting notes, long-form content
**Validation:** minLength, maxLength

### Number

Numeric input (integers or decimals).

**Best for:** Age, ABV, ratings, quantities
**Validation:** min, max
**Note:** Stored as float64 in JSON. Use `min`/`max` validation to enforce ranges.

### Select

Dropdown with predefined options.

**Best for:** Categories with a small fixed set of options
**Configuration:** Add options in the field editor (one per line)
**Example:** Style = ["IPA", "Stout", "Pilsner", "Wheat"]

### Checkbox

Boolean toggle.

**Best for:** Yes/no attributes
**Example:** Organic, Gluten-Free, In Stock
**Note:** Stored as boolean true/false in JSON.

### Enum

Similar to select but stored as string values.

**Best for:** Status fields, classifications
**Configuration:** Same as select

---

## Validation Rules

Validation is enforced server-side on every create and update.

### Required

If a field is marked as required, it must be present and non-empty in the request body.

### String Length

- **minLength** - Minimum character count
- **maxLength** - Maximum character count

**Example:** `{ "minLength": 1, "maxLength": 100 }`

### Numeric Range

- **min** - Minimum numeric value
- **max** - Maximum numeric value

**Example:** `{ "min": 0, "max": 20 }` for ABV percentage

### Pattern Matching

- **pattern** - Regular expression string

**Example:** `{ "pattern": "^[A-Z]{2}$" }` for two-letter country codes

### Select/Enum Validation

Values must match one of the predefined options. This is automatic for select and enum fields.

---

## Display Hints

Display hints control how fields render in the Flutter client app.

### Badge

```json
{ "badge": true }
```

The badge field appears as a colored pill on item cards. **Only one field should be the badge field.**

**Example:** For wine, the `color` field might be the badge, showing "Red", "White", or "Rosé" as a pill.

### Primary

```json
{ "primary": true }
```

The primary field is used as the main subtitle on item cards and in lists.

**Example:** For beer, `style` might be primary, showing "IPA" below the beer name.

### Secondary

```json
{ "secondary": true }
```

The secondary field is used as a fallback subtitle if the primary field is empty.

**Example:** For beer, `brewery` might be secondary, showing the brewery name if style is not set.

### Display Fallback Chain

The client uses this priority for subtitles:
1. Primary field value
2. Secondary field value
3. First available field value

---

## Unique Fields

Unique fields define which combination of fields must be unique across all items of that type. This prevents duplicates.

### Configuration

In the schema editor's **Settings** panel, select fields from the dropdown. You can select multiple fields for composite uniqueness.

### Examples

| Item Type | Unique Fields | Meaning |
|-----------|--------------|---------|
| Cheese | `name`, `origin` | Same name from different origins is allowed |
| Gin | `name`, `producer` | Same name from different producers is allowed |
| Wine | `name`, `producer`, `vintage` | Same wine from different years is allowed |
| Beer | `name`, `brewery` | Same name from different breweries is allowed |

### Special Case: Name Field

The `name` field is stored as a first-class database column and gets a fast-path uniqueness check. Other fields use EAV subqueries.

### Deduplication in Seeding

When bulk-importing items via the seed endpoint, unique fields are used to skip existing items automatically.

---

## Editing a Schema

1. Go to the schema list page
2. Click on a schema name to open the editor
3. Make changes to fields, validation, or settings
4. Click **"Update Schema"**

**Important:** Editing a schema creates a new version automatically. Existing items keep their original schema version for data integrity. New items use the latest version.

### What Can Be Changed

- Display name, plural name, icon, color
- Add/remove/reorder fields
- Change field types, validation, display hints
- Activate/deactivate the schema
- Change unique fields

### What Cannot Be Changed

- Schema `name` (kebab-case identifier) - this is permanent
- Existing field keys (add new fields instead)

---

## Activating and Deactivating

### Deactivate

Set **"Is Active"** to `false` in the schema editor. This:
- Hides the item type from the client app
- Prevents creating new items of this type
- Keeps existing items and ratings intact

**Use case:** Temporarily disabling an item type without data loss.

### Activate

Set **"Is Active"** back to `true`. The item type immediately reappears in the client app.

---

## Version History

Each schema update creates a new immutable version. View version history at:

```
/admin/schemas/:type/history
```

### Version Details

- **Version Number** - Incrementing integer (1, 2, 3, ...)
- **Fields Snapshot** - Complete field configuration at that version
- **Created At** - When the version was created
- **Is Active** - Whether this is the current active version

### How Versions Work

1. When you create a schema, it gets version 1
2. When you edit the schema, it gets version 2 (version 1 is preserved)
3. Existing items reference their creation version
4. New items always use the latest active version
5. Items are validated against their creation version, not the latest

This ensures data integrity: if you remove a required field in version 2, items created with version 1 still validate correctly.

---

## Deleting a Schema

**Warning:** Deleting a schema is permanent and cannot be undone.

### Requirements

- The schema must have **zero items**. If items exist, you must delete them first or deactivate the schema instead.
- You must have admin privileges.

### Steps

1. Open the schema editor
2. Click **"Delete Schema"**
3. Confirm the deletion

### Alternative: Deactivate

If you want to keep the data but hide the type, deactivate the schema instead of deleting it.

---

## Best Practices

### Planning a Schema

1. **List all fields** the item type needs
2. **Choose field types** appropriate for the data
3. **Identify required fields** (usually name + 2-3 others)
4. **Define unique fields** to prevent duplicates
5. **Pick a badge field** for visual distinction
6. **Choose primary/secondary** fields for subtitles

### Field Naming

- Use descriptive, self-documenting keys
- Be consistent with existing schemas
- Use snake_case consistently

### Validation

- Always set reasonable maxLength for text fields
- Use numeric ranges to catch data entry errors
- Mark truly required fields as required

### Unique Fields

- Always configure unique fields before seeding data
- Use the minimum set of fields that guarantees uniqueness
- Test with a few items before bulk import

### Color Selection

- Choose colors that stand out from existing types
- Ensure good contrast for accessibility
- Test in both light and dark modes

---

## Troubleshooting

### "Schema with this name already exists"

The kebab-case name must be unique across all schemas. Choose a different name.

### "Cannot delete schema with existing items"

Delete all items of this type first, or deactivate the schema instead.

### "Validation failed" when creating items

Check that:
- All required fields are present
- Field values match their types (numbers for number fields, booleans for checkboxes)
- Select/enum values match the predefined options
- String values are within minLength/maxLength

### Client not showing new schema

- Ensure the schema is active (`is_active: true`)
- The client caches schemas for 5 minutes. Force refresh or wait.
- Check the API response at `GET /api/schemas`

### Items not deduplicating during seed

- Verify `unique_fields` is configured correctly
- Ensure the seed data includes all unique fields
- Check that field values match exactly (case-sensitive)

### Schema changes not reflecting in existing items

This is by design. Existing items keep their creation schema version. Only new items use the latest version. If you need to migrate existing items, contact a developer.

---

## Related Documentation

- [API Endpoints Reference](/docs/api/endpoints.md) - Schema and item API details
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Developer guide
- [Dynamic Schema Design](/openspec/changes/dynamic-item-schema/design.md) - Technical design document
