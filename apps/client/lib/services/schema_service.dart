import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/item_schema.dart';
import 'dio_client.dart';

class SchemaService {
  static final SchemaService _instance = SchemaService._internal();
  factory SchemaService() => _instance;
  SchemaService._internal();

  final Dio _dio = DioClient.instance.dio;

  final Map<String, ItemSchema> _schemaCache = {};
  final Map<String, String> _etagCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamp = {};

  Future<ApiResponse<List<ItemSchema>>> fetchSchemas({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      return ApiResponseHelper.success(_schemaCache.values.toList());
    }

    try {
      final response = await _dio.get('/api/schemas');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final etag = response.headers.value('etag');
        final data = response.data;

        List<ItemSchema> schemas = [];
        if (data is Map<String, dynamic>) {
          final schemasList = data['schemas'] ?? data['data'];
          if (schemasList is List) {
            for (final item in schemasList) {
              if (item is Map<String, dynamic>) {
                try {
                  schemas.add(ItemSchema.fromJson(item));
                } catch (e) {
                  // Skip invalid schemas
                }
              }
            }
          }
        } else if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              try {
                schemas.add(ItemSchema.fromJson(item));
              } catch (e) {
                // Skip invalid schemas
              }
            }
          }
        }

        for (final schema in schemas) {
          _schemaCache[schema.name] = schema;
          _cacheTimestamp[schema.name] = DateTime.now();
          if (etag != null) {
            _etagCache[schema.name] = etag;
          }
        }

        return ApiResponseHelper.success(schemas);
      } else {
        return ApiResponseHelper.error(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponseHelper.error('Unexpected error: ${e.toString()}');
    }
  }

  Future<ApiResponse<ItemSchema>> fetchSchema(
    String type, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _schemaCache.containsKey(type)) {
      final cached = _schemaCache[type]!;
      final age = DateTime.now().difference(
        _cacheTimestamp[type] ?? DateTime.now(),
      );
      if (age < _cacheExpiry) {
        return ApiResponseHelper.success(cached);
      }
    }

    try {
      final response = await _dio.get('/api/schemas/$type');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          try {
            final schema = ItemSchema.fromJson(data);
            _schemaCache[schema.name] = schema;
            _cacheTimestamp[schema.name] = DateTime.now();
            return ApiResponseHelper.success(schema);
          } catch (e) {
            return ApiResponseHelper.error('Failed to parse schema: $e');
          }
        }
        return ApiResponseHelper.error('Invalid response format');
      } else {
        return ApiResponseHelper.error(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponseHelper.error('Unexpected error: ${e.toString()}');
    }
  }

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

  bool _isCacheValid() {
    if (_schemaCache.isEmpty) return false;
    final now = DateTime.now();
    return _cacheTimestamp.values.every(
      (timestamp) => now.difference(timestamp) < _cacheExpiry,
    );
  }

  void clearCache() {
    _schemaCache.clear();
    _etagCache.clear();
    _cacheTimestamp.clear();
  }

  ItemSchema? getCachedSchema(String type) => _schemaCache[type];

  List<ItemSchema> get cachedSchemas => _schemaCache.values.toList();

  Future<ApiResponse<ItemSchema>> refreshSchema(String type) async {
    return fetchSchema(type, forceRefresh: true);
  }

  Future<ApiResponse<List<ItemSchema>>> refreshSchemas() async {
    return fetchSchemas(forceRefresh: true);
  }
}
