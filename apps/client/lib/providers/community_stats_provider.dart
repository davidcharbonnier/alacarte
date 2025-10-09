import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/api_response.dart';

/// Provider family for community statistics of specific items
/// 
/// This provider fetches and caches anonymous aggregate statistics for any item.
/// The statistics include total ratings count and average rating.
/// 
/// Parameters:
/// - itemType: The type of item (e.g., 'cheese', 'gin')
/// - itemId: The unique identifier of the item
/// 
/// Returns a Map with:
/// - 'total_ratings': int - Total number of community ratings
/// - 'average_rating': double - Average rating score
/// - 'item_type': String - The item type
/// - 'item_id': int - The item ID
/// 
/// The provider automatically caches results per (itemType, itemId) pair.
/// To refresh data, use: ref.invalidate(communityStatsProvider(itemType, itemId))
final communityStatsProvider = FutureProvider.family<Map<String, dynamic>, CommunityStatsParams>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    final response = await apiService.getCommunityStats(params.itemType, params.itemId);

    // Use direct type checking as documented in README
    // ✅ Correct - Direct type checking pattern
    if (response is ApiSuccess<Map<String, dynamic>>) {
      return response.data;
    } else if (response is ApiError<Map<String, dynamic>>) {
      throw Exception('Failed to load community stats: ${response.message}');
    }
    
    // Handle loading state (shouldn't happen with await)
    throw Exception('Unexpected loading state');
  },
);

/// Parameters for community stats provider
class CommunityStatsParams {
  final String itemType;
  final int itemId;

  const CommunityStatsParams({
    required this.itemType,
    required this.itemId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityStatsParams &&
          runtimeType == other.runtimeType &&
          itemType == other.itemType &&
          itemId == other.itemId;

  @override
  int get hashCode => itemType.hashCode ^ itemId.hashCode;
}

/// Helper extension to provide convenient access to community stats values
extension CommunityStatsExtension on Map<String, dynamic> {
  /// Get total number of ratings, defaulting to 0 if not present
  int get totalRatings => (this['total_ratings'] as int?) ?? 0;
  
  /// Get average rating as double, defaulting to 0.0 if not present
  double get averageRating => (this['average_rating'] as num?)?.toDouble() ?? 0.0;
  
  /// Get item type string
  String get itemType => (this['item_type'] as String?) ?? '';
  
  /// Get item ID
  int get itemId => (this['item_id'] as int?) ?? 0;
}
