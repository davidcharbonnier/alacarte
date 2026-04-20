import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/dynamic_item.dart';
import '../models/item_schema.dart';
import 'dio_client.dart';

class DynamicItemService {
  static final DynamicItemService _instance = DynamicItemService._internal();
  factory DynamicItemService() => _instance;
  DynamicItemService._internal();

  final Dio _dio = DioClient.instance.dio;

  final Map<String, List<DynamicItem>> _itemCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  Future<ApiResponse<List<DynamicItem>>> getItemsByType(
    String type, {
    ItemSchema? schema,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid(type)) {
      return ApiResponseHelper.success(_itemCache[type] ?? []);
    }

    try {
      final response = await _dio.get('/api/items/$type');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;

        List<DynamicItem> items = [];
        if (data is Map<String, dynamic>) {
          final itemsList = data['items'] ?? data['data'];
          if (itemsList is List) {
            items = itemsList
                .map(
                  (item) => DynamicItem.fromJson(
                    item as Map<String, dynamic>,
                    schema: schema,
                  ),
                )
                .toList();
          }
        } else if (data is List) {
          items = data
              .map(
                (item) => DynamicItem.fromJson(
                  item as Map<String, dynamic>,
                  schema: schema,
                ),
              )
              .toList();
        }

        _itemCache[type] = items;
        _cacheTimestamp[type] = DateTime.now();

        return ApiResponseHelper.success(items);
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

  Future<ApiResponse<DynamicItem>> getItemById(
    String type,
    int id, {
    ItemSchema? schema,
  }) async {
    try {
      final response = await _dio.get('/api/items/$type/$id');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;
        final item = DynamicItem.fromJson(data, schema: schema);
        return ApiResponseHelper.success(item);
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

  Future<ApiResponse<DynamicItem>> createItem(
    String type,
    DynamicItem item,
  ) async {
    try {
      final response = await _dio.post('/api/items/$type', data: item.toJson());

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;
        final createdItem = DynamicItem.fromJson(data);
        _invalidateCache(type);
        return ApiResponseHelper.success(createdItem);
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

  Future<ApiResponse<DynamicItem>> updateItem(
    String type,
    int id,
    DynamicItem item,
  ) async {
    try {
      final response = await _dio.put(
        '/api/items/$type/$id',
        data: item.toJson(),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;
        final updatedItem = DynamicItem.fromJson(data);
        _invalidateCache(type);
        return ApiResponseHelper.success(updatedItem);
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

  Future<ApiResponse<bool>> deleteItem(String type, int id) async {
    try {
      final response = await _dio.delete('/api/items/$type/$id');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        _invalidateCache(type);
        return ApiResponseHelper.success(true);
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

  Future<ApiResponse<String>> uploadImage(
    String type,
    int id,
    String imagePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/api/items/$type/$id/image',
        data: formData,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;
        final imageUrl = data['image_url'] as String?;
        return ApiResponseHelper.success(imageUrl ?? '');
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

  Future<ApiResponse<bool>> deleteImage(String type, int id) async {
    try {
      final response = await _dio.delete('/api/items/$type/$id/image');

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

  bool _isCacheValid(String type) {
    if (!_itemCache.containsKey(type)) return false;
    final timestamp = _cacheTimestamp[type];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _invalidateCache(String type) {
    _itemCache.remove(type);
    _cacheTimestamp.remove(type);
  }

  void clearCache() {
    _itemCache.clear();
    _cacheTimestamp.clear();
  }

  List<DynamicItem>? getCachedItems(String type) => _itemCache[type];
}
