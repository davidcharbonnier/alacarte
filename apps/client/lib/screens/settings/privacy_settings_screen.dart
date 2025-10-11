import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/rating.dart';
import '../../models/api_response.dart';
import '../../utils/constants.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/localization_utils.dart';
import '../../utils/safe_navigation.dart';
import '../../utils/item_provider_helper.dart';
import '../../widgets/rating/share_rating_dialog.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/loading_banner.dart';
import '../../widgets/settings/bulk_action_button.dart';
import '../../utils/notification_helper.dart';
import '../../widgets/settings/rating_item_card.dart';

/// Privacy settings screen with progressive item loading and full list display
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoadingItemData = false;
  String _selectedItemTypeFilter =
      'all'; // Filter state: 'all', 'cheese', 'gin', 'wine', etc.

  // Track loaded items by type - automatically handles all item types
  final Map<String, Set<int>> _loadedItemIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMissingItemData();
    });
  }

  @override
  void didUpdateWidget(PrivacySettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMissingItemData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final ratingState = ref.watch(ratingProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.privacySettings),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(child: Text(context.l10n.userNotAuthenticated)),
      );
    }

    final myRatings = ratingState.ratings
        .where((r) => r.authorId == user.id)
        .cast<Rating>()
        .toList();

    final sharedRatings = myRatings
        .where((rating) => _hasSharedViewers(rating))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.privacySettings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () => SafeNavigation.goBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Loading banner
                if (_isLoadingItemData)
                  LoadingBanner(message: context.l10n.loadingItemDetails),

                const SizedBox(height: AppConstants.spacingM),

                // Main privacy card
                _buildPrivacyCard(context, ref, user, sharedRatings),

                const SizedBox(height: AppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    List<Rating> sharedRatings,
  ) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy overview
            SettingsSectionHeader(
              icon: Icons.shield,
              title: context.l10n.privacyOverview,
            ),
            const SizedBox(height: AppConstants.spacingM),

            _buildSharingSummary(context, user, sharedRatings),

            const SizedBox(height: AppConstants.spacingL),
            const Divider(),
            const SizedBox(height: AppConstants.spacingL),

            // Discovery settings
            _buildDiscoverySection(context, ref, user),

            if (sharedRatings.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingL),
              const Divider(),
              const SizedBox(height: AppConstants.spacingL),

              // Bulk actions
              _buildBulkActionsSection(context, ref, sharedRatings),

              const SizedBox(height: AppConstants.spacingL),
              const Divider(),
              const SizedBox(height: AppConstants.spacingL),

              // Individual ratings - NEW: Shows full list with item type organization
              _buildIndividualRatingsSection(context, ref, sharedRatings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSharingSummary(
    BuildContext context,
    dynamic user,
    List<Rating> sharedRatings,
  ) {
    final uniqueRecipients = _getUniqueRecipients(sharedRatings);

    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.yourSharingActivity,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  Icons.share,
                  context.l10n.sharedRatingsCount(sharedRatings.length),
                  AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  Icons.people,
                  context.l10n.recipientsCount(uniqueRecipients.length),
                  AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppConstants.iconS, color: color),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          icon: Icons.explore,
          title: context.l10n.discoverySettings,
        ),
        const SizedBox(height: AppConstants.spacingM),

        Row(
          children: [
            Icon(
              Icons.visibility,
              size: AppConstants.iconM,
              color: AppConstants.primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppConstants.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.discoverableForSharing,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    context.l10n.discoverabilityExplanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(authProvider.select((state) => state.user));
                return Switch(
                  value: user?.discoverable ?? false,
                  onChanged: (value) => _updateDiscoverableSetting(context, ref, value),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulkActionsSection(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          icon: Icons.security,
          title: context.l10n.bulkPrivacyActions,
        ),
        const SizedBox(height: AppConstants.spacingM),

        BulkActionButton(
          icon: Icons.lock,
          title: context.l10n.makeAllRatingsPrivate,
          subtitle: context.l10n.makeAllRatingsPrivateDescription,
          buttonColor: AppConstants.warningColor,
          onPressed: () =>
              _showMakeAllPrivateDialog(context, ref, sharedRatings),
        ),

        const SizedBox(height: AppConstants.spacingM),

        BulkActionButton(
          icon: Icons.person_remove,
          title: context.l10n.removePersonFromAllShares,
          subtitle: context.l10n.removePersonFromAllSharesDescription,
          buttonColor: AppConstants.primaryColor,
          onPressed: () => _showRemovePersonDialog(context, ref, sharedRatings),
        ),
      ],
    );
  }

  Widget _buildIndividualRatingsSection(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) {
    if (sharedRatings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(
            icon: Icons.list,
            title: context.l10n.manageIndividualShares,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildEmptySharedRatingsState(context),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          icon: Icons.list,
          title: context.l10n.manageIndividualShares,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildExpandedIndividualRatingsSection(context, ref, sharedRatings),
      ],
    );
  }

  Widget _buildExpandedIndividualRatingsSection(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) {
    // Get available item types
    final availableItemTypes = sharedRatings
        .map((r) => r.itemType)
        .toSet()
        .toList();
    availableItemTypes.sort();

    // Filter ratings based on selected type
    final filteredRatings = _selectedItemTypeFilter == 'all'
        ? sharedRatings
        : sharedRatings
              .where((r) => r.itemType == _selectedItemTypeFilter)
              .toList();
    
    // Sort ratings alphabetically by item display title (A to Z, case-insensitive)
    filteredRatings.sort((a, b) {
      final titleA = _getLocalizedRatingDisplayTitle(context, a);
      final titleB = _getLocalizedRatingDisplayTitle(context, b);
      return titleA.toLowerCase().compareTo(titleB.toLowerCase());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item type filters - always show for consistency
        _buildItemTypeFilters(context, sharedRatings, availableItemTypes),
        const SizedBox(height: AppConstants.spacingL),

        // Filtered ratings list
        ...filteredRatings.map(
          (rating) => Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
            child: RatingItemCard(
              rating: rating,
              getDisplayTitle: (rating) =>
                  _getLocalizedRatingDisplayTitle(context, rating),
              getItemTypeDisplayName: _getItemTypeDisplayName,
              onManageSharing: () =>
                  _showIndividualSharingDialog(context, ref, rating),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTypeFilters(
    BuildContext context,
    List<Rating> sharedRatings,
    List<String> availableItemTypes,
  ) {
    // Count ratings by type
    final ratingCounts = <String, int>{};
    for (final rating in sharedRatings) {
      ratingCounts[rating.itemType] = (ratingCounts[rating.itemType] ?? 0) + 1;
    }

    return Wrap(
      spacing: AppConstants.spacingS,
      runSpacing: AppConstants.spacingS,
      children: [
        // "All" filter
        FilterChip(
          label: Text(
            context.l10n.allFilterOption + ' (${sharedRatings.length})',
          ),
          selected: _selectedItemTypeFilter == 'all',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedItemTypeFilter = 'all';
              });
            }
          },
        ),

        // Individual item type filters
        ...availableItemTypes.map((itemType) {
          final count = ratingCounts[itemType] ?? 0;
          final displayName = _getItemTypeDisplayName(itemType);

          return FilterChip(
            label: Text('$displayName ($count)'),
            selected: _selectedItemTypeFilter == itemType,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedItemTypeFilter = itemType;
                });
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildEmptySharedRatingsState(BuildContext context) {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: AppConstants.iconL,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            context.l10n.noSharedRatingsYet,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            context.l10n.noSharedRatingsExplanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Progressive loading methods
  Future<void> _loadMissingItemData() async {
    final ratingState = ref.read(ratingProvider);
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) return;

    final myRatings = ratingState.ratings
        .where((r) => r.authorId == user.id)
        .cast<Rating>()
        .toList();

    final sharedRatings = myRatings
        .where((rating) => _hasSharedViewers(rating))
        .toList();

    final missingItemsByType = <String, Set<int>>{};

    for (final rating in sharedRatings) {
      if (_isItemDataMissing(rating)) {
        final loadedIds = _loadedItemIds[rating.itemType] ?? <int>{};

        if (!loadedIds.contains(rating.itemId)) {
          missingItemsByType
              .putIfAbsent(rating.itemType, () => <int>{})
              .add(rating.itemId);
        }
      }
    }

    if (missingItemsByType.isNotEmpty) {
      setState(() => _isLoadingItemData = true);

      try {
        await _loadItemsByType(missingItemsByType);
        if (mounted) setState(() => _isLoadingItemData = false);
      } catch (e) {
        if (mounted) setState(() => _isLoadingItemData = false);
      }
    }
  }

  Future<void> _loadItemsByType(
    Map<String, Set<int>> missingItemsByType,
  ) async {
    // Fire all item type loads in parallel (HTTP/2 multiplexing!)
    final futures = missingItemsByType.entries.map((entry) {
      final itemType = entry.key;
      final itemIds = entry.value.toList();

      // Use ItemProviderHelper - works for any item type!
      return ItemProviderHelper.loadSpecificItems(ref, itemType, itemIds)
          .then((_) {
            // Track loaded items after successful load
            _loadedItemIds.putIfAbsent(itemType, () => <int>{}).addAll(itemIds);
          });
    });
    
    // Wait for all types to load in parallel
    await Future.wait(futures);
  }

  bool _isItemDataMissing(Rating rating) {
    // Check if item exists in cache using helper
    final items = ItemProviderHelper.getItems(ref, rating.itemType);
    return !items.any((item) => item.id == rating.itemId);
  }

  // Display title methods
  String _getLocalizedRatingDisplayTitle(BuildContext context, Rating rating) {
    // Try to get item from cache using helper (works for any item type)
    final items = ItemProviderHelper.getItems(ref, rating.itemType);
    final item = items.where((i) => i.id == rating.itemId).firstOrNull;
    
    if (item != null) {
      // Use generic displayTitle from RateableItem interface
      return item.displayTitle;
    }
    
    // Fallback with localized item type
    final localizedType = ItemTypeLocalizer.getLocalizedItemType(
      context,
      rating.itemType,
    );
    
    if (_isLoadingItemData && _isItemDataMissing(rating)) {
      return '$localizedType #${rating.itemId} (${context.l10n.loading})';
    }
    
    return '$localizedType #${rating.itemId}';
  }

  String _getItemTypeDisplayName(String itemType) {
    return ItemTypeLocalizer.getLocalizedItemType(context, itemType);
  }

  // Action handlers
  void _updateDiscoverableSetting(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    // Optimistic UI update first to avoid navigation glitches
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;
    
    try {
      // Call the API to update the setting
      await ref.read(authProvider.notifier).updateDiscoverable(value);
      
      // Success feedback
      if (context.mounted) {
        NotificationHelper.showSuccess(
          context,
          value
              ? context.l10n.discoverabilityEnabled
              : context.l10n.discoverabilityDisabledWithExplanation,
        );
      }
    } catch (e) {
      // Error feedback
      if (context.mounted) {
        NotificationHelper.showError(context, context.l10n.errorUpdatingSettings);
      }
    }
  }

  void _showMakeAllPrivateDialog(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppConstants.warningColor,
              size: AppConstants.iconM,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Text(
                dialogContext.l10n.makeAllRatingsPrivate,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.l10n.makeAllPrivateWarning(sharedRatings.length),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: AppConstants.cardPadding,
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppConstants.warningColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                dialogContext.l10n.makeAllPrivateConsequences,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppConstants.warningColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                _confirmMakeAllPrivate(context, ref, sharedRatings);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              foregroundColor: Colors.white,
            ),
            child: Text(dialogContext.l10n.makeAllRatingsPrivate),
          ),
        ],
      ),
    );
  }

  void _showRemovePersonDialog(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) {
    final uniqueRecipients = _getUniqueRecipientsWithIds(sharedRatings);

    if (uniqueRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noRecipientsToRemove)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.removePersonFromAllShares),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dialogContext.l10n.selectPersonToRemove),
            const SizedBox(height: AppConstants.spacingM),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: uniqueRecipients
                      .map(
                        (recipient) => ListTile(
                          leading: _buildUserAvatar(recipient),
                          title: Text(
                            recipient['name'].toString(),
                            style: Theme.of(dialogContext).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            dialogContext.l10n.sharedRatingsWithUser(
                              _countRatingsSharedWithUser(
                                sharedRatings,
                                recipient['id'] as int,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            if (context.mounted) {
                              _confirmRemoveUser(
                                context,
                                ref,
                                recipient['id'] as int,
                                recipient['name'].toString(),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showIndividualSharingDialog(
    BuildContext context,
    WidgetRef ref,
    Rating rating,
  ) {
    if (rating.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cannotManageSharing)));
      return;
    }

    final currentlySharedWith = <int>[];
    if (rating.viewers != null && rating.viewers is List) {
      final viewers = rating.viewers as List;
      for (final viewer in viewers) {
        if (viewer is Map<String, dynamic>) {
          // Try both 'ID' (uppercase) and 'id' (lowercase)
          final viewerId = viewer['ID'] ?? viewer['id'];
          final authorId = rating.authorId;

          if (viewerId != null && authorId != null && viewerId != authorId) {
            final id = viewerId is int
                ? viewerId
                : int.tryParse(viewerId.toString());
            if (id != null) {
              currentlySharedWith.add(id);
            }
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => ShareRatingDialog(
        rating: rating,
        currentlySharedWith: currentlySharedWith.isNotEmpty
            ? currentlySharedWith
            : null,
        onShare: (shareWithUserIds, removeFromUserIds) async {
          await _handleIndividualSharingUpdate(
            context,
            ref,
            rating,
            shareWithUserIds,
            removeFromUserIds,
          );
        },
      ),
    );
  }

  Future<void> _handleIndividualSharingUpdate(
    BuildContext context,
    WidgetRef ref,
    Rating rating,
    List<int> shareWithUserIds,
    List<int> removeFromUserIds,
  ) async {
    if (shareWithUserIds.isEmpty && removeFromUserIds.isEmpty) return;

    try {
      final ratingNotifier = ref.read(ratingProvider.notifier);

      if (shareWithUserIds.isNotEmpty) {
        final shareSuccess = await ratingNotifier.shareRating(
          rating.id!,
          shareWithUserIds,
        );
        if (!shareSuccess) {
          if (context.mounted) {
            NotificationHelper.showError(context, context.l10n.shareRatingError);
          }
          return;
        }
      }

      if (removeFromUserIds.isNotEmpty) {
        final ratingService = ref.read(ratingServiceProvider);
        final unshareResponse = await ratingService.unshareRatingFromUsers(
          rating.id!,
          removeFromUserIds,
        );

        final success = unshareResponse is ApiSuccess<Rating>;

        if (!success) {
          if (context.mounted) {
            final errorMessage = unshareResponse is ApiError<Rating>
                ? unshareResponse.message
                : context.l10n.errorRemovingUserFromShares;
            NotificationHelper.showError(context, errorMessage);
          }
          return;
        }
      }

      if (context.mounted) {
        String message;
        if (shareWithUserIds.isNotEmpty && removeFromUserIds.isNotEmpty) {
          message = context.l10n.sharingPreferencesUpdated;
        } else if (shareWithUserIds.isNotEmpty) {
          message = context.l10n.shareRatingSuccess;
        } else {
          message = context.l10n.ratingUnsharedFromUsers(
            removeFromUserIds.length,
          );
        }

        NotificationHelper.showSuccess(context, message);
      }

      await ref.read(ratingProvider.notifier).refreshRatings();
      await _loadMissingItemData();
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.showError(
          context,
          '${context.l10n.errorUpdatingSharing}: $e',
        );
      }
    }
  }

  // Action handlers for bulk privacy operations
  Future<void> _confirmMakeAllPrivate(
    BuildContext context,
    WidgetRef ref,
    List<Rating> sharedRatings,
  ) async {
    try {
      // Show loading state
      if (context.mounted) {
        NotificationHelper.showLoading(context, context.l10n.makingRatingsPrivate);
      }

      final result = await ref
          .read(ratingProvider.notifier)
          .makeAllRatingsPrivate();

      if (context.mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        final ratingsAffected = result['ratings_affected'] as int? ?? 0;
        NotificationHelper.showSuccess(context, context.l10n.allRatingsMadePrivate);

        // Trigger a refresh of the screen data
        await _loadMissingItemData();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        NotificationHelper.showError(context, context.l10n.errorMakingRatingsPrivate);
      }
    }
  }

  Future<void> _confirmRemoveUser(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String userName,
  ) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.removeUserFromShares),
        content: Text(dialogContext.l10n.removeUserWarning(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              foregroundColor: Colors.white,
            ),
            child: Text(dialogContext.l10n.removeUser),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Show loading state
      NotificationHelper.showLoading(context, context.l10n.removingUserFromShares(userName));

      final result = await ref
          .read(ratingProvider.notifier)
          .removeUserFromAllShares(userId);

      if (context.mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        final ratingsAffected = result['ratings_affected'] as int? ?? 0;
        NotificationHelper.showSuccess(
          context,
          context.l10n.userRemovedFromShares(userName, ratingsAffected),
        );

        // Trigger a refresh of the screen data
        await _loadMissingItemData();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        NotificationHelper.showError(context, context.l10n.errorRemovingUserFromShares);
      }
    }
  }

  // Helper methods
  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final avatarUrl = user['avatar'] as String?;
    final userName = user['name']?.toString() ?? context.l10n.anonymousUser;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initials if image fails to load
        },
        child: avatarUrl.isEmpty
            ? Text(
                userName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    } else {
      // Fallback to initials
      return CircleAvatar(
        backgroundColor: AppConstants.primaryColor,
        child: Text(
          userName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  bool _hasSharedViewers(Rating rating) {
    if (rating.viewers == null) return false;
    if (rating.viewers is! List) return false;

    final viewers = rating.viewers as List;
    return viewers.any((viewer) {
      if (viewer is Map<String, dynamic>) {
        // Try both 'ID' (uppercase) and 'id' (lowercase)
        final viewerId = viewer['ID'] ?? viewer['id'];
        return viewerId != null && viewerId != rating.authorId;
      }
      return false;
    });
  }

  Set<String> _getUniqueRecipients(List<Rating> sharedRatings) {
    final recipients = <String>{};

    for (final rating in sharedRatings) {
      if (rating.viewers != null && rating.viewers is List) {
        final viewers = rating.viewers as List;
        for (final viewer in viewers) {
          if (viewer is Map<String, dynamic>) {
            // Try both 'ID' (uppercase) and 'id' (lowercase)
            final viewerId = viewer['ID'] ?? viewer['id'];
            final authorId = rating.authorId;

            if (viewerId != null && authorId != null && viewerId != authorId) {
              final displayName =
                  viewer['display_name'] as String? ??
                  context.l10n.anonymousUser;
              recipients.add(displayName);
            }
          }
        }
      }
    }

    return recipients;
  }

  List<Map<String, dynamic>> _getUniqueRecipientsWithIds(
    List<Rating> sharedRatings,
  ) {
    final recipients = <String, Map<String, dynamic>>{};

    for (final rating in sharedRatings) {
      if (rating.viewers != null && rating.viewers is List) {
        final viewers = rating.viewers as List;
        for (final viewer in viewers) {
          if (viewer is Map<String, dynamic>) {
            // Try both 'ID' (uppercase) and 'id' (lowercase) as the backend might use either
            final viewerId = viewer['ID'] ?? viewer['id'];
            final authorId = rating.authorId;

            if (viewerId != null && authorId != null && viewerId != authorId) {
              final userId = viewerId.toString();
              final displayName =
                  viewer['display_name'] as String? ??
                  context.l10n.anonymousUser;
              final avatarUrl = viewer['avatar'] as String?;

              if (userId.isNotEmpty && !recipients.containsKey(userId)) {
                recipients[userId] = {
                  'id': viewerId is int ? viewerId : int.tryParse(userId) ?? 0,
                  'name': displayName,
                  'avatar': avatarUrl,
                };
              }
            }
          }
        }
      }
    }

    final recipientsList = recipients.values.toList();
    
    // Sort alphabetically by name (A to Z, case-insensitive)
    recipientsList.sort((a, b) {
      final nameA = (a['name'] as String?) ?? '';
      final nameB = (b['name'] as String?) ?? '';
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });
    
    return recipientsList;
  }

  int _countRatingsSharedWithUser(List<Rating> sharedRatings, int userId) {
    int count = 0;
    for (final rating in sharedRatings) {
      if (rating.viewers != null && rating.viewers is List) {
        final viewers = rating.viewers as List;
        if (viewers.any((viewer) {
          if (viewer is Map<String, dynamic>) {
            // Try both 'ID' (uppercase) and 'id' (lowercase)
            final viewerId = viewer['ID'] ?? viewer['id'];
            return viewerId == userId ||
                (viewerId is String && int.tryParse(viewerId) == userId);
          }
          return false;
        })) {
          count++;
        }
      }
    }
    return count;
  }
}
