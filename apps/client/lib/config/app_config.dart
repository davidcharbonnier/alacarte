import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration settings
class AppConfig {
  static const String appName = 'À la carte';

  // Environment-based configuration
  static String get appVersion {
    final version = dotenv.env['APP_VERSION'];
    if (version == null || version.isEmpty) {
      throw Exception(
        'APP_VERSION environment variable is required but not set',
      );
    }
    return version;
  }

  // API Configuration - requires environment variables
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'API_BASE_URL environment variable is required but not set',
      );
    }
    return url;
  }

  // Google OAuth Configuration
  static String get googleWebClientId {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID environment variable is required but not set',
      );
    }
    return clientId;
  }

  // TODO: Add API key management when implemented on backend
  // static const String apiKeyHeaderName = 'Authorization';
  // static String apiKeyPrefix = 'Bearer';

  // Local storage keys
  static const String selectedUserIdKey = 'selected_user_id';
  static const String appSettingsKey = 'app_settings';

  // UI Configuration
  static const int defaultPageSize = 20;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration animationDuration = Duration(milliseconds: 300);
}
