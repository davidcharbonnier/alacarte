import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Professional loading screen for app initialization that matches app styling
class LoadingScreen extends ConsumerWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Padding(
              padding: AppConstants.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo/icon - matching app theme
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingXL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXL),

                  // App title - matching main app styling
                  Text(
                    context.l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingS),

                  // App subtitle
                  Text(
                    context.l10n.welcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.spacingXL * 2),

                  // Loading indicator with card background - matching app style
                  Card(
                    child: Padding(
                      padding: AppConstants.cardPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Loading indicator
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 3,
                          ),

                          const SizedBox(height: AppConstants.spacingL),

                          // Loading message with status
                          _buildStatusMessage(context, message),

                          const SizedBox(height: AppConstants.spacingM),

                          // Progress hint
                          Text(
                            context.l10n.settingUpPreferenceHub,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build status message with appropriate styling
  Widget _buildStatusMessage(BuildContext context, String? message) {
    // ignore: unnecessary_null_comparison
    if (message == null) {
      return Text(
        context.l10n.loading,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Style different status messages based on localized content
    Color? statusColor;
    IconData? statusIcon;

    // Check for specific localized messages first (more reliable than string matching)
    if (message == context.l10n.checkingConnection) {
      statusColor = Colors.blue;
      statusIcon = Icons.wifi_find;
    } else if (message == context.l10n.settingUpPreferenceHub) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.settings;
    } else if (message == context.l10n.verifyingAccount) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.account_circle;
    } else if (message == context.l10n.workingOffline) {
      statusColor = Colors.orange;
      statusIcon = Icons.wifi_off;
    } else if (message == context.l10n.profileSetupRequired) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.person_add;
    } else if (message == context.l10n.readyWelcomeBack) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (message == context.l10n.signInRequired) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.login;
    } else if (message == context.l10n.preparingPreferences) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.dashboard_customize;
    } else {
      // Default loading state for any other messages
      statusColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);
      statusIcon = Icons.hourglass_empty;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (statusIcon != null) ...[
          Icon(
            statusIcon,
            size: AppConstants.iconS,
            color: statusColor,
          ),
          const SizedBox(width: AppConstants.spacingS),
        ],
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
