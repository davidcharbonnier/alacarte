import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Fullscreen offline screen shown when app cannot connect
class FullscreenOfflineScreen extends ConsumerWidget {
  final ConnectivityState connectivityState;
  
  const FullscreenOfflineScreen({
    super.key,
    required this.connectivityState,
  });

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
                  // App branding
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingXL),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor().withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      size: 64,
                      color: _getStatusColor(),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXL),

                  // Status title
                  Text(
                    _getTitle(context),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Status description
                  Card(
                    child: Padding(
                      padding: AppConstants.cardPadding,
                      child: Column(
                        children: [
                          Text(
                            _getDescription(context),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: AppConstants.spacingL),
                          
                          // Retry button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _retryConnection(),
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.retry),
                              style: FilledButton.styleFrom(
                                backgroundColor: _getStatusColor(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.spacingM,
                                ),
                              ),
                            ),
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
  
  /// Get appropriate color for current connectivity state
  Color _getStatusColor() {
    switch (connectivityState) {
      case ConnectivityState.networkOffline:
        return Colors.red.shade600;
      case ConnectivityState.serverOffline:
        return Colors.orange.shade600;
      case ConnectivityState.online:
        return Colors.green.shade600;
    }
  }
  
  /// Get appropriate icon for current connectivity state
  IconData _getStatusIcon() {
    switch (connectivityState) {
      case ConnectivityState.networkOffline:
        return Icons.wifi_off;
      case ConnectivityState.serverOffline:
        return Icons.cloud_off;
      case ConnectivityState.online:
        return Icons.wifi;
    }
  }
  
  /// Get title for current connectivity state
  String _getTitle(BuildContext context) {
    switch (connectivityState) {
      case ConnectivityState.networkOffline:
        return context.l10n.noInternetConnectionTitle;
      case ConnectivityState.serverOffline:
        return context.l10n.serverUnavailableTitle;
      case ConnectivityState.online:
        return context.l10n.connectedTitle;
    }
  }
  
  /// Get description for current connectivity state
  String _getDescription(BuildContext context) {
    switch (connectivityState) {
      case ConnectivityState.networkOffline:
        return context.l10n.noInternetConnectionDescription;
      case ConnectivityState.serverOffline:
        return context.l10n.serverUnavailableDescription;
      case ConnectivityState.online:
        return context.l10n.connectionRestoredDescription;
    }
  }
  
  /// Trigger connection retry
  void _retryConnection() {
    print('🔄 User triggered connection retry from offline screen');
    ApiService.checkConnectivityAfterTimeout();
  }
}
