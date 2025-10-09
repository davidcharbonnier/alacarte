import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rating.dart';
import '../../models/rateable_item.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Reusable component for displaying shared ratings from other users
class SharedRatingsList extends ConsumerWidget {
  final List<Rating> sharedRatings;
  final RateableItem item;

  const SharedRatingsList({
    super.key,
    required this.sharedRatings,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.recommendations,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            if (sharedRatings.isEmpty) ...[
              // No shared ratings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: AppConstants.iconL,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      context.l10n.noSharedRatings,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                    context.l10n.noSharedRatingsMessage(item.name),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show shared ratings
              Column(
                children: sharedRatings.map((rating) => _buildSharedRatingCard(context, ref, rating)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSharedRatingCard(BuildContext context, WidgetRef ref, Rating rating) {
    // Use only the privacy-safe display name that users chose to share
    String displayName = rating.authorName;
    
    // If no display name available, use localized anonymous fallback
    if (displayName == 'Anonymous User') {
      displayName = context.l10n.anonymousUser;
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.recommendationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppConstants.recommendationColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating header with author and grade
          Row(
            children: [
              // Author avatar
              CircleAvatar(
              radius: AppConstants.spacingM,
              backgroundColor: AppConstants.recommendationColor,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppConstants.fontM,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.recommendationColor,
                      ),
                    ),
                    Row(
                      children: [
                        // Star rating
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating.grade.round() ? Icons.star : Icons.star_border,
                              size: AppConstants.iconS,
                              color: AppConstants.recommendationColor,
                            );
                          }),
                        ),
                        const SizedBox(width: AppConstants.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingXS,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.recommendationColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                          ),
                          child: Text(
                            rating.grade.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppConstants.fontS,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Rating note (always show with placeholder if empty)
          const SizedBox(height: AppConstants.spacingS),
          const Divider(),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            rating.note.isNotEmpty 
              ? rating.note 
              : context.l10n.noNotesAdded,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: rating.note.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: rating.note.isEmpty 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                : null,
            ),
          ),
        ],
      ),
    );
  }
}
