import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/rating_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/rateable_item.dart';
import '../../models/cheese_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/appbar_helper.dart';
import '../../routes/route_names.dart';
// Removed auth_status_widget import - user profile now shown in app bar

/// Item Type Hub - main dashboard for selecting item type to focus on
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateToItemType(BuildContext context, String itemType) {
    GoRouter.of(context).go('${RouteNames.itemType}/$itemType');
  }

  void _navigateToSettings(BuildContext context) {
    // TODO: Implement OAuth settings screen or remove this
    // For now, we can show the auth status widget in the home screen
  }
  
  /// Count unique items that have ratings (personal or shared) for this user
  int _getUniqueItemCount(List<dynamic> ratings, String itemType) {
    final itemIds = ratings
        .where((r) => r.itemType == itemType)
        .map((r) => r.itemId)
        .toSet(); // Set automatically handles uniqueness
    return itemIds.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the rating listener to enable automatic auth change reactions
    ref.read(ratingListenerProvider);
    
    // Ensure data is loaded when accessing the home screen
    final cheeseItemState = ref.watch(cheeseItemProvider);
    final ginItemState = ref.watch(ginItemProvider);
    final wineItemState = ref.watch(wineItemProvider);
    final coffeeItemState = ref.watch(coffeeItemProvider);
    
    // Load cheese data if not already loaded and not currently loading
    if (!cheeseItemState.hasLoadedOnce && !cheeseItemState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cheeseItemProvider.notifier).loadItems();
      });
    }
    
    // Load gin data if not already loaded and not currently loading
    if (!ginItemState.hasLoadedOnce && !ginItemState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ginItemProvider.notifier).loadItems();
      });
    }
    
    // Load wine data if not already loaded and not currently loading
    if (!wineItemState.hasLoadedOnce && !wineItemState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(wineItemProvider.notifier).loadItems();
      });
    }
    
    // Load coffee data if not already loaded and not currently loading
    if (!coffeeItemState.hasLoadedOnce && !coffeeItemState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(coffeeItemProvider.notifier).loadItems();
      });
    }
    
    final authState = ref.watch(authProvider);
    final ratingState = ref.watch(ratingProvider);
    final appState = ref.watch(appProvider);

    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('A la carte'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: true
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(cheeseItemProvider.notifier).refreshItems();
          ref.read(ginItemProvider.notifier).refreshItems();
          ref.read(wineItemProvider.notifier).refreshItems();
          ref.read(coffeeItemProvider.notifier).refreshItems();
          ref.read(ratingProvider.notifier).refreshRatings();
        },
        child: SingleChildScrollView(
          padding: AppConstants.screenPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item type grid
                  Text(
                    context.l10n.yourPreferenceLists,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Item type cards
                  _buildItemTypeCard(
                    context,
                    ItemTypeLocalizer.getLocalizedItemType(context, 'cheese'),
                    'cheese',
                    Icons.local_pizza,
                    AppConstants.primaryColor,
                    cheeseItemState.items.length,
                    _getUniqueItemCount(ratingState.ratings, 'cheese'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  _buildItemTypeCard(
                    context,
                    ItemTypeLocalizer.getLocalizedItemType(context, 'gin'),
                    'gin',
                    Icons.local_bar,
                    Colors.teal,
                    ginItemState.items.length,
                    _getUniqueItemCount(ratingState.ratings, 'gin'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  _buildItemTypeCard(
                    context,
                    ItemTypeLocalizer.getLocalizedItemType(context, 'wine'),
                    'wine',
                    Icons.wine_bar,
                    const Color(0xFF8E24AA),
                    wineItemState.items.length,
                    _getUniqueItemCount(ratingState.ratings, 'wine'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  _buildItemTypeCard(
                    context,
                    ItemTypeLocalizer.getLocalizedItemType(context, 'coffee'),
                    'coffee',
                    Icons.local_cafe,
                    Colors.brown,
                    coffeeItemState.items.length,
                    _getUniqueItemCount(ratingState.ratings, 'coffee'),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Future item types (grayed out for now)
                  _buildComingSoonCard(context, context.l10n.moreCategoriesTitle, Icons.add_box, Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTypeCard(
    BuildContext context,
    String displayName,
    String itemType,
    IconData icon,
    Color color,
    int totalItems,
    int myRatings,
  ) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToItemType(context, itemType),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Icon(
                  icon,
                  size: AppConstants.iconXL,
                  color: color,
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingM),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      context.l10n.itemsAvailable(totalItems),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      context.l10n.inYourList(myRatings),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(BuildContext context, String displayName, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Icon(
                icon,
                size: AppConstants.iconXL,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    context.l10n.moreCategoriesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
