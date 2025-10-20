# Cache Management

## Overview

The Flutter client uses a **two-level caching strategy** for optimal performance:
1. **Data Cache** - API response data stored in memory
2. **Image Cache** - Image files stored on disk

Both are managed through a combination of **bulk clearing** (for refresh operations) and **granular clearing** (for single item updates).

---

## Architecture

### Data Cache (In-Memory)

**Location**: `ItemService` classes (Cheese/Gin/Wine)

**What's Cached**:
- API response: `List<CheeseItem>` / `List<GinItem>` / `List<WineItem>`
- Cache expiry: 5 minutes
- Stored in: `_cachedResponse` field

**Clearing Strategy**:
```dart
// Bulk clear - clears ALL data + ALL images
await itemService.clearCache();

// Granular - invalidate specific item
itemProvider.invalidateItem(itemId); // Removes from state
```

### Image Cache (On-Disk)

**Location**: Managed by `flutter_cache_manager` (DefaultCacheManager)

**What's Cached**:
- Downloaded image files from backend
- No expiry (manual eviction only)
- Stored in: App's cache directory

**Clearing Strategy**:
```dart
// Bulk clear - clears ALL images
await DefaultCacheManager().emptyCache();

// Granular - clears ONE image
await DefaultCacheManager().removeFile(imageUrl);
```

---

## Cache Strategies

### Strategy 1: Bulk Clear (Used for Refresh Operations)

**When Used**:
- Pull-to-refresh on item list
- Item creation
- Item update (data only, not image)

**What Happens**:
```dart
// 1. Clear ALL data cache + ALL image cache
await itemService.clearCache();

// 2. Fetch ALL items from API
await itemService.getAllItems();
```

**Benefits**:
- ✅ Simple and reliable
- ✅ Guarantees fresh state everywhere
- ✅ No edge cases

**Trade-offs**:
- ❌ Clears everything (even unchanged items)
- ❌ Multiple API calls
- ✅ But fast enough with HTTP/2 multiplexing

### Strategy 2: Granular Clear (Used for Single Item Operations)

**When Used**:
- Image upload/delete for single item
- Pull-to-refresh on item detail screen

**What Happens**:
```dart
// 1. Clear ONLY this item's image
await DefaultCacheManager().removeFile(oldImageUrl);

// 2. Invalidate ONLY this item from provider state
itemProvider.invalidateItem(itemId);

// 3. Reload ONLY this item from API
await loadSpecificItems([itemId]);
```

**Benefits**:
- ✅ Efficient - only touches what changed
- ✅ Fast - single API call
- ✅ Scales well (1000+ items)

**Trade-offs**:
- ❌ Slightly more complex (3 steps)
- ✅ But worth it for single-item operations

---

## Implementation Details

### Bulk Clear Implementation

**In ItemService** (`apps/client/lib/services/item_service.dart`):
```dart
class CheeseItemService extends ItemService<CheeseItem> {
  ApiResponse<List<CheeseItem>>? _cachedResponse;
  DateTime? _cacheTime;
  
  Future<void> clearCache() async {
    // Clear data cache
    _cachedResponse = null;
    _cacheTime = null;
    
    // Clear ALL image cache
    await DefaultCacheManager().emptyCache();
  }
}
```

**In ItemProvider** (`apps/client/lib/providers/item_provider.dart`):
```dart
Future<void> refreshItems() async {
  // Clear both data and images
  await itemService.clearCache();
  
  // Fetch fresh data
  final response = await itemService.getAllItems();
  // Update state...
}
```

### Granular Clear Implementation

**In ItemProvider** (`apps/client/lib/providers/item_provider.dart`):
```dart
void invalidateItem(int itemId) {
  // Remove item from provider state
  final updatedItems = state.items.where((i) => i.id != itemId).toList();
  state = state.copyWith(items: updatedItems);
}
```

**In Form** (`apps/client/lib/forms/generic_item_form_screen.dart`):
```dart
// After successful image upload
if (imageUrl != null) {
  // 1. Clear old image
  if (oldImageUrl != null) {
    await DefaultCacheManager().removeFile(oldImageUrl);
  }
  
  // 2. Invalidate item from state
  ItemProviderHelper.invalidateItem(ref, itemType, itemId);
  
  // 3. Reload this item
  await ItemProviderHelper.loadSpecificItems(ref, itemType, [itemId]);
}
```

**In Detail Screen** (`apps/client/lib/screens/items/item_detail_screen.dart`):
```dart
Future<void> _refreshItemData() async {
  // 1. Clear this item's image
  if (imageUrl != null) {
    await DefaultCacheManager().removeFile(imageUrl);
  }
  
  // 2. Invalidate from state
  ItemProviderHelper.invalidateItem(ref, itemType, itemId);
  
  // 3. Reload from API
  await ItemProviderHelper.loadSpecificItems(ref, itemType, [itemId]);
  
  // 4. Refresh local state
  await _loadItemData();
}
```

---

## When Each Strategy is Used

| Operation | Strategy | What's Cleared | What's Reloaded |
|-----------|----------|----------------|-----------------|
| **Pull-to-refresh (list)** | Bulk | ALL data + ALL images | ALL items |
| **Pull-to-refresh (detail)** | Granular | 1 item's image | 1 item |
| **Item creation** | Bulk | ALL data + ALL images | ALL items |
| **Item update (data)** | Bulk | ALL data + ALL images | ALL items |
| **Image upload** | Granular | 1 item's image | 1 item |
| **Image delete** | Granular | 1 item's image | 1 item |

