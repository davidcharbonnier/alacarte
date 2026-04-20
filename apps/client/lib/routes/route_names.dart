/// Route name constants for type-safe navigation
class RouteNames {
  // Authentication routes
  static const String auth = '/auth';
  static const String displayNameSetup = '/setup';

  // Legacy - kept for reference during migration
  static const String initialization = '/initialization';
  static const String userSelection = '/';
  static const String userCreate = '/user/create';
  static const String userEdit = '/user/edit';
  static const String userSettings = '/user/settings';

  // Main app routes (require user selection)
  static const String home = '/home'; // Item Type Hub
  static const String settings = '/settings'; // User settings screen
  static const String privacySettings = '/privacy'; // Privacy management screen
  static const String itemType = '/items'; // Item type sections
  static const String itemDetail = '/items/detail'; // Generic item detail

  // Generic item routes (dynamic - works for any item type)
  static const String itemCreate = '/items/create';
  static const String itemEdit = '/items/edit';
  static const String ratingCreate = '/rating/create';
  static const String ratingEdit = '/rating/edit';

  // Error routes
  static const String notFound = '/404';
}

/// Route parameter names
class RouteParams {
  static const String itemType = 'itemType';
  static const String itemId = 'itemId';
  static const String userId = 'userId';
  static const String ratingId = 'ratingId';
}

/// Route paths with parameters
class RoutePaths {
  static const String auth = '/auth';
  static const String displayNameSetup = '/setup';

  // Legacy paths - kept for migration reference
  static const String initialization = '/initialization';
  static const String userSelection = '/';
  static const String userCreate = '/user/create';
  static const String userEdit = '/user/edit/:${RouteParams.userId}';
  static const String userSettings = '/user/settings';

  static const String home = '/home'; // Item Type Hub
  static const String settings = '/settings'; // User settings screen
  static const String privacySettings = '/privacy'; // Privacy management screen
  static const String itemTypeSection =
      '/items/:${RouteParams.itemType}'; // Item type sections
  static const String itemDetailSection =
      '/items/:${RouteParams.itemType}/:${RouteParams.itemId}'; // Generic item detail

  // Generic item routes (preferred)
  static const String itemCreateSection =
      '/items/:${RouteParams.itemType}/create';
  static const String itemEditSection =
      '/items/:${RouteParams.itemType}/edit/:${RouteParams.itemId}';

  static const String ratingCreate =
      '/rating/create/:${RouteParams.itemType}/:${RouteParams.itemId}';
  static const String ratingEdit = '/rating/edit/:${RouteParams.ratingId}';

  static const String notFound = '/404';
}
