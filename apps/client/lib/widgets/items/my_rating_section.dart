import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/rating.dart';
import '../../models/rateable_item.dart';
import '../../models/user.dart';
import '../../models/api_response.dart';
import '../../providers/rating_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rating_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/safe_navigation.dart';
import '../../routes/route_names.dart';
import '../rating/share_rating_dialog.dart';
import '../rating/delete_rating_dialog.dart';

/// Reusable component for displaying user's personal rating
class MyRatingSection extends ConsumerWidget {
  final Rating? myRating;
  final RateableItem item;
  final VoidCallback? onRatingAdded;

  const MyRatingSection({
    super.key,
    this.myRating,
    required this.item,
    this.onRatingAdded,
  });

  void _showShareDialog(BuildContext context, WidgetRef ref, Rating rating) async {
    // Extract current sharing information from the rating's viewers
    List<int> currentlySharedWith = [];
    
    if (rating.viewers != null && rating.viewers is List) {
      for (final viewer in (rating.viewers as List)) {
        if (viewer is Map<String, dynamic>) {
          final userId = viewer['ID'] ?? viewer['id'];
          if (userId != null && userId is int && userId != rating.authorId) {
            currentlySharedWith.add(userId);
          }
        }
      }
    }
    
    print('Rating ${rating.id} currently shared with: $currentlySharedWith');
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => ShareRatingDialog(
          rating: rating,
          currentlySharedWith: currentlySharedWith,
          onShare: (shareWithUserIds, removeFromUserIds) => _handleSharingChanges(
            context, ref, rating.id!, shareWithUserIds, removeFromUserIds),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Rating rating) {
    showDialog(
      context: context,
      builder: (context) => DeleteRatingDialog(
        rating: rating,
        sharingCount: 0, // Use 0 to trigger generic sharing warning
        onConfirm: () => _deleteRating(context, ref, rating.id!),
      ),
    );
  }

  Future<void> _deleteRating(BuildContext context, WidgetRef ref, int ratingId) async {
    final success = await ref.read(ratingProvider.notifier).deleteRating(ratingId);
    
    if (success) {
      _showSuccessSnackBar(context, context.l10n.ratingDeleted);
      // Navigate back to item detail after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      SafeNavigation.goBackFromRatingDeletion(context, item.itemType, item.id!);
    } else {
      final error = ref.read(ratingProvider).error ?? context.l10n.couldNotDeleteRating;
      _showErrorSnackBar(context, error);
    }
  }

  Future<void> _handleSharingChanges(
    BuildContext context, 
    WidgetRef ref, 
    int ratingId, 
    List<int> shareWithUserIds, 
    List<int> removeFromUserIds,
  ) async {
    bool hasSuccess = false;
    String? lastError;
    
    // Handle sharing with new users (single API call)
    if (shareWithUserIds.isNotEmpty) {
      final success = await ref.read(ratingProvider.notifier).shareRating(ratingId, shareWithUserIds);
      if (success) {
        hasSuccess = true;
      } else {
        lastError = ref.read(ratingProvider).error ?? context.l10n.shareRatingError;
      }
    }
    
    // Handle unsharing from users (single batch API call)
    if (removeFromUserIds.isNotEmpty) {
      final success = await _batchUnshareRating(ref, ratingId, removeFromUserIds);
      if (success) {
        hasSuccess = true;
      } else {
        lastError = context.l10n.shareRatingError;
      }
    }
    
    // Show result
    if (hasSuccess) {
      String message;
      if (shareWithUserIds.isEmpty && removeFromUserIds.isNotEmpty) {
        message = context.l10n.ratingUnsharedFromUsers(removeFromUserIds.length);
      } else if (shareWithUserIds.isNotEmpty && removeFromUserIds.isEmpty) {
        message = context.l10n.shareRatingSuccess;
      } else {
        message = context.l10n.sharingPreferencesUpdated;
      }
      
      if (context.mounted) {
        _showSuccessSnackBar(context, message);
      }
      
      // Trigger data refresh
      if (onRatingAdded != null) {
        onRatingAdded!();
      }
    } else if (lastError != null && context.mounted) {
      _showErrorSnackBar(context, lastError);
    }
  }
  
  Future<bool> _batchUnshareRating(WidgetRef ref, int ratingId, List<int> userIds) async {
    // Use the batch unshare API endpoint
    try {
      final ratingService = ref.read(ratingServiceProvider);
      final response = await ratingService.unshareRatingFromUsers(ratingId, userIds);
      
      return response.when(
        success: (updatedRating, _) {
          // Update the rating using the provider's public method
          final ratingNotifier = ref.read(ratingProvider.notifier);
          final currentState = ref.read(ratingProvider);
          final updatedRatings = currentState.ratings
              .map((r) => r.id == updatedRating.id ? updatedRating : r)
              .toList();
          
          // We need a public method to update the state
          // For now, trigger a refresh to get updated data
          ratingNotifier.refreshRatings();
          
          return true;
        },
        error: (message, statusCode, errorCode, details) => false,
        loading: () => false,
      );
    } catch (e) {
      return false;
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: context.l10n.dismiss,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.myRating,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            if (myRating != null) ...[
              // Show existing rating
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Star rating display
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < myRating!.grade.round() ? Icons.star : Icons.star_border,
                              size: AppConstants.iconM,
                              color: AppConstants.primaryColor,
                            );
                          }),
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: AppConstants.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Text(
                            myRating!.grade.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppConstants.fontS,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Action buttons - icon only, aligned to the right
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                GoRouter.of(context).go('${RouteNames.ratingEdit}/${myRating!.id}');
                              },
                              icon: const Icon(Icons.edit, size: AppConstants.iconM),
                              color: AppConstants.primaryColor,
                              tooltip: context.l10n.editRating,
                            ),
                            IconButton(
                              onPressed: () => _showShareDialog(context, ref, myRating!),
                              icon: const Icon(Icons.share, size: AppConstants.iconM),
                              color: AppConstants.secondaryColor,
                              tooltip: context.l10n.shareRating,
                            ),
                            IconButton(
                              onPressed: () => _showDeleteDialog(context, ref, myRating!),
                              icon: const Icon(Icons.delete, size: AppConstants.iconM),
                              color: Theme.of(context).colorScheme.error,
                              tooltip: context.l10n.deleteRating,
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Notes section - full width
                    const SizedBox(height: AppConstants.spacingS),
                    const Divider(),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      myRating!.note.isNotEmpty 
                        ? myRating!.note 
                        : context.l10n.noNotesAdded,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: myRating!.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: myRating!.note.isEmpty 
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                          : null,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No rating yet - encourage user to rate
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_border,
                      size: AppConstants.iconXL,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                    context.l10n.haventRatedYet(item.name),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      context.l10n.addRatingToBuild,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
