import 'package:flutter/material.dart';
import '../../models/item_schema.dart';
import '../../models/schema_field.dart';
import '../../models/dynamic_item.dart';

class DynamicForm extends StatefulWidget {
  final ItemSchema schema;
  final DynamicItem? initialItem;
  final Map<String, dynamic> initialValues;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback? onSubmit;
  final bool enabled;

  const DynamicForm({
    super.key,
    required this.schema,
    this.initialItem,
    this.initialValues = const {},
    required this.onChanged,
    this.onSubmit,
    this.enabled = true,
  });

  @override
  State<DynamicForm> createState() => DynamicFormState();
}

class DynamicFormState extends State<DynamicForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  @override
  void didUpdateWidget(DynamicForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schema != widget.schema ||
        oldWidget.initialItem != widget.initialItem) {
      _disposeControllers();
      _initializeValues();
    }
  }

  void _initializeValues() {
    if (widget.initialItem != null) {
      _values.addAll(widget.initialItem!.fieldValues);
      _values['name'] = widget.initialItem!.name;
      _values['description'] = widget.initialItem!.description;
    } else {
      _values.addAll(widget.initialValues);
    }

    for (final field in widget.schema.sortedFields) {
      if (field.fieldType == SchemaFieldType.checkbox) {
        _values[field.key] = _values[field.key] ?? false;
      } else {
        _controllers[field.key] = TextEditingController(
          text: _values[field.key]?.toString() ?? '',
        );
      }
    }
    _notifyChanges();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(Map<String, dynamic>.from(_values));
  }

  String? _validateField(SchemaField field, dynamic value) {
    if (field.required) {
      if (value == null || (value is String && value.isEmpty)) {
        return '${field.label} is required';
      }
    }

    if (value != null && field.validation != null) {
      final error = field.validation!.validate(value);
      if (error != null) return error;
    }

    return null;
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _values[key] = value;
      final field = widget.schema.getField(key);
      if (field != null) {
        _errors[key] = _validateField(field, value);
      }
    });
    _notifyChanges();
  }

  void _onTextChanged(String key, String value) {
    _onFieldChanged(key, value);
  }

  bool validate() {
    bool isValid = true;
    final newErrors = <String, String?>{};

    for (final field in widget.schema.fields) {
      final value = _values[field.key];
      final error = _validateField(field, value);
      newErrors[field.key] = error;
      if (error != null) isValid = false;
    }

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });

    return isValid;
  }

  Map<String, dynamic> getValues() {
    return Map<String, dynamic>.from(_values);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in widget.schema.sortedFields)
          if (field.isVisible) _buildField(field),
      ],
    );
  }

  Widget _buildField(SchemaField field) {
    final error = _errors[field.key];
    final value = _values[field.key];

    switch (field.fieldType) {
      case SchemaFieldType.text:
        return _buildTextField(field, error);
      case SchemaFieldType.textarea:
        return _buildTextareaField(field, error);
      case SchemaFieldType.number:
        return _buildNumberField(field, error);
      case SchemaFieldType.select:
        return _buildSelectField(field, error);
      case SchemaFieldType.enum_:
        return _buildEnumField(field, error);
      case SchemaFieldType.checkbox:
        return _buildCheckboxField(field, error, value);
    }
  }

  Widget _buildTextField(SchemaField field, String? error) {
    final controller = _controllers[field.key];
    if (controller == null) {
      _controllers[field.key] = TextEditingController(
        text: _values[field.key]?.toString() ?? '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.key],
        decoration: InputDecoration(
          labelText: field.label,
          errorText: error,
          border: const OutlineInputBorder(),
          hintText: field.display?.placeholder,
        ),
        enabled: widget.enabled,
        onChanged: (value) => _onTextChanged(field.key, value),
        validator: (value) {
          return _validateField(field, value);
        },
      ),
    );
  }

  Widget _buildTextareaField(SchemaField field, String? error) {
    final controller = _controllers[field.key];
    if (controller == null) {
      _controllers[field.key] = TextEditingController(
        text: _values[field.key]?.toString() ?? '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.key],
        decoration: InputDecoration(
          labelText: field.label,
          errorText: error,
          border: const OutlineInputBorder(),
          hintText: field.display?.placeholder,
        ),
        enabled: widget.enabled,
        maxLines: 4,
        onChanged: (value) => _onTextChanged(field.key, value),
        validator: (value) {
          return _validateField(field, value);
        },
      ),
    );
  }

  Widget _buildNumberField(SchemaField field, String? error) {
    final controller = _controllers[field.key];
    if (controller == null) {
      _controllers[field.key] = TextEditingController(
        text: _values[field.key]?.toString() ?? '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.key],
        decoration: InputDecoration(
          labelText: field.label,
          errorText: error,
          border: const OutlineInputBorder(),
          hintText: field.display?.placeholder,
        ),
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final numValue = num.tryParse(value);
          _onFieldChanged(field.key, numValue);
        },
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final numValue = num.tryParse(value);
            if (numValue == null) {
              return 'Please enter a valid number';
            }
          }
          return _validateField(field, value);
        },
      ),
    );
  }

  Widget _buildSelectField(SchemaField field, String? error) {
    final options = field.options ?? [];
    final currentValue = _values[field.key]?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: options.contains(currentValue) ? currentValue : null,
        decoration: InputDecoration(
          labelText: field.label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: widget.enabled
            ? (value) {
                if (value != null) {
                  _onFieldChanged(field.key, value);
                }
              }
            : null,
        validator: (value) {
          return _validateField(field, value);
        },
      ),
    );
  }

  Widget _buildEnumField(SchemaField field, String? error) {
    return _buildSelectField(field, error);
  }

  Widget _buildCheckboxField(
    SchemaField field,
    String? error,
    dynamic currentValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CheckboxListTile(
        title: Text(field.label),
        value: currentValue == true,
        onChanged: widget.enabled
            ? (value) {
                _onFieldChanged(field.key, value ?? false);
              }
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
