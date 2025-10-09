import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rateable_item.dart';
import '../models/rating.dart';
import '../providers/item_provider.dart';
import '../providers/rating_provider.dart';

/// Helper class for filtering items with rating context
class ItemFilterHelper {
  /// Filter items based on rating context for both discovery and personal lists
  static List<T> filterItemsWithRatingContext<T extends RateableItem>(
    List<T> items,
    List<Rating> userRatings,
    int? currentUserId,
    Map<String, String> filters,
    bool isPersonalListTab,
  ) {
    var filtered = items;
    
    if (isPersonalListTab) {
      // Personal list tab: filter by rating source
      final ratingSourceFilter = filters['rating_source'];
      if (ratingSourceFilter != null && currentUserId != null) {
        switch (ratingSourceFilter) {
          case 'personal':
            // Items user has rated themselves
            if (currentUserId == null) {
              return [];
            }
            
            final personalRatedIds = userRatings
                .where((r) => r.authorId == currentUserId)
                .map((r) => r.itemId)
                .toSet();
            
            filtered = filtered.where((item) => personalRatedIds.contains(item.id)).toList();
            break;
            
          case 'recommendations':
            // Items that others have recommended to the user (shared with them)
            if (currentUserId == null) {
              // No user selected, can't show recommendations
              return [];
            }
            
            final otherUsersRatings = userRatings.where((r) => r.authorId != currentUserId).toList();
            
            final visibleRecommendations = otherUsersRatings.where((r) => r.isVisibleToUser(currentUserId)).toList();
            
            final recommendedItemIds = visibleRecommendations.map((r) => r.itemId).toSet();
            
            filtered = filtered.where((item) => recommendedItemIds.contains(item.id)).toList();
            break;
        }
      }
    } else {
      // All items tab: filter by rating existence
      final ratingStatusFilter = filters['rating_status'];
      if (ratingStatusFilter != null) {
        switch (ratingStatusFilter) {
          case 'has_ratings':
            // Items that have any ratings from anyone
            // Note: This would need community rating data to work properly
            // For now, filter by items that current user has interacted with
            final ratedItemIds = userRatings.map((r) => r.itemId).toSet();
            filtered = filtered.where((item) => ratedItemIds.contains(item.id)).toList();
            break;
            
          case 'no_ratings':
            // Items with no ratings from current user (approximation)
            final ratedItemIds = userRatings.map((r) => r.itemId).toSet();
            filtered = filtered.where((item) => !ratedItemIds.contains(item.id)).toList();
            break;
        }
      }
    }
    
    return filtered;
  }
  
  /// Get available filter options for an item type
  static Map<String, List<String>> getAvailableFilters<T extends RateableItem>(
    List<T> items,
    String itemType,
  ) {
    final filterOptions = <String, Set<String>>{};
    
    // Extract all unique values for each category
    for (final item in items) {
      for (final category in item.categories.entries) {
        filterOptions.putIfAbsent(category.key, () => <String>{}).add(category.value);
      }
    }
    
    // Convert sets to sorted lists
    return filterOptions.map(
      (key, valueSet) => MapEntry(key, valueSet.toList()..sort()),
    );
  }
  
  /// Get localized search hint for item type
  static String getSearchHint(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return 'Search cheeses by name, type, origin...';
      case 'wine':
        return 'Search wines by name, region, vintage...';
      case 'beer':
        return 'Search beers by name, style, brewery...';
      case 'coffee':
        return 'Search coffee by name, origin, roast...';
      default:
        return 'Search ${itemType}s...';
    }
  }
}
