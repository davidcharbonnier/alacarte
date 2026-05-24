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

  final Map<String, int> totalByType;
  final Map<String, int> currentPageByType;
  final Map<String, int> totalPagesByType;
  final Map<String, bool> isLoadingMoreByType;
  final Map<String, Map<String, dynamic>?> typeStatsByType;

  const DynamicItemState({
    this.itemsByType = const {},
    this.loadingByType = const {},
    this.errorsByType = const {},
    this.hasLoadedOnce = false,
    this.searchQueriesByType = const {},
    this.categoryFiltersByType = const {},
    this.totalByType = const {},
    this.currentPageByType = const {},
    this.totalPagesByType = const {},
    this.isLoadingMoreByType = const {},
    this.typeStatsByType = const {},
  });

  DynamicItemState copyWith({
    Map<String, List<DynamicItem>>? itemsByType,
    Map<String, bool>? loadingByType,
    Map<String, String?>? errorsByType,
    bool? hasLoadedOnce,
    Map<String, String>? searchQueriesByType,
    Map<String, Map<String, String>>? categoryFiltersByType,
    Map<String, int>? totalByType,
    Map<String, int>? currentPageByType,
    Map<String, int>? totalPagesByType,
    Map<String, bool>? isLoadingMoreByType,
    Map<String, Map<String, dynamic>?>? typeStatsByType,
  }) {
    return DynamicItemState(
      itemsByType: itemsByType ?? this.itemsByType,
      loadingByType: loadingByType ?? this.loadingByType,
      errorsByType: errorsByType ?? this.errorsByType,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      searchQueriesByType: searchQueriesByType ?? this.searchQueriesByType,
      categoryFiltersByType:
          categoryFiltersByType ?? this.categoryFiltersByType,
      totalByType: totalByType ?? this.totalByType,
      currentPageByType: currentPageByType ?? this.currentPageByType,
      totalPagesByType: totalPagesByType ?? this.totalPagesByType,
      isLoadingMoreByType: isLoadingMoreByType ?? this.isLoadingMoreByType,
      typeStatsByType: typeStatsByType ?? this.typeStatsByType,
    );
  }

  List<DynamicItem> getItems(String type) => itemsByType[type] ?? [];

  bool isLoading(String type) => loadingByType[type] ?? false;

  bool isLoadingMore(String type) => isLoadingMoreByType[type] ?? false;

  String? getError(String type) => errorsByType[type];

  bool hasItems(String type) =>
      itemsByType.containsKey(type) && itemsByType[type]!.isNotEmpty;

  String getSearchQuery(String type) => searchQueriesByType[type] ?? '';

  Map<String, String> getCategoryFilters(String type) =>
      categoryFiltersByType[type] ?? {};

  int totalForType(String type) => totalByType[type] ?? 0;

  bool hasMore(String type) {
    final currentPage = currentPageByType[type] ?? 0;
    final totalPages = totalPagesByType[type] ?? 0;
    return currentPage < totalPages;
  }

  Map<String, dynamic>? typeStats(String type) => typeStatsByType[type];

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
    final search = state.getSearchQuery(type);
    final filters = state.getCategoryFilters(type);

    final response = await _itemService.getItemsByType(
      type,
      schema: schema,
      page: 1,
      search: search.isNotEmpty ? search : null,
      filters: filters.isNotEmpty ? filters : null,
    );

    response.when(
      success: (paginated, _) {
        state = state.copyWith(
          itemsByType: {...state.itemsByType, type: paginated.items},
          loadingByType: {...state.loadingByType, type: false},
          hasLoadedOnce: true,
          totalByType: {...state.totalByType, type: paginated.total},
          currentPageByType: {...state.currentPageByType, type: paginated.page},
          totalPagesByType: {...state.totalPagesByType, type: paginated.totalPages},
        );
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

  Future<void> loadMoreItems(String type) async {
    if (state.isLoading(type) || state.isLoadingMore(type)) return;
    if (!state.hasMore(type)) return;

    final currentPage = state.currentPageByType[type] ?? 0;

    state = state.copyWith(
      isLoadingMoreByType: {...state.isLoadingMoreByType, type: true},
    );

    final schema = _getSchema(type);
    final search = state.getSearchQuery(type);
    final filters = state.getCategoryFilters(type);

    final response = await _itemService.getItemsByType(
      type,
      schema: schema,
      page: currentPage + 1,
      search: search.isNotEmpty ? search : null,
      filters: filters.isNotEmpty ? filters : null,
    );

    response.when(
      success: (paginated, _) {
        final existingItems = state.getItems(type);
        final updatedItems = [...existingItems, ...paginated.items];
        state = state.copyWith(
          itemsByType: {...state.itemsByType, type: updatedItems},
          isLoadingMoreByType: {...state.isLoadingMoreByType, type: false},
          currentPageByType: {...state.currentPageByType, type: paginated.page},
          totalByType: {...state.totalByType, type: paginated.total},
          totalPagesByType: {...state.totalPagesByType, type: paginated.totalPages},
        );
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoadingMoreByType: {...state.isLoadingMoreByType, type: false},
          errorsByType: {...state.errorsByType, type: message},
        );
      },
      loading: () {},
    );
  }

  Future<void> loadTypeStats(String type) async {
    final response = await _itemService.getTypeStats(type);

    response.when(
      success: (stats, _) {
        state = state.copyWith(
          typeStatsByType: {...state.typeStatsByType, type: stats},
        );
      },
      error: (message, statusCode, errorCode, details) {},
      loading: () {},
    );
  }

  Future<ApiResponse<DynamicItem>> createItem(
    String type,
    DynamicItem item,
  ) async {
    final response = await _itemService.createItem(type, item);

    response.when(
      success: (createdItem, _) {
        state = state.copyWith(
          totalByType: {...state.totalByType, type: 0},
          currentPageByType: {...state.currentPageByType, type: 0},
          totalPagesByType: {...state.totalPagesByType, type: 0},
        );
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
        state = state.copyWith(
          totalByType: {...state.totalByType, type: 0},
          currentPageByType: {...state.currentPageByType, type: 0},
          totalPagesByType: {...state.totalPagesByType, type: 0},
        );
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

  void updateSearchQuery(String type, String query) {
    state = state.copyWith(
      searchQueriesByType: {...state.searchQueriesByType, type: query},
    );
  }

  void updateSearchAndLoad(String type, String query) {
    state = state.copyWith(
      searchQueriesByType: {...state.searchQueriesByType, type: query},
    );
    loadItems(type, forceRefresh: true);
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
    loadItems(type, forceRefresh: true);
  }

  void clearFilters(String type) {
    state = state.copyWith(
      searchQueriesByType: {...state.searchQueriesByType, type: ''},
      categoryFiltersByType: {...state.categoryFiltersByType, type: {}},
    );
    loadItems(type, forceRefresh: true);
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
    state = state.copyWith(
      totalByType: {...state.totalByType, type: 0},
      currentPageByType: {...state.currentPageByType, type: 0},
      totalPagesByType: {...state.totalPagesByType, type: 0},
    );
  }

  void addItem(String type, DynamicItem item) {
    final items = state.getItems(type);
    final existingIndex = items.indexWhere((i) => i.id == item.id);
    List<DynamicItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List<DynamicItem>.from(items);
      updatedItems[existingIndex] = item;
    } else {
      updatedItems = [...items, item];
    }
    state = state.copyWith(
      itemsByType: {...state.itemsByType, type: updatedItems},
      totalByType: {...state.totalByType, type: 0},
      currentPageByType: {...state.currentPageByType, type: 0},
      totalPagesByType: {...state.totalPagesByType, type: 0},
    );
  }

  void updateItemInCache(String type, DynamicItem item) {
    addItem(type, item);
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

final isLoadingItemsProvider = Provider.family<bool, String>((ref, type) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.isLoading(type);
});

final totalItemsProvider = Provider.family<int, String>((ref, type) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.totalForType(type);
});

final hasMoreProvider = Provider.family<bool, String>((ref, type) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.hasMore(type);
});

final isLoadingMoreProvider = Provider.family<bool, String>((ref, type) {
  final itemState = ref.watch(dynamicItemProvider);
  return itemState.isLoadingMore(type);
});