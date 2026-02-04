import 'package:flutter/material.dart';
import 'rateable_item.dart';
import '../utils/localization_utils.dart';

/// Spice level enum for chili sauces
enum SpiceLevel {
  mild,
  medium,
  hot,
  extraHot,
  extreme,
}

/// Extension for SpiceLevel to get display names
extension SpiceLevelExtension on SpiceLevel {
  String get displayName {
    switch (this) {
      case SpiceLevel.mild:
        return 'Mild';
      case SpiceLevel.medium:
        return 'Medium';
      case SpiceLevel.hot:
        return 'Hot';
      case SpiceLevel.extraHot:
        return 'Extra Hot';
      case SpiceLevel.extreme:
        return 'Extreme';
    }
  }

  /// Get localized display name
  String getLocalizedDisplayName(BuildContext context) {
    switch (this) {
      case SpiceLevel.mild:
        return context.l10n.spiceLevelMild;
      case SpiceLevel.medium:
        return context.l10n.spiceLevelMedium;
      case SpiceLevel.hot:
        return context.l10n.spiceLevelHot;
      case SpiceLevel.extraHot:
        return context.l10n.spiceLevelExtraHot;
      case SpiceLevel.extreme:
        return context.l10n.spiceLevelExtreme;
    }
  }
}

/// ChiliSauceItem - implements RateableItem interface for chili sauce-specific functionality
class ChiliSauceItem implements RateableItem {
  @override
  final int? id;
  @override
  final String name;
  final String? brand;
  final SpiceLevel spiceLevel;
  final String? chilis;
  final String? description;
  final String? imageUrl;

  const ChiliSauceItem({
    this.id,
    required this.name,
    this.brand,
    required this.spiceLevel,
    this.chilis,
    this.description,
    this.imageUrl,
  });

  @override
  String get itemType => 'chili-sauce';

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle {
    final parts = <String>[];
    if (brand != null && brand!.isNotEmpty) parts.add(brand!);
    parts.add(spiceLevel.displayName);
    return parts.join(' • ');
  }

  @override
  bool get isNew => id == null;

  @override
  String get searchableText =>
      '$name ${brand ?? ''} ${spiceLevel.displayName} ${chilis ?? ''} ${description ?? ''}'.toLowerCase();

  @override
  Map<String, String> get categories {
    final cats = <String, String>{
      'spiceLevel': spiceLevel.displayName,
    };
    if (brand != null && brand!.isNotEmpty) cats['brand'] = brand!;
    if (chilis != null && chilis!.isNotEmpty) cats['chilis'] = chilis!;
    return cats;
  }

  @override
  List<DetailField> get detailFields => [
        if (brand != null && brand!.isNotEmpty)
          DetailField(
            label: 'Brand',
            value: brand!,
            icon: Icons.business,
          ),
        // Note: Spice Level is displayed as a badge in the header, not here
        if (chilis != null && chilis!.isNotEmpty)
          DetailField(
            label: 'Chilis',
            value: chilis!,
            icon: Icons.grass,
          ),
        if (description != null && description!.isNotEmpty)
          DetailField(
            label: 'Description',
            value: description!,
            isDescription: true,
          ),
      ];

  /// Get localized detail fields for display
  List<DetailField> getLocalizedDetailFields(BuildContext context) {
    return [
      if (brand != null && brand!.isNotEmpty)
        DetailField(
          label: context.l10n.brandLabel,
          value: brand!,
          icon: Icons.business,
        ),
      // Note: Spice Level is displayed as a badge in the header, not here
      if (chilis != null && chilis!.isNotEmpty)
        DetailField(
          label: context.l10n.chilisLabel,
          value: chilis!,
          icon: Icons.grass,
        ),
      if (description != null && description!.isNotEmpty)
        DetailField(
          label: context.l10n.descriptionLabel,
          value: description!,
          isDescription: true,
        ),
    ];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'brand': brand,
      'spiceLevel': spiceLevel.displayName,
      'chilis': chilis,
      'description': description,
      'image_url': imageUrl,
    };
  }

  /// Create from JSON
  factory ChiliSauceItem.fromJson(Map<String, dynamic> json) {
    final spiceLevelString = json['spiceLevel'] as String? ?? 'Medium';
    final spiceLevel = _parseSpiceLevel(spiceLevelString);

    return ChiliSauceItem(
      id: json['ID'] as int?,
      name: (json['name'] as String?) ?? '',
      brand: json['brand'] as String?,
      spiceLevel: spiceLevel,
      chilis: json['chilis'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Parse spice level from string
  static SpiceLevel _parseSpiceLevel(String value) {
    switch (value.toLowerCase()) {
      case 'mild':
        return SpiceLevel.mild;
      case 'medium':
        return SpiceLevel.medium;
      case 'hot':
        return SpiceLevel.hot;
      case 'extra hot':
      case 'extra_hot':
        return SpiceLevel.extraHot;
      case 'extreme':
        return SpiceLevel.extreme;
      default:
        return SpiceLevel.medium;
    }
  }

  @override
  ChiliSauceItem copyWith(Map<String, dynamic> updates) {
    return ChiliSauceItem(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      brand: updates['brand'] ?? brand,
      spiceLevel: updates['spice_level'] != null
          ? _parseSpiceLevel(updates['spice_level'] as String)
          : spiceLevel,
      chilis: updates['chilis'] ?? chilis,
      description: updates['description'] ?? description,
      imageUrl: updates['image_url'] ?? imageUrl,
    );
  }

  // ChiliSauce-specific methods
  ChiliSauceItem copyWithChiliSauce({
    int? id,
    String? name,
    String? brand,
    SpiceLevel? spiceLevel,
    String? chilis,
    String? description,
    String? imageUrl,
  }) {
    return ChiliSauceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      chilis: chilis ?? this.chilis,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChiliSauceItem &&
        other.id == id &&
        other.name == name &&
        other.brand == brand &&
        other.spiceLevel == spiceLevel &&
        other.chilis == chilis &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, brand, spiceLevel, chilis, description, imageUrl);
  }

  @override
  String toString() {
    return 'ChiliSauceItem(id: $id, name: $name, brand: $brand, spiceLevel: $spiceLevel, chilis: $chilis, description: $description, imageUrl: $imageUrl)';
  }
}

/// Extension for ChiliSauceItem convenience methods
extension ChiliSauceItemExtension on ChiliSauceItem {
  /// Get all unique brands from a list of chili sauce items
  static List<String> getUniqueBrands(List<ChiliSauceItem> chiliSauces) {
    return chiliSauces
        .where((c) => c.brand != null && c.brand!.isNotEmpty)
        .map((c) => c.brand!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get all unique chilis from a list of chili sauce items
  static List<String> getUniqueChilis(List<ChiliSauceItem> chiliSauces) {
    final allChilis = <String>{};
    for (final chiliSauce in chiliSauces) {
      if (chiliSauce.chilis != null && chiliSauce.chilis!.isNotEmpty) {
        // Split by comma and add each chili type
        final chilis = chiliSauce.chilis!.split(',').map((c) => c.trim());
        allChilis.addAll(chilis);
      }
    }
    return allChilis.toList()..sort();
  }

  /// Get all unique spice levels from a list of chili sauce items
  static List<String> getUniqueSpiceLevels(List<ChiliSauceItem> chiliSauces) {
    return chiliSauces
        .map((c) => c.spiceLevel.displayName)
        .toSet()
        .toList()
      ..sort();
  }
}
