import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/display_name_setup_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/initialization/app_initialization_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/items/item_type_screen.dart';
import '../screens/items/item_detail_screen.dart';
import '../screens/items/dynamic_item_form_screen.dart';
import '../screens/rating/rating_create_screen.dart';
import '../screens/rating/rating_edit_screen.dart';
import 'route_names.dart';

import '../screens/settings/user_settings_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';

/// Provider for the GoRouter configuration with OAuth authentication
final appRouterProvider = Provider<GoRouter>((ref) {
  // Only watch authentication status and profile setup needs, not the entire auth state
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  final needsProfileSetup = ref.watch(
    authProvider.select((state) => state.needsProfileSetup),
  );
  final hasUser = ref.watch(authProvider.select((state) => state.user != null));

  return GoRouter(
    // Start with app initialization (shows loading screen)
    initialLocation: RouteNames.initialization,
    debugLogDiagnostics: true,

    // OAuth-based route protection with stable redirect logic
    redirect: (context, state) {
      final currentLocation = state.uri.path;

      // Allow initialization screen to handle initial routing
      if (currentLocation == RouteNames.initialization) {
        return null; // Let initialization screen handle routing
      }

      // Always redirect to auth if not authenticated
      if (!isAuthenticated) {
        if (currentLocation == RouteNames.auth) {
          return null; // Already on auth screen
        }
        return RouteNames.auth; // Redirect to authentication
      }

      // If authenticated but needs profile setup
      if (hasUser && needsProfileSetup) {
        if (currentLocation == RouteNames.displayNameSetup) {
          return null; // Allow access to setup
        }
        return RouteNames.displayNameSetup; // Force profile completion
      }

      // Authenticated and profile complete - allow access to app
      if (currentLocation == RouteNames.auth ||
          currentLocation == RouteNames.displayNameSetup) {
        return RouteNames.home; // Redirect to main app
      }

      return null; // No redirect needed
    },

    routes: [
      // App Initialization (shows loading screen during auth check)
      GoRoute(
        path: RoutePaths.initialization,
        name: RouteNames.initialization,
        builder: (context, state) => const AppInitializationScreen(),
      ),

      // Authentication screen
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),

      GoRoute(
        path: RoutePaths.displayNameSetup,
        name: RouteNames.displayNameSetup,
        builder: (context, state) => const DisplayNameSetupScreen(),
      ),

      // Main App Routes (Protected)
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(), // Item Type Hub
      ),

      // Settings Route (Protected)
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const UserSettingsScreen(),
      ),

      // Privacy Settings Route (Protected)
      GoRoute(
        path: RoutePaths.privacySettings,
        name: RouteNames.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),

      // Item Type Sections
      GoRoute(
        path: RoutePaths.itemTypeSection,
        name: RouteNames.itemType,
        builder: (context, state) {
          final itemType = state.pathParameters[RouteParams.itemType];
          if (itemType == null) {
            return _buildPlaceholderScreen('Invalid Item Type');
          }
          return ItemTypeScreen(itemType: itemType);
        },
      ),

      // Generic item routes (work for any item type) - MUST be before item detail to avoid /create being interpreted as itemId
      GoRoute(
        path: RoutePaths.itemCreateSection,
        name: RouteNames.itemCreate,
        builder: (context, state) {
          final itemType = state.pathParameters[RouteParams.itemType];
          if (itemType == null) {
            return _buildPlaceholderScreen('Invalid Item Type');
          }
          return DynamicItemFormScreen(itemType: itemType);
        },
      ),

      GoRoute(
        path: RoutePaths.itemEditSection,
        name: RouteNames.itemEdit,
        builder: (context, state) {
          final itemType = state.pathParameters[RouteParams.itemType];
          final itemIdParam = state.pathParameters[RouteParams.itemId];
          final itemId = int.tryParse(itemIdParam ?? '');
          if (itemType == null || itemId == null) {
            return _buildPlaceholderScreen('Invalid Item Type or ID');
          }
          return DynamicItemFormScreen(itemType: itemType, itemId: itemId);
        },
      ),

      // Generic Item Detail - MUST be after item create/edit routes
      GoRoute(
        path: RoutePaths.itemDetailSection,
        name: RouteNames.itemDetail,
        builder: (context, state) {
          final itemType = state.pathParameters[RouteParams.itemType];
          final itemIdParam = state.pathParameters[RouteParams.itemId];
          final itemId = int.tryParse(itemIdParam ?? '');

          if (itemType == null || itemId == null) {
            return _buildPlaceholderScreen('Invalid Item or ID');
          }

          return ItemDetailScreen(itemType: itemType, itemId: itemId);
        },
      ),

      // Rating Routes
      GoRoute(
        path: RoutePaths.ratingCreate,
        name: RouteNames.ratingCreate,
        builder: (context, state) {
          final itemType = state.pathParameters[RouteParams.itemType];
          final itemIdParam = state.pathParameters[RouteParams.itemId];
          final itemId = int.tryParse(itemIdParam ?? '');

          if (itemType == null || itemId == null) {
            return _buildPlaceholderScreen('Invalid Rating Parameters');
          }

          return RatingCreateScreen(itemType: itemType, itemId: itemId);
        },
      ),

      GoRoute(
        path: RoutePaths.ratingEdit,
        name: RouteNames.ratingEdit,
        builder: (context, state) {
          final ratingIdParam = state.pathParameters[RouteParams.ratingId];
          final ratingId = int.tryParse(ratingIdParam ?? '');

          if (ratingId == null) {
            return _buildPlaceholderScreen('Invalid Rating ID');
          }

          return RatingEditScreen(ratingId: ratingId);
        },
      ),

      // Error handling
      GoRoute(
        path: RoutePaths.notFound,
        name: RouteNames.notFound,
        builder: (context, state) =>
            _buildPlaceholderScreen('404 - Page Not Found'),
        // builder: (context, state) => const NotFoundScreen(),
      ),
    ],

    // Handle unknown routes
    errorBuilder: (context, state) =>
        _buildPlaceholderScreen('Error: ${state.error}'),
  );
});

