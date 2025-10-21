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
  static const String cheeseList = '/items/cheese'; // Cheese list via item type
  static const String cheeseCreate = '/cheese/create';
  static const String cheeseEdit = '/cheese/edit';
  static const String cheeseDetail = '/cheese/detail';
  static const String ginCreate = '/gin/create';
  static const String ginEdit = '/gin/edit';
  static const String wineCreate = '/wine/create';
  static const String wineEdit = '/wine/edit';
  static const String coffeeCreate = '/coffee/create';
  static const String coffeeEdit = '/coffee/edit';
  static const String ratingCreate = '/rating/create';
  static const String ratingEdit = '/rating/edit';
  
  // Error routes
  static const String notFound = '/404';
}

/// Route parameter names
class RouteParams {
  static const String cheeseId = 'cheeseId';
  static const String ginId = 'ginId';
  static const String wineId = 'wineId';
  static const String coffeeId = 'coffeeId';
  static const String userId = 'userId';
  static const String ratingId = 'ratingId';
  static const String itemType = 'itemType';
  static const String itemId = 'itemId';
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
  static const String itemTypeSection = '/items/:${RouteParams.itemType}'; // Item type sections
  static const String itemDetailSection = '/items/:${RouteParams.itemType}/:${RouteParams.itemId}'; // Generic item detail
  static const String cheeseCreate = '/cheese/create';
  static const String cheeseEdit = '/cheese/edit/:${RouteParams.cheeseId}';
  static const String cheeseDetail = '/cheese/detail/:${RouteParams.cheeseId}';
  static const String ginCreate = '/gin/create';
  static const String ginEdit = '/gin/edit/:${RouteParams.ginId}';
  static const String wineCreate = '/wine/create';
  static const String wineEdit = '/wine/edit/:${RouteParams.wineId}';
  static const String coffeeCreate = '/coffee/create';
  static const String coffeeEdit = '/coffee/edit/:${RouteParams.coffeeId}';
  static const String ratingCreate = '/rating/create/:${RouteParams.itemType}/:${RouteParams.itemId}';
  static const String ratingEdit = '/rating/edit/:${RouteParams.ratingId}';
  
  static const String notFound = '/404';
}
