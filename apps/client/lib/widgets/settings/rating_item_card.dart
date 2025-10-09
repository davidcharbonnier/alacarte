import 'package:flutter/material.dart';
import '../../models/rating.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Rating item widget with type badge for privacy settings
class RatingItemCard extends StatelessWidget {
  final Rating rating;
  final String Function(Rating) getDisplayTitle;
  final String Function(String) getItemTypeDisplayName;
  final VoidCallback onManageSharing;

  const RatingItemCard({
    super.key,
    required this.rating,
    required this.getDisplayTitle,
    required this.getItemTypeDisplayName,
    required this.onManageSharing,
  });

  int _getViewerCount(Rating rating) {
    if (rating.viewers == null || rating.viewers is! List) return 0;
    
    final viewers = rating.viewers as List;
    return viewers.where((viewer) => 
      viewer is Map<String, dynamic> && viewer['id'] != rating.authorId
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final viewerCount = _getViewerCount(rating);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          // Rating grade badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              rating.grade.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          
          // Rating info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getDisplayTitle(rating),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Row(
                  children: [
                    // Small type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingXS,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                      ),
                      child: Text(
                        getItemTypeDisplayName(rating.itemType).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      context.l10n.sharedWithCount(viewerCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Manage button
          IconButton(
            onPressed: onManageSharing,
            icon: const Icon(Icons.manage_accounts),
            iconSize: AppConstants.iconM,
            color: AppConstants.primaryColor,
            tooltip: context.l10n.shareRatingWith,
          ),
        ],
      ),
    );
  }
}
