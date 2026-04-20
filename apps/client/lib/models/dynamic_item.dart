import 'package:flutter/material.dart';
import 'item_schema.dart';
import 'rateable_item.dart';
import 'schema_field.dart';

class DynamicItem implements RateableItem {
  @override
  final int? id;
  @override
  final String name;
  final String schemaName;
  final String? description;
  final String? imageUrl;
  final int? userId;
  final Map<String, dynamic> fieldValues;
  final ItemSchema? schema;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DynamicItem({
    this.id,
    required this.name,
    required this.schemaName,
    this.description,
    this.imageUrl,
    this.userId,
    this.fieldValues = const {},
    this.schema,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String get itemType => schemaName;

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle {
    if (schema == null) return schemaName;

    final secondary = schema!.secondaryField;
    if (secondary != null) {
      final value = fieldValues[secondary.key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    final primary = schema!.primaryField;
    if (primary != null && primary.key != 'name') {
      final value = fieldValues[primary.key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return schema!.displayName;
  }

  @override
  bool get isNew => id == null;

  @override
  String get searchableText {
    final buffer = StringBuffer(name);
    if (description != null) buffer.write(' $description');
    for (final value in fieldValues.values) {
      if (value != null) buffer.write(' $value');
    }
    return buffer.toString().toLowerCase();
  }

  @override
  Map<String, String> get categories {
    final cats = <String, String>{};
    for (final field in schema?.fields ?? []) {
      if (field.fieldType == SchemaFieldType.select ||
          field.fieldType == SchemaFieldType.enum_) {
        final value = fieldValues[field.key];
        if (value != null) {
          cats[field.key] = value.toString();
        }
      }
    }
    return cats;
  }

  @override
  List<DetailField> get detailFields {
    if (schema == null) {
      if (description != null && description!.isNotEmpty) {
        return [
          DetailField(
            label: 'Description',
            value: description!,
            isDescription: true,
          ),
        ];
      }
      return [];
    }

    final fields = <DetailField>[];
    for (final field in schema!.visibleFields) {
      final value = fieldValues[field.key];
      if (value == null || (value is String && value.isEmpty)) continue;

      if (field.key == 'description' || field.display?.isVisible == false) {
        continue;
      }

      fields.add(
        DetailField(
          label: field.label,
          value: value.toString(),
          icon: _getIconForFieldType(field.fieldType),
        ),
      );
    }

    if (description != null && description!.isNotEmpty) {
      fields.add(
        DetailField(
          label: 'Description',
          value: description!,
          isDescription: true,
        ),
      );
    }

    return fields;
  }

  IconData? _getIconForFieldType(SchemaFieldType type) {
    switch (type) {
      case SchemaFieldType.text:
      case SchemaFieldType.textarea:
        return Icons.text_fields;
      case SchemaFieldType.number:
        return Icons.numbers;
      case SchemaFieldType.select:
      case SchemaFieldType.enum_:
        return Icons.list;
      case SchemaFieldType.checkbox:
        return Icons.check_box;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'schema_name': schemaName,
      'description': description,
      'image_url': imageUrl,
      'field_values': fieldValues,
    };
  }

  factory DynamicItem.fromJson(
    Map<String, dynamic> json, {
    ItemSchema? schema,
  }) {
    final fieldValuesJson = json['field_values'] as Map<String, dynamic>?;
    final schemaName =
        json['schema_name'] as String? ??
        json['schema_type'] as String? ??
        json['type'] as String? ??
        '';

    return DynamicItem(
      id: json['id'] as int?,
      name: (json['name'] as String?) ?? '',
      schemaName: schemaName,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      userId: json['user_id'] as int?,
      fieldValues: fieldValuesJson ?? {},
      schema: schema,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  DynamicItem copyWith(Map<String, dynamic> updates) {
    return DynamicItem(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      schemaName: updates['schema_name'] ?? schemaName,
      description: updates['description'] ?? description,
      imageUrl: updates['image_url'] ?? imageUrl,
      userId: updates['user_id'] ?? userId,
      fieldValues: updates['field_values'] ?? fieldValues,
      schema: schema,
    );
  }

  DynamicItem withSchema(ItemSchema? newSchema) {
    return DynamicItem(
      id: id,
      name: name,
      schemaName: schemaName,
      description: description,
      imageUrl: imageUrl,
      userId: userId,
      fieldValues: fieldValues,
      schema: newSchema,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  T? getFieldValue<T>(String key) {
    final value = fieldValues[key];
    if (value == null) return null;
    if (value is T) return value;
    try {
      return value as T;
    } catch (_) {
      return null;
    }
  }

  String? getFieldDisplayValue(String key) {
    final value = fieldValues[key];
    if (value == null) return null;

    if (schema != null) {
      final field = schema!.getField(key);
      if (field != null &&
          (field.fieldType == SchemaFieldType.select ||
              field.fieldType == SchemaFieldType.enum_)) {
        return value.toString();
      }
    }

    return value.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schemaName == other.schemaName;

  @override
  int get hashCode => Object.hash(id, schemaName);

  @override
  String toString() =>
      'DynamicItem(id: $id, name: $name, schemaName: $schemaName, fieldValues: $fieldValues)';
}
