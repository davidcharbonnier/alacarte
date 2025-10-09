import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/route_names.dart';

/// Global navigation helper to handle navigation safely across the app
class SafeNavigation {
  /// Safely navigate back with fallback options
  static void goBack(BuildContext context, {String? fallbackRoute}) {
    try {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        // Use provided fallback or default to home
        final route = fallbackRoute ?? RouteNames.home;
        GoRouter.of(context).go(route);
      }
    } catch (e) {
      // If all else fails, go to home
      GoRouter.of(context).go(RouteNames.home);
    }
  }

  /// Safely navigate back from rating creation (should go to item detail)
  static void goBackFromRatingCreation(BuildContext context, String itemType, int itemId) {
    try {
      // From rating creation, we always want to go back to the item detail
      // regardless of whether we can pop or not, because the user needs to 
      // see their newly created rating
      GoRouter.of(context).go('/items/$itemType/$itemId');
    } catch (e) {
      // If that fails, try item type list as fallback
      GoRouter.of(context).go('/items/$itemType');
    }
  }

  /// Safely navigate back from rating edit (should go to item detail)
  static void goBackFromRatingEdit(BuildContext context, String itemType, int itemId) {
    try {
      // From rating edit, we always want to go back to the item detail
      // to see the updated rating
      GoRouter.of(context).go('/items/$itemType/$itemId');
    } catch (e) {
      // If that fails, try item type list as fallback
      GoRouter.of(context).go('/items/$itemType');
    }
  }

  /// Safely navigate back from rating deletion (should go to item detail)
  static void goBackFromRatingDeletion(BuildContext context, String itemType, int itemId) {
    try {
      // From rating deletion, we always want to go back to the item detail
      // to see the item without the deleted rating
      GoRouter.of(context).go('/items/$itemType/$itemId');
    } catch (e) {
      // If that fails, try item type list as fallback
      GoRouter.of(context).go('/items/$itemType');
    }
  }

  /// Safely navigate back to a specific item detail screen
  static void goBackToItemDetail(BuildContext context, String itemType, int itemId) {
    try {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        // Direct navigation to item detail
        GoRouter.of(context).go('/items/$itemType/$itemId');
      }
    } catch (e) {
      // Fallback to item detail
      GoRouter.of(context).go('/items/$itemType/$itemId');
    }
  }

  /// Safely navigate back to item type screen (cheese list, etc.)
  static void goBackToItemType(BuildContext context, String itemType) {
    try {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        // Direct navigation to item type list
        GoRouter.of(context).go('/items/$itemType');
      }
    } catch (e) {
      // Fallback to item type list
      GoRouter.of(context).go('/items/$itemType');
    }
  }

  /// Safely navigate back to hub (home screen)
  static void goBackToHub(BuildContext context) {
    try {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        GoRouter.of(context).go(RouteNames.home);
      }
    } catch (e) {
      // Direct navigation to home
      GoRouter.of(context).go(RouteNames.home);
    }
  }

  /// Safely navigate back to user selection
  static void goBackToUserSelection(BuildContext context) {
    try {
      if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        GoRouter.of(context).go(RouteNames.userSelection);
      }
    } catch (e) {
      // Direct navigation to user selection
      GoRouter.of(context).go(RouteNames.userSelection);
    }
  }

  /// Replace current route safely
  static void goReplace(BuildContext context, String route) {
    try {
      GoRouter.of(context).go(route);
    } catch (e) {
      // If navigation fails, try pushing to route
      GoRouter.of(context).go(RouteNames.home);
    }
  }

  /// Push new route safely
  static void goPush(BuildContext context, String route) {
    try {
      GoRouter.of(context).push(route);
    } catch (e) {
      // Fallback to go instead of push
      GoRouter.of(context).go(route);
    }
  }

  /// Get safe fallback route based on current context
  static String getSafeFallbackRoute(String? currentRoute) {
    if (currentRoute == null) return RouteNames.home;

    // Determine appropriate fallback based on current route
    if (currentRoute.startsWith('/items/')) {
      // Extract item type and go to that section
      final parts = currentRoute.split('/');
      if (parts.length >= 3) {
        return '/items/${parts[2]}'; // Go to item type screen
      }
    } else if (currentRoute.startsWith('/user/')) {
      return RouteNames.userSelection;
    } else if (currentRoute.startsWith('/rating/')) {
      // Try to extract item info from rating routes
      final parts = currentRoute.split('/');
      if (parts.length >= 5) {
        return '/items/${parts[3]}/${parts[4]}'; // Go to item detail
      }
    }

    // Default fallback
    return RouteNames.home;
  }

  /// Check if navigation is safe
  static bool canNavigateBack(BuildContext context) {
    try {
      return GoRouter.of(context).canPop();
    } catch (e) {
      return false;
    }
  }

  /// Get current route safely
  static String? getCurrentRoute(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (e) {
      return null;
    }
  }
}
