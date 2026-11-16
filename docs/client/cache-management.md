# Cache Management

> **Schema cache contract (ETag, TTL, versioning) and offline behavior live in [/docs/features/](/docs/features/).** This doc covers how the Flutter client caches data and images, and how refresh and eviction work.

**Last Updated:** November 2026  
**Related Documentation:**
- [Offline Handling](/docs/features/offline-handling.md)
- [Rating System](/docs/features/rating-system.md)
- [Image Upload](/docs/features/image-upload.md)
- [Client Architecture](/docs/client/architecture/)

---

## Overview

The Flutter client has **no dedicated data cache layer**. Freshness is managed by three independent mechanisms:

1. **Riverpod state** — item lists held in memory per type (`DynamicItemProvider`); "cache" means "already loaded, skip refetch"
2. **Service-level in-memory caches** — schema cache and community stats cache, each with a 5-minute TTL
3. **Image disk cache** — `cached_network_image` (^3.4.1), with explicit eviction on image replacement/deletion

On the API side, schema responses carry an `ETag` and `Cache-Control: public, max-age=300`.

**There is no `flutter_cache_manager` dependency and no persisted data cache.** Restarting the app always refetches item lists and schemas.

---

## What Is Cached, and Where

### 1. Item Lists — Riverpod State (Memory Only)

**Location**: `apps/client/lib/providers/dynamic_item_provider.dart`  
**Helpers**: `apps/client/lib/utils/item_provider_helper.dart`

`DynamicItemState` holds per-type maps:

- `itemsByType` — item lists per schema type
- `userRatedItemsByType` — the user's rated items per type
- pagination state (`totalByType`, `currentPageByType`, `totalPagesByType`, ...)
- loading/error flags per type
- search queries and category filters per type

`loadItems(type, {forceRefresh})` skips the network when all of these hold:

- `!forceRefresh`
- `state.hasLoadedOnce` (at least one successful load this session)
- `state.hasItems(type)` (the list is non-empty)

Otherwise it fetches page 1 (with current search/filter values) and replaces the list. There is **no TTL on item state** — the list lives as long as the provider does (app session), and any pull-to-refresh forces a refetch.

Screens never touch the notifier directly; they go through `ItemProviderHelper` static wrappers (`refreshItems`, `loadMoreItems`, `invalidateItem`, `loadSpecificItems`).

### 2. Schema Cache — In-Memory, 5-Minute TTL + ETag

**Location**: `apps/client/lib/services/schema_service.dart` (`SchemaService` singleton)  
**Exposed via**: `schemaProvider` (`lib/providers/schema_provider.dart`)

`SchemaService` keeps three per-schema maps:

- `_schemaCache` — parsed `ItemSchema` objects keyed by schema name
- `_cacheTimestamp` — when each entry was fetched
- `_etagCache` — the `ETag` header from the last response

Behavior:

- `fetchSchemas({forceRefresh})` / `fetchSchema(type, {forceRefresh})` return cached entries while every entry is younger than `_cacheExpiry` (5 minutes); otherwise fetch from `/api/schemas`
- `forceRefresh: true` bypasses the TTL check (`refreshSchemas()` / `refreshSchema(type)` are the force variants)
- `clearCache()` empties all three maps

**ETag note:** the API sends `ETag` on schema responses and honors `If-None-Match` with a `304` (see API side below). The client *stores* the ETag in `_etagCache` but does **not yet send `If-None-Match`** — client-side revalidation is purely TTL-based. Sending it is the natural next step if schema traffic becomes a concern.

### 3. Community Stats Cache — In-Memory, 5-Minute TTL

**Location**: `apps/client/lib/services/api_service.dart` (`_communityStatsCache`)

Per-item community stats (`/api/items/{type}/{id}/stats`) cached for 5 minutes, keyed by item. Cleared wholesale via `clearCommunityStatsCache()` on pull-to-refresh, or per-provider via `ref.invalidate(communityStatsProvider)`.

### 4. Ratings Cache — In-Memory, 5-Minute TTL

**Location**: `apps/client/lib/services/rating_service.dart`

Ratings cached per viewer (`_ratingsByViewerCache`, keyed by viewer id, 5-minute expiry). `clearCache({viewerId})` clears one viewer's entries or all. Called after rating changes — see [Rating System](/docs/features/rating-system.md).

### 5. Image Cache — Disk, via `cached_network_image`

**Location**: `apps/client/lib/widgets/items/item_image.dart` (all item images render through `CachedNetworkImage`)

