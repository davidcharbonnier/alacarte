import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rateable_item.dart';
import '../models/cheese_item.dart';
import '../models/gin_item.dart';
import '../models/wine_item.dart';
import '../models/coffee_item.dart';
import '../models/api_response.dart';
import '../providers/item_provider.dart';
import '../services/item_service.dart';

/// Helper class to interact with item providers in a type-agnostic way
class ItemProviderHelper {
  /// Get items from the appropriate provider
  static List<RateableItem> getItems(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).items.cast<RateableItem>();
      case 'gin':
        return ref.watch(ginItemProvider).items.cast<RateableItem>();
      case 'wine':
        return ref.watch(wineItemProvider).items.cast<RateableItem>();
      case 'coffee':
        return ref.watch(coffeeItemProvider).items.cast<RateableItem>();
      default:
        return [];
    }
  }

  /// Get filtered items from the appropriate provider
  static List<RateableItem> getFilteredItems(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).filteredItems.cast<RateableItem>();
      case 'gin':
        return ref.watch(ginItemProvider).filteredItems.cast<RateableItem>();
      case 'wine':
        return ref.watch(wineItemProvider).filteredItems.cast<RateableItem>();
      case 'coffee':
        return ref.watch(coffeeItemProvider).filteredItems.cast<RateableItem>();
      default:
        return [];
    }
  }

  /// Check if items are loading
  static bool isLoading(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).isLoading;
      case 'gin':
        return ref.watch(ginItemProvider).isLoading;
      case 'wine':
        return ref.watch(wineItemProvider).isLoading;
      case 'coffee':
        return ref.watch(coffeeItemProvider).isLoading;
      default:
        return false;
    }
  }

  /// Check if items have loaded once
  static bool hasLoadedOnce(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).hasLoadedOnce;
      case 'gin':
        return ref.watch(ginItemProvider).hasLoadedOnce;
      case 'wine':
        return ref.watch(wineItemProvider).hasLoadedOnce;
      case 'coffee':
        return ref.watch(coffeeItemProvider).hasLoadedOnce;
      default:
        return false;
    }
  }

  /// Get error message if any
  static String? getErrorMessage(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).error;
      case 'gin':
        return ref.watch(ginItemProvider).error;
      case 'wine':
        return ref.watch(wineItemProvider).error;
      case 'coffee':
        return ref.watch(coffeeItemProvider).error;
      default:
        return null;
    }
  }

  /// Get search query
  static String getSearchQuery(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).searchQuery;
      case 'gin':
        return ref.watch(ginItemProvider).searchQuery;
      case 'wine':
        return ref.watch(wineItemProvider).searchQuery;
      case 'coffee':
        return ref.watch(coffeeItemProvider).searchQuery;
      default:
        return '';
    }
  }

  /// Get active filters
  static Map<String, String> getActiveFilters(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).categoryFilters;
      case 'gin':
        return ref.watch(ginItemProvider).categoryFilters;
      case 'wine':
        return ref.watch(wineItemProvider).categoryFilters;
      case 'coffee':
        return ref.watch(coffeeItemProvider).categoryFilters;
      default:
        return {};
    }
  }

  /// Get filter options
  static Map<String, List<String>> getFilterOptions(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return ref.watch(cheeseItemProvider).filterOptions;
      case 'gin':
        return ref.watch(ginItemProvider).filterOptions;
      case 'wine':
        return ref.watch(wineItemProvider).filterOptions;
      case 'coffee':
        return ref.watch(coffeeItemProvider).filterOptions;
      default:
        return {};
    }
  }

  /// Load items for a given type
  static void loadItems(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).loadItems();
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).loadItems();
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).loadItems();
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).loadItems();
        break;
    }
  }

  /// Refresh items for a given type
  static Future<void> refreshItems(WidgetRef ref, String itemType) async {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        await ref.read(cheeseItemProvider.notifier).refreshItems();
        break;
      case 'gin':
        await ref.read(ginItemProvider.notifier).refreshItems();
        break;
      case 'wine':
        await ref.read(wineItemProvider.notifier).refreshItems();
        break;
      case 'coffee':
        await ref.read(coffeeItemProvider.notifier).refreshItems();
        break;
    }
  }

  /// Clear all filters
  static void clearFilters(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).clearFilters();
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).clearFilters();
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).clearFilters();
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).clearFilters();
        break;
    }
  }

  /// Clear tab-specific filters
  static void clearTabSpecificFilters(WidgetRef ref, String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).clearTabSpecificFilters();
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).clearTabSpecificFilters();
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).clearTabSpecificFilters();
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).clearTabSpecificFilters();
        break;
    }
  }

  /// Update search query
  static void updateSearchQuery(WidgetRef ref, String itemType, String query) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).updateSearchQuery(query);
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).updateSearchQuery(query);
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).updateSearchQuery(query);
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).updateSearchQuery(query);
        break;
    }
  }

  /// Set category filter
  static void setCategoryFilter(
    WidgetRef ref,
    String itemType,
    String key,
    String? value,
  ) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).setCategoryFilter(key, value);
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).setCategoryFilter(key, value);
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).setCategoryFilter(key, value);
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).setCategoryFilter(key, value);
        break;
    }
  }

  /// Get item by ID from provider or API
  static Future<RateableItem?> getItemById(
    WidgetRef ref,
    String itemType,
    int itemId,
  ) async {
    // First try cache
    final items = getItems(ref, itemType);
    final cachedItem = items.where((item) => item.id == itemId).firstOrNull;

    if (cachedItem != null) return cachedItem;

    // Load from API based on type
    switch (itemType.toLowerCase()) {
      case 'cheese':
        final service = ref.read(cheeseItemServiceProvider);
        final response = await service.getItemById(itemId);
        if (response is ApiSuccess<CheeseItem>) {
          return response.data;
        }
        return null;
      case 'gin':
        final service = ref.read(ginItemServiceProvider);
        final response = await service.getItemById(itemId);
        if (response is ApiSuccess<GinItem>) {
          return response.data;
        }
        return null;
      case 'wine':
        final service = ref.read(wineItemServiceProvider);
        final response = await service.getItemById(itemId);
        if (response is ApiSuccess<WineItem>) {
          return response.data;
        }
        return null;
      case 'coffee':
        final service = ref.read(coffeeItemServiceProvider);
        final response = await service.getItemById(itemId);
        if (response is ApiSuccess<CoffeeItem>) {
          return response.data;
        }
        return null;
      default:
        return null;
    }
  }

  /// Load specific items by IDs (for filling cache gaps)
  static Future<void> loadSpecificItems(
    WidgetRef ref,
    String itemType,
    List<int> itemIds,
  ) async {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        await ref.read(cheeseItemProvider.notifier).loadSpecificItems(itemIds);
        break;
      case 'gin':
        await ref.read(ginItemProvider.notifier).loadSpecificItems(itemIds);
        break;
      case 'wine':
        await ref.read(wineItemProvider.notifier).loadSpecificItems(itemIds);
        break;
      case 'coffee':
        await ref.read(coffeeItemProvider.notifier).loadSpecificItems(itemIds);
        break;
      default:
        // Unknown item type - skip loading
        break;
    }
  }

  /// Invalidate a specific item from cache
  /// 
  /// Removes the item from provider state, forcing it to be refetched
  /// from the API next time it's needed.
  static void invalidateItem(WidgetRef ref, String itemType, int itemId) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        ref.read(cheeseItemProvider.notifier).invalidateItem(itemId);
        break;
      case 'gin':
        ref.read(ginItemProvider.notifier).invalidateItem(itemId);
        break;
      case 'wine':
        ref.read(wineItemProvider.notifier).invalidateItem(itemId);
        break;
      case 'coffee':
        ref.read(coffeeItemProvider.notifier).invalidateItem(itemId);
        break;
    }
  }
}
