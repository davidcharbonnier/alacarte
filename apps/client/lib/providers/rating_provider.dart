import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../models/api_response.dart';
import '../services/rating_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Provider for the RatingService
final ratingServiceProvider = Provider<RatingService>((ref) => RatingService());

/// Provider for managing rating data and operations
final ratingProvider = StateNotifierProvider<RatingNotifier, RatingState>(
  (ref) => RatingNotifier(ref.read(ratingServiceProvider), ref),
);

/// State for rating data management
class RatingState {
  final List<Rating> ratings;
  final Rating? selectedRating;
  final bool isLoading;
  final String? error;
  
  // Statistics
  final Map<int, Map<String, dynamic>> cheeseRatingStats; // cheeseId -> stats
  
  // Filtering
  final double? minRating;
  final double? maxRating;
  final String searchQuery;

  const RatingState({
    this.ratings = const [],
    this.selectedRating,
    this.isLoading = false,
    this.error,
    this.cheeseRatingStats = const {},
    this.minRating,
    this.maxRating,
    this.searchQuery = '',
  });

  RatingState copyWith({
    List<Rating>? ratings,
    Rating? selectedRating,
    bool? isLoading,
    String? error,
    Map<int, Map<String, dynamic>>? cheeseRatingStats,
    double? minRating,
    double? maxRating,
    String? searchQuery,
  }) {
    return RatingState(
      ratings: ratings ?? this.ratings,
      selectedRating: selectedRating ?? this.selectedRating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      cheeseRatingStats: cheeseRatingStats ?? this.cheeseRatingStats,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get filtered ratings based on current filters
  List<Rating> get filteredRatings {
    var filtered = ratings;

    // Apply rating range filter
    if (minRating != null || maxRating != null) {
      filtered = filtered.where((rating) {
        if (minRating != null && rating.grade < minRating!) return false;
        if (maxRating != null && rating.grade > maxRating!) return false;
        return true;
      }).toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((rating) =>
        rating.note.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  /// Check if any filters are active
  bool get hasActiveFilters => 
    minRating != null || maxRating != null || searchQuery.isNotEmpty;

  /// Get count of filtered results
  int get filteredCount => filteredRatings.length;

  /// Get average rating for all user ratings
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<double>(0.0, (sum, rating) => sum + rating.grade);
    return total / ratings.length;
  }
}

/// Notifier for managing rating state
class RatingNotifier extends StateNotifier<RatingState> {
  final RatingService _ratingService;
  final Ref _ref;
  
  RatingNotifier(this._ratingService, this._ref) : super(const RatingState()) {
    // Don't load ratings immediately - wait for profile completion
    // _loadUserRatings(); // Removed - now triggered by profile completion
  }

  /// Load ratings for the currently authenticated user (only if profile complete)
  Future<void> _loadUserRatings() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user?.id == null) {
      state = state.copyWith(ratings: [], error: 'No authenticated user');
      return;
    }
    
    // Don't load ratings if user hasn't completed profile setup
    if (authState.needsProfileSetup) {
      state = state.copyWith(ratings: [], error: null);
      return;
    }

    // Check connectivity before loading
    if (!ApiService.isOnline) {
      state = state.copyWith(
        ratings: [],
        error: 'Offline - Rating data not available',
        isLoading: false,
      );
      return;
    }

    await loadRatingsByViewer(authState.user!.id!);
  }

  /// Load ratings by author (specific user)
  Future<void> loadRatingsByAuthor(int authorId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _ratingService.getRatingsByAuthor(authorId);
    
    response.when(
      success: (ratings, _) {
        state = state.copyWith(
          ratings: ratings,
          isLoading: false,
        );
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
      },
      loading: () {
        // Keep loading state
      },
    );
  }

  /// Load ratings by viewer (user's complete reference list: own + shared)
  Future<void> loadRatingsByViewer(int viewerId) async {
    // Check connectivity before attempting to load
    if (!ApiService.isOnline) {
      state = state.copyWith(
        ratings: [],
        isLoading: false,
        error: 'Offline - Rating data not available for this user',
      );
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _ratingService.getRatingsByViewer(viewerId);
    
    response.when(
      success: (ratings, _) {
        state = state.copyWith(
          ratings: ratings,
          isLoading: false,
        );
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
      },
      loading: () {
        // Keep loading state
      },
    );
  }

  /// Refresh rating data for current user
  Future<void> refreshRatings() async {
    await _loadUserRatings();
  }

  /// Select a specific rating for detailed view
  void selectRating(Rating rating) {
    state = state.copyWith(selectedRating: rating);
  }

  /// Clear selected rating
  void clearSelectedRating() {
    state = state.copyWith(selectedRating: null);
  }

  /// Create a new rating
  Future<bool> createRating({
    required double grade,
    required String note,
    required String itemType,
    required int itemId,
  }) async {
    final authState = _ref.read(authProvider);
    
    if (!authState.isAuthenticated || authState.user?.id == null) {
      state = state.copyWith(error: 'No authenticated user');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final newRating = RatingBuilder.createNew(
      grade: grade,
      note: note.trim(),
      authorId: authState.user!.id!,
      itemType: itemType,
      itemId: itemId,
    );

    // Validate before sending
    final validationErrors = _ratingService.validateRating(newRating);
    if (validationErrors.isNotEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: validationErrors.join(', '),
      );
      return false;
    }

    final response = await _ratingService.createRating(newRating);

    return response.when(
      success: (createdRating, _) {
        // Add to rating list
        final updatedRatings = [...state.ratings, createdRating];
        state = state.copyWith(
          ratings: updatedRatings,
          selectedRating: createdRating,
          isLoading: false,
        );
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }

  /// Create a cheese rating specifically
  Future<bool> createCheeseRating({
    required double grade,
    required String note,
    required int cheeseId,
  }) async {
    return createRating(
      grade: grade,
      note: note,
      itemType: 'cheese',
      itemId: cheeseId,
    );
  }

  /// Update an existing rating
  Future<bool> updateRating(
    int ratingId, {
    required double grade,
    required String note,
  }) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user?.id == null) {
      state = state.copyWith(error: 'No authenticated user');
      return false;
    }

    // Find existing rating safely
    final existingRating = state.ratings.where((r) => r.id == ratingId).firstOrNull;
    if (existingRating == null) {
      state = state.copyWith(error: 'Rating not found');
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final updatedRating = existingRating.copyWith(
      grade: grade,
      note: note.trim(),
    );

    final response = await _ratingService.updateRating(ratingId, updatedRating);

    return response.when(
      success: (rating, _) {
        // Update in rating list
        final updatedRatings = state.ratings
            .map((r) => r.id == rating.id ? rating : r)
            .toList();
        
        state = state.copyWith(
          ratings: updatedRatings,
          selectedRating: rating,
          isLoading: false,
        );
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }

  /// Delete a rating
  Future<bool> deleteRating(int ratingId) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _ratingService.deleteRating(ratingId);

    return response.when(
      success: (_, __) {
        // Remove from rating list
        final updatedRatings = state.ratings
            .where((r) => r.id != ratingId)
            .toList();
        
        // Clear selection if deleted rating was selected
        Rating? newSelectedRating = state.selectedRating;
        if (state.selectedRating?.id == ratingId) {
          newSelectedRating = null;
        }

        state = state.copyWith(
          ratings: updatedRatings,
          selectedRating: newSelectedRating,
          isLoading: false,
        );
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }

  /// Load rating statistics for a specific cheese
  Future<void> loadCheeseRatingStats(int cheeseId) async {
    final response = await _ratingService.getCheeseRatingStats(cheeseId);
    
    response.when(
      success: (stats, _) {
        final updatedStats = Map<int, Map<String, dynamic>>.from(state.cheeseRatingStats);
        updatedStats[cheeseId] = stats;
        state = state.copyWith(cheeseRatingStats: updatedStats);
      },
      error: (_, __, ___, ____) {
        // Error loading stats - continue without them
      },
      loading: () {},
    );
  }

  /// Get cached rating stats for a cheese
  Map<String, dynamic>? getCheeseStats(int cheeseId) {
    return state.cheeseRatingStats[cheeseId];
  }

  /// Update search query for filtering ratings
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set rating range filter
  void setRatingFilter(double? minRating, double? maxRating) {
    state = state.copyWith(
      minRating: minRating,
      maxRating: maxRating,
    );
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      minRating: null,
      maxRating: null,
      searchQuery: '',
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// React to user selection changes
  void onUserChanged() {
    _loadUserRatings();
  }
  
  /// Clear user-specific data when user logs out
  void clearUserData() {
    state = const RatingState();
  }
  
  /// Bulk make all user's ratings private
  Future<Map<String, dynamic>> makeAllRatingsPrivate() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _ratingService.makeAllRatingsPrivate();
      
      return response.when(
        success: (data, _) {
          // Refresh ratings to get updated viewer data
          _loadUserRatings();
          return data;
        },
        error: (message, statusCode, errorCode, details) {
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
          throw Exception(message);
        },
        loading: () => <String, dynamic>{},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to make ratings private: $e',
      );
      rethrow;
    }
  }
  
  /// Bulk remove specific user from all shares
  Future<Map<String, dynamic>> removeUserFromAllShares(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _ratingService.removeUserFromAllShares(userId);
      
      return response.when(
        success: (data, _) {
          // Refresh ratings to get updated viewer data
          _loadUserRatings();
          return data;
        },
        error: (message, statusCode, errorCode, details) {
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
          throw Exception(message);
        },
        loading: () => <String, dynamic>{},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove user from shares: $e',
      );
      rethrow;
    }
  }
  
  /// Load ratings for authenticated user (OAuth compatible)
  Future<void> loadRatingsForCurrentUser(int userId) async {
    // Check connectivity before loading
    if (!ApiService.isOnline) {
      state = state.copyWith(
        ratings: [],
        error: 'Offline - Rating data not available',
        isLoading: false,
      );
      return;
    }

    await loadRatingsByViewer(userId);
  }
  
  /// Share a rating with specific users - single API call
  Future<bool> shareRating(int ratingId, List<int> userIds) async {
    // Validate that the rating exists and belongs to current user
    final existingRating = state.ratings.where((r) => r.id == ratingId).firstOrNull;
    if (existingRating == null) {
      state = state.copyWith(error: 'Rating not found in your list (ID: $ratingId)');
      return false;
    }
    
    final authState = _ref.read(authProvider);
    final currentUserId = authState.user?.id;
    if (currentUserId == null || existingRating.authorId != currentUserId) {
      state = state.copyWith(error: 'You can only share your own ratings (Rating author: ${existingRating.authorId}, Current user: $currentUserId)');
      return false;
    }
    
    if (userIds.isEmpty) {
      state = state.copyWith(error: 'Please select at least one user to share with');
      return false;
    }
    
    print('Sharing rating $ratingId with user IDs: $userIds (single API call)');
    
    state = state.copyWith(isLoading: true, error: null);

    // Always use single API call with array of user IDs
    final response = await _ratingService.shareRating(ratingId, userIds: userIds);
    
    return response.when(
      success: (rating, _) {
        // Update the rating in our list
        final updatedRatings = state.ratings
            .map((r) => r.id == rating.id ? rating : r)
            .toList();
        
        state = state.copyWith(
          ratings: updatedRatings,
          selectedRating: rating,
          isLoading: false,
        );
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sharing failed: $message (Status: $statusCode)',
        );
        return false;
      },
      loading: () => false,
    );
  }
  
  /// Hide/unshare a rating (make it private again)
  Future<bool> unshareRating(int ratingId) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _ratingService.hideRating(ratingId);

    return response.when(
      success: (rating, _) {
        // Update the rating in our list
        final updatedRatings = state.ratings
            .map((r) => r.id == rating.id ? rating : r)
            .toList();
        
        state = state.copyWith(
          ratings: updatedRatings,
          selectedRating: rating,
          isLoading: false,
        );
        return true;
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
        return false;
      },
      loading: () => false,
    );
  }
}

/// Computed provider for user's cheese ratings only
final cheeseRatingsProvider = Provider<List<Rating>>((ref) {
  final ratingState = ref.watch(ratingProvider);
  return ratingState.ratings.where((r) => r.isCheeseRating).toList();
});

/// Computed provider for checking if user has ratings
final hasRatingsProvider = Provider<bool>((ref) {
  final ratingState = ref.watch(ratingProvider);
  return ratingState.ratings.isNotEmpty;
});

/// Provider to watch for authentication changes and reload ratings
final ratingListenerProvider = Provider<void>((ref) {
  // Watch for authentication state changes
  ref.listen(authProvider, (previous, next) {
    final ratingNotifier = ref.read(ratingProvider.notifier);
    
    if (previous?.user?.id != next.user?.id) {
      // User changed or logged in/out
      if (next.isAuthenticated && next.user?.id != null && !next.needsProfileSetup) {
        // User authenticated AND profile complete - load their ratings
        if (ApiService.isOnline) {
          ratingNotifier.loadRatingsForCurrentUser(next.user!.id!);
        } else {
          ratingNotifier.clearUserData();
        }
      } else {
        // User logged out or profile incomplete - clear data
        ratingNotifier.clearUserData();
      }
    } else if (previous?.needsProfileSetup == true && next.needsProfileSetup == false) {
      // Profile setup was just completed - now load ratings
      if (next.isAuthenticated && next.user?.id != null && ApiService.isOnline) {
        ratingNotifier.loadRatingsForCurrentUser(next.user!.id!);
      }
    }
  });
});
