# Filtering System Documentation

## Overview

The A la carte app features a sophisticated, mobile-friendly filtering system that enables users to efficiently search and filter items across different contexts. The system is built with a generic architecture that supports any item type while providing context-aware filtering options.

## Architecture

### Core Components

```
FilteringSystem/
├── ItemSearchAndFilter (Widget)      # Main UI component with collapsible interface
├── ItemFilterHelper (Utility)        # Generic filtering logic for rating context
├── ItemProvider (State Management)   # Filter state and persistence
└── Localization Support             # Full French/English translations
```

### Design Philosophy

**Generic & Extensible**
- Single implementation works for cheese, wine, beer, coffee, etc.
- Type-safe filtering with compile-time guarantees
- Zero refactoring needed to add new item types

**Context-Aware**
- Different filter options per tab (All Items vs Personal List)
- Smart filter persistence (universal filters persist, tab-specific filters clear)
- Adaptive UI based on available data

**Mobile-First**
- Collapsible interface saves 70% screen space when collapsed
- Touch-friendly controls with proper spacing
- Progressive disclosure of advanced options

## User Interface

### Collapsible Filter Panel

**Collapsed State (Default)**
```
[🔍 Search cheeses by name...] [🔧] [❌]
[Showing 5 of 38 items]
```

**Expanded State (When filter button tapped)**
```
[🔍 Search cheeses by name...] [🔧²] [❌]
[Type] [Origin] [Producer] [My Ratings] [Recommendations]
[Showing 5 of 38 items]
```

### Visual Indicators

**Filter Button States:**
- **Inactive**: Gray outline filter icon
- **Active with filters**: Purple filled filter icon + red count badge
- **Expanded**: Filter icon shows current state

**Filter Count Badge:**
- Red circular badge showing number of active filters
- Positioned on top-right of filter button
- Only appears when filters are active

**Clear Filters Button:**
- Uses `Icons.filter_alt_off` (filter icon with slash)
- Red color indicates removal action
- Only appears when filters are active
- Direct access without expanding filters

## Filter Types

### Universal Filters (Persist Across Tabs)

**1. Text Search**
- **Scope**: Name field only (simplified from multi-field search)
- **Behavior**: Case-insensitive partial matching
- **Example**: "cheddar" finds "Sharp Cheddar", "Cheddar Aged"
- **Localization**: 
  - EN: "Search cheeses by name..."
  - FR: "Rechercher fromages par nom..."

**2. Category Filters**
- **Type**: Hard, Soft, Semi-soft, Blue, etc.
- **Origin**: France, Switzerland, Canada, etc.
- **Producer**: Specific cheese makers
- **Dynamic**: Options populated from actual data
- **Interface**: Dialog with radio buttons (All + specific values)

### Context-Specific Filters (Tab-Specific)

**All Items Tab:**
- **"Rated"**: Items you have rated (discovery context)
- **"Unrated"**: Items you haven't rated yet (discovery context)
- **Purpose**: Help users find new items to rate or revisit rated items

**Personal List Tab:**
- **"My Ratings"**: Items you've personally rated
- **"Recommendations"**: Items others have recommended to you
- **Purpose**: Separate your ratings from friend recommendations

## Smart Filter Persistence

### Behavior Rules

**When Switching Tabs:**
- **✅ Preserved**: Search query, Type, Origin, Producer filters
- **❌ Cleared**: My Ratings, Recommendations, Rated, Unrated filters
- **Reason**: Universal filters apply to both contexts, tab-specific filters don't

