import 'package:flutter/material.dart';
import '../utils/extensions.dart';

/// Detail field structure for item-specific information
class DetailField {
  final String label;
  final String value;
  final IconData? icon;
  final bool isDescription;
  
  const DetailField({
    required this.label,
    required this.value,
    this.icon,
    this.isDescription = false,
  });
}

/// Generic interface for all rateable items (cheese, future categories, etc.)
abstract class RateableItem {
  /// Unique identifier for the item
  int? get id;
  
  /// Type identifier for the rating system ('cheese', future types, etc.)
  String get itemType;
  
  /// Primary name/title of the item
  String get name;
  
  /// Display title for UI (formatted for presentation)
  String get displayTitle;
  
  /// Display subtitle for UI (additional context)
  String get displaySubtitle;
  
  /// Check if item is new (no ID assigned)
  bool get isNew;
  
  /// Convert to JSON for API communication
  Map<String, dynamic> toJson();
  
  /// Create a copy with updated fields
  RateableItem copyWith(Map<String, dynamic> updates);
  
  /// Get searchable text for filtering
  String get searchableText;
  
  /// Get all categorization fields for filtering
  Map<String, String> get categories;
  
  /// Get structured detail fields for display
  List<DetailField> get detailFields;
}

/// Helper class for item type utilities
class ItemTypeHelper {
  /// Get display name for item type
  static String getItemTypeDisplayName(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return 'Cheese';
      case 'gin':
        return 'Gin';
      case 'wine':
        return 'Wine';
      case 'coffee':
        return 'Coffee';
      case 'chili-sauce':
        return 'Chili Sauce';
      default:
        return itemType.capitalized;
    }
  }
  
  /// Get icon for item type
  static IconData getItemTypeIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return Icons.local_pizza;
      case 'gin':
        return Icons.local_bar;
      case 'wine':
        return Icons.wine_bar;
      case 'beer':
        return Icons.sports_bar;
      case 'coffee':
        return Icons.local_cafe;
      case 'chili-sauce':
        return Icons.local_fire_department;
      default:
        return Icons.category;
    }
  }
  
  /// Get appropriate color for item type
  static Color getItemTypeColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'cheese':
        return Colors.orange;
      case 'gin':
        return Colors.teal;
      case 'wine':
        return Colors.purple;
      case 'beer':
        return Colors.amber;
      case 'coffee':
        return Colors.brown;
      case 'chili-sauce':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Check if item type is supported
  static bool isItemTypeSupported(String itemType) {
    const supportedTypes = ['cheese', 'gin', 'wine', 'coffee', 'chili-sauce']; // Add more as they're implemented
    return supportedTypes.contains(itemType.toLowerCase());
  }
}
