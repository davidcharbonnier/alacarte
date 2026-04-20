import 'package:flutter/material.dart';
import '../../models/schema_field.dart';

class DynamicFieldRenderer extends StatelessWidget {
  final SchemaField field;
  final dynamic value;
  final bool showLabel;

  const DynamicFieldRenderer({
    super.key,
    required this.field,
    required this.value,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.fieldType) {
      case SchemaFieldType.text:
        return _buildTextValue(value, showLabel ? field.label : null);
      case SchemaFieldType.textarea:
        return _buildTextareaValue(value, showLabel ? field.label : null);
      case SchemaFieldType.number:
        return _buildNumberValue(value, showLabel ? field.label : null);
      case SchemaFieldType.select:
        return _buildSelectValue(value, showLabel ? field.label : null);
      case SchemaFieldType.enum_:
        return _buildEnumValue(value, showLabel ? field.label : null);
      case SchemaFieldType.checkbox:
        return _buildCheckboxValue(value, showLabel ? field.label : null);
    }
  }

  Widget _buildTextValue(dynamic value, String? label) {
    final displayValue = value?.toString() ?? '';
    if (displayValue.isEmpty) return const SizedBox.shrink();

    if (label != null) {
      return _FieldWithLabel(label: label, child: Text(displayValue));
    }
    return Text(displayValue);
  }

  Widget _buildTextareaValue(dynamic value, String? label) {
    final displayValue = value?.toString() ?? '';
    if (displayValue.isEmpty) return const SizedBox.shrink();

    if (label != null) {
      return _FieldWithLabel(
        label: label,
        child: Text(
          displayValue,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    return Text(
      displayValue,
      style: const TextStyle(fontStyle: FontStyle.italic),
    );
  }

  Widget _buildNumberValue(dynamic value, String? label) {
    final displayValue = value?.toString() ?? '';
    if (displayValue.isEmpty) return const SizedBox.shrink();

    if (label != null) {
      return _FieldWithLabel(label: label, child: Text(displayValue));
    }
    return Text(displayValue);
  }

  Widget _buildSelectValue(dynamic value, String? label) {
    final displayValue = value?.toString() ?? '';
    if (displayValue.isEmpty) return const SizedBox.shrink();

    if (label != null) {
      return _FieldWithLabel(
        label: label,
        child: Chip(
          label: Text(displayValue),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    return Chip(
      label: Text(displayValue),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEnumValue(dynamic value, String? label) {
    return _buildSelectValue(value, label);
  }

  Widget _buildCheckboxValue(dynamic value, String? label) {
    final isChecked = value == true;

    if (label != null) {
      return _FieldWithLabel(
        label: label,
        child: Icon(
          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
          color: isChecked ? Colors.green : Colors.grey,
        ),
      );
    }
    return Icon(
      isChecked ? Icons.check_box : Icons.check_box_outline_blank,
      color: isChecked ? Colors.green : Colors.grey,
    );
  }
}

class _FieldWithLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldWithLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DynamicFieldEditRenderer extends StatefulWidget {
  final SchemaField field;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;
  final bool enabled;

  const DynamicFieldEditRenderer({
    super.key,
    required this.field,
    this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<DynamicFieldEditRenderer> createState() =>
      _DynamicFieldEditRendererState();
}

class _DynamicFieldEditRendererState extends State<DynamicFieldEditRenderer> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.field.fieldType) {
      case SchemaFieldType.text:
        return _buildTextField();
      case SchemaFieldType.textarea:
        return _buildTextareaField();
      case SchemaFieldType.number:
        return _buildNumberField();
      case SchemaFieldType.select:
        return _buildSelectField();
      case SchemaFieldType.enum_:
        return _buildEnumField();
      case SchemaFieldType.checkbox:
        return _buildCheckboxField();
    }
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.field.label,
        border: const OutlineInputBorder(),
        hintText: widget.field.display?.placeholder,
      ),
      enabled: widget.enabled,
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildTextareaField() {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.field.label,
        border: const OutlineInputBorder(),
        hintText: widget.field.display?.placeholder,
      ),
      enabled: widget.enabled,
      maxLines: 4,
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.field.label,
        border: const OutlineInputBorder(),
        hintText: widget.field.display?.placeholder,
      ),
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final numValue = num.tryParse(value);
        widget.onChanged(numValue);
      },
    );
  }

  Widget _buildSelectField() {
    final options = widget.field.options ?? [];
    final currentValue = widget.initialValue?.toString();

    return DropdownButtonFormField<String>(
      value: options.contains(currentValue) ? currentValue : null,
      decoration: InputDecoration(
        labelText: widget.field.label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(value: option, child: Text(option));
      }).toList(),
      onChanged: widget.enabled
          ? (value) {
              if (value != null) {
                widget.onChanged(value);
              }
            }
          : null,
    );
  }

  Widget _buildEnumField() {
    return _buildSelectField();
  }

  Widget _buildCheckboxField() {
    return CheckboxListTile(
      title: Text(widget.field.label),
      value: widget.initialValue == true,
      onChanged: widget.enabled
          ? (value) {
              widget.onChanged(value ?? false);
            }
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