/// Temporary placeholder screen for development
Widget _buildPlaceholderScreen(String title) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.blue.shade100,
      actions: [
        // Auth status display (only show when authenticated)
        Consumer(
          builder: (context, ref, child) {
            final isAuthenticated = ref.watch(isAuthenticatedProvider);
            if (!isAuthenticated) return const SizedBox.shrink();

            return IconButton(
              onPressed: () {
                // TODO: Add settings screen for OAuth users
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            );
          },
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This screen will be implemented in Phase 3',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          const Text('Available routes:'),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildRouteChip('User Selection', RouteNames.userSelection),
              _buildRouteChip('Create User', RouteNames.userCreate),
              _buildRouteChip('Home', RouteNames.home),
              _buildRouteChip('Cheese List', '${RouteNames.itemType}/cheese'),
              _buildRouteChip(
                'Create Item',
                '${RouteNames.itemType}/cheese/create',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildRouteChip(String label, String route) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Builder(
      builder: (context) => ActionChip(
        label: Text(label),
        onPressed: () => GoRouter.of(context).go(route),
      ),
    ),
  );
}

/// Extension for type-safe navigation helpers
extension AppRouterExtension on GoRouter {
  // User routes
  void goToUserSelection() => go(RouteNames.userSelection);
  void goToUserCreate() => go(RouteNames.userCreate);
  void goToUserEdit(int userId) => go('${RouteNames.userEdit}/$userId');
  void goToUserSettings() => go(RouteNames.userSettings);

  // Main app routes
  void goToHome() => go(RouteNames.home); // Item Type Hub
  void goToItemType(String itemType) => go('${RouteNames.itemType}/$itemType');

  // Rating routes
  void goToRatingCreate(String itemType, int itemId) =>
      go('${RouteNames.ratingCreate}/$itemType/$itemId');
  void goToRatingEdit(int ratingId) => go('${RouteNames.ratingEdit}/$ratingId');
}

/// Navigation helper methods for use in widgets
class AppNavigation {
  static void toUserSelection(BuildContext context) {
    GoRouter.of(context).goToUserSelection();
  }

  static void toHome(BuildContext context) {
    GoRouter.of(context).goToHome();
  }

  static void toCreateRating(
    BuildContext context,
    String itemType,
    int itemId,
  ) {
    GoRouter.of(context).goToRatingCreate(itemType, itemId);
  }

  static void toEditRating(BuildContext context, int ratingId) {
    GoRouter.of(context).goToRatingEdit(ratingId);
  }

  /// Go back if possible, otherwise go to default route
  static void goBackOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).goToHome();
    }
  }

  /// Go back or to user selection if no user is selected
  static void goBackOrUserSelection(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).goToUserSelection();
    }
  }
}
