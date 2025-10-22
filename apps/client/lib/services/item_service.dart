import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rateable_item.dart';
import '../models/cheese_item.dart';
import '../models/gin_item.dart';
import '../models/wine_item.dart';
import '../models/coffee_item.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Generic service for managing any type of rateable item
abstract class ItemService<T extends RateableItem> extends ApiService {
  String get itemTypeEndpoint;
  T Function(dynamic) get fromJson; // Changed to match ApiService signature
  List<String> Function(T) get validateItem;

  /// Get all items of this type
  Future<ApiResponse<List<T>>> getAllItems() async {
    return handleListResponse<T>(get('$itemTypeEndpoint/all'), fromJson);
  }

  /// Get item by ID
  Future<ApiResponse<T>> getItemById(int id) async {
    return handleResponse<T>(get('$itemTypeEndpoint/$id'), fromJson);
  }

  /// Create new item
  Future<ApiResponse<T>> createItem(T item) async {
    final validationErrors = validateItem(item);
    if (validationErrors.isNotEmpty) {
      return ApiResponseHelper.error(
        'Validation failed: ${validationErrors.join(', ')}',
      );
    }

    return handleResponse<T>(
      post('$itemTypeEndpoint/new', data: item.toJson()),
      fromJson,
    );
  }

  /// Update existing item
  Future<ApiResponse<T>> updateItem(int id, T item) async {
    final validationErrors = validateItem(item);
    if (validationErrors.isNotEmpty) {
      return ApiResponseHelper.error(
        'Validation failed: ${validationErrors.join(', ')}',
      );
    }

    return handleResponse<T>(
      put('$itemTypeEndpoint/$id', data: item.toJson()),
      fromJson,
    );
  }

  /// Delete item
  Future<ApiResponse<bool>> deleteItem(int id) async {
    return handleEmptyResponse(delete('$itemTypeEndpoint/$id'));
  }
}

/// Concrete implementation for Cheese items
class CheeseItemService extends ItemService<CheeseItem> {
  // Singleton pattern to preserve cache across provider recreations
  static final CheeseItemService _instance = CheeseItemService._internal();
  
  factory CheeseItemService() => _instance;
  
  CheeseItemService._internal();
  
  // Cache for avoiding duplicate API calls
  ApiResponse<List<CheeseItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  @override
  String get itemTypeEndpoint => '/api/cheese';

  @override
  CheeseItem Function(dynamic) get fromJson =>
      (dynamic json) => CheeseItem.fromJson(json as Map<String, dynamic>);

  @override
  List<String> Function(CheeseItem) get validateItem => _validateCheeseItem;
  
  @override
  Future<ApiResponse<List<CheeseItem>>> getAllItems() async {
    // Check if we have valid cached data
    if (_cachedResponse != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheExpiry) {
        return _cachedResponse!;
      }
    }
    
    // Make API call and cache result
    final response = await handleListResponse<CheeseItem>(get('$itemTypeEndpoint/all'), fromJson);
    
    // Cache successful responses
    if (response is ApiSuccess<List<CheeseItem>>) {
      _cachedResponse = response;
      _cacheTime = DateTime.now();
    }
    
