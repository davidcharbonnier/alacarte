import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'connectivity_provider.dart';

// Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? token;
  final String? error;
  final bool needsProfileSetup;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
    this.needsProfileSetup = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? token,
    String? error,
    bool? needsProfileSetup,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
      needsProfileSetup: needsProfileSetup ?? this.needsProfileSetup,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._apiService, this._authService, this._ref) : super(const AuthState()) {
    _initializeAuth();
    _listenToConnectivity();
  }

  /// Listen to connectivity changes and retry auth when coming back online
  void _listenToConnectivity() {
    _ref.listen<AsyncValue<ConnectivityState>>(connectivityStateProvider, (previous, next) {
      next.whenData((connectivityState) {
        if (connectivityState == ConnectivityState.online && previous?.value != ConnectivityState.online) {
          print('🔄 Connectivity restored - will revalidate user authentication');
          _handleConnectivityRestored();
        }
      });
    });
  }

  /// Handle connectivity being restored
  Future<void> _handleConnectivityRestored() async {
    // Always revalidate user when connectivity is restored (if we have a token)
    if (state.isAuthenticated && state.token != null) {
      print('🔄 Connectivity restored - revalidating user authentication');
      await _validateTokenWithBackend(state.token!);
    }
  }

  /// Validate token with backend and update state
  Future<void> _validateTokenWithBackend(String token) async {
    try {
      final response = await _apiService.getCurrentUser();
      
      if (response is ApiSuccess<User>) {
        final user = response.data;
        print('✅ User revalidation successful');
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          token: token,
          needsProfileSetup: !user.profileCompleted,
        );
      } else {
        print('❌ User revalidation failed - clearing auth');
        // Token invalid, clear it
        await _clearAuth();
      }
    } catch (e) {
      print('❌ User revalidation error: $e');
      // Don't clear auth on network errors, might just be temporary
      // Keep offline state and will retry on next connectivity restore
    }
  }

  /// Set offline auth state (token exists but user data not available)
  void _setOfflineAuthState(String token) {
    state = state.copyWith(
      isAuthenticated: true,
      isLoading: false,
      token: token,
      user: null, // No user data available offline
      needsProfileSetup: false, // We'll check when online
    );
  }

  // Initialize authentication on app start
  Future<void> _initializeAuth() async {
    print('🔐 Initializing authentication...');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final token = await TokenStorage.getToken();
      
      if (token != null && !TokenStorage.isTokenExpired(token)) {
        print('🔑 Found stored token, setting in API service');
        // Set token in API service
        _apiService.setAuthToken(token);
        
        // Only validate token with backend if we're online
        // Wait a bit for connectivity status to be established
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (ApiService.isOnline) {
          print('🌐 Online - validating token with backend');
          await _validateTokenWithBackend(token);
        } else {
          print('🚫 Offline - using token without validation');
          _setOfflineAuthState(token);
        }
      } else {
        print('🚫 No valid token found');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('❌ Auth initialization failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize authentication: $e',
      );
    }
  }

  // Google OAuth sign in
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.signInWithGoogle();
      
      if (result.isSuccess && result.user != null && result.token != null) {
        // Store token securely
        await TokenStorage.saveToken(result.token!);
        
        // Set token in API service
        _apiService.setAuthToken(result.token!);
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: result.user,
          token: result.token,
          needsProfileSetup: !result.user!.profileCompleted,
        );
      } else if (result.isCancelled) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Authentication failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'OAuth sign in failed: $e',
      );
    }
  }
  // Complete profile setup
  Future<void> completeProfile(String displayName, bool discoverable) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.completeProfile(displayName, discoverable);
      
      response.when(
        success: (data, _) {
          // Update user with new profile data
          final updatedUser = state.user!.copyWith(
            displayName: displayName,
            discoverable: discoverable,
            profileCompleted: true, // Mark as completed
          );
          
          state = state.copyWith(
            isLoading: false,
            user: updatedUser,
            needsProfileSetup: false,
          );
        },
        error: (message, statusCode, errorCode, details) {
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
        },
        loading: () {
          // Keep loading state
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete profile: $e',
      );
    }
  }

  // Check if display name is available
  Future<bool> isDisplayNameAvailable(String displayName) async {
    try {
      final response = await _apiService.checkDisplayNameAvailability(displayName);
      
      return response.when(
        success: (data, _) {
          return data['available'] as bool;
        },
        error: (message, statusCode, errorCode, details) {
          return false;
        },
        loading: () {
          return false;
        },
      );
    } catch (e) {
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _clearAuth();
  }
  
  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.updateDisplayName(displayName);
      
      response.when(
        success: (updatedUser, _) {
          state = state.copyWith(
            isLoading: false,
            user: updatedUser,
          );
        },
        error: (message, statusCode, errorCode, details) {
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
          throw Exception(message);
        },
        loading: () {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update display name: $e',
      );
      rethrow;
    }
  }
  
  // Update discoverable setting
  Future<void> updateDiscoverable(bool discoverable) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.updateDiscoverable(discoverable);
      
      response.when(
        success: (updatedUser, _) {
          state = state.copyWith(
            isLoading: false,
            user: updatedUser,
          );
        },
        error: (message, statusCode, errorCode, details) {
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
          throw Exception(message);
        },
        loading: () {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update discoverability: $e',
      );
      rethrow;
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.deleteAccount();
      
      if (response is ApiSuccess<bool>) {
        // Clear all auth data after successful deletion
        await _clearAuth();
      } else if (response is ApiError<bool>) {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        throw Exception(response.message);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: $e',
      );
      rethrow;
    }
  }

  // Handle 401 responses (token expired/invalid)
  Future<void> handleAuthError() async {
    await _clearAuth();
  }

  // Clear authentication data
  Future<void> _clearAuth() async {
    await TokenStorage.deleteToken();
    await _authService.signOut();
    _apiService.clearAuthToken();
    
    state = const AuthState();
  }

  // Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Refresh auth state (used during initialization)
  Future<void> refreshAuthState() async {
    // This is essentially the same as _initializeAuth but public
    await _initializeAuth();
  }
  
  /// Check local auth state without API calls (offline mode)
  Future<void> checkLocalAuthState() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final token = await TokenStorage.getToken();
      
      if (token != null && !TokenStorage.isTokenExpired(token)) {
        // Set token in API service for when we come back online
        _apiService.setAuthToken(token);
        
        // In offline mode, we can't validate the token or get user data
        // So we set a minimal authenticated state and will refresh when online
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          user: null, // No user data available offline
          needsProfileSetup: false, // We'll determine this when online
        );
      } else {
        // No valid token - user needs to sign in (requires connectivity)
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: 'Sign in requires an internet connection',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check authentication: $e',
      );
    }
  }
  
  /// Convert technical errors to user-friendly messages
  String _convertToUserFriendlyError(String technicalError) {
    // In development, show technical details. In production, show user-friendly messages
    if (technicalError.contains('DioException') || technicalError.contains('status code')) {
      if (technicalError.contains('500')) {
        return 'Server temporarily unavailable. Please try again.';
      } else if (technicalError.contains('400') || technicalError.contains('401')) {
        return 'Authentication failed. Please try again.';
      } else if (technicalError.contains('403')) {
        return 'Access denied. Please check your account.';
      } else if (technicalError.contains('duplicate') || technicalError.contains('already exists')) {
        return 'Account setup conflict. Please try a different account.';
      } else {
        return 'Connection failed. Please check your network and try again.';
      }
    }
    
    // For development, preserve technical details, but clean them up
    if (technicalError.contains('Token exchange failed') || technicalError.contains('Backend authentication failed')) {
      return 'Sign in failed. Please try again or contact support.';
    }
    
    return technicalError; // Return as-is for other cases
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(apiService, authService, ref);
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthService(apiService);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final needsProfileSetupProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated && authState.needsProfileSetup;
});
