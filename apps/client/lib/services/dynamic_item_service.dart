import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/dynamic_item.dart';
import '../models/item_schema.dart';
import '../models/paginated_response.dart';
import 'dio_client.dart';

class DynamicItemService {
  static final DynamicItemService _instance = DynamicItemService._internal();
  factory DynamicItemService() => _instance;
  DynamicItemService._internal();

  final Dio _dio = DioClient.instance.dio;

  Future<ApiResponse<PaginatedResponse<DynamicItem>>> getItemsByType(
    String type, {
    ItemSchema? schema,
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, String>? filters,
    bool rated = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (rated) {
        queryParams['rated'] = 'true';
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (filters != null && filters.isNotEmpty) {
        for (final entry in filters.entries) {
          if (entry.key == 'has_picture') {
            queryParams['filter[has_image]'] = entry.value;
          } else {
            queryParams['filter[${entry.key}]'] = entry.value;
          }
        }
      }

      final response = await _dio.get(
        '/api/items/$type',
        queryParameters: queryParams,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;

        final itemsList = data['items'] as List? ?? [];
        final items = itemsList
            .map((item) => DynamicItem.fromJson(
                  item as Map<String, dynamic>,
                  schema: schema,
                ))
            .toList();

        final total = (data['total'] as num?)?.toInt() ?? 0;
        final responsePage = (data['page'] as num?)?.toInt() ?? 1;
        final perPageResponse = (data['per_page'] as num?)?.toInt() ?? 20;
        final totalPages = (data['total_pages'] as num?)?.toInt() ?? 0;

        return ApiResponseHelper.success(
          PaginatedResponse(
            items: items,
            total: total,
            page: responsePage,
            perPage: perPageResponse,
            totalPages: totalPages,
          ),
        );
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

  Future<ApiResponse<Map<String, dynamic>>> getTypeStats(String type) async {
    try {
      final response = await _dio.get('/api/stats/type/$type');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponseHelper.success(data);
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
}