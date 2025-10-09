import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Dio HTTP client configuration with interceptors
class DioClient {
  static DioClient? _instance;
  late Dio _dio;
  
  DioClient._internal() {
    _dio = Dio();
    _setupInterceptors();
  }
  
  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }
  
  Dio get dio => _dio;
  
  void _setupInterceptors() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: ApiConfig.defaultHeaders,
    );
    
    // Request interceptor for logging and future API key injection
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: Add API key to headers when backend implements API key middleware
          // options.headers['Authorization'] = 'Bearer $apiKey';
          
          print('🚀 REQUEST: ${options.method} ${options.path}');
          if (options.data != null) {
            print('📤 DATA: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('❌ MESSAGE: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }
  
  /// Update API key for future authenticated requests
  /// TODO: Implement when backend adds API key middleware
  void setApiKey(String apiKey) {
    // _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    print('📝 API Key set (not yet implemented on backend)');
  }
  
  /// Remove API key
  void clearApiKey() {
    // _dio.options.headers.remove('Authorization');
    print('🗑️ API Key cleared');
  }
  
  /// Reset client (useful for testing)
  void reset() {
    _dio.interceptors.clear();
    _setupInterceptors();
  }
}