---

## Cache Flow Examples

### Example 1: User Uploads Image for Cheese #5

```
1. User edits cheese #5, uploads new image
2. Form: Clear cheese #5's old image from cache
3. Form: Invalidate cheese #5 from provider state
4. Form: Reload cheese #5 from API (with new image URL)
5. Navigate back to detail screen
6. Detail screen: Loads cheese #5 from provider state ✅
7. Image widget: Loads new image (old one was cleared) ✅
8. Navigate to cheese list
9. List: Shows cheese #5 with new image ✅
```

### Example 2: Pull-to-Refresh on Cheese List

```
1. User pulls down on cheese list
2. Provider: Clear ALL data cache + ALL image cache
3. Provider: Fetch ALL cheeses from API
4. List: Displays all fresh data ✅
```

### Example 3: Pull-to-Refresh on Cheese #5 Detail

```
1. User pulls down on cheese #5 detail screen
2. Screen: Clear cheese #5's image from cache
3. Screen: Invalidate cheese #5 from provider state
4. Screen: Reload cheese #5 from API
5. Screen: Display fresh data ✅
6. Navigate to list
7. List: Cheese #5 is present (was reloaded) ✅
```

---

## Key Components

### Files Involved

1. **ItemService** (`apps/client/lib/services/item_service.dart`)
   - `clearCache()` - Bulk clear method
   - Clears data cache + ALL images

2. **ItemProvider** (`apps/client/lib/providers/item_provider.dart`)
   - `refreshItems()` - Calls clearCache(), reloads all
   - `invalidateItem(id)` - Removes specific item from state
   - `loadSpecificItems([ids])` - Reloads specific items

3. **ItemProviderHelper** (`apps/client/lib/utils/item_provider_helper.dart`)
   - Wrapper methods for type-agnostic access
   - `refreshItems()` - Bulk refresh
   - `invalidateItem()` - Granular invalidation
   - `loadSpecificItems()` - Granular reload

4. **ItemImage Widget** (`apps/client/lib/widgets/items/item_image.dart`)
   - Uses `CachedNetworkImage`
   - Automatic loading/error states
   - Fetches from cache or network

### Helper Utilities

**Clear specific image**:
```dart
await DefaultCacheManager().removeFile(imageUrl);
```

**Clear all images**:
```dart
await DefaultCacheManager().emptyCache();
```

**Invalidate item from state**:
```dart
ItemProviderHelper.invalidateItem(ref, itemType, itemId);
```

**Reload specific item**:
```dart
await ItemProviderHelper.loadSpecificItems(ref, itemType, [itemId]);
```

---

## Performance Characteristics

### Bulk Clear

| Metric | Value |
|--------|-------|
| API Calls | 1 (getAllItems) |
| Items Cleared | ALL (e.g., 100 items) |
| Images Cleared | ALL (e.g., 100 images) |
| Time | ~200-500ms (HTTP/2 multiplexing) |

### Granular Clear

| Metric | Value |
|--------|-------|
| API Calls | 1 (getItemById) |
| Items Cleared | 1 |
| Images Cleared | 1 |
| Time | ~50-100ms |

**Efficiency Gain**: ~5-10x faster for single item operations

---

## Testing

### Test Bulk Clear

```bash
cd apps/client
flutter run -d linux
```

1. Go to cheese list
2. Pull down to refresh
3. ✅ Verify: All images reload
4. Check network tab: Single API call for all items

### Test Granular Clear

1. Edit cheese #5, upload new image
2. Save
3. ✅ Verify: New image appears immediately
4. Go to cheese list
5. ✅ Verify: Cheese #5 has new image
6. ✅ Verify: Other cheeses unchanged (no reload)
7. Pull-to-refresh on cheese #5 detail
8. ✅ Verify: Image reloads
9. Go to list
10. ✅ Verify: Cheese #5 still in list

---

## Future Optimizations

### Potential Improvements

1. **Smarter Bulk Clear**
   - Only clear images for items currently in view
   - Keep off-screen images cached

2. **Cache Size Limits**
   - Implement max cache size (e.g., 100MB)
   - LRU eviction for old images

3. **Preemptive Loading**
   - Prefetch images for next/previous items
   - Background refresh for stale data

4. **Cache Analytics**
   - Track hit/miss rates
   - Optimize based on usage patterns

### When to Optimize

Current approach is fine unless:
- App has 1000+ items per type
- Users complain about slow list scrolling
- Mobile data usage is excessive
- Cache directory grows too large (>500MB)

---

## Dependencies

```yaml
dependencies:
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1
```

---

## Troubleshooting

### Images not updating after edit

**Symptom**: Old image still shows after upload
**Cause**: Image cache not cleared
**Fix**: Check that `DefaultCacheManager().removeFile()` is called

### Item missing from list after update

**Symptom**: Item disappears after image upload
**Cause**: Item invalidated but not reloaded
**Fix**: Ensure `loadSpecificItems()` is called after `invalidateItem()`

### Slow pull-to-refresh

**Symptom**: List takes 2+ seconds to refresh
**Cause**: Too many items, bulk clear overhead
**Fix**: Consider paginated loading or virtual scrolling

---

## Summary

**Two strategies for two scenarios**:

1. ✅ **Bulk Clear** - Simple, reliable, used for list refresh
2. ✅ **Granular Clear** - Efficient, fast, used for single item operations

**Best of both worlds**:
- Simple where it matters (user-initiated refresh)
- Efficient where it counts (background operations)
- Scales to production use cases
