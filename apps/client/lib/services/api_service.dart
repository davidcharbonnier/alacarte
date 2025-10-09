import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../models/api_response.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'dio_client.dart';

/// Connectivity states for the app
enum ConnectivityState {
  online,           // Network + API both accessible
  networkOffline,   // No network connection
  serverOffline,    // Network OK, but API unreachable
}

/// Unified API service with integrated connectivity monitoring
abstract class ApiService {
  final Dio _dio = DioClient.instance.dio;
  
  // Connectivity monitoring
  static ConnectivityState _state = ConnectivityState.online;
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static Timer? _serverCheckTimer;
  static Timer? _debounceTimer;
  static final StreamController<ConnectivityState> _stateController = 
      StreamController<ConnectivityState>.broadcast();
  
  /// Current connectivity state
  static ConnectivityState get connectivityState => _state;
  
  /// Simple boolean for API availability
  static bool get isOnline => _state == ConnectivityState.online;
  
  /// Stream of connectivity state changes
  static Stream<ConnectivityState> get connectivityStream => _stateController.stream;
  
  /// Debug logging utility (only in debug mode)
  static void _debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  /// Start connectivity monitoring
  static void startConnectivityMonitoring() {
    if (_connectivitySubscription != null) return; // Already started
    
    // Listen to platform connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Check initial connectivity
    _checkInitialConnectivity();
    
    _debugLog('Started connectivity monitoring');
  }
  
  /// Check initial connectivity on app start
  static Future<void> _checkInitialConnectivity() async {
    _debugLog('🔍 Checking initial connectivity...');
    try {
      final results = await _connectivity.checkConnectivity();
      _debugLog('📱 Platform connectivity results: $results');
      await _handleConnectivityChange(results);
    } catch (e) {
      _debugLog('❌ Initial connectivity check failed: $e');
      _updateState(ConnectivityState.networkOffline);
    }
  }
  
  /// Handle platform connectivity changes with debouncing
  static Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _debugLog('🔄 Handling connectivity change: $results');
    
    // Cancel existing debounce timer if any
    _debounceTimer?.cancel();
    
