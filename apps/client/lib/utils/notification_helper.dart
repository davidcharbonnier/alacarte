import 'package:flutter/material.dart';
import 'constants.dart';

/// Unified notification helper for consistent user feedback across the app
/// 
/// Provides three types of notifications following A la carte design standards:
/// - Success: Green background, check icon, 2 second duration
/// - Error: Warning color background, dismissible, 3 second duration
/// - Loading: Blue background, 30 second duration for long operations
/// 
/// Usage:
/// ```dart
/// NotificationHelper.showSuccess(context, context.l10n.ratingCreated);
/// NotificationHelper.showError(context, context.l10n.errorOccurred);
/// NotificationHelper.showLoading(context, context.l10n.loadingData);
/// ```
class NotificationHelper {
  /// Show success notification
  /// 
  /// - Green background with check circle icon
  /// - White text with semi-bold weight
  /// - 2 second duration (quick positive feedback)
  /// - Floating behavior with rounded corners
  static void showSuccess(BuildContext context, String message) {
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

  /// Show error notification
  /// 
  /// - Warning color background (from AppConstants)
  /// - White text
  /// - 3 second duration (longer for errors)
  /// - Dismissible action button
  /// - Floating behavior with rounded corners
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.warningColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss', // Note: Should be localized by caller if needed
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show loading notification
  /// 
  /// - Blue/Primary color background
  /// - 30 second duration (for long operations)
  /// - Should be manually dismissed when operation completes
  /// - Use with ScaffoldMessenger.of(context).clearSnackBars() to dismiss
  static void showLoading(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
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
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Convenience method to show error from Theme context
  /// 
  /// Uses Theme.of(context).colorScheme.error instead of AppConstants.warningColor
  /// Useful when AppConstants.warningColor is not desired
  static void showErrorFromTheme(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