- `cached_network_image` ^3.4.1 backs onto `DefaultCacheManager` — files persist across app restarts (unlike all in-memory caches above)
- No custom `stalePeriod` or cache-size configuration; package defaults apply
- Eviction is **explicit and targeted** — see [Image Cache Eviction](#image-cache-eviction)

### 6. API-Side Schema Cache (for context)

The API (`apps/api/services/schema_registry.go`) keeps an in-memory `SchemaRegistry` of `CachedSchema` entries with a `VersionHash`. `GET /api/schemas/{type}` returns:

- `ETag: <VersionHash>`
- `Cache-Control: public, max-age=300`
- `304 Not Modified` when the request carries a matching `If-None-Match`

So even without client-side cooperation, CDN/HTTP-layer caching covers 5 minutes per schema.

---

## How Refresh Works

### Pull-to-Refresh: Home Screen

`home_screen.dart` refreshes the global view:

```dart
onRefresh: () async {
  await ref.read(schemaProvider.notifier).refreshSchemas(); // forceRefresh
  _hasLoadedStats = false;
  _loadTypeStats();
  await ref.read(ratingProvider.notifier).refreshRatings();
}
```

### Pull-to-Refresh: Item Type Screen

`item_type_screen.dart` refreshes one type — full cache sweep:

```dart
onRefresh: () async {
  apiService.clearCommunityStatsCache();     // all stats
  ratingService.clearCache();                // all ratings
  await ref.read(schemaProvider.notifier).refreshSchema(widget.itemType);
  await ItemProviderHelper.refreshItems(ref, widget.itemType);
  ref.read(ratingProvider.notifier).refreshRatings();
  ref.invalidate(communityStatsProvider);
}
```

`ItemProviderHelper.refreshItems` → `DynamicItemNotifier.refreshItems(type)` → `loadItems(type, forceRefresh: true)`, which refetches page 1 with the current search query and filters and replaces the list. Pagination state resets to page 1.

### Pull-to-Refresh: Item Detail Screen

`item_detail_screen.dart` (`_refreshItemData`) does a **granular** refresh for a single item:

1. Evict the item's image from the disk cache (`CachedNetworkImage.evictFromCache`)
2. Invalidate the item in provider state (`ItemProviderHelper.invalidateItem`)
3. Reload the item via `loadSpecificItems` → `getItemById` → `addItem` (merges back into the list)
4. Reload local screen state

### User-Rated Tabs

The "My ratings" tabs in `item_type_screen.dart` refresh via `ItemProviderHelper.refreshUserRatedItems`, which clears the list/pagination state and reloads from scratch.

### Force-Refresh Triggers (Summary)

| Trigger | What refreshes |
|---|---|
| Pull-to-refresh (home) | Schemas (all), stats, ratings |
| Pull-to-refresh (item type) | Stats cache, ratings cache, schema (type), items (type, force) |
| Pull-to-refresh (item detail) | Single item: image evict + state invalidate + refetch |
| Search / filter change | `loadItems(forceRefresh: true)` with new query/filters |
| Item create/update/delete | Provider state updated in place; pagination reset |

---

## Image Cache Eviction

Images are only evicted explicitly — `cached_network_image` never invalidates on its own. The eviction points:

**`dynamic_item_form_screen.dart`** (edit mode):

- Before saving: if the user deleted the image, `CachedNetworkImage.evictFromCache(_oldImageUrl)` after the API delete succeeds
- After upload: if the image was replaced, evict the old URL so the new one (possibly same URL with different content) is refetched

**`item_detail_screen.dart`** (`_refreshItemData`):

- Evicts the current item's image before refetching the item, so a changed image shows fresh

**Rule of thumb:** any time an image at a known URL can change or disappear server-side, call `CachedNetworkImage.evictFromCache(url)` for the old URL. If a URL ever points to changing content (e.g. same URL re-uploaded), eviction must happen on both replace and delete paths.

---

## Offline Behavior

The client has **no offline data cache for items** — offline, previously loaded Riverpod state may still render, but nothing is persisted or revalidated. What does happen offline:

- Requests fail gracefully into per-type error state (`errorsByType`); screens show error UI with retry
- When connectivity is restored, the auth provider revalidates the session via `/api/user/me` and data loads resume normally — no manual refresh needed

Details, including the connectivity provider and revalidation flow: [Offline Handling](/docs/features/offline-handling.md). That doc also sketches a future `OfflineCache` class (persisting ratings/items); it is not implemented — today's only persistent cache is images.

---

## Guidance

**When adding a new screen or feature:**

- Read items through `ItemProviderHelper`, not the notifier directly
- Pull-to-refresh must call the force variants (`refreshItems`, `refreshSchema(s)`, `refreshRatings`) and clear any service cache the screen reads (stats, ratings)
- If your feature caches responses in memory, follow the existing pattern: singleton service, `Map` cache + timestamp map, `static const Duration _cacheExpiry = Duration(minutes: 5)`, force-refresh parameter, `clearCache()`

**When changing items or images:**

- Mutations update provider state in place (`addItem` / `updateItem` / `invalidateItem`) — do not drop the whole list for a single-item change
- Always evict replaced or deleted images: `CachedNetworkImage.evictFromCache(oldUrl)`

**When adding a new item type:**

- Nothing cache-specific is needed — types are dynamic; the schema cache and provider state are keyed by type name automatically

**Known limitation:** the client stores schema ETags but never sends `If-None-Match`, so schema revalidation is TTL-only. If schema changes need to appear faster than 5 minutes without pull-to-refresh, wire `_etagCache` into a conditional request.
