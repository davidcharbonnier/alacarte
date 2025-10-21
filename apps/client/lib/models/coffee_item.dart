import 'package:flutter/material.dart';
import 'rateable_item.dart';
import '../utils/localization_utils.dart';

/// CoffeeItem - implements RateableItem interface for coffee-specific functionality
class CoffeeItem implements RateableItem {
  @override
  final int? id;
  @override
  final String name;
  final String roaster;
  final String? country;
  final String? region;
  final String? farm;
  final String? altitude;
  final String? species;
  final String? variety;
  final String? processingMethod;
  final bool decaffeinated;
  final String? roastLevel;
  final List<String>? tastingNotes;
  final String? acidity;
  final String? body;
  final String? sweetness;
  final bool organic;
  final bool fairTrade;
  final String? description;
  final String? imageUrl;

  const CoffeeItem({
    this.id,
    required this.name,
    required this.roaster,
    this.country,
    this.region,
    this.farm,
    this.altitude,
    this.species,
    this.variety,
    this.processingMethod,
    this.decaffeinated = false,
    this.roastLevel,
    this.tastingNotes,
    this.acidity,
    this.body,
    this.sweetness,
    this.organic = false,
    this.fairTrade = false,
    this.description,
    this.imageUrl,
  });

  @override
  String get itemType => 'coffee';

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle {
    return roaster;
  }

  @override
  bool get isNew => id == null;

  @override
  String get searchableText {
    final parts = [
      name,
      roaster,
      country ?? '',
      region ?? '',
      farm ?? '',
      variety ?? '',
      processingMethod ?? '',
      roastLevel ?? '',
      if (tastingNotes != null) tastingNotes!.join(' '),
      description ?? '',
    ];
    return parts.join(' ').toLowerCase();
  }

  @override
  Map<String, String> get categories {
    final cats = <String, String>{
      'roaster': roaster,
    };
    if (country != null && country!.isNotEmpty) cats['country'] = country!;
    if (region != null && region!.isNotEmpty) cats['region'] = region!;
    if (processingMethod != null && processingMethod!.isNotEmpty) {
      cats['processing_method'] = processingMethod!;
    }
    if (roastLevel != null && roastLevel!.isNotEmpty) {
      cats['roast_level'] = roastLevel!;
    }
    return cats;
  }