**Auto-Expansion Logic:**
- **Collapsed by default**: Clean interface, saves space
- **Auto-expands**: When filters are already active (so users can see what's applied)
- **Manual toggle**: Users can expand/collapse at any time

### Filter State Management

**Provider Level:**
```dart
class ItemState<T> {
  final String searchQuery;           // Persists across tabs
  final Map<String, String> categoryFilters; // Mixed persistence
  // categoryFilters['type'] -> Persists
  // categoryFilters['rating_source'] -> Cleared on tab switch
}
```

**Tab Change Handler:**
```dart
void _onTabChanged() {
  // Automatically remove rating-based filters
  provider.clearTabSpecificFilters();
}
```

## Technical Implementation

### Generic Architecture

**ItemSearchAndFilter Widget**
- Generic widget that adapts to any item type
- Context-aware filter options based on `isPersonalListTab` parameter
- Collapsible state management with visual feedback

**ItemFilterHelper Utility**
- Static methods for rating context filtering
- Handles visibility checks for shared ratings
- Separates filtering logic from UI concerns

### Rating Context Filtering

**All Items Tab Logic:**
```dart
case 'has_ratings':
  // Show items user has interacted with (approximation of community ratings)
  final ratedItemIds = userRatings.map((r) => r.itemId).toSet();
  filtered = items.where((item) => ratedItemIds.contains(item.id)).toList();

case 'no_ratings':
  // Show items user hasn't rated (discovery)
  final ratedItemIds = userRatings.map((r) => r.itemId).toSet();
  filtered = items.where((item) => !ratedItemIds.contains(item.id)).toList();
```

**Personal List Tab Logic:**
```dart
case 'personal':
  // Show only items user has rated themselves
  final personalRatedIds = userRatings
    .where((r) => r.authorId == currentUserId)
    .map((r) => r.itemId).toSet();
  filtered = items.where((item) => personalRatedIds.contains(item.id)).toList();

case 'recommendations':
  // Show items others have recommended (shared with user)
  final recommendedItemIds = userRatings
    .where((r) => r.authorId != currentUserId && r.isVisibleToUser(currentUserId))
    .map((r) => r.itemId).toSet();
  filtered = items.where((item) => recommendedItemIds.contains(item.id)).toList();
```

### Special Base Items Logic

**Problem Solved**: Rating-based filters in Personal List tab needed to start with different base item sets than the default personal list.

**Solution**: Dynamic base items selection based on filter type:

```dart
// For "My Ratings" filter: Start with items user has rated
if (ratingSourceFilter == 'personal') {
  final personalRatedItemIds = userRatings
    .where((r) => r.itemType == 'cheese' && r.authorId == selectedUserId)
    .map((r) => r.itemId).toSet();
  
  var personalRatedItems = cheeseItemState.items
    .where((item) => personalRatedItemIds.contains(item.id)).toList();
  // Then apply search and category filters...
}

// For "Recommendations" filter: Start with all items that have any ratings  
if (ratingSourceFilter == 'recommendations') {
  final allRatedItemIds = userRatings
    .where((r) => r.itemType == 'cheese')
    .map((r) => r.itemId).toSet();
  
  var allRatedItems = cheeseItemState.items
    .where((item) => allRatedItemIds.contains(item.id)).toList();
  // Then apply search and category filters...
}
```

This ensures accurate filtering and counting for context-specific filters.

## Localization

### Supported Languages
- **English** (Primary)
- **French** (Complete translation)

### Localized Elements

**Filter Interface:**
- Search hint: "Search cheeses by name..." / "Rechercher fromages par nom..."
- Filter chips: "My Ratings" / "Mes Évaluations"
- Tooltips: "Show Filters" / "Afficher les Filtres"
- Category names: "Type" / "Type", "Origin" / "Origine"

**Filter Dialogs:**
- Dialog title: "Filter by Type" / "Filtrer par Type"
- All option: "All" / "Tous"
- Action buttons: "Clear All Filters" / "Effacer Tous les Filtres"

**Results Summary:**
- Count display: "Showing 5 of 20 items" / "Affichage de 5 sur 20 articles"

### Adding New Languages

To add a new language (e.g., Spanish):

1. **Create translation file**: `lib/l10n/app_es.arb`
2. **Add filter-specific translations**:
   ```json
   {
     "searchCheeseByNameHint": "Buscar quesos por nombre...",
     "myRatingsFilter": "Mis Valoraciones",
     "recommendationsFilter": "Recomendaciones",
     "ratedFilter": "Valorado", 
     "unratedFilter": "Sin valorar",
     "allFilterOption": "Todos",
     "showFilters": "Mostrar Filtros",
     "hideFilters": "Ocultar Filtros"
   }
   ```
3. **Regenerate**: Run `flutter gen-l10n`

## Usage Examples

### Developer Integration

**Adding Filtering to New Item Type:**
```dart
// 1. Add to screen
ItemSearchAndFilter(
  itemType: 'wine',  // Changes filter context automatically
  onSearchChanged: (query) => ref.read(wineProvider.notifier).updateSearchQuery(query),
  onFilterChanged: (key, value) => ref.read(wineProvider.notifier).setCategoryFilter(key, value),
  onClearFilters: () => ref.read(wineProvider.notifier).clearFilters(),
  // ... other parameters
)

// 2. No additional code needed - automatically gets:
//    - Type, Origin, Producer filters (from item data)  
//    - My Ratings, Recommendations filters (for Personal tab)
//    - Rated, Unrated filters (for All Items tab)
//    - Localized interface
//    - Collapsible mobile-friendly design
```

### User Workflows

**Discovery Workflow (All Items Tab):**
1. Search by name: "roquefort"
2. Apply category filter: Origin = "France"  
3. Apply rating filter: "Unrated" (find new French cheeses to try)
4. Switch to Personal tab → Category filters persist, rating filter clears

**Reference List Management (Personal Tab):**
1. Apply "My Ratings" → See only items you've rated
2. Search within your ratings: "blue"
3. Apply category: Type = "Blue" → Find your blue cheese ratings
4. Switch to "Recommendations" → See what others suggested

**Filter Combination Examples:**
- Search "cheddar" + Type "Hard" + "Unrated" = Find hard cheddars to try
- Origin "Switzerland" + "My Ratings" = Your Swiss cheese ratings
- "Recommendations" + Type "Soft" = Soft cheese recommendations from friends

## Performance Considerations

### Efficient Filtering Pipeline

**Filter Order (Optimized):**
1. **Search query** (most selective, applied first)
2. **Category filters** (reduces dataset size)
3. **Rating context filters** (applied to pre-filtered set)

**Counting Strategy:**
- Counting logic exactly matches display logic
- Avoids discrepancies between shown count and actual results
- Efficient: Only processes necessary data

### Mobile Optimization

**Collapsible Interface:**
- **Default collapsed**: Minimal space usage
- **Smart expansion**: Auto-expand when filters active
- **Action consolidation**: Filter toggle + clear actions in search bar

**Performance Benefits:**
- **Reduced renders**: Filter chips only render when expanded
- **Memory efficient**: Filter state only maintained when needed
- **Touch-optimized**: Proper button sizing and spacing

## Future Enhancement Opportunities

### Advanced Filtering

**Multi-Select Filters:**
- Select multiple types: "Hard" + "Semi-soft"
- Multiple origins: "France" + "Switzerland"  
- Complex queries with AND/OR logic

**Rating Score Filters:**
- "4+ stars": Items with high ratings
- "My 5-star ratings": Your favorite items
- "Highly recommended": Items with many recommendations

**Advanced Search:**
- **Search in notes**: Find items by your personal notes
- **Producer search**: Search specific producers  
- **Description search**: Full-text search in descriptions
- **Recent activity**: Recently rated items

### Mobile Enhancements

**Bottom Sheet Alternative:**
- Full-screen filter interface on small screens
- Tabbed filter categories for complex filtering
- Filter presets: "My Favorites", "To Try", "French Cheeses"

**Quick Actions:**
- Swipe gestures for common filters
- Long-press for quick access to filter dialogs
- Voice search integration

### Analytics Integration

**Filter Usage Analytics:**
- Track most-used filter combinations
- Optimize filter order based on usage
- Suggest relevant filters based on user behavior

**Performance Monitoring:**
- Filter response times
- Cache hit rates for filter results
- Memory usage optimization

## Testing Strategy

### Unit Tests

**Filter Logic Testing:**
```dart
test('ItemFilterHelper filters recommendations correctly', () {
  final items = [testCheese1, testCheese2];
  final ratings = [recommendationRating];
  final result = ItemFilterHelper.filterItemsWithRatingContext(
    items, ratings, userId, {'rating_source': 'recommendations'}, true
  );
  expect(result.length, 1);
  expect(result.first.id, testCheese1.id);
});
```

**Widget Testing:**
```dart
testWidgets('Filter interface collapses and expands correctly', (tester) async {
  await tester.pumpWidget(testApp);
  
  // Initially collapsed
  expect(find.byType(FilterChip), findsNothing);
  
  // Tap filter button to expand
  await tester.tap(find.byIcon(Icons.filter_list_outlined));
  await tester.pump();
  
  // Now filter chips should be visible
  expect(find.byType(FilterChip), findsWidgets);
});
```

### Integration Tests

**Cross-Tab Filter Persistence:**
1. Apply universal filter (Type = "Hard")
2. Apply tab-specific filter ("My Ratings")
3. Switch tabs
4. Verify: Type filter persists, My Ratings clears

**Mobile Responsiveness:**
1. Test on different screen sizes
2. Verify collapsible behavior
3. Check touch target sizes
4. Validate scrolling behavior

## Troubleshooting

### Common Issues

**Filter Not Working:**
- Check if `ItemFilterHelper.filterItemsWithRatingContext` is called correctly
- Verify filter keys match between UI and logic ('rating_source' vs 'rating_status')
- Ensure `isVisibleToUser()` method handles backend data format correctly

**Count Mismatch:**
- Ensure counting logic exactly matches display logic
- Verify same base items are used in both count and display methods
- Check that rating visibility filters are applied consistently

**Missing Translations:**
- Add missing strings to both `app_en.arb` and `app_fr.arb`
- Run `flutter gen-l10n` after adding translations
- Use `context.l10n.keyName` instead of hardcoded strings

### Debug Tools

**Rating Visibility Issues:**
```dart
// Add temporary debug to ItemFilterHelper
print('Rating ${r.id} visible to $userId: ${r.isVisibleToUser(userId)}');
print('Rating viewers: ${r.viewers}');
```

**Filter Flow Debugging:**
```dart
// Add to provider
print('Active filters: ${state.categoryFilters}');
print('Filtered items count: ${filteredItems.length}');
```

## Implementation Checklist

### For New Item Types

**Backend Requirements:**
- [ ] Item model with categories (type, origin, producer, etc.)
- [ ] Rating sharing system with viewer permissions
- [ ] API endpoints for item CRUD and rating management

**Frontend Implementation:**
- [ ] Create item model implementing `RateableItem` interface
- [ ] Add provider extending `ItemProvider<T>`
- [ ] Register provider in main.dart
- [ ] Add item type to navigation routes
- [ ] Update localization files with item-specific strings

**Filtering Integration:**
- [ ] No additional code needed - automatic inheritance
- [ ] Verify category fields map correctly to filter options
- [ ] Test rating context filters work with new item type
- [ ] Add item-specific search hint if needed

### Mobile Optimization Checklist

**Design Verification:**
- [ ] Filter interface collapses by default
- [ ] Active filters auto-expand interface
- [ ] Touch targets are 44px minimum
- [ ] Proper spacing between interactive elements

**Functionality Testing:**
- [ ] All filters work in collapsed and expanded states
- [ ] Tab switching clears appropriate filters
- [ ] Search and filtering perform well on lists of 100+ items
- [ ] Localization works correctly in both languages

## Maintenance

### Regular Updates

**Filter Options:**
- **Dynamic generation**: Filter options auto-update when new data is added
- **Cache invalidation**: Options refresh when items are created/updated
- **Cleanup**: Remove empty filter categories automatically

**Performance Monitoring:**
- Monitor filter response times as data grows
- Optimize filtering algorithms for large datasets
- Consider pagination for very large item lists

### Localization Maintenance

**Adding Translations:**
1. Update both `.arb` files simultaneously
2. Test both languages for UI consistency  
3. Verify filter functionality in both locales
4. Update documentation for new language support

**String Management:**
- Use consistent naming conventions for translation keys
- Group related strings together in `.arb` files
- Add descriptive comments for translators
- Test edge cases (long translations, special characters)

## Success Metrics

### User Experience Goals

**Efficiency:**
- Users can find specific items in under 10 seconds
- Filter combinations provide meaningful results
- Clear path from discovery to rating creation

**Mobile Usability:**
- Filtering interface uses <30% of screen space when collapsed
- Touch interactions feel natural and responsive
- No accidental taps or UI conflicts

**Accessibility:**
- Screen reader compatible
- Keyboard navigation support
- High contrast mode compatibility
- Proper focus management

### Technical Performance

**Response Times:**
- Filter application: <200ms for datasets under 1000 items
- Search results: <100ms for text queries
- Tab switching: <50ms filter state updates

**Memory Usage:**
- Filter state: <1MB for typical datasets
- UI components: Efficient widget recycling
- Cache management: Automatic cleanup of unused filter options

---

**Built with Flutter & Riverpod for A la carte**
*Last updated: September 2025*
