import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rateable_item.dart';
import '../models/api_response.dart';
import '../models/dynamic_item.dart';
import '../providers/dynamic_item_provider.dart';

class ItemProviderHelper {
  static List<RateableItem> getItems(WidgetRef ref, String itemType) {
    return ref
        .watch(dynamicItemProvider)
        .getItems(itemType)
        .cast<RateableItem>();
  }

  static bool isLoading(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).isLoading(itemType);
  }

  static bool hasLoadedOnce(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).hasLoadedOnce;
  }

  static String? getErrorMessage(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).getError(itemType);
  }

  static String getSearchQuery(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).getSearchQuery(itemType);
  }

  static Map<String, String> getActiveFilters(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).getCategoryFilters(itemType);
  }

  static bool hasMore(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).hasMore(itemType);
  }

  static bool isLoadingMore(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).isLoadingMore(itemType);
  }

  static int totalItems(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).totalForType(itemType);
  }

  static Map<String, dynamic>? typeStats(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).typeStats(itemType);
  }

  static void loadItems(WidgetRef ref, String itemType) {
    ref.read(dynamicItemProvider.notifier).loadItems(itemType);
  }

  static Future<void> refreshItems(WidgetRef ref, String itemType) async {
    await ref.read(dynamicItemProvider.notifier).refreshItems(itemType);
  }

  static Future<void> loadMoreItems(WidgetRef ref, String itemType) async {
    await ref.read(dynamicItemProvider.notifier).loadMoreItems(itemType);
  }

  static Future<void> loadTypeStats(WidgetRef ref, String itemType) async {
    await ref.read(dynamicItemProvider.notifier).loadTypeStats(itemType);
  }

  static void clearFilters(WidgetRef ref, String itemType) {
    ref.read(dynamicItemProvider.notifier).clearFilters(itemType);
  }

  static void clearTabSpecificFilters(WidgetRef ref, String itemType) {
    ref.read(dynamicItemProvider.notifier).clearTabSpecificFilters(itemType);
  }

  static void updateSearchQuery(WidgetRef ref, String itemType, String query) {
    ref.read(dynamicItemProvider.notifier).updateSearchAndLoad(itemType, query);
  }

  static void setCategoryFilter(
    WidgetRef ref,
    String itemType,
    String key,
    String? value,
  ) {
    ref
        .read(dynamicItemProvider.notifier)
        .setCategoryFilter(itemType, key, value);
  }

  static Future<RateableItem?> getItemById(
    WidgetRef ref,
    String itemType,
    int itemId,
  ) async {
    final response = await ref
        .read(dynamicItemProvider.notifier)
        .getItemById(itemType, itemId);
    return response.when(
      success: (item, _) {
        ref.read(dynamicItemProvider.notifier).addItem(itemType, item);
        return item;
      },
      error: (message, statusCode, errorCode, details) {
        if (kDebugMode) {
          print('getItemById error: $message, statusCode: $statusCode');
        }
        return null;
      },
      loading: () => null,
    );
  }

  static Future<void> loadSpecificItems(
    WidgetRef ref,
    String itemType,
    List<int> itemIds,
  ) async {
    for (final itemId in itemIds) {
      invalidateItem(ref, itemType, itemId);

      final response = await ref
          .read(dynamicItemProvider.notifier)
          .getItemById(itemType, itemId);
      response.when(
        success: (item, _) {
          ref.read(dynamicItemProvider.notifier).addItem(itemType, item);
        },
        error: (message, statusCode, errorCode, details) {},
        loading: () {},
      );
    }
  }

  static void updateItemInCache(WidgetRef ref, String itemType, DynamicItem item) {
    ref.read(dynamicItemProvider.notifier).updateItemInCache(itemType, item);
  }

  static void invalidateItem(WidgetRef ref, String itemType, int itemId) {
    ref.read(dynamicItemProvider.notifier).invalidateItem(itemType, itemId);
  }

  static List<RateableItem> getUserRatedItems(
      WidgetRef ref, String itemType) {
    return ref
        .watch(dynamicItemProvider)
        .getUserRatedItems(itemType)
        .cast<RateableItem>();
  }

  static bool userRatedHasMore(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).userRatedHasMore(itemType);
  }

  static bool userRatedIsLoadingMore(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).isUserRatedLoadingMore(itemType);
  }

  static int userRatedTotalItems(WidgetRef ref, String itemType) {
    return ref.watch(dynamicItemProvider).userRatedTotalForType(itemType);
  }

  static Future<void> loadUserRatedItems(WidgetRef ref, String itemType) async {
    await ref
        .read(dynamicItemProvider.notifier)
        .loadUserRatedItems(itemType);
  }

  static Future<void> loadMoreUserRatedItems(
      WidgetRef ref, String itemType) async {
    await ref
        .read(dynamicItemProvider.notifier)
        .loadMoreUserRatedItems(itemType);
  }

  static Future<void> refreshUserRatedItems(
      WidgetRef ref, String itemType) async {
    await ref
        .read(dynamicItemProvider.notifier)
        .refreshUserRatedItems(itemType);
  }
}