  @override
  List<DetailField> get detailFields => [
    DetailField(
      label: 'Roaster',
      value: roaster,
      icon: Icons.local_cafe,
    ),
    if (country != null && country!.isNotEmpty)
      DetailField(
        label: 'Country',
        value: country!,
        icon: Icons.public,
      ),
    if (region != null && region!.isNotEmpty)
      DetailField(
        label: 'Region',
        value: region!,
        icon: Icons.location_on,
      ),
    if (farm != null && farm!.isNotEmpty)
      DetailField(
        label: 'Farm',
        value: farm!,
        icon: Icons.agriculture,
      ),
    if (altitude != null && altitude!.isNotEmpty)
      DetailField(
        label: 'Altitude',
        value: altitude!,
        icon: Icons.terrain,
      ),
    if (species != null && species!.isNotEmpty)
      DetailField(
        label: 'Species',
        value: species!,
        icon: Icons.eco,
      ),
    if (variety != null && variety!.isNotEmpty)
      DetailField(
        label: 'Variety',
        value: variety!,
        icon: Icons.category,
      ),
    if (processingMethod != null && processingMethod!.isNotEmpty)
      DetailField(
        label: 'Processing',
        value: processingMethod!,
        icon: Icons.settings,
      ),
    if (decaffeinated)
      DetailField(
        label: 'Decaffeinated',
        value: 'Yes',
        icon: Icons.check_circle_outline,
      ),
    if (roastLevel != null && roastLevel!.isNotEmpty)
      DetailField(
        label: 'Roast Level',
        value: roastLevel!,
        icon: Icons.whatshot,
      ),
    if (tastingNotes != null && tastingNotes!.isNotEmpty)
      DetailField(
        label: 'Tasting Notes',
        value: tastingNotes!.join(', '),
        icon: Icons.local_bar,
      ),
    if (acidity != null && acidity!.isNotEmpty)
      DetailField(
        label: 'Acidity',
        value: acidity!,
        icon: Icons.water_drop,
      ),
    if (body != null && body!.isNotEmpty)
      DetailField(
        label: 'Body',
        value: body!,
        icon: Icons.fitness_center,
      ),
    if (sweetness != null && sweetness!.isNotEmpty)
      DetailField(
        label: 'Sweetness',
        value: sweetness!,
        icon: Icons.cake,
      ),
    if (organic)
      DetailField(
        label: 'Organic',
        value: 'Yes',
        icon: Icons.spa,
      ),
    if (fairTrade)
      DetailField(
        label: 'Fair Trade',
        value: 'Yes',
        icon: Icons.handshake,
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
      DetailField(
        label: context.l10n.roasterLabel,
        value: roaster,
        icon: Icons.local_cafe,
      ),
      if (country != null && country!.isNotEmpty)
        DetailField(
          label: context.l10n.countryLabel,
          value: country!,
          icon: Icons.public,
        ),
      if (region != null && region!.isNotEmpty)
        DetailField(
          label: context.l10n.regionLabel,
          value: region!,
          icon: Icons.location_on,
        ),
      if (farm != null && farm!.isNotEmpty)
        DetailField(
          label: context.l10n.farmLabel,
          value: farm!,
          icon: Icons.agriculture,
        ),
      if (altitude != null && altitude!.isNotEmpty)
        DetailField(
          label: context.l10n.altitudeLabel,
          value: altitude!,
          icon: Icons.terrain,
        ),
      if (species != null && species!.isNotEmpty)
        DetailField(
          label: context.l10n.speciesLabel,
          value: species!,
          icon: Icons.eco,
        ),
      if (variety != null && variety!.isNotEmpty)
        DetailField(
          label: context.l10n.varietyLabel,
          value: variety!,
          icon: Icons.category,
        ),
      if (processingMethod != null && processingMethod!.isNotEmpty)
        DetailField(
          label: context.l10n.processingMethodLabel,
          value: processingMethod!,
          icon: Icons.settings,
        ),
      if (decaffeinated)
        DetailField(
          label: context.l10n.decaffeinatedLabel,
          value: context.l10n.yes,
          icon: Icons.check_circle_outline,
        ),
      // roast_level is excluded - shown in badge
      if (tastingNotes != null && tastingNotes!.isNotEmpty)
        DetailField(
          label: context.l10n.tastingNotesLabel,
          value: tastingNotes!.join(', '),
          icon: Icons.local_bar,
        ),
      if (acidity != null && acidity!.isNotEmpty)
        DetailField(
          label: context.l10n.acidityLabel,
          value: acidity!,
          icon: Icons.water_drop,
        ),
      if (body != null && body!.isNotEmpty)
        DetailField(
          label: context.l10n.bodyLabel,
          value: body!,
          icon: Icons.fitness_center,
        ),
      if (sweetness != null && sweetness!.isNotEmpty)
        DetailField(
          label: context.l10n.sweetnessLabel,
          value: sweetness!,
          icon: Icons.cake,
        ),
      if (organic)
        DetailField(
          label: context.l10n.organicLabel,
          value: context.l10n.yes,
          icon: Icons.spa,
        ),
      if (fairTrade)
        DetailField(
          label: context.l10n.fairTradeLabel,
          value: context.l10n.yes,
          icon: Icons.handshake,
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
      'roaster': roaster,
      'country': country,
      'region': region,
      'farm': farm,
      'altitude': altitude,
      'species': species,
      'variety': variety,
      'processing_method': processingMethod,
      'decaffeinated': decaffeinated,
      'roast_level': roastLevel,
      'tasting_notes': tastingNotes,
      'acidity': acidity,
      'body': body,
      'sweetness': sweetness,
      'organic': organic,
      'fair_trade': fairTrade,
      'description': description,
      'image_url': imageUrl,
    };
  }

  /// Create from JSON
  factory CoffeeItem.fromJson(Map<String, dynamic> json) {
    // Handle tasting_notes - can be List or null
    List<String>? tastingNotesList;
    if (json['tasting_notes'] != null) {
      if (json['tasting_notes'] is List) {
        tastingNotesList = (json['tasting_notes'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return CoffeeItem(
      id: json['ID'] as int?,
      name: (json['name'] as String?) ?? '',
      roaster: (json['roaster'] as String?) ?? '',
      country: json['country'] as String?,
      region: json['region'] as String?,
      farm: json['farm'] as String?,
      altitude: json['altitude'] as String?,
      species: json['species'] as String?,
      variety: json['variety'] as String?,
      processingMethod: json['processing_method'] as String?,
      decaffeinated: (json['decaffeinated'] as bool?) ?? false,
      roastLevel: json['roast_level'] as String?,
      tastingNotes: tastingNotesList,
      acidity: json['acidity'] as String?,
      body: json['body'] as String?,
      sweetness: json['sweetness'] as String?,
      organic: (json['organic'] as bool?) ?? false,
      fairTrade: (json['fair_trade'] as bool?) ?? false,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  CoffeeItem copyWith(Map<String, dynamic> updates) {
    return CoffeeItem(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      roaster: updates['roaster'] ?? roaster,
      country: updates['country'] ?? country,
      region: updates['region'] ?? region,
      farm: updates['farm'] ?? farm,
      altitude: updates['altitude'] ?? altitude,
      species: updates['species'] ?? species,
      variety: updates['variety'] ?? variety,
      processingMethod: updates['processing_method'] ?? processingMethod,
      decaffeinated: updates['decaffeinated'] ?? decaffeinated,
      roastLevel: updates['roast_level'] ?? roastLevel,
      tastingNotes: updates['tasting_notes'] ?? tastingNotes,
      acidity: updates['acidity'] ?? acidity,
      body: updates['body'] ?? body,
      sweetness: updates['sweetness'] ?? sweetness,
      organic: updates['organic'] ?? organic,
      fairTrade: updates['fair_trade'] ?? fairTrade,
      description: updates['description'] ?? description,
      imageUrl: updates['image_url'] ?? imageUrl,
    );
  }

  // Coffee-specific methods
  CoffeeItem copyWithCoffee({
    int? id,
    String? name,
    String? roaster,
    String? country,
    String? region,
    String? farm,
    String? altitude,
    String? species,
    String? variety,
    String? processingMethod,
    bool? decaffeinated,
    String? roastLevel,
    List<String>? tastingNotes,
    String? acidity,
    String? body,
    String? sweetness,
    bool? organic,
    bool? fairTrade,
    String? description,
    String? imageUrl,
  }) {
    return CoffeeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      roaster: roaster ?? this.roaster,
      country: country ?? this.country,
      region: region ?? this.region,
      farm: farm ?? this.farm,
      altitude: altitude ?? this.altitude,
      species: species ?? this.species,
      variety: variety ?? this.variety,
      processingMethod: processingMethod ?? this.processingMethod,
      decaffeinated: decaffeinated ?? this.decaffeinated,
      roastLevel: roastLevel ?? this.roastLevel,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      acidity: acidity ?? this.acidity,
      body: body ?? this.body,
      sweetness: sweetness ?? this.sweetness,
      organic: organic ?? this.organic,
      fairTrade: fairTrade ?? this.fairTrade,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoffeeItem &&
        other.id == id &&
        other.name == name &&
        other.roaster == roaster &&
        other.country == country &&
        other.region == region &&
        other.farm == farm &&
        other.altitude == altitude &&
        other.species == species &&
        other.variety == variety &&
        other.processingMethod == processingMethod &&
        other.decaffeinated == decaffeinated &&
        other.roastLevel == roastLevel &&
        _listEquals(other.tastingNotes, tastingNotes) &&
        other.acidity == acidity &&
        other.body == body &&
        other.sweetness == sweetness &&
        other.organic == organic &&
        other.fairTrade == fairTrade &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      roaster,
      country,
      region,
      farm,
      altitude,
      species,
      variety,
      processingMethod,
      decaffeinated,
      roastLevel,
      Object.hashAll(tastingNotes ?? []),
      acidity,
      body,
      sweetness,
      organic,
      fairTrade,
      description,
      imageUrl,
    );
  }

  @override
  String toString() {
    return 'CoffeeItem(id: $id, name: $name, roaster: $roaster, country: $country, processingMethod: $processingMethod, roastLevel: $roastLevel)';
  }
}

/// Extension for CoffeeItem convenience methods
extension CoffeeItemExtension on CoffeeItem {
  /// Get all unique roasters from a list of coffee items
  static List<String> getUniqueRoasters(List<CoffeeItem> coffees) {
    return coffees.map((c) => c.roaster).toSet().toList()..sort();
  }

  /// Get all unique countries from a list of coffee items
  static List<String> getUniqueCountries(List<CoffeeItem> coffees) {
    return coffees
        .where((c) => c.country != null && c.country!.isNotEmpty)
        .map((c) => c.country!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get all unique regions from a list of coffee items
  static List<String> getUniqueRegions(List<CoffeeItem> coffees) {
    return coffees
        .where((c) => c.region != null && c.region!.isNotEmpty)
        .map((c) => c.region!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get all unique processing methods from a list of coffee items
  static List<String> getUniqueProcessingMethods(List<CoffeeItem> coffees) {
    return coffees
        .where((c) => c.processingMethod != null && c.processingMethod!.isNotEmpty)
        .map((c) => c.processingMethod!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get all unique roast levels from a list of coffee items
  static List<String> getUniqueRoastLevels(List<CoffeeItem> coffees) {
    return coffees
        .where((c) => c.roastLevel != null && c.roastLevel!.isNotEmpty)
        .map((c) => c.roastLevel!)
        .toSet()
        .toList()
      ..sort();
  }
}
