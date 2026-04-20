import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/api_response.dart';
import '../models/dynamic_item.dart';
import '../models/item_schema.dart';
import '../services/dynamic_item_service.dart';
import 'schema_provider.dart';

class DynamicItemState {
  final Map<String, List<DynamicItem>> itemsByType;
  final Map<String, bool> loadingByType;
  final Map<String, String?> errorsByType;
  final bool hasLoadedOnce;
  final Map<String, String> searchQueriesByType;
  final Map<String, Map<String, String>> categoryFiltersByType;
  final Map<String, Map<String, List<String>>> filterOptionsByType;

  const DynamicItemState({
    this.itemsByType = const {},
    this.loadingByType = const {},
    this.errorsByType = const {},
    this.hasLoadedOnce = false,
    this.searchQueriesByType = const {},
    this.categoryFiltersByType = const {},
    this.filterOptionsByType = const {},
  });

  DynamicItemState copyWith({
    Map<String, List<DynamicItem>>? itemsByType,
    Map<String, bool>? loadingByType,
    Map<String, String?>? errorsByType,
    bool? hasLoadedOnce,
    Map<String, String>? searchQueriesByType,
    Map<String, Map<String, String>>? categoryFiltersByType,
    Map<String, Map<String, List<String>>>? filterOptionsByType,
  }) {
    return DynamicItemState(
      itemsByType: itemsByType ?? this.itemsByType,
      loadingByType: loadingByType ?? this.loadingByType,
      errorsByType: errorsByType ?? this.errorsByType,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      searchQueriesByType: searchQueriesByType ?? this.searchQueriesByType,
      categoryFiltersByType:
          categoryFiltersByType ?? this.categoryFiltersByType,
      filterOptionsByType: filterOptionsByType ?? this.filterOptionsByType,
    );
  }

  List<DynamicItem> getItems(String type) => itemsByType[type] ?? [];

  bool isLoading(String type) => loadingByType[type] ?? false;

  String? getError(String type) => errorsByType[type];

  bool hasItems(String type) =>
      itemsByType.containsKey(type) && itemsByType[type]!.isNotEmpty;

  String getSearchQuery(String type) => searchQueriesByType[type] ?? '';

  Map<String, String> getCategoryFilters(String type) =>
      categoryFiltersByType[type] ?? {};

  Map<String, List<String>> getFilterOptions(String type) =>
      filterOptionsByType[type] ?? {};

  List<DynamicItem> getFilteredItems(String type) {
    var filtered = getItems(type);
    final searchQuery = getSearchQuery(type);
    final categoryFilters = getCategoryFilters(type);

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    for (final entry in categoryFilters.entries) {
      if (entry.key == 'has_picture') {
        final hasPictureFilter = entry.value.toLowerCase() == 'true';
        filtered = filtered.where((item) {
          final imageUrl = item.imageUrl;
          return hasPictureFilter
              ? imageUrl != null && imageUrl.isNotEmpty
              : imageUrl == null || imageUrl.isEmpty;
        }).toList();
        continue;
      }

      filtered = filtered
          .where(
            (item) =>
                item.categories[entry.key]?.toLowerCase() ==
                entry.value.toLowerCase(),
          )
          .toList();
    }

    filtered.sort((a, b) => _compareLocaleAware(a.name, b.name));
    return filtered;
  }

  static int _compareLocaleAware(String a, String b) {
    return removeDiacritics(
      a,
    ).toLowerCase().compareTo(removeDiacritics(b).toLowerCase());
  }

  bool hasActiveFilters(String type) {
    final searchQuery = getSearchQuery(type);
    final categoryFilters = getCategoryFilters(type);
    return searchQuery.isNotEmpty || categoryFilters.isNotEmpty;
  }
}

class DynamicItemNotifier extends StateNotifier<DynamicItemState> {
  final DynamicItemService _itemService;
  final Ref _ref;

  DynamicItemNotifier(this._itemService, this._ref)
    : super(const DynamicItemState());

  ItemSchema? _getSchema(String type) {
    return _ref.read(schemaProvider).getSchema(type);
  }

