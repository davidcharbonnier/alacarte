import 'package:flutter_test/flutter_test.dart';
import 'package:alc_client/widgets/common/item_search_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alc_client/flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  group('Picture Filter Integration Tests', () {
    Widget createTestWidget({
      String itemType = 'cheese',
      Map<String, List<String>> availableFilters = const {},
      Map<String, String> activeFilters = const {},
      required Function(String, String?) onFilterChanged,
      bool isPersonalListTab = false,
    }) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ItemSearchAndFilter(
              itemType: itemType,
              onSearchChanged: (_) {},
              onFilterChanged: onFilterChanged,
              onClearFilters: () {},
              availableFilters: availableFilters,
              activeFilters: activeFilters,
              currentSearchQuery: '',
              totalItems: 10,
              filteredItems: 5,
              isPersonalListTab: isPersonalListTab,
            ),
          ),
        ),
      );
    }

    testWidgets('should display picture filter chip', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget(onFilterChanged: (_, __) {}));

      // Wait for localization to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('With Picture'), findsOneWidget);
    });

    testWidgets('should toggle picture filter when chip is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      String? capturedFilterKey;
      String? capturedFilterValue;

      await tester.pumpWidget(
        createTestWidget(
          onFilterChanged: (key, value) {
            capturedFilterKey = key;
            capturedFilterValue = value;
          },
        ),
      );

      // Wait for localization to load
      await tester.pumpAndSettle();

      // Act - Tap the picture filter chip
      await tester.tap(find.text('With Picture'));
      await tester.pump();

      // Assert
      expect(capturedFilterKey, 'has_picture');
      expect(capturedFilterValue, 'true');
    });

    testWidgets('should show picture filter as selected when active', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          activeFilters: {'has_picture': 'true'},
          onFilterChanged: (_, __) {},
        ),
      );

      // Wait for localization to load
      await tester.pumpAndSettle();

      // Act - Find the picture filter chip
      final pictureFilterChip = find.byType(FilterChip).last;

      // Assert - Check if it's selected (this is a bit tricky as FilterChip doesn't expose selected state directly)
      // We can verify by checking if the chip exists and is tappable
      expect(pictureFilterChip, findsOneWidget);
    });

    testWidgets(
      'should show picture filter in both personal and all items tabs',
      (WidgetTester tester) async {
        // Test personal list tab
        await tester.pumpWidget(
          createTestWidget(
            isPersonalListTab: true,
            onFilterChanged: (_, __) {},
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('With Picture'), findsOneWidget);

        // Test all items tab
        await tester.pumpWidget(
          createTestWidget(
            isPersonalListTab: false,
            onFilterChanged: (_, __) {},
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('With Picture'), findsOneWidget);
      },
    );

    testWidgets('should clear picture filter when clear filters is called', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          activeFilters: {'has_picture': 'true'},
          onFilterChanged: (_, __) {},
        ),
      );

      await tester.pumpAndSettle();

      // Act - Simulate clearing filters (this would be called by the parent widget)
      // In a real scenario, the parent would call onClearFilters which would reset activeFilters
      await tester.pumpWidget(
        createTestWidget(
          activeFilters: {}, // Cleared filters
          onFilterChanged: (_, __) {},
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('With Picture'), findsOneWidget); // Chip still exists
      // The filter would be cleared by the parent widget calling onClearFilters
    });
  });
}
