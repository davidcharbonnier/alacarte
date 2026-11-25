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

1. Log in to the admin SPA (served at the host root)
2. Navigate to **Schemas** in the sidebar (`/schemas`)
3. The schema list page shows all schemas with item counts

---

## Creating a New Schema

### Step 1: Create the Schema

Click **"Create schema"** on the schema list page. A small dialog asks for the settings below; submitting it creates an **empty schema** (no fields) that is already active and visible in the API. Fields are added in the next steps.

### Step 2: Schema Settings (in the create dialog)

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Unique kebab-case identifier (cannot change later) | `craft-beer` |
| **Display Name** | Human-readable singular name | `Craft Beer` |
| **Plural Name** | Human-readable plural name | `Craft Beers` |
| **Icon** | Icon from the admin icon picker (stored as the MUI icon name) | `SportsBar` (shown as "Beer") |
| **Color** | Pick a color from the dialog's swatch palette (stored as hex) | a swatch such as orange |

**Important:** The `name` field must be unique and use kebab-case (lowercase with hyphens). This becomes part of the API URL: `/api/items/craft-beer`.

### Step 3: Add Fields

Open the schema (click its row on the list page), go to the **Fields** tab and click **"Add Field"** for each field, then **"Save fields"**:

| Property | Description |
|----------|-------------|
| **Key** | Machine-readable identifier (snake_case) |
| **Label** | Human-readable label shown in forms |
| **Field Type** | One of: text, textarea, number, select, checkbox, enum |
| **Required** | Whether the field is mandatory |
| **Group** | Optional group name (max 50 chars) to group fields in forms/views |
| **Order** | Display order in forms and detail views (up/down arrows) |

### Step 4: Validation, Options and Display Hints (API-level)

The schema editor UI does not expose editing for validation rules, select/enum options, or display hints — new fields get empty defaults. To set them, include them in the field objects of the schema API payload (`PUT /admin/schemas/:type` — see the field structure in [API endpoints](/docs/api/endpoints.md)):

- **Validation** — `minLength`/`maxLength` (text/textarea), `min`/`max` (number), `pattern` (regex, text)
- **Options** — predefined values for select/enum fields
- **Display hints** — `badge` (colored pill on item cards), `primary`/`secondary` (subtitle fields)

**Note:** Only one field should have `badge: true`. The badge field is excluded from detail rows.

### Step 5: Set Unique Fields (Optional)

In the **Settings** tab, select which fields together must be unique. This prevents duplicate items.

**Example:** For beer, you might set `name` + `brewery` as unique fields. This allows two beers with the same name from different breweries, but prevents the exact same beer from being added twice.

### Step 6: Save

Click **"Save Settings"** (and **"Save fields"** for field changes). Saved changes are immediately available in the API and client apps.

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

### Field Order

Fields are displayed in forms and detail views in the order you define them. Reorder with the up/down arrows in the schema editor.

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
**Configuration:** Options are not editable in the admin UI; set them in the schema API payload (see Step 4)
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
3. Make changes to fields or settings (validation, options and display hints are API-only, see Step 4 above)
4. Click **"Save fields"** (Fields tab) or **"Save Settings"** (Settings tab)

**Important:** Editing a schema creates a new version automatically. The creation version is stored on items for reference, but items are always validated against the latest active schema.

### What Can Be Changed

- Display name, plural name, icon, color
- Add/remove/reorder fields
- Change field types
- Activate/deactivate the schema
- Change unique fields

### What Cannot Be Changed

- Schema `name` (kebab-case identifier) - this is permanent
- Existing field keys: the UI does not block editing a key, but existing items store values under the old key, so add a new field instead

---

## Activating and Deactivating

### Deactivate

Click **Deactivate** at the top right of the schema editor. This:
- Hides the item type from the client app
- Prevents creating new items of this type
- Keeps existing items and ratings intact

**Use case:** Temporarily disabling an item type without data loss.

### Activate

Click **Activate** in the same place. The item type immediately reappears in the client app.

---

## Version History

Version history is shown in the schema editor's history tab (`/schemas/:type`) and served by the API at `GET /admin/schemas/:type/versions/:version`. Versions come embedded in `GET /api/schemas/:type`.

### Version Details

- **Version Number** - Incrementing integer (1, 2, 3, ...)
- **Fields Snapshot** - Complete field configuration at that version
- **Created At** - When the version was created
- **Is Active** - Whether this is the current active version

### How Versions Work

1. When you create a schema, it gets version 1
2. Only edits that change fields create a new version (metadata-only edits like display name or icon skip versioning)
3. Old versions are preserved immutable
4. **Items are always validated against the latest active schema** — not their creation version. The creation version is stored on items for reference but never consulted at validation time.

This means removing or tightening a field's rules applies to validation of all future writes, including updates to items created under older versions.

---

## Deleting a Schema

**Warning:** Deleting a schema is permanent and cannot be undone.

### Requirements

- The schema must have **zero items**. If items exist, you must delete them first or deactivate the schema instead.
- You must have admin privileges.

### Steps

1. On the schema list page, click the trash icon on the schema's row
2. Confirm the deletion (the confirmation text mentions "and all its items", but the API refuses to delete a schema that still has items)

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

Items are validated against the latest active schema, not their creation version. Existing item data is not rewritten; if you need to migrate it, contact a developer.

---

## Related Documentation

- [API Endpoints Reference](/docs/api/endpoints.md) - Schema and item API details
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Developer guide
