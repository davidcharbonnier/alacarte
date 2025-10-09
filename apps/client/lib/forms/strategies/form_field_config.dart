import 'package:flutter/material.dart';

/// Types of form fields supported by the form system
enum FormFieldType {
  text,
  multiline,
}

/// Configuration for a single form field with localization support
class FormFieldConfig {
  /// Unique key for this field (used for controller map)
  final String key;
  
  /// Type of field to render
  final FormFieldType type;
  
  /// Icon to display with the field
  final IconData? icon;
  
  /// Whether this field is required
  final bool required;
  
  /// Maximum number of lines for text input
  final int? maxLines;
  
  /// Maximum character length
  final int? maxLength;
  
  /// Localization: Function that returns localized label
  final String Function(BuildContext) labelBuilder;
  
  /// Localization: Function that returns localized hint text
  final String Function(BuildContext) hintBuilder;
  
  /// Localization: Optional function that returns localized helper text
  final String Function(BuildContext)? helperTextBuilder;

  const FormFieldConfig({
    required this.key,
    required this.type,
    required this.labelBuilder,
    required this.hintBuilder,
    this.helperTextBuilder,
    this.icon,
    this.required = false,
    this.maxLines = 1,
    this.maxLength,
  });

  /// Factory constructor for standard text fields
  factory FormFieldConfig.text({
    required String key,
    required String Function(BuildContext) labelBuilder,
    required String Function(BuildContext) hintBuilder,
    String Function(BuildContext)? helperTextBuilder,
    IconData? icon,
    bool required = false,
  }) {
    return FormFieldConfig(
      key: key,
      type: FormFieldType.text,
      labelBuilder: labelBuilder,
      hintBuilder: hintBuilder,
      helperTextBuilder: helperTextBuilder,
      icon: icon,
      required: required,
      maxLines: 1,
    );
  }

  /// Factory constructor for multiline text fields
  factory FormFieldConfig.multiline({
    required String key,
    required String Function(BuildContext) labelBuilder,
    required String Function(BuildContext) hintBuilder,
    String Function(BuildContext)? helperTextBuilder,
    int maxLines = 3,
    int? maxLength,
  }) {
    return FormFieldConfig(
      key: key,
      type: FormFieldType.multiline,
      labelBuilder: labelBuilder,
      hintBuilder: hintBuilder,
      helperTextBuilder: helperTextBuilder,
      maxLines: maxLines,
      maxLength: maxLength,
    );
  }

  /// Get localized label for this field
  String getLabel(BuildContext context) => labelBuilder(context);
  
  /// Get localized hint text for this field
  String getHint(BuildContext context) => hintBuilder(context);
  
  /// Get localized helper text for this field (optional)
  String? getHelperText(BuildContext context) => helperTextBuilder?.call(context);
}
