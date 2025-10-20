import 'package:flutter/material.dart';
import 'rateable_item.dart';
import 'wine_color.dart';
import '../utils/localization_utils.dart';

class WineItem implements RateableItem {
  final int? id;
  final String name;
  final String producer;
  final String country;
  final String region;
  final WineColor color;
  final String grape;
  final double alcohol;
  final String description;
  final String designation;
  final double sugar;
  final bool organic;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WineItem({
    this.id,
    required this.name,
    required this.producer,
    required this.country,
    required this.region,
    required this.color,
    required this.grape,
    required this.alcohol,
    required this.description,
    required this.designation,
    required this.sugar,
    required this.organic,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String get itemType => 'wine';

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle {
    final parts = <String>[];
    parts.add(color.value);
    if (producer.isNotEmpty) parts.add(producer);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(' • ');
  }

  @override
  bool get isNew => id == null;

  @override
  String get searchableText =>
      '$name $producer $country $region ${color.value} $grape $designation'.toLowerCase();

  @override
  Map<String, String> get categories => {
        'color': color.value,
        'country': country,
        'producer': producer.isNotEmpty ? producer : 'Unknown',
        'region': region.isNotEmpty ? region : 'Unknown',
      };

  @override
  List<DetailField> get detailFields => [
        DetailField(
          label: 'Country',
          value: country,
          icon: Icons.public,
        ),
        if (producer.isNotEmpty)
          DetailField(
            label: 'Producer',
            value: producer,
            icon: Icons.business,
          ),
        if (region.isNotEmpty)
          DetailField(
            label: 'Region',
            value: region,
            icon: Icons.location_on,
          ),
        if (grape.isNotEmpty)
          DetailField(
            label: 'Grape Varieties',
            value: grape,
            icon: Icons.nature,
          ),
        if (designation.isNotEmpty)
          DetailField(
            label: 'Designation',
            value: designation,
            icon: Icons.verified,
          ),
        if (alcohol > 0)
          DetailField(
            label: 'Alcohol',
            value: '${alcohol}%',
            icon: Icons.percent,
          ),
        if (sugar > 0)
          DetailField(
            label: 'Sugar',
            value: '${sugar} g/L',
            icon: Icons.bubble_chart,
          ),
        if (organic)
          DetailField(
            label: 'Organic',
            value: 'Yes',
            icon: Icons.eco,
          ),
        if (description.isNotEmpty)
          DetailField(
            label: 'Description',
            value: description,
            isDescription: true,
          ),
      ];

  /// Get localized detail fields for display
  List<DetailField> getLocalizedDetailFields(BuildContext context) {
    return [
      DetailField(
        label: context.l10n.country,
        value: country,
        icon: Icons.public,
      ),
      if (producer.isNotEmpty)
        DetailField(
          label: context.l10n.producer,
          value: producer,
          icon: Icons.business,
        ),
      if (region.isNotEmpty)
        DetailField(
          label: context.l10n.region,
          value: region,
          icon: Icons.location_on,
        ),
      if (grape.isNotEmpty)
        DetailField(
          label: context.l10n.grapeLabel,
          value: grape,
          icon: Icons.nature,
        ),
      if (designation.isNotEmpty)
        DetailField(
          label: context.l10n.designationLabel,
          value: designation,
          icon: Icons.verified,
        ),
      if (alcohol > 0)
        DetailField(
          label: context.l10n.alcoholLabel,
          value: '${alcohol}%',
          icon: Icons.percent,
        ),
      if (sugar > 0)
        DetailField(
          label: context.l10n.sugarLabel,
          value: '${sugar} g/L',
          icon: Icons.bubble_chart,
        ),
      DetailField(
        label: context.l10n.organicLabel,
        value: organic ? context.l10n.yes : context.l10n.no,
        icon: Icons.eco,
      ),
      if (description.isNotEmpty)
        DetailField(
          label: context.l10n.description,
          value: description,
          isDescription: true,
        ),
    ];
  }

  factory WineItem.fromJson(Map<String, dynamic> json) {
    return WineItem(
      id: json['ID'] as int?,
      name: json['name'] as String? ?? '',
      producer: json['producer'] as String? ?? '',
      country: json['country'] as String? ?? '',
      region: json['region'] as String? ?? '',
      color: WineColor.fromString(json['color'] as String?) ?? WineColor.rouge,
      grape: json['grape'] as String? ?? '',
      alcohol: (json['alcohol'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      organic: json['organic'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'producer': producer,
      'country': country,
      'region': region,
      'color': color.value,
      'grape': grape,
      'alcohol': alcohol,
      'description': description,
      'designation': designation,
      'sugar': sugar,
      'organic': organic,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  WineItem copyWith(Map<String, dynamic> updates) {
    return WineItem(
      id: updates['id'] as int? ?? id,
      name: updates['name'] as String? ?? name,
      producer: updates['producer'] as String? ?? producer,
      country: updates['country'] as String? ?? country,
      region: updates['region'] as String? ?? region,
      color: updates['color'] is WineColor 
          ? updates['color'] as WineColor
          : (updates['color'] is String 
              ? WineColor.fromString(updates['color'] as String) ?? color
              : color),
      grape: updates['grape'] as String? ?? grape,
      alcohol: updates['alcohol'] as double? ?? alcohol,
      description: updates['description'] as String? ?? description,
      designation: updates['designation'] as String? ?? designation,
      sugar: updates['sugar'] as double? ?? sugar,
      organic: updates['organic'] as bool? ?? organic,
      imageUrl: updates['image_url'] as String? ?? imageUrl,
      createdAt: updates['created_at'] as DateTime? ?? createdAt,
      updatedAt: updates['updated_at'] as DateTime? ?? updatedAt,
    );
  }
}
