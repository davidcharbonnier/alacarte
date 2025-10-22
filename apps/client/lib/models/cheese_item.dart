import 'package:flutter/material.dart';
import 'rateable_item.dart';
import '../utils/localization_utils.dart';

/// CheeseItem - implements RateableItem interface for cheese-specific functionality
class CheeseItem implements RateableItem {
  @override
  final int? id;
  @override
  final String name;
  final String type;
  final String? origin;
  final String? producer;
  final String? description;
  final String? imageUrl;

  const CheeseItem({
    this.id,
    required this.name,
    required this.type,
    this.origin,
    this.producer,
    this.description,
    this.imageUrl,
  });

  @override
  String get itemType => 'cheese';

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle {
    final parts = <String>[];
    if (producer != null && producer!.isNotEmpty) parts.add(producer!);
    if (origin != null && origin!.isNotEmpty) parts.add(origin!);
    return parts.isNotEmpty ? parts.join(' • ') : type;
  }

  @override
  bool get isNew => id == null;

  @override
  String get searchableText => 
    '$name $type ${origin ?? ''} ${producer ?? ''} ${description ?? ''}'.toLowerCase();

  @override
  Map<String, String> get categories {
    final cats = <String, String>{
      'type': type,
    };
    if (origin != null && origin!.isNotEmpty) cats['origin'] = origin!;
    if (producer != null && producer!.isNotEmpty) cats['producer'] = producer!;
    return cats;
  }

  @override
  List<DetailField> get detailFields => [
    if (origin != null && origin!.isNotEmpty)
      DetailField(
        label: 'Origin',
        value: origin!,
        icon: Icons.public,
      ),
    if (producer != null && producer!.isNotEmpty)
      DetailField(
        label: 'Producer', 
        value: producer!,
        icon: Icons.business,
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
      if (origin != null && origin!.isNotEmpty)
        DetailField(
          label: context.l10n.originLabel,
          value: origin!,
          icon: Icons.public,
        ),
      if (producer != null && producer!.isNotEmpty)
        DetailField(
          label: context.l10n.producerLabel, 
          value: producer!,
          icon: Icons.business,
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
      'name': name, // Changed from 'Name' to 'name'
      'type': type,
      'origin': origin,
      'producer': producer,
      'description': description,
      'image_url': imageUrl,
    };
  }

  /// Create from JSON
  factory CheeseItem.fromJson(Map<String, dynamic> json) {
    return CheeseItem(
      id: json['ID'] as int?,
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      origin: json['origin'] as String?,
      producer: json['producer'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  @override
  CheeseItem copyWith(Map<String, dynamic> updates) {
    return CheeseItem(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      type: updates['type'] ?? type,
      origin: updates['origin'] ?? origin,
      producer: updates['producer'] ?? producer,
      description: updates['description'] ?? description,
      imageUrl: updates['image_url'] ?? imageUrl,
    );
  }

  // Cheese-specific methods
  CheeseItem copyWithCheese({
    int? id,
    String? name,
    String? type,
    String? origin,
    String? producer,
    String? description,
    String? imageUrl,
  }) {
    return CheeseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      origin: origin ?? this.origin,
      producer: producer ?? this.producer,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheeseItem &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.origin == origin &&
        other.producer == producer &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, origin, producer, description, imageUrl);
  }

  @override
  String toString() {
    return 'CheeseItem(id: $id, name: $name, type: $type, origin: $origin, producer: $producer, description: $description, imageUrl: $imageUrl)';
  }
}

/// Extension for CheeseItem convenience methods
extension CheeseItemExtension on CheeseItem {
  /// Get all unique types from a list of cheese items
  static List<String> getUniqueTypes(List<CheeseItem> cheeses) {
    return cheeses.map((c) => c.type).toSet().toList()..sort();
  }
  
  /// Get all unique origins from a list of cheese items
  static List<String> getUniqueOrigins(List<CheeseItem> cheeses) {
    return cheeses
        .where((c) => c.origin != null && c.origin!.isNotEmpty)
        .map((c) => c.origin!)
        .toSet()
        .toList()
      ..sort();
  }
  
  /// Get all unique producers from a list of cheese items
  static List<String> getUniqueProducers(List<CheeseItem> cheeses) {
    return cheeses
        .where((c) => c.producer != null && c.producer!.isNotEmpty)
        .map((c) => c.producer!)
        .toSet()
        .toList()
      ..sort();
  }
}
