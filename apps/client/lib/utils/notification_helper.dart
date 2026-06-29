import 'package:flutter/material.dart';
import 'constants.dart';

/// SnackBar helpers with consistent styles.
class NotificationHelper {
  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Widget? leading,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: leading != null
            ? Row(children: [leading, const SizedBox(width: 12), Expanded(child: _text(message))])
            : _text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  static Widget _text(String message) => Text(
    message,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  );

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      leading: const Icon(Icons.check_circle, color: Colors.white, size: 24),
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppConstants.warningColor,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    );
  }

  static void showLoading(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.blue,
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      duration: const Duration(seconds: 30),
    );
  }
}