import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure token storage using flutter_secure_storage
/// 
/// SECURITY: JWT tokens contain sensitive user information (user ID, email, display name)
/// and provide authentication for API calls. These must be stored securely.
/// 
/// MIGRATION NOTE (v1.0.0): Switched from SharedPreferences to flutter_secure_storage
/// for improved security. Old tokens in SharedPreferences are automatically cleaned up
/// on first launch. Users will need to re-authenticate once after the update.
/// 
/// Platform-specific storage:
/// - Android: AES encryption with Android Keystore
/// - iOS: Keychain Services
/// - Web: Web Crypto API with IndexedDB
/// - Linux/Windows/macOS: Encrypted storage with OS keyring
class TokenStorage {
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _cleanupKey = 'secure_storage_cleanup_done';
  
  // Initialize secure storage with platform-specific options
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  /// Clean up old tokens from SharedPreferences (one-time migration cleanup)
  /// This runs once per installation to remove insecure legacy token storage
  static Future<void> _cleanupOldStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if cleanup already done
    final cleanupDone = prefs.getBool(_cleanupKey) ?? false;
    if (cleanupDone) {
      return; // Already cleaned up
    }
    
    // Remove old tokens from SharedPreferences
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    
    // Mark cleanup as complete
    await prefs.setBool(_cleanupKey, true);
    
    if (kDebugMode) print('🧹 Cleaned up legacy token storage from SharedPreferences');
  }
  
  /// Read JWT token from secure storage
  static Future<String?> getToken() async {
    // Ensure old storage is cleaned up
    await _cleanupOldStorage();
    
    return await _secureStorage.read(key: _tokenKey);
  }
  
  /// Save JWT token to secure storage
  static Future<void> saveToken(String token) async {
    // Ensure old storage is cleaned up
    await _cleanupOldStorage();
    
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  /// Delete JWT token from secure storage
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  /// Delete all auth tokens from secure storage
  static Future<void> deleteAllTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
  
  /// Check if JWT token is expired (basic implementation)
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      // For mock tokens, check timestamp format
      if (token.startsWith('mock.jwt.token.')) {
        final tokenParts = token.split('.');
        if (tokenParts.length >= 5) {
          final timestampStr = tokenParts[4];
          final timestamp = int.tryParse(timestampStr);
          if (timestamp != null) {
            final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            return DateTime.now().difference(tokenTime).inHours > 24;
          }
        }
      }
      
      // For real JWT tokens, check the 'exp' claim
      // Note: Backend sets 24-hour expiration
      // TODO: Implement proper JWT decoding to check exp claim
      return false;
    } catch (e) {
      return true; // If we can't parse it, consider it expired
    }
  }
  
  /// Get info about current storage method (for debugging)
  static String get storageInfo {
    return 'Secure Storage (flutter_secure_storage with platform encryption)';
  }
}
