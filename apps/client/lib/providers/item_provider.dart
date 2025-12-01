import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:diacritic/diacritic.dart';
import '../models/rateable_item.dart';
import '../models/cheese_item.dart';
import '../models/gin_item.dart';
import '../models/wine_item.dart';
import '../models/coffee_item.dart';
import '../models/api_response.dart';
import '../services/item_service.dart';

/// Generic provider for managing any type of rateable item
class ItemProvider<T extends RateableItem> extends StateNotifier<ItemState<T>> {
  final ItemService<T> _itemService;
  
  ItemProvider(this._itemService) : super(ItemState<T>()) {
    // Don't auto-load data in constructor - let consumers trigger loading
    // Temporarily disable filter options loading to reduce API calls
    // _loadFilterOptions();
  }

  /// Load all items from the backend
  Future<void> loadItems() async {
    // Prevent duplicate loading if already loading
    if (state.isLoading) {
      return;
    }
    
    // If already loaded and items exist, skip loading (use cache)
    if (state.hasLoadedOnce && state.items.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _itemService.getAllItems();
    
    response.when(
      success: (items, _) {
        state = state.copyWith(
          items: items,
          isLoading: false,
          hasLoadedOnce: true,
        );
        
        // Load filter options after items are loaded - use current items instead of making more API calls
        _refreshFilterOptions();
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          hasLoadedOnce: true, // Mark as loaded even on error to prevent infinite retries
          error: message,
        );
      },
      loading: () {
        // Keep loading state
      },
    );
  }

  /// Load specific items by their IDs (for filling cache gaps)
  Future<void> loadSpecificItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    
    try {
      for (final itemId in itemIds) {
        // Skip if already loaded
        if (state.items.any((item) => item.id == itemId)) {
          continue;
        }
        
        // Load individual item
        final response = await _itemService.getItemById(itemId);
        
        response.when(
          success: (item, _) {
            // Add to items list if not already present
            if (!state.items.any((i) => i.id == item.id)) {
              final updatedItems = [...state.items, item];
              state = state.copyWith(items: updatedItems);
            }
          },
          error: (message, statusCode, errorCode, details) {
            if (kDebugMode) print('Failed to load item $itemId: $message');
            // Continue loading other items
          },
          loading: () {},
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error in loadSpecificItems: $e');
    }
  }

  /// Refresh item data (bypasses loading guard)
  Future<void> refreshItems() async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Clear both data and image cache before refreshing
    if (_itemService is CheeseItemService) {
      await (_itemService as CheeseItemService).clearCache();
    } else if (_itemService is GinItemService) {
      await (_itemService as GinItemService).clearCache();
    } else if (_itemService is WineItemService) {
      await (_itemService as WineItemService).clearCache();
    } else if (_itemService is CoffeeItemService) {
      await (_itemService as CoffeeItemService).clearCache();
    }
    
    final response = await _itemService.getAllItems();
    
    response.when(
      success: (items, _) {
        state = state.copyWith(
          items: items,
          isLoading: false,
          hasLoadedOnce: true,
        );
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
      },
      loading: () {
        // Keep loading state
      },
    );
  }

  /// Select a specific item for detailed view
  void selectItem(T item) {
    state = state.copyWith(selectedItem: item);
  }

  /// Clear selected item
  void clearSelectedItem() {
    state = state.copyWith(selectedItem: null);
  }

  /// Create a new item
  Future<int?> createItem(T item) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _itemService.createItem(item);

