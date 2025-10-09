import 'package:flutter/material.dart';
import '../../models/rating.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Dialog for confirming rating deletion with sharing impact information
class DeleteRatingDialog extends StatelessWidget {
  final Rating rating;
  final int sharingCount;
  final VoidCallback onConfirm;

  const DeleteRatingDialog({
    super.key,
    required this.rating,
    required this.sharingCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.delete_forever,
        color: Theme.of(context).colorScheme.error,
        size: AppConstants.iconL,
      ),
      title: Text(
        context.l10n.deleteRatingConfirmation,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.deleteRatingWarning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // Always show generic sharing warning
          const SizedBox(height: AppConstants.spacingM),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: AppConstants.iconM,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    context.l10n.deleteRatingGenericSharing,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(context.l10n.delete),
        ),
      ],
    );
  }
}
