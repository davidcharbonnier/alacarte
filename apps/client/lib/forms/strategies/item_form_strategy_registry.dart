import '../../models/rateable_item.dart';
import 'item_form_strategy.dart';
import 'cheese_form_strategy.dart';
import 'gin_form_strategy.dart';
import 'wine_form_strategy.dart';
import 'coffee_form_strategy.dart';

/// Central registry for all item form strategies
/// 
/// This registry provides type-safe access to form strategies for each
/// supported item type. Adding a new item type requires only:
/// 1. Creating a new strategy class
/// 2. Adding it to the _strategies map below
class ItemFormStrategyRegistry {
  // Private constructor to prevent instantiation
  ItemFormStrategyRegistry._();

  /// Static registry mapping item types to their strategies
  static final Map<String, ItemFormStrategy> _strategies = {
    'cheese': CheeseFormStrategy(),
    'gin': GinFormStrategy(),
    'wine': WineFormStrategy(),
    'coffee': CoffeeFormStrategy(),
    // Future item types:
    // 'beer': BeerFormStrategy(),
  };

  /// Get strategy for the specified item type
  /// 
  /// Throws [UnsupportedError] if no strategy is registered for the item type.
  /// 
  /// Example:
  /// ```dart
  /// final strategy = ItemFormStrategyRegistry.getStrategy<CheeseItem>('cheese');
  /// ```
  static ItemFormStrategy<T> getStrategy<T extends RateableItem>(
    String itemType,
  ) {
    final strategy = _strategies[itemType];

    if (strategy == null) {
      throw UnsupportedError(
        'No form strategy registered for item type: $itemType. '
        'Available types: ${_strategies.keys.join(', ')}',
      );
    }

    return strategy as ItemFormStrategy<T>;
  }

  /// Check if a strategy exists for the specified item type
  /// 
  /// Returns true if a strategy is registered, false otherwise.
  static bool hasStrategy(String itemType) {
    return _strategies.containsKey(itemType);
  }

  /// Get all supported item types
  /// 
  /// Returns a list of item type strings that have registered strategies.
  static List<String> getSupportedItemTypes() {
    return _strategies.keys.toList();
  }
}
