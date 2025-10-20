import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/rating_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/community_stats_provider.dart';
import '../../services/api_service.dart';
import '../../models/rating.dart';
import '../../models/rateable_item.dart';
import '../../models/cheese_item.dart';
import '../../models/gin_item.dart';
import '../../models/wine_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/safe_navigation.dart';
import '../../utils/item_provider_helper.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/item_search_filter.dart';
import '../../widgets/items/item_image.dart';
import '../../utils/item_filter_helper.dart';

/// Provider to remember the last active tab for each item type
final itemTypeTabProvider = StateProvider.family<int, String>((ref, itemType) => 0);

/// Dedicated screen for a specific item type (cheese, gin, wine, etc.)
class ItemTypeScreen extends ConsumerStatefulWidget {
  final String itemType;

  const ItemTypeScreen({super.key, required this.itemType});

  @override
  ConsumerState<ItemTypeScreen> createState() => _ItemTypeScreenState();
}

class _ItemTypeScreenState extends ConsumerState<ItemTypeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Cache the last loaded item IDs to prevent infinite provider refreshes
  List<int>? _lastLoadedItemIds;

  @override
  void initState() {
    super.initState();
    
    // Restore last active tab from provider
    final lastTab = ref.read(itemTypeTabProvider(widget.itemType));
    
    // Start with last active tab (defaults to "All Items" if never set)
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: lastTab.clamp(0, 1), // Ensure valid tab index
    );

    // Listen to tab changes to save state and update FAB visibility
    _tabController.addListener(() {
      // Save current tab to provider
      ref.read(itemTypeTabProvider(widget.itemType).notifier).state = _tabController.index;
      
      _onTabChanged(); // Clear tab-specific filters
      setState(() {
        // Rebuild to update FAB visibility
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItemTypeData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadItemTypeData() {
    // Only load if data has never been loaded and is not currently loading
    if (!ItemProviderHelper.hasLoadedOnce(ref, widget.itemType) &&
        !ItemProviderHelper.isLoading(ref, widget.itemType)) {
      ItemProviderHelper.loadItems(ref, widget.itemType);
    }

    // Always refresh ratings as they can change more frequently
    ref.read(ratingProvider.notifier).refreshRatings();
  }

  void _onTabChanged() {
    // Clear tab-specific filters when switching tabs
    final activeFilters = ItemProviderHelper.getActiveFilters(ref, widget.itemType);
    final hasTabSpecificFilters =
        activeFilters.containsKey('rating_source') ||
        activeFilters.containsKey('rating_status');

    if (hasTabSpecificFilters) {
      ItemProviderHelper.clearTabSpecificFilters(ref, widget.itemType);
    }
  }

  void _navigateToSettings() {
    GoRouter.of(context).go(RouteNames.userSettings);
  }

  void _navigateToAddItem() {
    if (widget.itemType == 'cheese') {
      GoRouter.of(context).go(RouteNames.cheeseCreate);
    } else if (widget.itemType == 'gin') {
      GoRouter.of(context).go(RouteNames.ginCreate);
    } else if (widget.itemType == 'wine') {
      GoRouter.of(context).go(RouteNames.wineCreate);
    } else {
      // Future enhancement: support other item types
      GoRouter.of(context).go(RouteNames.cheeseCreate);
    }
  }

  void _switchItemType(String newItemType) {
    if (newItemType != widget.itemType) {
      GoRouter.of(context).go('${RouteNames.itemType}/$newItemType');
    }
  }

  void _goBackToHub() {
    SafeNavigation.goBackToHub(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final appState = ref.watch(appProvider);
    final currentUser = authState.user;

    // Generic loading state using helper
    final isLoading = ItemProviderHelper.isLoading(ref, widget.itemType) ||
        ref.watch(ratingProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: _buildItemTypeSwitcher(context),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: _goBackToHub,
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.backToHub,
        ),
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: true,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: ItemTypeLocalizer.getAllItemsText(context, widget.itemType),
            ),
            Tab(
              icon: const Icon(Icons.bookmark),
              text: ItemTypeLocalizer.getMyItemListText(
                context,
                widget.itemType,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter interface (works for all item types)
          _buildSearchAndFilter(),

          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllItemsTab(isLoading),
                _buildMyListTab(isLoading),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddItem,
              tooltip: ItemTypeLocalizer.getAddItemText(context, widget.itemType),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  int _getTabSpecificTotalCount() {
    final items = ItemProviderHelper.getItems(ref, widget.itemType);

    if (_tabController.index == 0) {
      // "All Items" tab - show total available items
      return items.length;
    } else {
      // "My List" tab - show total items in personal list
      final ratingState = ref.read(ratingProvider);
      final currentUserId = ref.read(authProvider).user?.id;
      final userRatings = ratingState.ratings as List<Rating>;

      final ratedItemIds = userRatings
          .where((r) => r.itemType == widget.itemType)
          .map((r) => r.itemId)
          .toSet();

      return items.where((item) => ratedItemIds.contains(item.id)).length;
    }
  }

  int _getTabSpecificFilteredCount() {
    final filteredItems = ItemProviderHelper.getFilteredItems(ref, widget.itemType);
    final activeFilters = ItemProviderHelper.getActiveFilters(ref, widget.itemType);
    final ratingState = ref.read(ratingProvider);
    final currentUserId = ref.read(authProvider).user?.id;
    final userRatings = ratingState.ratings as List<Rating>;

    if (_tabController.index == 0) {
      // "All Items" tab - apply rating filters to get accurate count
      var itemsToCount = filteredItems;

      // Apply rating-based filters if any
      if (activeFilters.containsKey('rating_status')) {
        itemsToCount = ItemFilterHelper.filterItemsWithRatingContext(
          itemsToCount,
          userRatings,
          currentUserId,
          activeFilters,
          false, // isPersonalListTab = false
        );
      }

      return itemsToCount.length;
    } else {
      // "My List" tab - show filtered personal list count
      final ratingSourceFilter = activeFilters['rating_source'];

      // Apply search and filter to the base items first
      var filteredBaseItems = filteredItems;

      // Apply rating source filters if any (My Ratings vs Recommendations)
      if (activeFilters.containsKey('rating_source')) {
        final allItems = ItemProviderHelper.getItems(ref, widget.itemType);
        final searchQuery = ItemProviderHelper.getSearchQuery(ref, widget.itemType);
        
        // For recommendations filter, we need to start with all items that have ratings
        if (ratingSourceFilter == 'recommendations') {
          final allRatedItemIds = userRatings
              .where((r) => r.itemType == widget.itemType)
              .map((r) => r.itemId)
              .toSet();

          // Start with all items that have any ratings, then apply search/category filters
          var allRatedItems = allItems
              .where((item) => allRatedItemIds.contains(item.id))
              .toList();

          // Apply search query if present
          if (searchQuery.isNotEmpty) {
            allRatedItems = allRatedItems
                .where((item) => item.searchableText.contains(searchQuery.toLowerCase()))
                .toList();
          }

          // Apply category filters if present
          for (final entry in activeFilters.entries) {
            if (entry.key != 'rating_source') {
              allRatedItems = allRatedItems
                  .where(
                    (item) =>
                        item.categories[entry.key]?.toLowerCase() ==
                        entry.value?.toLowerCase(),
                  )
                  .toList();
            }
          }

          filteredBaseItems = allRatedItems;
        } else if (ratingSourceFilter == 'personal') {
          // For personal filter, start with items the user has rated
          final personalRatedItemIds = userRatings
              .where(
                (r) => r.itemType == widget.itemType && r.authorId == currentUserId,
              )
              .map((r) => r.itemId)
              .toSet();

          // Start with all items that user has rated, then apply search/category filters
          var personalRatedItems = allItems
              .where((item) => personalRatedItemIds.contains(item.id))
              .toList();

          // Apply search query if present
          if (searchQuery.isNotEmpty) {
            personalRatedItems = personalRatedItems
                .where((item) => item.searchableText.contains(searchQuery.toLowerCase()))
                .toList();
          }

          // Apply category filters if present
          for (final entry in activeFilters.entries) {
            if (entry.key != 'rating_source') {
              personalRatedItems = personalRatedItems
                  .where(
                    (item) =>
                        item.categories[entry.key]?.toLowerCase() ==
                        entry.value?.toLowerCase(),
                  )
                  .toList();
            }
          }

          filteredBaseItems = personalRatedItems;
        }

        filteredBaseItems = ItemFilterHelper.filterItemsWithRatingContext(
          filteredBaseItems,
          userRatings,
          currentUserId,
          activeFilters,
          true, // isPersonalListTab = true
        );

        // When rating filter is active, just return the filtered items count
        return filteredBaseItems.length;
      }

      final personalRatings = userRatings
          .where(
            (r) =>
                r.itemType == widget.itemType &&
                r.authorId == currentUserId &&
                filteredBaseItems.any((item) => item.id == r.itemId),
          )
          .toList();

      final sharedRatings = userRatings
          .where(
            (r) =>
                r.itemType == widget.itemType &&
                r.authorId != currentUserId &&
                filteredBaseItems.any((item) => item.id == r.itemId),
          )
          .toList();

      final personalItemIds = personalRatings.map((r) => r.itemId).toSet();
      final sharedItemIds = sharedRatings.map((r) => r.itemId).toSet();
      final sharedOnlyItemIds = sharedItemIds.difference(personalItemIds);

      return personalItemIds.length + sharedOnlyItemIds.length;
    }
  }

  Widget _buildItemTypeSwitcher(BuildContext context) {
    return PopupMenuButton<String>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ItemTypeHelper.getItemTypeIcon(widget.itemType)),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
          ),
          const SizedBox(width: AppConstants.spacingXS),
          const Icon(Icons.arrow_drop_down, size: AppConstants.iconM),
        ],
      ),
      onSelected: _switchItemType,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'cheese',
          child: Row(
            children: [
              Icon(
                Icons.local_pizza,
                color: widget.itemType == 'cheese'
                    ? AppConstants.primaryColor
                    : null,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                ItemTypeLocalizer.getLocalizedItemType(context, 'cheese'),
                style: TextStyle(
                  fontWeight: widget.itemType == 'cheese'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.itemType == 'cheese'
                      ? AppConstants.primaryColor
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'gin',
          child: Row(
            children: [
              Icon(
                Icons.local_bar,
                color: widget.itemType == 'gin' ? Colors.teal : null,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                ItemTypeLocalizer.getLocalizedItemType(context, 'gin'),
                style: TextStyle(
                  fontWeight:
                      widget.itemType == 'gin' ? FontWeight.bold : FontWeight.normal,
                  color: widget.itemType == 'gin' ? Colors.teal : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'wine',
          child: Row(
            children: [
              Icon(
                Icons.wine_bar,
                color: widget.itemType == 'wine' ? const Color(0xFF8E24AA) : null,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                ItemTypeLocalizer.getLocalizedItemType(context, 'wine'),
                style: TextStyle(
                  fontWeight:
                      widget.itemType == 'wine' ? FontWeight.bold : FontWeight.normal,
                  color: widget.itemType == 'wine' ? const Color(0xFF8E24AA) : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.add_box, color: Colors.grey),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                context.l10n.moreCategoriesComingSoon,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllItemsTab(bool isLoading) {
    if (!ItemTypeHelper.isItemTypeSupported(widget.itemType)) {
      return _buildComingSoonTab();
    }

    final filteredItems = ItemProviderHelper.getFilteredItems(ref, widget.itemType);
    final allItems = ItemProviderHelper.getItems(ref, widget.itemType);
    final activeFilters = ItemProviderHelper.getActiveFilters(ref, widget.itemType);
    final ratingState = ref.watch(ratingProvider);
    final currentUserId = ref.read(authProvider).user?.id;

    // Start with provider's filtered items (search + category filters)
    var itemsToShow = filteredItems;

    // Apply rating-based filters if any
    if (activeFilters.containsKey('rating_status')) {
      itemsToShow = ItemFilterHelper.filterItemsWithRatingContext(
        itemsToShow,
        ratingState.ratings,
        currentUserId,
        activeFilters,
        false, // isPersonalListTab = false
      );
    }

    // Load community stats in batch for all visible items (HTTP/2 multiplexing!)
    final itemIds = itemsToShow.map((item) => item.id!).toList();
    
    // Only update if the item IDs actually changed (prevent infinite loop)
    final itemIdsChanged = _lastLoadedItemIds == null ||
        itemIds.length != _lastLoadedItemIds!.length ||
        !_listEquals(itemIds, _lastLoadedItemIds!);
    
    if (itemIdsChanged) {
      // Update the cached list only when it actually changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastLoadedItemIds = List.from(itemIds);
          });
        }
      });
    }
    
    // Use cached IDs for provider to prevent recreation on every build
    final idsToLoad = _lastLoadedItemIds ?? itemIds;
    final batchStatsAsync = ref.watch(
      communityStatsProvider(
        CommunityStatsParams(
          itemType: widget.itemType,
          itemIds: idsToLoad,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        // Clear all caches for fresh data
        final apiService = ref.read(apiServiceProvider);
        apiService.clearCommunityStatsCache(); // Clear all stats cache
        
        final ratingService = ref.read(ratingServiceProvider);
        ratingService.clearCache(); // Clear all ratings cache
        
        await ItemProviderHelper.refreshItems(ref, widget.itemType);
        ref.read(ratingProvider.notifier).refreshRatings();
        // Invalidate batch stats to force refresh
        ref.invalidate(communityStatsProvider);
      },
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allItems.isEmpty
              ? _buildEmptyItemsState()
              : itemsToShow.isEmpty && activeFilters.isNotEmpty
                  ? _buildNoFilterResultsState()
                  : batchStatsAsync.when(
                      data: (statsMap) => _buildItemsList(
                        itemsToShow,
                        ratingState.ratings,
                        statsMap: statsMap,
                        showAll: true,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => _buildItemsList(
                        itemsToShow,
                        ratingState.ratings,
                        statsMap: {}, // Empty map on error - placeholders will show
                        showAll: true,
                      ),
                    ),
    );
  }

  Widget _buildMyListTab(bool isLoading) {
    if (!ItemTypeHelper.isItemTypeSupported(widget.itemType)) {
      return _buildComingSoonTab();
    }

    final filteredItems = ItemProviderHelper.getFilteredItems(ref, widget.itemType);
    final allItems = ItemProviderHelper.getItems(ref, widget.itemType);
    final activeFilters = ItemProviderHelper.getActiveFilters(ref, widget.itemType);
    final searchQuery = ItemProviderHelper.getSearchQuery(ref, widget.itemType);
    final ratingState = ref.watch(ratingProvider);
    final currentUserId = ref.read(authProvider).user?.id;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userRatings = ratingState.ratings as List<Rating>;

    // Apply search and filter to the base items first
    var filteredBaseItems = filteredItems;

    // Apply rating source filters if any (My Ratings vs Recommendations)
    if (activeFilters.containsKey('rating_source')) {
      final ratingSourceFilter = activeFilters['rating_source'];

      // For recommendations filter, we need to start with all items that have ratings
      if (ratingSourceFilter == 'recommendations') {
        final allRatedItemIds = userRatings
            .where((r) => r.itemType == widget.itemType)
            .map((r) => r.itemId)
            .toSet();

        // Start with all items that have any ratings, then apply search/category filters
        var allRatedItems =
            allItems.where((item) => allRatedItemIds.contains(item.id)).toList();

        // Apply search query if present
        if (searchQuery.isNotEmpty) {
          allRatedItems = allRatedItems
              .where((item) => item.searchableText.contains(searchQuery.toLowerCase()))
              .toList();
        }

        // Apply category filters if present
        for (final entry in activeFilters.entries) {
          if (entry.key != 'rating_source') {
            allRatedItems = allRatedItems
                .where(
                  (item) =>
                      item.categories[entry.key]?.toLowerCase() ==
                      entry.value?.toLowerCase(),
                )
                .toList();
          }
        }

        filteredBaseItems = allRatedItems;
      } else if (ratingSourceFilter == 'personal') {
        // For personal filter, start with items the user has rated
        final personalRatedItemIds = userRatings
            .where((r) => r.itemType == widget.itemType && r.authorId == currentUserId)
            .map((r) => r.itemId)
            .toSet();

        // Start with all items that user has rated, then apply search/category filters
        var personalRatedItems =
            allItems.where((item) => personalRatedItemIds.contains(item.id)).toList();

        // Apply search query if present
        if (searchQuery.isNotEmpty) {
          personalRatedItems = personalRatedItems
              .where((item) => item.searchableText.contains(searchQuery.toLowerCase()))
              .toList();
        }

        // Apply category filters if present
        for (final entry in activeFilters.entries) {
          if (entry.key != 'rating_source') {
            personalRatedItems = personalRatedItems
                .where(
                  (item) =>
                      item.categories[entry.key]?.toLowerCase() ==
                      entry.value?.toLowerCase(),
                )
                .toList();
          }
        }

        filteredBaseItems = personalRatedItems;
      }

      filteredBaseItems = ItemFilterHelper.filterItemsWithRatingContext(
        filteredBaseItems,
        userRatings,
        currentUserId,
        activeFilters,
        true, // isPersonalListTab = true
      );

      // When rating source filter is active, use simplified logic
      if (ratingSourceFilter == 'personal') {
        // Show only items user has rated personally
        final personalRatings = userRatings
            .where(
              (r) =>
                  r.itemType == widget.itemType &&
                  r.authorId == currentUserId &&
                  filteredBaseItems.any((item) => item.id == r.itemId),
            )
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(ratingProvider.notifier).refreshRatings();
          },
          child: filteredBaseItems.isEmpty
              ? _buildNoFilterResultsState()
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  children: filteredBaseItems.map((item) {
                    final myRating =
                        personalRatings.where((r) => r.itemId == item.id).firstOrNull;
                    return _buildItemCard(item, myRating, [], false);
                  }).toList(),
                ),
        );
      } else if (ratingSourceFilter == 'recommendations') {
        // Show items that others have recommended (shared with current user)
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(ratingProvider.notifier).refreshRatings();
          },
          child: filteredBaseItems.isEmpty
              ? _buildNoFilterResultsState()
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  children: filteredBaseItems.map((item) {
                    final myRating = userRatings
                        .where(
                          (r) => r.authorId == currentUserId && r.itemId == item.id,
                        )
                        .firstOrNull;
                    final itemRecommendations = userRatings
                        .where(
                          (r) =>
                              r.itemType == widget.itemType &&
                              r.authorId != currentUserId &&
                              r.isVisibleToUser(currentUserId ?? 0) &&
                              r.itemId == item.id,
                        )
                        .toList();
                    return _buildItemCard(
                      item,
                      myRating,
                      itemRecommendations,
                      false,
                    );
                  }).toList(),
                ),
        );
      }
    }

    // No rating source filter - show both personal and shared items (original logic)
    final personalRatings = userRatings
        .where(
          (r) =>
              r.itemType == widget.itemType &&
              r.authorId == currentUserId &&
              filteredBaseItems.any((item) => item.id == r.itemId),
        )
        .toList();

    final sharedRatings = userRatings
        .where(
          (r) =>
              r.itemType == widget.itemType &&
              r.authorId != currentUserId &&
              filteredBaseItems.any((item) => item.id == r.itemId),
        )
        .toList();

    // Get items that match the current filters AND have ratings
    final personalItemIds = personalRatings.map((r) => r.itemId).toSet();
    final personalItems =
        filteredBaseItems.where((item) => personalItemIds.contains(item.id)).toList();

    // Get items for shared ratings (items user hasn't rated themselves)
    final sharedItemIds = sharedRatings.map((r) => r.itemId).toSet();
    final sharedOnlyItemIds = sharedItemIds.difference(personalItemIds);
    final sharedOnlyItems =
        filteredBaseItems.where((item) => sharedOnlyItemIds.contains(item.id)).toList();

    final totalItems = personalItems.length + sharedOnlyItems.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ratingProvider.notifier).refreshRatings();
      },
      child: totalItems == 0
          ? (activeFilters.isNotEmpty
              ? _buildNoFilterResultsState()
              : _buildEmptyMyListState())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                // Items with personal ratings
                ...personalItems.map((item) {
                  final myRating =
                      personalRatings.where((r) => r.itemId == item.id).firstOrNull;
                  final itemSharedRatings =
                      sharedRatings.where((r) => r.itemId == item.id).toList();
                  return _buildItemCard(
                    item,
                    myRating,
                    itemSharedRatings,
                    false,
                  );
                }),

                // Items with only shared ratings (recommendations)
                ...sharedOnlyItems.map((item) {
                  final itemSharedRatings =
                      sharedRatings.where((r) => r.itemId == item.id).toList();
                  return _buildItemCard(item, null, itemSharedRatings, false);
                }),
              ],
            ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  context.l10n.noResultsFound,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  context.l10n.adjustSearchFilters,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                OutlinedButton(
                  onPressed: () {
                    ItemProviderHelper.clearFilters(ref, widget.itemType);
                  },
                  child: Text(context.l10n.clearAllFilters),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(
    List<RateableItem> items,
    List<Rating> allRatings, {
    Map<int, Map<String, dynamic>>? statsMap,
    required bool showAll,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        96, // FAB height (56px) + FAB bottom margin (24px) + card spacing (16px)
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemRatings = allRatings
            .where((r) => r.itemId == item.id && r.itemType == widget.itemType)
            .toList();
        final currentUserId = ref.watch(authProvider).user?.id;
        final myRating =
            itemRatings.where((r) => r.authorId == currentUserId).firstOrNull;
        final sharedRatings = itemRatings
            .where(
              (r) =>
                  r.authorId != currentUserId &&
                  r.isVisibleToUser(currentUserId ?? 0),
            )
            .toList();

        return _buildItemCard(
          item,
          myRating,
          sharedRatings,
          showAll,
          statsMap: statsMap,
        );
      },
    );
  }

  Widget _buildItemCard(
    RateableItem item,
    Rating? myRating,
    List<Rating> sharedRatings,
    bool showCommunityData, {
    Map<int, Map<String, dynamic>>? statsMap,
  }) {
    // Get image URL based on item type
    String? imageUrl;
    if (item is CheeseItem) {
      imageUrl = item.imageUrl;
    } else if (item is GinItem) {
      imageUrl = item.imageUrl;
    } else if (item is WineItem) {
      imageUrl = item.imageUrl;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: InkWell(
        onTap: () {
          GoRouter.of(context).go('/items/${widget.itemType}/${item.id}');
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Row(
            children: [
              // Image thumbnail
              ItemImage(
                imageUrl: imageUrl,
                itemType: widget.itemType,
                size: 60,
              ),
              const SizedBox(width: AppConstants.spacingM),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with inline rating badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        // Inline rating badges
                        if (showCommunityData)
                          _buildCommunityRatingsSummary(item.id!, statsMap: statsMap)
                        else
                          ..._buildCompactRatingBadges(
                            myRating,
                            sharedRatings,
                            item.id!,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      item.displaySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityRatingsSummary(int itemId, {Map<int, Map<String, dynamic>>? statsMap}) {
    // If we have preloaded stats from batch request, use them directly
    if (statsMap != null) {
      final stats = statsMap[itemId];
      
      if (stats == null) {
        // Stats not available for this item - show placeholder
        return _buildStatsBadge(
          icon: Icons.people_outline,
          text: '0',
          color: Colors.grey,
          isError: false,
        );
      }
      
      final totalRatings = (stats['total_ratings'] as int?) ?? 0;
      final averageRating = ((stats['average_rating'] as num?) ?? 0).toDouble();
      
      if (totalRatings == 0) {
        return _buildStatsBadge(
          icon: Icons.people_outline,
          text: '0',
          color: Colors.grey,
          isError: false,
        );
      }
      
      return _buildStatsBadge(
        icon: Icons.people,
        text: '${averageRating.toStringAsFixed(1)} ($totalRatings)',
        color: AppConstants.communityRatingColor,
        isError: false,
      );
    }
    
    // Fallback: No batch stats provided - this shouldn't happen in "All Items" tab
    // but keeping for safety
    return _buildStatsBadge(
      icon: Icons.people_outline,
      text: '--',
      color: Colors.grey,
      isError: false,
    );
  }
  
  Widget _buildStatsBadge({
    required IconData icon,
    required String text,
    required Color color,
    required bool isError,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isError ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: isError ? null : Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppConstants.iconS,
            color: color,
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppConstants.fontS,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompactRatingBadges(
    Rating? myRating,
    List<Rating> sharedRatings,
    int itemId,
  ) {
    final badges = <Widget>[];

    if (myRating != null) {
      badges.add(
        _buildCompactBadge(
          Icons.person,
          myRating.grade.toStringAsFixed(1),
          AppConstants.personalRatingColor,
        ),
      );
    }

    if (sharedRatings.isNotEmpty) {
      if (badges.isNotEmpty) {
        badges.add(const SizedBox(width: AppConstants.spacingXS));
      }
      badges.add(
        _buildCompactBadge(
          Icons.recommend,
          sharedRatings.length.toString(),
          AppConstants.recommendationColor,
        ),
      );
    }

    // Return empty list for unrated items - cleaner appearance
    return badges;
  }

  Widget _buildCompactBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppConstants.iconS, color: color),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppConstants.fontM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            context.l10n.comingSoon(
              ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
            ),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ItemTypeHelper.getItemTypeIcon(widget.itemType),
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  context.l10n.noItemsAvailable(
                    ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  context.l10n.addFirstItem(
                    ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                ElevatedButton.icon(
                  onPressed: _navigateToAddItem,
                  icon: const Icon(Icons.add),
                  label: Text(
                    context.l10n.addFirstItemButton(
                      ItemTypeLocalizer.getLocalizedItemType(
                        context,
                        widget.itemType,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMyListState() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  context.l10n.yourListEmpty(
                    ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  context.l10n.rateItemsToBuild(
                    ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.explore),
                  label: Text(
                    context.l10n.exploreItems(
                      ItemTypeLocalizer.getLocalizedItemType(
                        context,
                        widget.itemType,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    final allItems = ItemProviderHelper.getItems(ref, widget.itemType);
    final activeFilters = ItemProviderHelper.getActiveFilters(ref, widget.itemType);
    final searchQuery = ItemProviderHelper.getSearchQuery(ref, widget.itemType);
    final ratingState = ref.watch(ratingProvider);

    // Get available filter options for this item type
    final availableFilters = ItemFilterHelper.getAvailableFilters(
      allItems,
      widget.itemType,
    );

    return ItemSearchAndFilter(
      itemType: widget.itemType,
      onSearchChanged: (query) {
        ItemProviderHelper.updateSearchQuery(ref, widget.itemType, query);
      },
      onFilterChanged: (categoryKey, value) {
        ItemProviderHelper.setCategoryFilter(ref, widget.itemType, categoryKey, value);
      },
      onClearFilters: () {
        ItemProviderHelper.clearFilters(ref, widget.itemType);
      },
      availableFilters: availableFilters,
      activeFilters: activeFilters,
      currentSearchQuery: searchQuery,
      totalItems: _getTabSpecificTotalCount(),
      filteredItems: _getTabSpecificFilteredCount(),
      isPersonalListTab: _tabController.index == 1, // Pass current tab context
    );
  }
  
  // Helper to compare lists
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
