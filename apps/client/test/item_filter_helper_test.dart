import 'package:flutter_test/flutter_test.dart';
import 'package:alc_client/models/cheese_item.dart';
import 'package:alc_client/models/rating.dart';
import 'package:alc_client/utils/item_filter_helper.dart';

void main() {
  group('ItemFilterHelper Picture Filter Tests', () {
    test('should filter items with pictures', () {
      // Arrange
      final items = [
        CheeseItem(
          id: 1,
          name: 'Cheddar',
          type: 'Hard',
          imageUrl: 'https://example.com/cheddar.jpg',
        ),
        CheeseItem(id: 2, name: 'Brie', type: 'Soft', imageUrl: null),
        CheeseItem(
          id: 3,
          name: 'Gouda',
          type: 'Hard',
          imageUrl: 'https://example.com/gouda.jpg',
        ),
      ];

      final filters = {'has_picture': 'true'};
      final userRatings = <Rating>[];

      // Act
      final result = ItemFilterHelper.filterItemsWithRatingContext(
        items,
        userRatings,
        null,
        filters,
        false, // isPersonalListTab
      );

      // Assert
      expect(result.length, 2);
      expect(result.map((item) => item.id).toSet(), {1, 3});
    });

    test('should filter items without pictures', () {
      // Arrange
      final items = [
        CheeseItem(
          id: 1,
          name: 'Cheddar',
          type: 'Hard',
          imageUrl: 'https://example.com/cheddar.jpg',
        ),
        CheeseItem(id: 2, name: 'Brie', type: 'Soft', imageUrl: null),
        CheeseItem(
          id: 3,
          name: 'Gouda',
          type: 'Hard',
          imageUrl: 'https://example.com/gouda.jpg',
        ),
      ];

      final filters = {'has_picture': 'false'};
      final userRatings = <Rating>[];

      // Act
      final result = ItemFilterHelper.filterItemsWithRatingContext(
        items,
        userRatings,
        null,
        filters,
        false, // isPersonalListTab
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('should not filter items when picture filter is not set', () {
      // Arrange
      final items = [
        CheeseItem(
          id: 1,
          name: 'Cheddar',
          type: 'Hard',
          imageUrl: 'https://example.com/cheddar.jpg',
        ),
        CheeseItem(id: 2, name: 'Brie', type: 'Soft', imageUrl: null),
      ];

      final filters = <String, String>{}; // No picture filter
      final userRatings = <Rating>[];

      // Act
      final result = ItemFilterHelper.filterItemsWithRatingContext(
        items,
        userRatings,
        null,
        filters,
        false, // isPersonalListTab
      );

      // Assert
      expect(result.length, 2);
    });

    test('should handle items with empty imageUrl as having no picture', () {
      // Arrange
      final items = [
        CheeseItem(
          id: 1,
          name: 'Cheddar',
          type: 'Hard',
          imageUrl: '', // Empty string
        ),
        CheeseItem(
          id: 2,
          name: 'Brie',
          type: 'Soft',
          imageUrl: 'https://example.com/brie.jpg',
        ),
      ];

      final filters = {'has_picture': 'true'};
      final userRatings = <Rating>[];

      // Act
      final result = ItemFilterHelper.filterItemsWithRatingContext(
        items,
        userRatings,
        null,
        filters,
        false, // isPersonalListTab
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('should combine picture filter with rating filters', () {
      // Arrange
      final items = [
        CheeseItem(
          id: 1,
          name: 'Cheddar',
          type: 'Hard',
          imageUrl: 'https://example.com/cheddar.jpg',
        ),
        CheeseItem(
          id: 2,
          name: 'Brie',
          type: 'Soft',
          imageUrl: 'https://example.com/brie.jpg',
        ),
        CheeseItem(id: 3, name: 'Gouda', type: 'Hard', imageUrl: null),
      ];

      final userRatings = [
        Rating(
          id: 1,
          itemId: 1,
          itemType: 'cheese',
          authorId: 1,
          grade: 4.0,
          note: 'Great cheese',
        ),
      ];

      // Filter for items with pictures AND ratings
      final filters = {'has_picture': 'true', 'rating_status': 'has_ratings'};

      // Act
      final result = ItemFilterHelper.filterItemsWithRatingContext(
        items,
        userRatings,
        1, // currentUserId
        filters,
        false, // isPersonalListTab
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 1); // Only cheddar has both picture and rating
    });
  });
}