  Future<void> loadItems(String type, {bool forceRefresh = false}) async {
    if (state.isLoading(type)) return;

    if (!forceRefresh && state.hasLoadedOnce && state.hasItems(type)) {
      return;
    }

    state = state.copyWith(
      loadingByType: {...state.loadingByType, type: true},
      errorsByType: {...state.errorsByType, type: null},
    );

    final schema = _getSchema(type);
    final response = await _itemService.getItemsByType(type, schema: schema);

    response.when(
      success: (items, _) {
        state = state.copyWith(
          itemsByType: {...state.itemsByType, type: items},
          loadingByType: {...state.loadingByType, type: false},
          hasLoadedOnce: true,
        );
        _refreshFilterOptions(type);
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          loadingByType: {...state.loadingByType, type: false},
          errorsByType: {...state.errorsByType, type: message},
        );
      },
      loading: () {},
    );
  }

  Future<void> refreshItems(String type) async {
    await loadItems(type, forceRefresh: true);
  }

  Future<ApiResponse<DynamicItem>> createItem(
    String type,
    DynamicItem item,
  ) async {
    final response = await _itemService.createItem(type, item);

    response.when(
      success: (createdItem, _) {
        final items = state.getItems(type);
        final updatedItems = [...items, createdItem];
        state = state.copyWith(
          itemsByType: {...state.itemsByType, type: updatedItems},
        );
        _refreshFilterOptions(type);
      },
      error: (message, statusCode, errorCode, details) {},
      loading: () {},
    );

    return response;
  }

  Future<ApiResponse<DynamicItem>> updateItem(
    String type,
    int id,
    DynamicItem item,
  ) async {
    final response = await _itemService.updateItem(type, id, item);

    response.when(
      success: (updatedItem, _) {
        final items = state.getItems(type);
        final index = items.indexWhere((i) => i.id == id);
        if (index >= 0) {
          final updatedItems = List<DynamicItem>.from(items);
          updatedItems[index] = updatedItem;
          state = state.copyWith(
            itemsByType: {...state.itemsByType, type: updatedItems},
          );
          _refreshFilterOptions(type);
        }
      },
      error: (message, statusCode, errorCode, details) {},
      loading: () {},
    );

    return response;
  }

  Future<ApiResponse<bool>> deleteItem(String type, int id) async {
    final response = await _itemService.deleteItem(type, id);

    response.when(
      success: (deleteResult, _) {
        final items = state.getItems(type);
        final updatedItems = items.where((i) => i.id != id).toList();
        state = state.copyWith(
          itemsByType: {...state.itemsByType, type: updatedItems},
        );
        _refreshFilterOptions(type);
      },
      error: (message, statusCode, errorCode, details) {},
      loading: () {},
    );

    return response;
  }

  Future<ApiResponse<DynamicItem>> getItemById(String type, int id) async {
    final schema = _getSchema(type);
    return _itemService.getItemById(type, id, schema: schema);
  }

  void clearError(String type) {
    state = state.copyWith(errorsByType: {...state.errorsByType, type: null});
  }

  void clearCache() {
    _itemService.clearCache();
    state = const DynamicItemState();
  }

  void updateSearchQuery(String type, String query) {
    state = state.copyWith(
      searchQueriesByType: {...state.searchQueriesByType, type: query},
    );
  }

  void setCategoryFilter(String type, String key, String? value) {
    final updatedFilters = Map<String, String>.from(
      state.getCategoryFilters(type),
    );
    if (value != null) {
      updatedFilters[key] = value;
    } else {
      updatedFilters.remove(key);
    }
    state = state.copyWith(
      categoryFiltersByType: {
        ...state.categoryFiltersByType,
        type: updatedFilters,
      },
    );
  }

  void clearFilters(String type) {
    state = state.copyWith(
      searchQueriesByType: {...state.searchQueriesByType, type: ''},
      categoryFiltersByType: {...state.categoryFiltersByType, type: {}},
    );
  }

  void clearTabSpecificFilters(String type) {
    final updatedFilters = Map<String, String>.from(
      state.getCategoryFilters(type),
    );
    updatedFilters.remove('rating_source');
    updatedFilters.remove('rating_status');
    state = state.copyWith(
      categoryFiltersByType: {
        ...state.categoryFiltersByType,
        type: updatedFilters,
      },
    );
  }

  void invalidateItem(String type, int itemId) {
    final items = state.getItems(type);
    final updatedItems = items.where((i) => i.id != itemId).toList();
    state = state.copyWith(
      itemsByType: {...state.itemsByType, type: updatedItems},
    );
  }

  void addItem(String type, DynamicItem item) {
    final items = state.getItems(type);
    if (!items.any((i) => i.id == item.id)) {
      final updatedItems = [...items, item];
      state = state.copyWith(
        itemsByType: {...state.itemsByType, type: updatedItems},
      );
    }
  }

  void _refreshFilterOptions(String type) {
    final items = state.getItems(type);
    final allCategories = <String, Set<String>>{};

    for (final item in items) {
      for (final entry in item.categories.entries) {
        allCategories.putIfAbsent(entry.key, () => <String>{}).add(entry.value);
      }
    }

    final filterOptions = allCategories.map((key, valueSet) {
      final sortedList = valueSet.toList();
      sortedList.sort((a, b) => DynamicItemState._compareLocaleAware(a, b));
      return MapEntry(key, sortedList);
    });

    state = state.copyWith(
      filterOptionsByType: {...state.filterOptionsByType, type: filterOptions},
    );
  }
}

final dynamicItemServiceProvider = Provider<DynamicItemService>((ref) {
  return DynamicItemService();
});

final dynamicItemProvider =
    StateNotifierProvider<DynamicItemNotifier, DynamicItemState>((ref) {
      final itemService = ref.watch(dynamicItemServiceProvider);
      return DynamicItemNotifier(itemService, ref);
    });

final itemsForTypeProvider = Provider.family<List<DynamicItem>, String>((
  ref,
  type,
) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.getItems(type);
});

final filteredItemsForTypeProvider = Provider.family<List<DynamicItem>, String>(
  (ref, type) {
    final itemState = ref.watch(dynamicItemProvider);
    return itemState.getFilteredItems(type);
  },
);

final isLoadingItemsProvider = Provider.family<bool, String>((ref, type) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.isLoading(type);
});
