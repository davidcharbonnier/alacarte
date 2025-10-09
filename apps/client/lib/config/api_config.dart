import 'app_config.dart';

/// API endpoints configuration matching the Go backend routes
class ApiConfig {
  static String get baseUrl => AppConfig.baseUrl;

  // Health check (no auth required)
  static const String health = '/health';

  // Google OAuth endpoint
  static const String googleOAuth = '/auth/google';

  // Profile completion endpoints (partial auth required)
  static const String profileComplete = '/profile/complete';
  static const String profileCheckDisplayName = '/profile/check-display-name';

  // Protected API endpoints (full auth required)
  // Cheese endpoints
  static const String cheeseNew = '/api/cheese/new';
  static const String cheeseAll = '/api/cheese/all';
  static String cheeseDetails(int id) => '/api/cheese/$id';
  static String cheeseEdit(int id) => '/api/cheese/$id';
  static String cheeseRemove(int id) => '/api/cheese/$id';

  // User endpoints
  static const String userMe = '/api/user/me';
  static const String userMePatch = '/api/user/me'; // PATCH for updates
  static const String userMeDelete =
      '/api/user/me'; // DELETE for account deletion
  static const String usersShareable = '/api/users/shareable';

  // Legacy user endpoints (now obsolete with OAuth)
  static const String userNew = '/user/new';
  static const String userAll = '/user/all';
  static String userEdit(int id) => '/user/$id';
  static String userRemove(int id) => '/user/$id';

  // Rating endpoints
  static const String ratingNew = '/api/rating/new';
  static String ratingByAuthor(int id) => '/api/rating/author/$id';
  static String ratingByViewer(int id) => '/api/rating/viewer/$id';
  static String ratingByItem(String type, int id) => '/api/rating/$type/$id';
  static String ratingEdit(int id) => '/api/rating/$id';
  static String ratingShare(int id) => '/api/rating/$id/share';
  static String ratingHide(int id) => '/api/rating/$id/hide';
  static String ratingRemove(int id) => '/api/rating/$id';

  // Bulk privacy actions
  static const String ratingBulkPrivate = '/api/rating/bulk/private';
  static String ratingBulkUnshare(int userId) =>
      '/api/rating/bulk/unshare/$userId';

  // Community statistics endpoints (anonymous aggregate data)
  static String communityStats(String type, int id) =>
      '/api/stats/community/$type/$id';

  // HTTP headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // TODO: Add API key headers when backend implements API key middleware
  // static Map<String, String> authenticatedHeaders(String apiKey) => {
  //   ...defaultHeaders,
  //   'Authorization': 'Bearer $apiKey',
  // };
}
