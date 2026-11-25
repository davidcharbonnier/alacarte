# Filtering System

> **See also:** [API endpoints reference](/docs/api/endpoints.md) · [Schema management](/docs/admin/schema-management.md)

**Last Updated:** November 2026  
**Status:** Production Ready

The À la carte platform uses a **hybrid filtering architecture**: schema-driven filters and full-text search run **server-side** against the EAV database, while rating-context filters (my ratings, recommendations, has-picture) run **client-side** over the loaded item list. The same UI adapts to any item type because filter options are extracted from the item type's dynamic schema, never hardcoded.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Server-Side Filtering](#server-side-filtering)
- [Client Implementation](#client-implementation)
- [Locale-Aware Sorting](#locale-aware-sorting)
- [Rating-Context Filters](#rating-context-filters)
- [Has-Picture Filter](#has-picture-filter)
- [UX Behavior](#ux-behavior)
- [Extending the System](#extending-the-system)

---

## Architecture Overview

```
Schema (admin-defined)          Client                          Server (Go API)
┌─────────────────────┐   ┌──────────────────────────┐   ┌────────────────────────┐
│ select/enum fields  │──▶│ ItemFilterHelper          │   │ DynamicItemList        │
│ searchable flags    │   │  → filter options         │──▶│  → parseFilterParams   │
└─────────────────────┘   │ ItemSearchAndFilter (UI)  │   │  → EAVQueryBuilder     │
                          │ dynamicItemProvider       │   │  → SQL over EAV tables │
                          │  → search + filter state  │   └────────────────────────┘
                          │ DynamicItemService        │
                          │  → query string building  │
                          └──────────────────────────┘
```

Two filter layers:

| Layer | Filters | Where applied |
|-------|---------|---------------|
| Server-side | `search`, `filter[field_key]`, `filter[has_image]`, `sort` | EAV query builder (`apps/api/services/query_builder.go`) |
| Client-side | `rating_source` (personal/recommendations), `rating_status` (rated/unrated) | Over loaded items in the provider state / screen |

The `has_picture` chip bridges both worlds: it is stored in the client filter map like a rating filter but is translated to `filter[has_image]` when the request is built, so it executes server-side.

---

## Server-Side Filtering

### Endpoint

`GET /api/items/:type` (`apps/api/controllers/dynamicItemController.go`, `DynamicItemList`) — the dynamic item list endpoint registered under the `/api/items` group in `apps/api/main.go`.

### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page (max 100) |
| `sort` | string | `name ASC` | Sort field; prefix `-` for descending |
| `search` | string | - | Full-text search across searchable fields |
| `filter[field_key]` | string | - | Exact-match filter on an EAV field value |
| `filter[has_image]` | boolean | - | `true` = items with image, `false` = items without |
| `rated` | boolean | false | Restrict to items the current user rated or that are shared with them |

Full reference: [docs/api/endpoints.md — Query Parameters](/docs/api/endpoints.md).

### How It Works

`parseFilterParams` scans the query string for keys of the form `filter[...]` and collects them into a map. `filter[has_image]` is handled separately and mapped to a boolean `HasImage` flag.

`EAVQueryBuilder.BuildListQuery` (`apps/api/services/query_builder.go`) composes the SQL:

1. **Base scope** — items of the schema resolved by `:type` (schema resolved from the in-memory registry, refreshed on demand).
2. **Search** — if `search` is non-empty (lowercased), it matches items where the serialized `field_values` JSON contains the term, **or** where the item has any EAV value in a field flagged `"searchable": true`. Known gap: that EAV subquery does not compare the search term, so such items match every search.
3. **Field filters** — for each `filter[key]=value`, the field is resolved via the schema registry; unknown keys are silently skipped. String values match exactly (`value = ?`), arrays match with `IN (?)`.
4. **Has image** — `filter[has_image]=true` filters `image_url IS NOT NULL AND image_url != ''` (inverted for `false`).
5. **Sort** — `name`, `created_at`, `updated_at` sort directly on the items table; any other sortable field joins `item_field_values` on the matching schema field and sorts on the EAV value. `sort=-field` reverses direction.
6. **Pagination** — applied last (`OFFSET`/`LIMIT`), with the total count computed before pagination so the client receives `total`, `page`, `per_page`, and `total_pages`.

The response is a paginated envelope:

```json
{
  "items": [ ... ],
  "total": 42,
  "page": 1,
  "per_page": 20,
  "total_pages": 3
}
```

Because filtering happens in SQL, filters compose with pagination correctly: every page of results honors the active search and filters.

---

## Client Implementation

### Filter Option Extraction — `ItemFilterHelper`

`apps/client/lib/utils/item_filter_helper.dart`

`getAvailableFilters(ItemSchema schema)` derives the filter UI from the schema, not from the loaded items:

- Iterates `schema.fields` and collects every field of type `select` or `enum` that has a non-empty `options` list.
- Returns `Map<String, List<String>>` keyed by field key, with each option list sorted locale-aware (see [Locale-Aware Sorting](#locale-aware-sorting)).

Consequence: adding a `select` field to a schema in the admin automatically adds a filter chip in the client — no client release required. See [docs/admin/schema-management.md](/docs/admin/schema-management.md).

The helper also provides `getSearchHint(itemType)` with per-type search hints (cheese, wine, beer, coffee) and a generic fallback.

### Query String Building — `DynamicItemService`

`apps/client/lib/services/dynamic_item_service.dart`

`getItemsByType(type, {schema, page, perPage, search, filters, rated})` builds the request to `/api/items/:type`:

- `page` and `per_page` are always sent.
- `search` is sent only when non-empty.
- The filter map is translated one-to-one into `filter[key]=value` query parameters, **except** the special key `has_picture`, which is sent as `filter[has_image]`. This keeps the UI-facing concept ("has picture") decoupled from the API parameter name.
- `rated=true` is added for the "My List" tab.

### State Management — `dynamicItemProvider`

`apps/client/lib/providers/dynamic_item_provider.dart`

Filter and search state is kept **per item type** in a single `StateNotifier`:

- `searchQueriesByType` — current search text per type.
- `categoryFiltersByType` — active `key → value` filter map per type.

Mutations that change server-side filtering all trigger a reload of page 1 with `forceRefresh: true`, sending the updated `search`/`filters`:

| Method | Effect |
|--------|--------|
| `updateSearchAndLoad(type, query)` | Sets search query, reloads page 1 |
| `setCategoryFilter(type, key, value)` | Adds/removes one filter (`null` removes), reloads page 1 |
| `clearFilters(type)` | Clears search **and** all filters, reloads page 1 |
| `clearTabSpecificFilters(type)` | Removes only `rating_source` / `rating_status` (client-side filters) without reloading |

`loadMoreItems` re-sends the same `search` and `filters` with `page = current + 1`, so infinite scroll appends filtered results.

The `rated` item list (My List tab) is loaded **without** search or filters; filtering of that list happens client-side (see below).

### UI — `ItemSearchAndFilter`

`apps/client/lib/widgets/common/item_search_filter.dart`

A single reusable widget rendered above the item list in `ItemTypeScreen` (`apps/client/lib/screens/items/item_type_screen.dart`):

- **Search bar** — bound to a `TextEditingController` seeded from the provider state; every keystroke calls `onSearchChanged`. A clear button appears while a query is active.
- **Filter toggle** — collapsible chip area; the filter icon shows a **count badge** of active filters and is tinted when filters are active. Auto-expands on init if filters are already active.
- **Filter chips** — one `FilterChip` per schema select/enum field (localized labels for known keys such as `type`, `origin`, `producer`, `color`, `region`, ...). Tapping opens a `_FilterSelectionDialog` with a radio list: "All" (clears the filter) plus the schema options.
- **Rating filter chips** — appended below schema chips, tab-dependent (see [Rating-Context Filters](#rating-context-filters)).
- **Results summary** — a "showing X of Y" banner whenever a search or filter is active.

### Screen Wiring — `ItemTypeScreen`

`apps/client/lib/screens/items/item_type_screen.dart`

- `ItemFilterHelper.getAvailableFilters(schema)` feeds the chip list; `schemaProvider` supplies the schema for the current type.
- **Debounced search:** keystrokes cancel the previous `Timer` and start a new 300 ms one; only after 300 ms of inactivity does `updateSearchQuery` (→ `updateSearchAndLoad`) fire a request. The timer is cancelled in `dispose`.
- Filter changes from the widget go through `ItemProviderHelper` (`apps/client/lib/utils/item_provider_helper.dart`) into `dynamicItemProvider`.

### Two-Sided Filtering on the My List Tab

The My List tab loads items with `rated=true` (no server filters), then applies the active search and filters **client-side**:

- Search matches `item.searchableText` (case-insensitive contains).
- Category filters match `item.categories[key]` (case-insensitive equality).
- `rating_source` filters are then applied via `ItemFilterHelper.filterItemsWithRatingContext`.

Rationale: the rated set is small and personal, and `rating_source` cannot be expressed by the server-side filter API.

---

## Locale-Aware Sorting

Filter options are sorted with the `diacritic` package (`ItemFilterHelper._compareLocaleAware`):

```dart
sortedList.sort((a, b) => _compareLocaleAware(a, b));
// removeDiacritics(a).toLowerCase().compareTo(removeDiacritics(b).toLowerCase())
```

Options are compared with diacritics stripped and case folded, so `Époisses` sorts next to `Emmental` instead of after `Z`. This matters for French (É, Œ) and other accented item names in this primarily EN/FR app.

---

## Rating-Context Filters

Implemented in `ItemFilterHelper.filterItemsWithRatingContext` and applied client-side over the already-loaded items. Which filters appear depends on the active tab (`ItemSearchAndFilter.isPersonalListTab`).

### All Items tab (`rating_status`)

| Filter | Behavior |
|--------|----------|
| Rated (`has_ratings`) | Items the current user has a rating for |
| Unrated (`no_ratings`) | Items the current user has **not** rated |

Note: `has_ratings` approximates "any ratings" using only the user's own loaded ratings; it does not reflect community ratings.

### My List tab (`rating_source`)

| Filter | Behavior |
|--------|----------|
| My Ratings (`personal`) | Items the user rated themselves |
| Recommendations (`recommendations`) | Items others rated where the rating is visible to the current user (privacy model applies, see [privacy-model.md](privacy-model.md)) |

Switching tabs clears tab-specific filters (`clearTabSpecificFilters`) so a `rating_source` filter never leaks into the All Items tab and vice versa.

---

## Has-Picture Filter

A **With Picture** chip is available on both tabs:

- UI key: `has_picture` (`'true'` or removed when deselected).
- On the All Items tab it is sent to the server as `filter[has_image]=true` (or `false`) by `DynamicItemService`, so the filter runs in SQL against `image_url`.
- The client-side `filterItemsWithRatingContext` also contains a `has_picture` branch (checking `image_url` on the loaded items), used when the filter is applied to client-side-filtered lists such as the My List tab.

---

## UX Behavior

- **Pagination + filters** — infinite scroll (list within 200 px of the bottom triggers `loadMoreItems`) requests the next page with the same search and filters; the server applies filters before paginating, so no results are skipped or duplicated. A spinner or "All items loaded" row terminates the list.
- **Pull-to-refresh** — the All Items tab refresh clears community stats and ratings caches, refreshes the schema, reloads items (respecting active filters), and invalidates stats providers. My List refreshes the rated item list and ratings.
- **Filter state per item type** — switching item types via the app-bar switcher does not clear filters: each type keeps its own search query and filter map in the provider.
- **No results** — when filters/search produce an empty list, a dedicated state offers a **Clear all filters** button instead of the plain empty state.
- **Result counts** — the summary line compares filtered count against the server `total` (All Items tab) or the locally counted set (My List tab).
- **Debounce** — 300 ms between last keystroke and request, avoiding a request per character.

---

## Extending the System

- **New filterable field:** add a `select`/`enum` field with options to the schema in the admin ([schema-management.md](/docs/admin/schema-management.md)). The client picks it up automatically; the server filters on any known field key.
- **Searchable field:** the search matches the serialized `field_values` JSON; see the known gap above before relying on `"searchable": true`.
- **New client-only filter:** add a chip in `ItemSearchAndFilter._buildRatingFilters`, a case in `ItemFilterHelper.filterItemsWithRatingContext`, and tab-clear behavior in `clearTabSpecificFilters` if it is tab-specific.
- **New server-side filter:** extend `parseFilterParams` / `QueryParams` in the API and the matching branch in `EAVQueryBuilder.BuildListQuery`; document it in [endpoints.md](/docs/api/endpoints.md).

## Related Documents

- [docs/api/endpoints.md](/docs/api/endpoints.md) — query parameter reference and response envelope
- [docs/admin/schema-management.md](/docs/admin/schema-management.md) — defining the fields that drive filters
- [docs/features/privacy-model.md](privacy-model.md) — visibility rules behind the recommendations filter
- [docs/features/rating-system.md](rating-system.md) — rating data the context filters operate on
