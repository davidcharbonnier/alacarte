import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
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
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Use web client ID as serverClientId for backend compatibility
    // This allows Android app to authenticate natively while sending
    // tokens that your backend can validate against the web client ID
    serverClientId: AppConfig.googleWebClientId,
  );

  final ApiService _apiService;

  AuthService(this._apiService);

  /// Sign in with Google OAuth
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled sign-in
        return const AuthResult.cancelled();
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.idToken == null || auth.accessToken == null) {
        return const AuthResult.error('Failed to get Google authentication tokens');
      }

      // Exchange Google tokens for our JWT token
      final response = await _apiService.googleOAuthExchange(
        auth.idToken!, 
        auth.accessToken!,
      );
      
      if (response is ApiSuccess<Map<String, dynamic>>) {
        final data = response.data;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        final token = data['token'] as String;
        return AuthResult.success(user, token);
      } else if (response is ApiError<Map<String, dynamic>>) {
        return AuthResult.error(response.message);
      } else {
        return const AuthResult.error('Authentication failed');
      }
    } catch (e) {
      return AuthResult.error('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore sign-out errors, just ensure we're signed out
    }
  }

  /// Check if user is currently signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Stream of sign-in state changes
  Stream<bool> get onSignInChanged => 
    _googleSignIn.onCurrentUserChanged.map((user) => user != null);

  /// Get current Google user (for debugging)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
