import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// Auth result types for OAuth flow
enum AuthResultType { success, cancelled, error }

class AuthResult {
  final AuthResultType type;
  final User? user;
  final String? token;
  final String? error;

  const AuthResult.success(this.user, this.token)
    : type = AuthResultType.success,
      error = null;

  const AuthResult.cancelled()
    : type = AuthResultType.cancelled,
      user = null,
      token = null,
      error = null;

  const AuthResult.error(this.error)
    : type = AuthResultType.error,
      user = null,
      token = null;

  bool get isSuccess => type == AuthResultType.success;
  bool get isCancelled => type == AuthResultType.cancelled;
  bool get isError => type == AuthResultType.error;
}

/// Google OAuth authentication service
class AuthService {
  final ApiService _apiService;
  bool _initialized = false;

  // Scopes required for authentication
  static const List<String> _requiredScopes = ['email', 'profile'];

  AuthService(this._apiService) {
    _ensureInitialized();
  }

  /// Ensure GoogleSignIn is initialized (v7 requirement)
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      await GoogleSignIn.instance.initialize(
        // Use web client ID as serverClientId for backend compatibility
        serverClientId: AppConfig.googleWebClientId,
      );
      _initialized = true;
      if (kDebugMode) print('✅ GoogleSignIn initialized');
    } catch (e) {
      if (kDebugMode) print('❌ GoogleSignIn initialization failed: $e');
      rethrow;
    }
  }

  /// Sign in with Google OAuth (v7 flow)
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Ensure initialization
      await _ensureInitialized();

      // Step 1: Authenticate user (get idToken)
      if (kDebugMode) print('🔐 Starting Google authentication...');
      final GoogleSignInAccount? account = await GoogleSignIn.instance
          .authenticate();

      if (account == null) {
        // User cancelled sign-in
        if (kDebugMode) print('❌ User cancelled sign-in');
        return const AuthResult.cancelled();
      }

      // Step 2: Get authentication tokens (idToken)
      if (kDebugMode) print('🔑 Getting authentication tokens...');
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        return const AuthResult.error('Failed to get Google ID token');
      }

      // Step 3: Get authorization (accessToken) for required scopes
      if (kDebugMode) print('🔓 Requesting authorization for scopes...');
      final GoogleSignInClientAuthorization? authorization = await account
          .authorizationClient
          .authorizeScopes(_requiredScopes);

      if (authorization == null) {
        return const AuthResult.error('Failed to get authorization tokens');
      }

      if (kDebugMode) print('✅ Got both tokens, exchanging with backend...');

      // Exchange Google tokens for our JWT token
      final response = await _apiService.googleOAuthExchange(
        auth.idToken!,
        authorization.accessToken,
      );

      if (response is ApiSuccess<Map<String, dynamic>>) {
        final data = response.data;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;
        if (kDebugMode) print('✅ OAuth exchange successful');
        return AuthResult.success(user, token);
      } else if (response is ApiError<Map<String, dynamic>>) {
        if (kDebugMode) print('❌ OAuth exchange failed: ${response.message}');
        return AuthResult.error(response.message);
      } else {
        return const AuthResult.error('Authentication failed');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Sign in failed: $e');
      return AuthResult.error('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      if (kDebugMode) print('✅ Google sign out successful');
    } catch (e) {
      if (kDebugMode) print('⚠️ Google sign out error (ignored): $e');
      // Ignore sign-out errors, just ensure we're signed out
    }
  }
}
