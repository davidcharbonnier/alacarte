import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

/// Service for handling image uploads
class ImageService {
  final Dio _dio = DioClient.instance.dio;

  /// Upload image for an item
  Future<String?> uploadImage(
    String itemType,
    int itemId,
    File imageFile,
  ) async {
    try {
      final fileName = imageFile.path.split('/').last;
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/$itemType/$itemId/image',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['image_url'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete image for an item
  Future<bool> deleteImage(
    String itemType,
    int itemId,
  ) async {
    try {
      final response = await _dio.delete(
        '/api/$itemType/$itemId/image',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});