    return response;
  }
  
  /// Clear cache (useful for testing or after data changes)
  Future<void> clearCache() async {
    _cachedResponse = null;
    _cacheTime = null;
    // Also clear image cache and wait for completion
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      print('Failed to clear image cache: $e');
    }
  }

  static List<String> _validateCheeseItem(CheeseItem cheese) {
    final errors = <String>[];

    if (cheese.name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (cheese.type.trim().isEmpty) {
      errors.add('Type is required');
    }

    if (cheese.description != null && cheese.description!.trim().isEmpty) {
      errors.add('Description cannot be empty if provided');
    }

    return errors;
  }

  /// Get unique cheese types for filtering
  Future<ApiResponse<List<String>>> getCheeseTypes() async {
    final response = await getAllItems();
    return response.when(
      success: (cheeses, _) {
        final types = CheeseItemExtension.getUniqueTypes(cheeses);
        return ApiResponseHelper.success(types);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique cheese origins for filtering
  Future<ApiResponse<List<String>>> getCheeseOrigins() async {
    final response = await getAllItems();
    return response.when(
      success: (cheeses, _) {
        final origins = CheeseItemExtension.getUniqueOrigins(cheeses);
        return ApiResponseHelper.success(origins);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Search cheeses by query
  Future<ApiResponse<List<CheeseItem>>> searchItems(String query) async {
    final response = await getAllItems();
    return response.when(
      success: (cheeses, _) {
        final filteredCheeses = cheeses
            .where(
              (cheese) => cheese.searchableText.contains(query.toLowerCase()),
            )
            .toList();
        return ApiResponseHelper.success(filteredCheeses);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<CheeseItem>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<CheeseItem>>(),
    );
  }

  /// Filter cheeses by category
  Future<ApiResponse<List<CheeseItem>>> filterByCategory(
    String categoryKey,
    String categoryValue,
  ) async {
    final response = await getAllItems();
    return response.when(
      success: (cheeses, _) {
        final filteredCheeses = cheeses
            .where(
              (cheese) =>
                  cheese.categories[categoryKey]?.toLowerCase() ==
                  categoryValue.toLowerCase(),
            )
            .toList();
        return ApiResponseHelper.success(filteredCheeses);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<CheeseItem>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<CheeseItem>>(),
    );
  }
}

/// Provider for CheeseItemService (cached to preserve service-level cache)
final cheeseItemServiceProvider = Provider<CheeseItemService>(
  (ref) {
    // Return singleton instance to preserve cache across provider reads
    return CheeseItemService._instance;
  },
);

/// Concrete implementation for Gin items
class GinItemService extends ItemService<GinItem> {
  // Singleton pattern to preserve cache across provider recreations
  static final GinItemService _instance = GinItemService._internal();
  
  factory GinItemService() => _instance;
  
  GinItemService._internal();
  
  // Cache for avoiding duplicate API calls
  ApiResponse<List<GinItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  @override
  String get itemTypeEndpoint => '/api/gin';

  @override
  GinItem Function(dynamic) get fromJson =>
      (dynamic json) => GinItem.fromJson(json as Map<String, dynamic>);

  @override
  List<String> Function(GinItem) get validateItem => _validateGinItem;
  
  @override
  Future<ApiResponse<List<GinItem>>> getAllItems() async {
    // Check if we have valid cached data
    if (_cachedResponse != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheExpiry) {
        return _cachedResponse!;
      }
    }
    
    // Make API call and cache result
    final response = await handleListResponse<GinItem>(get('$itemTypeEndpoint/all'), fromJson);
    
    // Cache successful responses
    if (response is ApiSuccess<List<GinItem>>) {
      _cachedResponse = response;
      _cacheTime = DateTime.now();
    }
    
    return response;
  }
  
  /// Clear cache (useful for testing or after data changes)
  Future<void> clearCache() async {
    _cachedResponse = null;
    _cacheTime = null;
    // Also clear image cache and wait for completion
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      print('Failed to clear image cache: $e');
    }
  }

  static List<String> _validateGinItem(GinItem gin) {
    final errors = <String>[];

    if (gin.name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (gin.producer.trim().isEmpty) {
      errors.add('Producer is required');
    }

    if (gin.profile.trim().isEmpty) {
      errors.add('Profile is required');
    }

    if (gin.description != null && gin.description!.trim().isEmpty) {
      errors.add('Description cannot be empty if provided');
    }

    return errors;
  }

  /// Get unique gin producers for filtering
  Future<ApiResponse<List<String>>> getGinProducers() async {
    final response = await getAllItems();
    return response.when(
      success: (gins, _) {
        final producers = GinItemExtension.getUniqueProducers(gins);
        return ApiResponseHelper.success(producers);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique gin origins for filtering
  Future<ApiResponse<List<String>>> getGinOrigins() async {
    final response = await getAllItems();
    return response.when(
      success: (gins, _) {
        final origins = GinItemExtension.getUniqueOrigins(gins);
        return ApiResponseHelper.success(origins);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique gin profiles for filtering
  Future<ApiResponse<List<String>>> getGinProfiles() async {
    final response = await getAllItems();
    return response.when(
      success: (gins, _) {
        final profiles = GinItemExtension.getUniqueProfiles(gins);
        return ApiResponseHelper.success(profiles);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }
}

/// Provider for GinItemService (cached to preserve service-level cache)
final ginItemServiceProvider = Provider<GinItemService>(
  (ref) {
    // Return singleton instance to preserve cache across provider reads
    return GinItemService._instance;
  },
);

/// Concrete implementation for Wine items
class WineItemService extends ItemService<WineItem> {
  // Singleton pattern to preserve cache across provider recreations
  static final WineItemService _instance = WineItemService._internal();
  
  factory WineItemService() => _instance;
  
  WineItemService._internal();
  
  // Cache for avoiding duplicate API calls
  ApiResponse<List<WineItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  @override
  String get itemTypeEndpoint => '/api/wine';

  @override
  WineItem Function(dynamic) get fromJson =>
      (dynamic json) => WineItem.fromJson(json as Map<String, dynamic>);

  @override
  List<String> Function(WineItem) get validateItem => _validateWineItem;
  
  @override
  Future<ApiResponse<List<WineItem>>> getAllItems() async {
    // Check if we have valid cached data
    if (_cachedResponse != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheExpiry) {
        return _cachedResponse!;
      }
    }
    
    // Make API call and cache result
    final response = await handleListResponse<WineItem>(get('$itemTypeEndpoint/all'), fromJson);
    
    // Cache successful responses
    if (response is ApiSuccess<List<WineItem>>) {
      _cachedResponse = response;
      _cacheTime = DateTime.now();
    }
    
    return response;
  }
  
  /// Clear cache (useful for testing or after data changes)
  Future<void> clearCache() async {
    _cachedResponse = null;
    _cacheTime = null;
    // Also clear image cache and wait for completion
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      print('Failed to clear image cache: $e');
    }
  }

  static List<String> _validateWineItem(WineItem wine) {
    final errors = <String>[];

    if (wine.name.trim().isEmpty) {
      errors.add('Name is required');
    }

    // Color is always valid (enum type)
    // No validation needed

    if (wine.country.trim().isEmpty) {
      errors.add('Country is required');
    }

    return errors;
  }

  /// Get unique wine colors for filtering
  Future<ApiResponse<List<String>>> getWineColors() async {
    final response = await getAllItems();
    return response.when(
      success: (wines, _) {
        final colors = wines
            .map((wine) => wine.color.value)
            .toSet()
            .toList()
          ..sort();
        return ApiResponseHelper.success(colors);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique wine countries for filtering
  Future<ApiResponse<List<String>>> getWineCountries() async {
    final response = await getAllItems();
    return response.when(
      success: (wines, _) {
        final countries = wines
            .map((wine) => wine.country)
            .where((country) => country.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        return ApiResponseHelper.success(countries);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique wine regions for filtering
  Future<ApiResponse<List<String>>> getWineRegions() async {
    final response = await getAllItems();
    return response.when(
      success: (wines, _) {
        final regions = wines
            .where((wine) => wine.region != null && wine.region!.isNotEmpty)
            .map((wine) => wine.region!)
            .toSet()
            .toList()
          ..sort();
        return ApiResponseHelper.success(regions);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }
}

/// Provider for WineItemService (cached to preserve service-level cache)
final wineItemServiceProvider = Provider<WineItemService>(
  (ref) {
    // Return singleton instance to preserve cache across provider reads
    return WineItemService._instance;
  },
);

/// Concrete implementation for Coffee items
class CoffeeItemService extends ItemService<CoffeeItem> {
  // Singleton pattern to preserve cache across provider recreations
  static final CoffeeItemService _instance = CoffeeItemService._internal();
  
  factory CoffeeItemService() => _instance;
  
  CoffeeItemService._internal();
  
  // Cache for avoiding duplicate API calls
  ApiResponse<List<CoffeeItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  @override
  String get itemTypeEndpoint => '/api/coffee';

  @override
  CoffeeItem Function(dynamic) get fromJson =>
      (dynamic json) => CoffeeItem.fromJson(json as Map<String, dynamic>);

  @override
  List<String> Function(CoffeeItem) get validateItem => _validateCoffeeItem;
  
  @override
  Future<ApiResponse<List<CoffeeItem>>> getAllItems() async {
    // Check if we have valid cached data
    if (_cachedResponse != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheExpiry) {
        return _cachedResponse!;
      }
    }
    
    // Make API call and cache result
    final response = await handleListResponse<CoffeeItem>(get('$itemTypeEndpoint/all'), fromJson);
    
    // Cache successful responses
    if (response is ApiSuccess<List<CoffeeItem>>) {
      _cachedResponse = response;
      _cacheTime = DateTime.now();
    }
    
    return response;
  }
  
  /// Clear cache (useful for testing or after data changes)
  Future<void> clearCache() async {
    _cachedResponse = null;
    _cacheTime = null;
    // Also clear image cache and wait for completion
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      print('Failed to clear image cache: $e');
    }
  }

  static List<String> _validateCoffeeItem(CoffeeItem coffee) {
    final errors = <String>[];

    if (coffee.name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (coffee.roaster.trim().isEmpty) {
      errors.add('Roaster is required');
    }

    return errors;
  }

  /// Get unique coffee roasters for filtering
  Future<ApiResponse<List<String>>> getCoffeeRoasters() async {
    final response = await getAllItems();
    return response.when(
      success: (coffees, _) {
        final roasters = CoffeeItemExtension.getUniqueRoasters(coffees);
        return ApiResponseHelper.success(roasters);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique coffee countries for filtering
  Future<ApiResponse<List<String>>> getCoffeeCountries() async {
    final response = await getAllItems();
    return response.when(
      success: (coffees, _) {
        final countries = CoffeeItemExtension.getUniqueCountries(coffees);
        return ApiResponseHelper.success(countries);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique coffee regions for filtering
  Future<ApiResponse<List<String>>> getCoffeeRegions() async {
    final response = await getAllItems();
    return response.when(
      success: (coffees, _) {
        final regions = CoffeeItemExtension.getUniqueRegions(coffees);
        return ApiResponseHelper.success(regions);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique coffee processing methods for filtering
  Future<ApiResponse<List<String>>> getCoffeeProcessingMethods() async {
    final response = await getAllItems();
    return response.when(
      success: (coffees, _) {
        final methods = CoffeeItemExtension.getUniqueProcessingMethods(coffees);
        return ApiResponseHelper.success(methods);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }

  /// Get unique coffee roast levels for filtering
  Future<ApiResponse<List<String>>> getCoffeeRoastLevels() async {
    final response = await getAllItems();
    return response.when(
      success: (coffees, _) {
        final roastLevels = CoffeeItemExtension.getUniqueRoastLevels(coffees);
        return ApiResponseHelper.success(roastLevels);
      },
      error: (message, statusCode, errorCode, details) =>
          ApiResponseHelper.error<List<String>>(
            message,
            statusCode: statusCode,
            errorCode: errorCode,
          ),
      loading: () => ApiResponseHelper.loading<List<String>>(),
    );
  }
}

/// Provider for CoffeeItemService (cached to preserve service-level cache)
final coffeeItemServiceProvider = Provider<CoffeeItemService>(
  (ref) {
    // Return singleton instance to preserve cache across provider reads
    return CoffeeItemService._instance;
  },
);
