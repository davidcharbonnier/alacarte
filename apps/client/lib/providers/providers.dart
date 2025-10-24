import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/rating.dart';
import '../services/api_service.dart';
import 'item_provider.dart';
import 'rating_provider.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// Provider that combines auth and rating state for easy access
final userRatingDataProvider = Provider<({User? user, List<Rating> ratings})>((
  ref,
) {
  final authState = ref.watch(authProvider);
  final ratingState = ref.watch(ratingProvider);

  return (user: authState.user, ratings: ratingState.ratings);
});

/// Provider for dashboard data summary (OAuth compatible)
final dashboardDataProvider = Provider<Map<String, dynamic>>((ref) {
  final authState = ref.watch(authProvider);
  final cheeseItemState = ref.watch(cheeseItemProvider);
  final ratingState = ref.watch(ratingProvider);

  return {
    'isAuthenticated': authState.isAuthenticated,
    'currentUserName': authState.user?.uiDisplayName ?? '',
    'totalCheeses': cheeseItemState.items.length,
    'totalRatings': ratingState.ratings.length,
    'averageRating': ratingState.averageRating,
    'isOnline': ref.watch(isOnlineProvider),
  };
});

/// Provider that automatically refreshes data when user changes
final dataRefreshProvider = Provider<void>((ref) {
  // Watch for authentication state changes
  ref.listen(authProvider, (previous, next) {
    // If user authenticated or changed, refresh user-dependent data
    if (previous?.user?.id != next.user?.id && next.isAuthenticated) {
      ref.read(ratingProvider.notifier).onUserChanged();
    }

    // If user logged out, clear user-specific data
    if (previous?.isAuthenticated == true && !next.isAuthenticated) {
      ref.read(ratingProvider.notifier).clearUserData();
    }
  });

  // Watch for connectivity changes - refresh data when back online
  ref.listen(connectivityStateProvider, (previous, next) {
    final wasOffline = previous?.value != ConnectivityState.online;
    final isNowOnline = next.value == ConnectivityState.online;
    
    if (wasOffline && isNowOnline) {
      // Just came back online - refresh all data if authenticated
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      if (isAuthenticated) {
        ref.read(cheeseItemProvider.notifier).refreshItems();
        ref.read(ratingProvider.notifier).refreshRatings();
      }
    }
  });
});
