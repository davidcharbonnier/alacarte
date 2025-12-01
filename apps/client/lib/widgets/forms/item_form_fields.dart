import 'package:flutter/material.dart';
import '../../utils/localization_utils.dart';

/// Generic dropdown field for selecting item types
class ItemTypeDropdownField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final String labelText;
  final String? hintText;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final bool enabled;

  const ItemTypeDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.labelText,
    this.hintText,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the current value is in the options list, or set to null
    final safeValue = (value != null && options.contains(value)) ? value : null;
    
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText ?? context.l10n.selectType,
        errorText: errorText,
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorText ?? context.l10n.typeRequired;
        }
        return null;
      },
    );
  }
}

/// Generic text field for item properties
class ItemPropertyField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool required;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const ItemPropertyField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$labelText *' : labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        border: const OutlineInputBorder(),
        enabled: enabled,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return errorText ?? '$labelText is required';
        }
        return null;
      } : null,
    );
  }
}

/// Specialized field for item names with proper validation
class ItemNameField extends StatelessWidget {
  final TextEditingController controller;
  final String itemType;
  final String? errorText;
  final bool enabled;

  const ItemNameField({
    super.key,
    required this.controller,
    required this.itemType,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '${context.l10n.name} *',
        hintText: context.l10n.enterItemName(itemType.toLowerCase()),
        errorText: errorText,
        border: const OutlineInputBorder(),
        enabled: enabled,
        prefixIcon: const Icon(Icons.label),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.l10n.itemNameRequired(itemType);
        }
        if (value.trim().length < 2) {
          return context.l10n.itemNameTooShort(itemType);
        }
        if (value.trim().length > 100) {
          return context.l10n.itemNameTooLong(itemType);
        }
        return null;
      },
    );
  }
}

/// Specialized field for descriptions with character count
class ItemDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  static const int maxLength = 500;

  const ItemDescriptionField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: context.l10n.description,
        hintText: context.l10n.enterDescription,
        errorText: errorText,
        border: const OutlineInputBorder(),
        enabled: enabled,
        prefixIcon: const Icon(Icons.description),
        helperText: context.l10n.optionalFieldHelper(maxLength),
      ),
      maxLines: 3,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value != null && value.length > maxLength) {
          return context.l10n.descriptionTooLong;
        }
        return null;
      },
    );
  }
}

/// Pre-configured form fields specifically for cheese items
class CheeseTypeField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;

  const CheeseTypeField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ItemPropertyField(
      controller: controller,
      labelText: context.l10n.type,
      hintText: context.l10n.cheeseTypeHint,
      required: true,
      enabled: enabled,
      prefixIcon: Icons.category,
    );
  }
}
