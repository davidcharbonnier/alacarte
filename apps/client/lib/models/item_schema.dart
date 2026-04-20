import 'schema_field.dart';

class ItemSchema {
  final int id;
  final String name;
  final String displayName;
  final String pluralName;
  final String icon;
  final String color;
  final bool isActive;
  final List<String>? uniqueFields;
  final List<SchemaField> fields;

  const ItemSchema({
    required this.id,
    required this.name,
    required this.displayName,
    required this.pluralName,
    required this.icon,
    required this.color,
    required this.isActive,
    this.uniqueFields,
    this.fields = const [],
  });

  factory ItemSchema.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List<dynamic>?;
    final uniqueFieldsJson = json['unique_fields'];

    return ItemSchema(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      displayName:
          (json['display_name'] as String?) ??
          json['displayName'] as String? ??
          '',
      pluralName:
          (json['plural_name'] as String?) ??
          json['pluralName'] as String? ??
          '',
      icon: _coerceString(json['icon']),
      color: _coerceString(json['color']),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      uniqueFields: uniqueFieldsJson != null
          ? List<String>.from(uniqueFieldsJson as List)
          : null,
      fields:
          fieldsJson
              ?.map((f) => SchemaField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String _coerceString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'plural_name': pluralName,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'unique_fields': uniqueFields,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  SchemaField? getField(String key) {
    try {
      return fields.firstWhere((f) => f.key == key);
    } catch (_) {
      return null;
    }
  }

  List<SchemaField> get sortedFields {
    final sorted = List<SchemaField>.from(fields);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  List<SchemaField> get visibleFields {
    return sortedFields.where((f) => f.isVisible).toList();
  }

  SchemaField? get primaryField {
    try {
      return sortedFields.firstWhere((f) => f.isPrimary);
    } catch (_) {
      return sortedFields.isNotEmpty ? sortedFields.first : null;
    }
  }

  SchemaField? get secondaryField {
    final sorted = sortedFields;
    if (sorted.length < 2) return null;
    try {
      return sorted.firstWhere((f) => f.isSecondary);
    } catch (_) {
      return sorted.length > 1 ? sorted[1] : null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSchema && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ItemSchema(id: $id, name: $name, displayName: $displayName, fields: ${fields.length})';
}
