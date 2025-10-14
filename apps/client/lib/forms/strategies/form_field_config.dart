import 'package:flutter/material.dart';

/// Types of form fields supported by the form system
enum FormFieldType {
  text,
  multiline,
  dropdown,
  checkbox,
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
  
  /// Options for dropdown fields
  final List<DropdownOption>? options;
  
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
    this.options,
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

  /// Factory constructor for dropdown fields
  factory FormFieldConfig.dropdown({
    required String key,
    required String Function(BuildContext) labelBuilder,
    required String Function(BuildContext) hintBuilder,
    required List<DropdownOption> options,
    String Function(BuildContext)? helperTextBuilder,
    IconData? icon,
    bool required = false,
  }) {
    return FormFieldConfig(
      key: key,
      type: FormFieldType.dropdown,
      labelBuilder: labelBuilder,
      hintBuilder: hintBuilder,
      helperTextBuilder: helperTextBuilder,
      icon: icon,
      required: required,
      options: options,
    );
  }

  /// Factory constructor for checkbox fields
  factory FormFieldConfig.checkbox({
    required String key,
    required String Function(BuildContext) labelBuilder,
    String Function(BuildContext)? helperTextBuilder,
  }) {
    return FormFieldConfig(
      key: key,
      type: FormFieldType.checkbox,
      labelBuilder: labelBuilder,
      hintBuilder: (_) => '', // Checkbox doesn't need hint
      helperTextBuilder: helperTextBuilder,
    );
  }

  /// Get localized label for this field
  String getLabel(BuildContext context) => labelBuilder(context);
  
  /// Get localized hint text for this field
  String getHint(BuildContext context) => hintBuilder(context);
  
  /// Get localized helper text for this field (optional)
  String? getHelperText(BuildContext context) => helperTextBuilder?.call(context);
}

/// Dropdown option for dropdown fields with localization support
class DropdownOption {
  final String value;
  final String Function(BuildContext) labelBuilder;

  const DropdownOption({
    required this.value,
    required this.labelBuilder,
  });

  /// Get the localized label
  String getLabel(BuildContext context) => labelBuilder(context);
}
