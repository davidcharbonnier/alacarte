import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rateable_item.dart';
import '../../providers/community_stats_provider.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Reusable rating summary component showing community statistics
class RatingSummaryCard extends ConsumerStatefulWidget {
  final RateableItem item;
  final String itemType;

  const RatingSummaryCard({
    super.key,
    required this.item,
    required this.itemType,
  });

  @override
  ConsumerState<RatingSummaryCard> createState() => _RatingSummaryCardState();
}

class _RatingSummaryCardState extends ConsumerState<RatingSummaryCard> {
  // Cache the item IDs list to prevent infinite provider refreshes
  late final List<int> _itemIds;
  
  @override
  void initState() {
    super.initState();
    // Create the list once and cache it
    _itemIds = [widget.item.id!];
  }

  @override
  Widget build(BuildContext context) {
    // Watch the community stats provider (handles single item elegantly)
    final statsAsync = ref.watch(
      communityStatsProvider(
        CommunityStatsParams(
          itemType: widget.itemType,
          itemIds: _itemIds, // Use cached list
        ),
      ),
    );

    return statsAsync.when(
      data: (statsMap) {
        final stats = statsMap[widget.item.id!];
        if (stats == null) {
          return _buildNoRatingsCard(context);
        }
        return _buildStatsCard(context, stats);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stackTrace) => _buildErrorCard(context),
    );
  }

  Widget _buildNoRatingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: AppConstants.iconL,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              context.l10n.noRatingsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              context.l10n.beFirstToRate(widget.item.name),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final totalRatings = stats.totalRatings;
    final averageRating = stats.averageRating;

    if (totalRatings == 0) {
      return Card(
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Column(
            children: [
              Icon(
                Icons.star_border,
                size: AppConstants.iconL,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                context.l10n.noRatingsYet,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                context.l10n.beFirstToRate(widget.item.name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.communityRatings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                // Average rating display
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.round() ? Icons.star : Icons.star_border,
                            size: AppConstants.iconS,
                            color: AppConstants.primaryColor,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                // Rating statistics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.ratingsCount(totalRatings),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        context.l10n.averageRating(averageRating.toStringAsFixed(1)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.communityRatings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.communityRatings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Center(
              child: Text(
                'Unable to load community statistics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