    // Debounce for 500ms to prevent duplicate calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processConnectivityChange(results);
    });
  }
  
  /// Process the connectivity change after debounce
  static Future<void> _processConnectivityChange(List<ConnectivityResult> results) async {
    final hasNetworkConnection = results.any((result) => result != ConnectivityResult.none);
    
    if (!hasNetworkConnection) {
      // No network - definitely offline
      _debugLog('🚫 Network unavailable - going offline');
      _stopServerChecking();
      _updateState(ConnectivityState.networkOffline);
      return;
    }
    
    _debugLog('🌍 Network available - checking API reachability...');
    // Network available - check if API is reachable
    await _checkApiReachability();
  }
  
  /// Check if API server is reachable
  static Future<void> _checkApiReachability() async {
    _debugLog('🎧 Testing API reachability...');
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/health'));
      final response = await request.close();
      
      _debugLog('📊 API health check response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _debugLog('✅ API server reachable - going online');
        _stopServerChecking();
        _updateState(ConnectivityState.online);
      } else {
        _debugLog('🟠 API returned non-200 status: ${response.statusCode} - server offline');
        _startServerChecking();
        _updateState(ConnectivityState.serverOffline);
      }
      
      client.close();
    } catch (e) {
      _debugLog('🟠 API server unreachable - server offline');
      _startServerChecking();
      _updateState(ConnectivityState.serverOffline);
    }
  }
  
  /// Start periodic server checking when network is available but server unreachable
  static void _startServerChecking() {
    if (_serverCheckTimer != null) {
      _debugLog('⏰ Server checking already active');
      return; // Already checking
    }
    
    _debugLog('⏰ Starting periodic server checking (30s intervals)');
    _serverCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _debugLog('🔄 Periodic server reachability check...');
      _checkApiReachability();
    });
  }
  
  /// Stop periodic server checking
  static void _stopServerChecking() {
    if (_serverCheckTimer != null) {
      _debugLog('⏹️ Stopping periodic server checking');
      _serverCheckTimer?.cancel();
      _serverCheckTimer = null;
    }
  }
  
  /// Update connectivity state and notify listeners
  static void _updateState(ConnectivityState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      
      _debugLog('📡 Connectivity state changed: $oldState → $newState');
      
      switch (newState) {
        case ConnectivityState.online:
          _debugLog('🟢 🌐 Connected to A la carte - app fully functional');
          break;
        case ConnectivityState.networkOffline:
          _debugLog('🔴 🚫 No network connection - showing offline screen');
          break;
        case ConnectivityState.serverOffline:
          _debugLog('🟠 ☁️ Server unreachable - showing server unavailable screen');
          break;
      }
    } else {
      _debugLog('📡 Connectivity state unchanged: $newState');
    }
  }
  
  /// Trigger immediate connectivity check (for API timeout handling)
  static Future<void> checkConnectivityAfterTimeout() async {
    _debugLog('⚡ API timeout detected - triggering immediate connectivity check');
    final results = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(results);
  }
  
  /// Dispose connectivity resources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _stopServerChecking();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _stateController.close();
  }
  
  /// Handle API response with reactive connectivity detection
  Future<ApiResponse<T>> handleResponse<T>(
    Future<Response> apiCall,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final response = await apiCall;
      
      if (response.statusCode != null && 
          response.statusCode! >= 200 && 
          response.statusCode! < 300) {
        
        if (response.data == null) {
          return ApiResponseHelper.success(fromJson({}));
        }
        
        return ApiResponseHelper.success(fromJson(response.data));
      } else {
        return ApiResponseHelper.error(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Check connectivity only when we get timeouts or connection errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Trigger immediate connectivity check after timeout
        checkConnectivityAfterTimeout();
      }
      
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponseHelper.error(
        'Unexpected error: ${e.toString()}',
      );
    }
  }
  
  /// Handle list API response
  Future<ApiResponse<List<T>>> handleListResponse<T>(
    Future<Response> apiCall,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final response = await apiCall;
      
      if (response.statusCode != null && 
          response.statusCode! >= 200 && 
          response.statusCode! < 300) {
        
        if (response.data == null) {
          return ApiResponseHelper.success(<T>[]);
        }
        
        if (response.data is List) {
          final list = (response.data as List)
              .map((item) => fromJson(item))
              .toList();
          return ApiResponseHelper.success(list);
        } else {
          return ApiResponseHelper.error('Expected list response but got ${response.data.runtimeType}');
        }
      } else {
        return ApiResponseHelper.error(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        checkConnectivityAfterTimeout();
      }
      
      return _handleDioError<List<T>>(e);
    } catch (e) {
      return ApiResponseHelper.error(
        'Unexpected error: ${e.toString()}',
      );
    }
  }
  
  /// Handle empty response (for DELETE, PUT operations)
  Future<ApiResponse<bool>> handleEmptyResponse(
    Future<Response> apiCall,
  ) async {
    try {
      final response = await apiCall;
      
      if (response.statusCode != null && 
          response.statusCode! >= 200 && 
          response.statusCode! < 300) {
        return ApiResponseHelper.success(true);
      } else {
        return ApiResponseHelper.error(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        checkConnectivityAfterTimeout();
      }
      
      return _handleDioError<bool>(e);
    } catch (e) {
      return ApiResponseHelper.error(
        'Unexpected error: ${e.toString()}',
      );
    }
  }
  
  /// Convert DioException to ApiResponse error
  ApiResponse<T> _handleDioError<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponseHelper.timeoutError<T>();
      case DioExceptionType.connectionError:
        return ApiResponseHelper.networkError<T>();
      case DioExceptionType.badResponse:
        return ApiResponseHelper.error<T>(
          e.response?.data?['message'] ?? 'Server error occurred',
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiResponseHelper.error<T>('Request was cancelled');
      case DioExceptionType.unknown:
        return ApiResponseHelper.networkError<T>();
      default:
        return ApiResponseHelper.error<T>('Unknown error occurred');
    }
  }
  
  /// Request helpers
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
  
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
  
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
  
  /// Auth token management
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  /// Google OAuth token exchange
  Future<ApiResponse<Map<String, dynamic>>> googleOAuthExchange(String idToken, String accessToken) async {
    return handleResponse<Map<String, dynamic>>(
      post(ApiConfig.googleOAuth, data: {
        'id_token': idToken,
        'access_token': accessToken,
      }),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  /// Profile completion
  Future<ApiResponse<Map<String, dynamic>>> completeProfile(String displayName, bool discoverable) async {
    return handleResponse<Map<String, dynamic>>(
      post(ApiConfig.profileComplete, data: {
        'display_name': displayName,
        'discoverable': discoverable,
      }),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> checkDisplayNameAvailability(String displayName) async {
    return handleResponse<Map<String, dynamic>>(
      get(ApiConfig.profileCheckDisplayName, queryParameters: {
        'display_name': displayName,
      }),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  /// User Management Methods
  
  Future<ApiResponse<User>> getCurrentUser() async {
    return handleResponse<User>(
      get(ApiConfig.userMe),
      (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getShareableUsers() async {
    return handleResponse<Map<String, dynamic>>(
      get(ApiConfig.usersShareable),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getCommunityStats(String itemType, int itemId) async {
    return handleResponse<Map<String, dynamic>>(
      get(ApiConfig.communityStats(itemType, itemId)),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  Future<ApiResponse<User>> updateDisplayName(String displayName) async {
    return handleResponse<User>(
      _dio.patch(ApiConfig.userMePatch, data: {
        'display_name': displayName,
      }),
      (data) {
        final userData = data['user'] ?? data;
        return User.fromJson(userData as Map<String, dynamic>);
      },
    );
  }
  
  Future<ApiResponse<User>> updateDiscoverable(bool discoverable) async {
    return handleResponse<User>(
      _dio.patch(ApiConfig.userMePatch, data: {
        'discoverable': discoverable,
      }),
      (data) {
        final userData = data['user'] ?? data;
        return User.fromJson(userData as Map<String, dynamic>);
      },
    );
  }
  
  Future<ApiResponse<bool>> deleteAccount() async {
    return handleEmptyResponse(
      delete(ApiConfig.userMeDelete),
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> bulkMakeRatingsPrivate() async {
    return handleResponse<Map<String, dynamic>>(
      put(ApiConfig.ratingBulkPrivate),
      (data) => data as Map<String, dynamic>,
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> bulkRemoveUserFromShares(int userId) async {
    return handleResponse<Map<String, dynamic>>(
      put(ApiConfig.ratingBulkUnshare(userId)),
      (data) => data as Map<String, dynamic>,
    );
  }
}

/// Concrete implementation of ApiService
class GeneralApiService extends ApiService {}

/// Provider for the API service
final apiServiceProvider = Provider<GeneralApiService>((ref) => GeneralApiService());
