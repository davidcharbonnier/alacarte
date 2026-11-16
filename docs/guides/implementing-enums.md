# Implementing Enums for Item Fields

**Last Updated:** November 2026
**Status:** ✅ Dynamic Schema System Active

This guide shows how to add an enum/select field (a dropdown with a fixed set of valid values) to any item type. The dynamic schema system supports enum fields end-to-end — admin, API, and Flutter client — with no code changes.

**Example:** Wine color (Rouge, Blanc, Rosé, Mousseux, Orange)

---

## 🎯 When to Use an Enum Field

Use `select` or `enum` for fields that:
- Have a fixed set of valid values (color, style, type, size)
- Should be enforced at the API level (values are validated server-side against the schema)
- Need dropdown selection in the item form
- Should appear as a filter chip in the client

**Examples:** wine color, cheese type, beer style, ABV category, chili heat level.

---

## 📋 How to Add an Enum/Select Field

### Step 1: Define the Field in the Admin Schema Editor

Open the schema for the item type in the admin panel (Schemas → item type). The field editor lets you set, per field:

| Property | UI control | Notes |
|---|---|---|
| `key` | Text field | Machine name, e.g. `color` |
| `label` | Text field | Display name, e.g. `Color` |
| `field_type` | Dropdown | Choose `Select` or `Enum` |
| `group` | Text field | Optional; groups fields in forms and detail views |
| `required` | Checkbox | Enforced server-side |
| `order` | Up/down arrows | Position within the form |

Both `select` and `enum` behave identically end-to-end (see Step 3); prefer `select` for new fields.

**Important:** the admin editor does **not** yet expose an options editor. Options are preserved on save but can only be set via the API payload (Step 2). The same applies to `validation` and `display` hints.

### Step 2: Provide Options via the API

Create or update the schema with the field's options as a JSON array of strings:

```http
POST /admin/schemas        # create
PUT  /admin/schemas/:type  # update
Authorization: Bearer ADMIN_JWT
```

```json
{
  "fields": [
    {
      "key": "color",
      "label": "Color",
      "field_type": "select",
      "required": true,
      "group": "Characteristics",
      "options": ["Rouge", "Blanc", "Rosé", "Mousseux", "Orange"],
      "display": { "badge": true }
    }
  ]
}
```

Notes:
- The API also accepts `{ "value": "...", "label": "..." }` objects in the options array, but only the `value` is stored — options are plain strings end-to-end.
- `select`/`enum` values are validated server-side on every item create and update: the submitted value must match one of the field's options, otherwise the request returns `400` with field-level details. No controller code needed.
- A schema update creates a new immutable schema version automatically. Existing items keep their creation version, so adding an option never invalidates old data. Optionally validate existing items against the new version with `POST /admin/items/:type/validate`.
- Reference: [docs/api/endpoints.md](/docs/api/endpoints.md) (schema section) and [docs/admin/schema-management.md](/docs/admin/schema-management.md).

### Step 3: Client Rendering (Automatic)

**Item form** — the Flutter client renders any field of type `select` or `enum` as a `DropdownButtonFormField` populated from the schema's `options` (`lib/widgets/forms/dynamic_form.dart`, `_buildSelectField`/`_buildEnumField`; enum delegates to the select builder). Users cannot enter values outside the options list.

**Detail views** — display hints control placement: `badge: true` shows the value as a colored pill on item cards, `primary`/`secondary` control heading placement (see [docs/admin/schema-management.md](/docs/admin/schema-management.md)).

**Filters** — every `select`/`enum` field with a non-empty options list automatically becomes a filter chip in the client list view (`ItemFilterHelper` extracts options from the schema; filtering runs server-side against the EAV database). Adding the field to the schema adds the filter with no client release. See [docs/features/filtering-system.md](/docs/features/filtering-system.md).

---

## 💡 Design Notes

### Values vs Display Labels

Options are stored and transmitted as plain strings — there is no per-option label or localization layer. Two ways to handle a multilingual audience:

**Option 1: Culture-neutral values (recommended)**
Use values that read the same in EN and FR, e.g. `Rouge, Blanc, Rosé` (SAQ standard for wine). Display and data stay in sync; no ambiguity.

**Option 2: Language-neutral keys**
Store keys like `red`, `white` and localize at display time. This requires client-side localization logic keyed off the value — only worth it if the options are user-facing categories that must translate. The schema system does not localize options for you.

### Enum/Select vs Free-Text String

**Select/enum pros:**
- ✅ Server-side validation — invalid values rejected with `400`
- ✅ Dropdown UI — no typos, no free-text drift
- ✅ Automatic filter chips per option
- ✅ Change options anytime via schema update, no migration

**Select/enum cons:**
- ❌ Adding a value requires a schema update (admin/API, not a code change)
- ❌ Not suitable for open-ended values (producers, regions) — use `text`
- ❌ Existing items are not re-validated when options change; renamed options leave stale values in old items

**Use select/enum when:** values are a small, stable controlled vocabulary used for categorization and filtering.
**Use text when:** values are user-defined, open-ended, or frequently changing.

### Migration Strategy

- **New item types:** define select/enum fields from day one — nothing to migrate.
- **Existing items and changed options:** old items keep their creation schema version and are never re-validated, so adding options is always safe. If you narrow options or rename values, decide whether stale values in old items are acceptable, re-map them if not, then optionally re-validate with `POST /admin/items/:type/validate`.

---

## 📚 Related Documentation

- [Adding New Item Types](adding-new-item-types.md) — full walkthrough for creating a new item type
- [Schema Management](../admin/schema-management.md) — admin-side field types, validation rules, display hints
- [API Endpoints](../api/endpoints.md) — schema payload reference
- [Filtering System](../features/filtering-system.md) — how schema options become filter chips

---

**Last Updated:** November 2026
