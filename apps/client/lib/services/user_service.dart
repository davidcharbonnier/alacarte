import '../models/user.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// OAuth-compatible User service for authenticated user operations
class UserService extends ApiService {
  /// Get current authenticated user (OAuth)
  Future<ApiResponse<User>> getCurrentUser() async {
    return handleResponse<User>(
      get(ApiConfig.userMe),
      (json) => User.fromJson(json),
    );
  }
  
  /// Get shareable users for sharing dialogs (OAuth)
  Future<ApiResponse<Map<String, dynamic>>> getShareableUsers() async {
    return handleResponse<Map<String, dynamic>>(
      get(ApiConfig.usersShareable),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  /// Update user discoverability setting (OAuth) - DEPRECATED: Use PATCH /api/user/me instead
  @deprecated
  Future<ApiResponse<Map<String, dynamic>>> updateDiscoverability(bool discoverable) async {
    // This method is deprecated - the AuthProvider now uses the PATCH endpoint directly
    // Keeping for backward compatibility but recommending direct PATCH usage
    return handleResponse<Map<String, dynamic>>(
      patch(ApiConfig.userMePatch, data: {
        'discoverable': discoverable,
      }),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  // Legacy methods below are now obsolete with OAuth authentication
  // These methods are kept for compatibility during migration but will be removed
  
  /// Get all users/profiles (LEGACY - OAuth uses shareable users instead)
  @deprecated
  Future<ApiResponse<List<User>>> getAllUsers() async {
    // This now calls the shareable users endpoint for compatibility
    final response = await getShareableUsers();
    return response.when(
      success: (data, message) {
        final previousConnections = (data['previous_connections'] as List)
            .map((userData) => User.fromJson(userData as Map<String, dynamic>))
            .toList();
        final discoverableUsers = (data['discoverable'] as List)
            .map((userData) => User.fromJson(userData as Map<String, dynamic>))
            .toList();
        
        final allUsers = [...previousConnections, ...discoverableUsers];
        return ApiResponseHelper.success(allUsers);
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<List<User>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<List<User>>(),
    );
  }
  
  /// Create a new user profile (LEGACY - OAuth handles user creation)
  @deprecated
  Future<ApiResponse<User>> createUser(User user) async {
    return ApiResponseHelper.error<User>('User creation is handled by OAuth authentication');
  }
  
  /// Update a user profile (LEGACY - OAuth handles profile updates)
  @deprecated
  Future<ApiResponse<User>> updateUser(int id, User user) async {
    return ApiResponseHelper.error<User>('User updates are handled through OAuth profile management');
  }
  
  /// Delete a user profile (LEGACY - OAuth handles account deletion)
  @deprecated
  Future<ApiResponse<bool>> deleteUser(int id) async {
    return ApiResponseHelper.error<bool>('User deletion is handled through OAuth account management');
  }
  
  /// Get user by ID (if backend supports it in the future)
  Future<ApiResponse<User>> getUserById(int id) async {
    // TODO: Add endpoint to backend if needed
    // For now, we get all users and filter
    final response = await getAllUsers();
    return response.when(
      success: (users, message) {
        try {
          final user = users.firstWhere((u) => u.id == id);
          return ApiResponseHelper.success(user);
        } catch (e) {
          return ApiResponseHelper.error<User>('User not found');
        }
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<User>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<User>(),
    );
  }
  
  /// Search users by name (LEGACY - adapted for OAuth)
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    final response = await getAllUsers();
    return response.when(
      success: (users, message) {
        final filteredUsers = users.where((user) =>
          user.displayName.toLowerCase().contains(query.toLowerCase()) ||
          user.fullName.toLowerCase().contains(query.toLowerCase())
        ).toList();
        return ApiResponseHelper.success(filteredUsers);
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<List<User>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<List<User>>(),
    );
  }
  
  /// Validate user data before creating/updating (LEGACY)
  List<String> validateUser(User user) {
    final errors = <String>[];
    
    if (user.displayName.trim().isEmpty && user.fullName.trim().isEmpty) {
      errors.add('Display name or full name is required');
    }
    
    if (user.email.trim().isEmpty) {
      errors.add('Email is required');
    }
    
    return errors;
  }
}
