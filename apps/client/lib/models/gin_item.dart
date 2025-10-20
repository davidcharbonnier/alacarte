import 'package:flutter/material.dart';
import 'rateable_item.dart';
import '../utils/localization_utils.dart';

/// GinItem - implements RateableItem interface for gin-specific functionality
class GinItem implements RateableItem {
  @override
  final int? id;
  @override
  final String name;
  final String producer;
  final String origin;
  final String profile;
  final String? description;
  final String? imageUrl;

  const GinItem({
    this.id,
    required this.name,
    required this.producer,
    required this.origin,
    required this.profile,
    this.description,
    this.imageUrl,
  });

  @override
  String get itemType => 'gin';

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle => '$producer • $origin';

  @override
  bool get isNew => id == null;

  @override
  String get searchableText => 
    '$name $producer $origin $profile ${description ?? ''}'.toLowerCase();

  @override
  Map<String, String> get categories => {
    'producer': producer,
    'origin': origin,
    'profile': profile,
  };

  @override
  List<DetailField> get detailFields => [
    DetailField(
      label: 'Producer',
      value: producer,
      icon: Icons.business,
    ),
    DetailField(
      label: 'Origin', 
      value: origin,
      icon: Icons.location_on,
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
        label: context.l10n.producerLabel,
        value: producer,
        icon: Icons.business,
      ),
      DetailField(
        label: context.l10n.originLabel,
        value: origin,
        icon: Icons.location_on,
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
      'producer': producer,
      'origin': origin,
      'profile': profile,
      'description': description,
      'image_url': imageUrl,
    };
  }

  /// Create from JSON
  factory GinItem.fromJson(Map<String, dynamic> json) {
    return GinItem(
      id: json['ID'] as int?,
      name: (json['name'] as String?) ?? '',
      producer: (json['producer'] as String?) ?? '',
      origin: (json['origin'] as String?) ?? '',
      profile: (json['profile'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  GinItem copyWith(Map<String, dynamic> updates) {
    return GinItem(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      producer: updates['producer'] ?? producer,
      origin: updates['origin'] ?? origin,
      profile: updates['profile'] ?? profile,
      description: updates['description'] ?? description,
      imageUrl: updates['image_url'] ?? imageUrl,
    );
  }

  // Gin-specific methods
  GinItem copyWithGin({
    int? id,
    String? name,
    String? producer,
    String? origin,
    String? profile,
    String? description,
    String? imageUrl,
  }) {
    return GinItem(
      id: id ?? this.id,
      name: name ?? this.name,
      producer: producer ?? this.producer,
      origin: origin ?? this.origin,
      profile: profile ?? this.profile,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GinItem &&
        other.id == id &&
        other.name == name &&
        other.producer == producer &&
        other.origin == origin &&
        other.profile == profile &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, producer, origin, profile, description, imageUrl);
  }

  @override
  String toString() {
    return 'GinItem(id: $id, name: $name, producer: $producer, origin: $origin, profile: $profile, description: $description, imageUrl: $imageUrl)';
  }
}

/// Extension for GinItem convenience methods
extension GinItemExtension on GinItem {
  /// Get all unique producers from a list of gin items
  static List<String> getUniqueProducers(List<GinItem> gins) {
    return gins.map((g) => g.producer).toSet().toList()..sort();
  }
  
  /// Get all unique origins from a list of gin items
  static List<String> getUniqueOrigins(List<GinItem> gins) {
    return gins.map((g) => g.origin).toSet().toList()..sort();
  }
  
  /// Get all unique profiles from a list of gin items
  static List<String> getUniqueProfiles(List<GinItem> gins) {
    return gins.map((g) => g.profile).toSet().toList()..sort();
  }
}
