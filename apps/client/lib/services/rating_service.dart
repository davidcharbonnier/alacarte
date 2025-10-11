import '../models/rating.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Rating service for managing cheese ratings
class RatingService extends ApiService {
  // Singleton pattern to preserve cache
  static final RatingService _instance = RatingService._internal();
  
  factory RatingService() => _instance;
  
  RatingService._internal();
  
  // Cache for ratings by viewer (5-minute expiry)
  final Map<int, List<Rating>> _ratingsByViewerCache = {};
  final Map<int, DateTime> _ratingsByViewerCacheTime = {};
  static const Duration _ratingsCacheExpiry = Duration(minutes: 5);
  
  /// Clear ratings cache (useful after rating changes)
  void clearCache({int? viewerId}) {
    if (viewerId != null) {
      _ratingsByViewerCache.remove(viewerId);
      _ratingsByViewerCacheTime.remove(viewerId);
    } else {
      _ratingsByViewerCache.clear();
      _ratingsByViewerCacheTime.clear();
    }
  }
  /// Create a new rating
  Future<ApiResponse<Rating>> createRating(Rating rating) async {
    return handleResponse<Rating>(
      post(ApiConfig.ratingNew, data: rating.toCreateJson()),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Update a rating
  Future<ApiResponse<Rating>> updateRating(int id, Rating rating) async {
    return handleResponse<Rating>(
      put(ApiConfig.ratingEdit(id), data: rating.toUpdateJson()),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Delete a rating
  Future<ApiResponse<bool>> deleteRating(int id) async {
    return handleEmptyResponse(
      delete(ApiConfig.ratingRemove(id)),
    );
  }
  
  /// Share a rating with specific users
  Future<ApiResponse<Rating>> shareRating(int id, {List<int>? userIds}) async {
    if (userIds == null || userIds.isEmpty) {
      return ApiResponseHelper.error<Rating>('No users specified for sharing');
    }
    
    // Backend expects user_ids array - single API call for all users
    final requestData = {
      'user_ids': userIds,
    };
    
    return handleResponse<Rating>(
      put(ApiConfig.ratingShare(id), data: requestData),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Hide a rating from specific users (batch unshare)
  Future<ApiResponse<Rating>> unshareRatingFromUsers(int ratingId, List<int> userIds) async {
    if (userIds.isEmpty) {
      return ApiResponseHelper.error<Rating>('No users specified for unsharing');
    }
    
    final requestData = {
      'user_ids': userIds, // Use batch endpoint
    };
    
    return handleResponse<Rating>(
      put(ApiConfig.ratingHide(ratingId), data: requestData),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Hide a rating from a specific user (single unshare - legacy)
  Future<ApiResponse<Rating>> unshareRatingFromUser(int ratingId, int userId) async {
    final requestData = {
      'user_id': userId,
    };
    
    return handleResponse<Rating>(
      put(ApiConfig.ratingHide(ratingId), data: requestData),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Hide a rating (make it private) - removes from all viewers
  Future<ApiResponse<Rating>> hideRating(int id) async {
    // Note: This should ideally remove from all viewers, but current backend implementation
    // requires a specific ViewerID. This method is kept for backward compatibility.
    return handleResponse<Rating>(
      put(ApiConfig.ratingHide(id)),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Get ratings by author (user who created the ratings)
  Future<ApiResponse<List<Rating>>> getRatingsByAuthor(int authorId) async {
    return handleListResponse<Rating>(
      get(ApiConfig.ratingByAuthor(authorId)),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Get ratings by viewer (user who can see the ratings)
  Future<ApiResponse<List<Rating>>> getRatingsByViewer(int viewerId) async {
    // Check cache first
    if (_ratingsByViewerCache.containsKey(viewerId) && _ratingsByViewerCacheTime.containsKey(viewerId)) {
      final age = DateTime.now().difference(_ratingsByViewerCacheTime[viewerId]!);
      if (age < _ratingsCacheExpiry) {
        return ApiResponseHelper.success(_ratingsByViewerCache[viewerId]!);
      }
    }
    
    // Fetch from API
    final response = await handleListResponse<Rating>(
      get(ApiConfig.ratingByViewer(viewerId)),
      (json) => Rating.fromJson(json),
    );
    
    // Cache successful responses
    if (response is ApiSuccess<List<Rating>>) {
      _ratingsByViewerCache[viewerId] = response.data;
      _ratingsByViewerCacheTime[viewerId] = DateTime.now();
    }
    
    return response;
  }
  
  /// Get ratings by item (e.g., all ratings for a specific cheese)
  Future<ApiResponse<List<Rating>>> getRatingsByItem(String itemType, int itemId) async {
    return handleListResponse<Rating>(
      get(ApiConfig.ratingByItem(itemType, itemId)),
      (json) => Rating.fromJson(json),
    );
  }
  
  /// Get all ratings for a specific cheese
  Future<ApiResponse<List<Rating>>> getCheeseRatings(int cheeseId) async {
    return getRatingsByItem('cheese', cheeseId);
  }
  
  /// Get ratings created by a user that are visible to another user
  Future<ApiResponse<List<Rating>>> getVisibleRatings(int authorId, int viewerId) async {
    final response = await getRatingsByAuthor(authorId);
    return response.when(
      success: (ratings, message) {
        final visibleRatings = ratings.where((rating) =>
          rating.isVisibleToUser(viewerId)
        ).toList();
        return ApiResponseHelper.success(visibleRatings);
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<List<Rating>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<List<Rating>>(),
    );
  }
  
  /// Calculate average rating for a specific item
  Future<ApiResponse<Map<String, dynamic>>> getItemRatingStats(String itemType, int itemId) async {
    final response = await getRatingsByItem(itemType, itemId);
    return response.when(
      success: (ratings, message) {
        if (ratings.isEmpty) {
          return ApiResponseHelper.success({
            'averageRating': 0.0,
            'ratingCount': 0,
            'ratings': <Rating>[],
          });
        }
        
        final totalRating = ratings.fold<double>(0.0, (sum, rating) => sum + rating.grade);
        final averageRating = totalRating / ratings.length;
        
        return ApiResponseHelper.success({
          'averageRating': averageRating,
          'ratingCount': ratings.length,
          'ratings': ratings,
        });
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<Map<String, dynamic>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<Map<String, dynamic>>(),
    );
  }
  
  /// Get average rating for a cheese
  Future<ApiResponse<Map<String, dynamic>>> getCheeseRatingStats(int cheeseId) async {
    return getItemRatingStats('cheese', cheeseId);
  }
  
  /// Search ratings by note content
  Future<ApiResponse<List<Rating>>> searchRatingsByComment(int userId, String query) async {
    final response = await getRatingsByAuthor(userId);
    return response.when(
      success: (ratings, message) {
        final filteredRatings = ratings.where((rating) =>
          rating.hasNote &&
          rating.note.toLowerCase().contains(query.toLowerCase())
        ).toList();
        return ApiResponseHelper.success(filteredRatings);
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<List<Rating>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<List<Rating>>(),
    );
  }
  
  /// Filter ratings by rating value range
  Future<ApiResponse<List<Rating>>> filterRatingsByRange(
    int userId, 
    double minRating, 
    double maxRating
  ) async {
    final response = await getRatingsByAuthor(userId);
    return response.when(
      success: (ratings, message) {
        final filteredRatings = ratings.where((rating) =>
          rating.grade >= minRating && rating.grade <= maxRating
        ).toList();
        return ApiResponseHelper.success(filteredRatings);
      },
      error: (message, statusCode, errorCode, details) => 
        ApiResponseHelper.error<List<Rating>>(message, statusCode: statusCode, errorCode: errorCode),
      loading: () => ApiResponseHelper.loading<List<Rating>>(),
    );
  }
  
  /// Bulk Privacy Actions
  
  /// Make all user's ratings private (remove all sharing)
  Future<ApiResponse<Map<String, dynamic>>> makeAllRatingsPrivate() async {
    return handleResponse<Map<String, dynamic>>(
      put(ApiConfig.ratingBulkPrivate),
      (json) => json as Map<String, dynamic>,
    );
  }
  
  /// Remove specific user from all shares
  Future<ApiResponse<Map<String, dynamic>>> removeUserFromAllShares(int userId) async {
    return handleResponse<Map<String, dynamic>>(
      put(ApiConfig.ratingBulkUnshare(userId)),
      (json) => json as Map<String, dynamic>,
    );
  }
  
  /// Validate rating data before creating/updating
  List<String> validateRating(Rating rating) {
    final errors = <String>[];
    
    if (rating.grade < 0.0 || rating.grade > 5.0) {
      errors.add('Rating must be between 0 and 5');
    }
    
    if (rating.authorId <= 0) {
      errors.add('Valid author is required');
    }
    
    if (rating.itemType.trim().isEmpty) {
      errors.add('Item type is required');
    }
    
    if (rating.itemId <= 0) {
      errors.add('Valid item ID is required');
    }
    
    if (rating.note.length > 1000) {
      errors.add('Note must be less than 1000 characters');
    }
    
    return errors;
  }
}