    return response.when(
      success: (createdItem, _) async {
        // Clear service cache after data changes
        if (_itemService is CheeseItemService) {
          await (_itemService as CheeseItemService).clearCache();
        } else if (_itemService is GinItemService) {
          await (_itemService as GinItemService).clearCache();
        } else if (_itemService is WineItemService) {
          await (_itemService as WineItemService).clearCache();
        } else if (_itemService is CoffeeItemService) {
          await (_itemService as CoffeeItemService).clearCache();
        }
        
        final updatedItems = [...state.items, createdItem];
        state = state.copyWith(
          items: updatedItems,
          selectedItem: createdItem,
          isLoading: false,
        );
        _refreshFilterOptions();
        return createdItem.id;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return null;
      },
      loading: () => null,
    );
  }

  /// Update an existing item
  Future<bool> updateItem(int itemId, T item) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _itemService.updateItem(itemId, item);

    return response.when(
      success: (updatedItem, _) async {
        // Clear service cache after data changes (includes image cache)
        if (_itemService is CheeseItemService) {
          await (_itemService as CheeseItemService).clearCache();
        } else if (_itemService is GinItemService) {
          await (_itemService as GinItemService).clearCache();
        } else if (_itemService is WineItemService) {
          await (_itemService as WineItemService).clearCache();
        } else if (_itemService is CoffeeItemService) {
          await (_itemService as CoffeeItemService).clearCache();
        }
        
        final updatedItems = state.items
            .map((i) => i.id == updatedItem.id ? updatedItem : i)
            .toList();
        
        state = state.copyWith(
          items: updatedItems,
          selectedItem: updatedItem,
          isLoading: false,
        );
        _refreshFilterOptions();
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }

  /// Delete an item
  Future<bool> deleteItem(int itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _itemService.deleteItem(itemId);

    // ignore: avoid_types_as_parameter_names, non_constant_identifier_names
    return response.when(
      success: (_, __) {
      final updatedItems = state.items.where((i) => i.id != itemId).toList();
      
      T? newSelectedItem = state.selectedItem;
        if (state.selectedItem?.id == itemId) {
          newSelectedItem = null;
        }

        state = state.copyWith(
          items: updatedItems,
          selectedItem: newSelectedItem,
          isLoading: false,
        );
        _refreshFilterOptions();
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set category filter
  void setCategoryFilter(String categoryKey, String? categoryValue) {
    final updatedFilters = Map<String, String>.from(state.categoryFilters);
    if (categoryValue != null) {
      updatedFilters[categoryKey] = categoryValue;
    } else {
      updatedFilters.remove(categoryKey);
    }
    state = state.copyWith(categoryFilters: updatedFilters);
  }

  /// Set rating-based filter (context-aware)
  void setRatingFilter(String? filterType, {bool isPersonalTab = false}) {
    if (isPersonalTab) {
      setCategoryFilter('rating_source', filterType);
    } else {
      setCategoryFilter('rating_status', filterType);
    }
  }

  /// Clear tab-specific filters (rating-based filters)
  void clearTabSpecificFilters() {
    final updatedFilters = Map<String, String>.from(state.categoryFilters);
    updatedFilters.remove('rating_source'); // Personal tab specific
    updatedFilters.remove('rating_status');  // All items tab specific
    state = state.copyWith(categoryFilters: updatedFilters);
  }
  
  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      categoryFilters: {},
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Invalidate a specific item from cache
  /// 
  /// Removes the item from provider state, forcing it to be refetched
  /// from the API next time it's needed. Used for granular cache invalidation.
  void invalidateItem(int itemId) {
    final updatedItems = state.items.where((i) => i.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Refresh filter options after data changes
  void _refreshFilterOptions() {
    // Extract categories from current items
    final allCategories = <String, Set<String>>{};
    
    for (final item in state.items) {
      for (final entry in item.categories.entries) {
        allCategories.putIfAbsent(entry.key, () => <String>{}).add(entry.value);
      }
    }
    
    // Sort filter options with locale-aware comparison for accented characters
    final filterOptions = allCategories.map(
      (key, valueSet) {
        final sortedList = valueSet.toList();
        sortedList.sort((a, b) => ItemState._compareLocaleAware(a, b));
        return MapEntry(key, sortedList);
      },
    );

    state = state.copyWith(filterOptions: filterOptions);
  }
}

/// State for generic item management
class ItemState<T extends RateableItem> {
  final List<T> items;
  final T? selectedItem;
  final bool isLoading;
  final bool hasLoadedOnce; // Track if we've ever loaded data
  final String? error;
  
  // Search and filtering
  final String searchQuery;
  final Map<String, String> categoryFilters;
  final Map<String, List<String>> filterOptions;

  const ItemState({
    this.items = const [],
    this.selectedItem,
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilters = const {},
    this.filterOptions = const {},
  });

  ItemState<T> copyWith({
    List<T>? items,
    T? selectedItem,
    bool? isLoading,
    bool? hasLoadedOnce,
    String? error,
    String? searchQuery,
    Map<String, String>? categoryFilters,
    Map<String, List<String>>? filterOptions,
  }) {
    return ItemState<T>(
      items: items ?? this.items,
      selectedItem: selectedItem ?? this.selectedItem,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilters: categoryFilters ?? this.categoryFilters,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }

  /// Get filtered items based on current search and filters
  List<T> get filteredItems {
    var filtered = items;

    // Apply search query (name only)
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
        item.name.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    // Apply category filters
    for (final entry in categoryFilters.entries) {
      if (entry.key == 'rating_status') {
        // Special handling for rating-based filters (requires external rating data)
        continue;
      }
      
      filtered = filtered.where((item) =>
        item.categories[entry.key]?.toLowerCase() == entry.value.toLowerCase()
      ).toList();
    }

    // Sort alphabetically by name with locale-aware comparison
    // This ensures accented characters (é, à, ç, etc.) sort correctly
    filtered.sort((a, b) => ItemState._compareLocaleAware(a.name, b.name));

    return filtered;
  }

  /// Locale-aware string comparison using diacritic package
  /// Normalizes strings to treat accented characters as base letters
  static int _compareLocaleAware(String a, String b) {
    return removeDiacritics(a).toLowerCase().compareTo(
      removeDiacritics(b).toLowerCase()
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters => 
    searchQuery.isNotEmpty || categoryFilters.isNotEmpty;

  /// Get count of filtered results
  int get filteredCount => filteredItems.length;
}

/// Specific provider for Cheese items
final cheeseItemProvider = StateNotifierProvider<CheeseItemProvider, ItemState<CheeseItem>>(
  (ref) => CheeseItemProvider(ref.read(cheeseItemServiceProvider)),
);

/// Concrete implementation for Cheese provider
class CheeseItemProvider extends ItemProvider<CheeseItem> {
  CheeseItemProvider(super.cheeseService);

  /// Cheese-specific filtering methods
  void setTypeFilter(String? type) => setCategoryFilter('type', type);
  void setOriginFilter(String? origin) => setCategoryFilter('origin', origin);
  void setProducerFilter(String? producer) => setCategoryFilter('producer', producer);
}

/// Computed provider for filtered cheese items
final filteredCheeseItemsProvider = Provider<List<CheeseItem>>((ref) {
  final itemState = ref.watch(cheeseItemProvider);
  return itemState.filteredItems;
});

/// Computed provider for checking if cheese data exists
final hasCheeseItemDataProvider = Provider<bool>((ref) {
  final itemState = ref.watch(cheeseItemProvider);
  return itemState.items.isNotEmpty;
});

/// Specific provider for Gin items
final ginItemProvider = StateNotifierProvider<GinItemProvider, ItemState<GinItem>>(
  (ref) => GinItemProvider(ref.read(ginItemServiceProvider)),
);

/// Concrete implementation for Gin provider
class GinItemProvider extends ItemProvider<GinItem> {
  GinItemProvider(super.ginService);

  /// Gin-specific filtering methods
  void setProducerFilter(String? producer) => setCategoryFilter('producer', producer);
  void setOriginFilter(String? origin) => setCategoryFilter('origin', origin);
  void setProfileFilter(String? profile) => setCategoryFilter('profile', profile);
}

/// Computed provider for filtered gin items
final filteredGinItemsProvider = Provider<List<GinItem>>((ref) {
  final itemState = ref.watch(ginItemProvider);
  return itemState.filteredItems;
});

/// Computed provider for checking if gin data exists
final hasGinItemDataProvider = Provider<bool>((ref) {
  final itemState = ref.watch(ginItemProvider);
  return itemState.items.isNotEmpty;
});

/// Specific provider for Wine items
final wineItemProvider = StateNotifierProvider<WineItemProvider, ItemState<WineItem>>(
  (ref) => WineItemProvider(ref.read(wineItemServiceProvider)),
);

/// Concrete implementation for Wine provider
class WineItemProvider extends ItemProvider<WineItem> {
  WineItemProvider(super.wineService);

  /// Wine-specific filtering methods
  void setColorFilter(String? color) => setCategoryFilter('color', color);
  void setCountryFilter(String? country) => setCategoryFilter('country', country);
  void setRegionFilter(String? region) => setCategoryFilter('region', region);
  void setProducerFilter(String? producer) => setCategoryFilter('producer', producer);
}

/// Computed provider for filtered wine items
final filteredWineItemsProvider = Provider<List<WineItem>>((ref) {
  final itemState = ref.watch(wineItemProvider);
  return itemState.filteredItems;
});

/// Computed provider for checking if wine data exists
final hasWineItemDataProvider = Provider<bool>((ref) {
  final itemState = ref.watch(wineItemProvider);
  return itemState.items.isNotEmpty;
});

/// Specific provider for Coffee items
final coffeeItemProvider = StateNotifierProvider<CoffeeItemProvider, ItemState<CoffeeItem>>(
  (ref) => CoffeeItemProvider(ref.read(coffeeItemServiceProvider)),
);

/// Concrete implementation for Coffee provider
class CoffeeItemProvider extends ItemProvider<CoffeeItem> {
  CoffeeItemProvider(super.coffeeService);

  /// Coffee-specific filtering methods
  void setRoasterFilter(String? roaster) => setCategoryFilter('roaster', roaster);
  void setCountryFilter(String? country) => setCategoryFilter('country', country);
  void setRegionFilter(String? region) => setCategoryFilter('region', region);
  void setProcessingMethodFilter(String? processingMethod) => setCategoryFilter('processing_method', processingMethod);
  void setRoastLevelFilter(String? roastLevel) => setCategoryFilter('roast_level', roastLevel);
}

/// Computed provider for filtered coffee items
final filteredCoffeeItemsProvider = Provider<List<CoffeeItem>>((ref) {
  final itemState = ref.watch(coffeeItemProvider);
  return itemState.filteredItems;
});

/// Computed provider for checking if coffee data exists
final hasCoffeeItemDataProvider = Provider<bool>((ref) {
  final itemState = ref.watch(coffeeItemProvider);
  return itemState.items.isNotEmpty;
});
