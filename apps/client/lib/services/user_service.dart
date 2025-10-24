import '../models/user.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// OAuth-compatible User service for authenticated user operations
class UserService extends ApiService {
  /// Get current authenticated user (OAuth)
  @override
  Future<ApiResponse<User>> getCurrentUser() async {
    return handleResponse<User>(
      get(ApiConfig.userMe),
      (json) => User.fromJson(json),
    );
  }
  
  /// Get shareable users for sharing dialogs (OAuth)
  @override
  Future<ApiResponse<Map<String, dynamic>>> getShareableUsers() async {
    return handleResponse<Map<String, dynamic>>(
      get(ApiConfig.usersShareable),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  /// Get user by ID
  /// 
  /// Note: Currently implemented by searching through shareable users.
  /// TODO: Add dedicated backend endpoint for better performance.
  Future<ApiResponse<User>> getUserById(int id) async {
    // TODO: Add endpoint to backend if needed
    // For now, we get shareable users and filter
    final response = await getShareableUsers();
    return response.when(
      success: (data, message) {
        try {
          // Extract users from both lists
          final previousConnections = (data['previous_connections'] as List)
              .map((userData) => User.fromJson(userData as Map<String, dynamic>))
              .toList();
          final discoverableUsers = (data['discoverable'] as List)
              .map((userData) => User.fromJson(userData as Map<String, dynamic>))
              .toList();
          
          final allUsers = [...previousConnections, ...discoverableUsers];
          final user = allUsers.firstWhere((u) => u.id == id);
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
  
  /// Search users by name
  /// 
  /// Searches through shareable users (previous connections + discoverable users).
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    final response = await getShareableUsers();
    return response.when(
      success: (data, message) {
        // Extract users from both lists
        final previousConnections = (data['previous_connections'] as List)
            .map((userData) => User.fromJson(userData as Map<String, dynamic>))
            .toList();
        final discoverableUsers = (data['discoverable'] as List)
            .map((userData) => User.fromJson(userData as Map<String, dynamic>))
            .toList();
        
        final allUsers = [...previousConnections, ...discoverableUsers];
        
        final filteredUsers = allUsers.where((user) =>
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
}
