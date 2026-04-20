import 'validation_rule.dart';
import 'display_hint.dart';

enum SchemaFieldType {
  text,
  textarea,
  number,
  select,
  checkbox,
  enum_;

  static SchemaFieldType fromString(String value) {
    switch (value) {
      case 'text':
        return SchemaFieldType.text;
      case 'textarea':
        return SchemaFieldType.textarea;
      case 'number':
        return SchemaFieldType.number;
      case 'select':
        return SchemaFieldType.select;
      case 'checkbox':
        return SchemaFieldType.checkbox;
      case 'enum':
        return SchemaFieldType.enum_;
      default:
        return SchemaFieldType.text;
    }
  }

  String toJson() => name;
}

class SchemaField {
  final int id;
  final int schemaId;
  final String key;
  final String label;
  final SchemaFieldType fieldType;
  final bool required;
  final int order;
  final String? group;
  final ValidationRule? validation;
  final DisplayHint? display;
  final List<String>? options;

  const SchemaField({
    required this.id,
    required this.schemaId,
    required this.key,
    required this.label,
    required this.fieldType,
    required this.required,
    required this.order,
    this.group,
    this.validation,
    this.display,
    this.options,
  });

  factory SchemaField.fromJson(Map<String, dynamic> json) {
    final validationJson = json['validation'];
    final displayJson = json['display'];
    final optionsJson = json['options'];

    List<String>? parsedOptions;
    if (optionsJson != null && optionsJson is List) {
      if (optionsJson.isNotEmpty) {
        final first = optionsJson.first;
        if (first is String) {
          parsedOptions = List<String>.from(optionsJson);
        } else if (first is Map) {
          parsedOptions = optionsJson.map((opt) {
            if (opt is Map) {
              return opt['value']?.toString() ?? opt['label']?.toString() ?? '';
            }
            return opt.toString();
          }).toList();
        }
      }
    }

    return SchemaField(
      id: json['id'] as int? ?? 0,
      schemaId: json['schema_id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      fieldType: SchemaFieldType.fromString(
        json['field_type'] as String? ?? 'text',
      ),
      required: json['required'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      group: json['group'] as String?,
      validation: validationJson != null && validationJson is Map
          ? ValidationRule.fromJson(validationJson as Map<String, dynamic>)
          : null,
      display: displayJson != null && displayJson is Map
          ? DisplayHint.fromJson(displayJson as Map<String, dynamic>)
          : null,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schema_id': schemaId,
      'key': key,
      'label': label,
      'field_type': fieldType.toJson(),
      'required': required,
      'order': order,
      'group': group,
      'validation': validation?.toJson(),
      'display': display?.toJson(),
      'options': options,
    };
  }

  bool get isPrimary => display?.isPrimary ?? false;
  bool get isSecondary => display?.isSecondary ?? false;
  bool get isVisible => display?.isVisible ?? true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaField &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SchemaField(id: $id, key: $key, label: $label, type: $fieldType)';
}
