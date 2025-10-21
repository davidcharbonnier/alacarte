import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/rateable_item.dart';
import '../utils/constants.dart';
import '../utils/localization_utils.dart';
import '../utils/appbar_helper.dart';
import '../utils/safe_navigation.dart';
import '../widgets/forms/item_form_fields.dart';
import '../widgets/items/item_image_picker.dart';
import '../services/image_service.dart';
import '../utils/item_provider_helper.dart';
import 'strategies/item_form_strategy.dart';
import 'strategies/item_form_strategy_registry.dart';
import 'strategies/form_field_config.dart';

/// Generic form screen using Strategy Pattern for item-specific logic
/// 
/// This form delegates all item-specific logic to ItemFormStrategy implementations.
/// Adding a new item type only requires creating a new strategy and registering it.
class GenericItemFormScreen<T extends RateableItem>
    extends ConsumerStatefulWidget {
  final String itemType;
  final int? itemId; // null for create, non-null for edit
  final T? initialItem; // For edit mode

  const GenericItemFormScreen({
    super.key,
    required this.itemType,
    this.itemId,
    this.initialItem,
  });

  @override
  ConsumerState<GenericItemFormScreen<T>> createState() =>
      _GenericItemFormScreenState<T>();
}

class _GenericItemFormScreenState<T extends RateableItem>
    extends ConsumerState<GenericItemFormScreen<T>> {
  final _formKey = GlobalKey<FormState>();

  // Strategy handles all item-specific logic
  late final ItemFormStrategy<T> _strategy;
  late final Map<String, TextEditingController> _controllers;

  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;
  File? _selectedImage;
  bool _imageRemoved = false;
  String? _oldImageUrl; // Capture image URL before form submission

  @override
  void initState() {
    super.initState();
    // Get strategy from registry - this is the only item-type specific logic!
    _strategy = ItemFormStrategyRegistry.getStrategy<T>(widget.itemType);
    // Strategy initializes all controllers with proper data
    _controllers = _strategy.initializeControllers(widget.initialItem);
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    void trackChanges() {
      setState(() => _hasChanges = true);
    }

    // Add listeners to all controllers
    for (final controller in _controllers.values) {
      controller.addListener(trackChanges);
    }
  }

  @override
  void dispose() {
    // Strategy handles cleanup
    _strategy.disposeControllers(_controllers);
    super.dispose();
  }

  bool get _isEditMode => widget.itemId != null;

  String get _localizedItemType {
    return ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType);
  }

  String? _getCurrentImageUrl() {
    if (widget.initialItem == null) return null;
    
    // Use runtime type checking to access imageUrl
    final item = widget.initialItem as dynamic;
    try {
      return item.imageUrl as String?;
    } catch (e) {
      return null;
    }
  }

  bool get _isFormValid {
    // Check all required fields have values
    final fields = _strategy.getFormFields();
    for (final field in fields) {
      if (field.required) {
        final controller = _controllers[field.key];
        if (controller == null || controller.text.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _navigateBack() {
    if (_isEditMode && widget.itemId != null) {
      SafeNavigation.goBackToItemDetail(
        context,
        widget.itemType,
        widget.itemId!,
      );
    } else {
      SafeNavigation.goBackToItemType(context, widget.itemType);
    }
  }

  void _handleCancel() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.unsavedChanges),
          content: Text(context.l10n.unsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateBack();
              },
              child: Text(context.l10n.discard),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    } else {
      _navigateBack();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture the current image URL BEFORE we start any operations
    _oldImageUrl = _getCurrentImageUrl();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If user is removing an image, delete it FIRST before updating the item
      // This ensures the DELETE endpoint sees the image still in the database
      if (_imageRemoved && _isEditMode && _oldImageUrl != null && _oldImageUrl!.isNotEmpty && widget.itemId != null) {
        final imageService = ref.read(imageServiceProvider);
        final bool deleted = await imageService.deleteImage(widget.itemType, widget.itemId!);
        if (deleted) {
          // Clear old image from cache
          await DefaultCacheManager().removeFile(_oldImageUrl!);
        }
      }

      // Strategy builds the item from controllers
      final item = _strategy.buildItem(_controllers, widget.itemId);

      // Validate using strategy
      final validationErrors = _strategy.validate(context, item);
      if (validationErrors.isNotEmpty) {
        setState(() {
          _error = validationErrors.first;
          _isLoading = false;
        });
        return;
      }

      // Strategy provides the correct provider
      final provider = _strategy.getProvider();

      // Perform create or update
      final bool success;
      int? createdItemId;
      
      if (_isEditMode) {
        success = await ref.read(provider.notifier).updateItem(widget.itemId!, item);
        createdItemId = widget.itemId;
      } else {
        final result = await ref.read(provider.notifier).createItem(item);
        success = result != null;
        createdItemId = result;
      }

      // Handle image upload if item creation/update was successful
      if (success && createdItemId != null) {
        final imageService = ref.read(imageServiceProvider);

        // If user selected a new image, upload it
        if (_selectedImage != null) {
          final imageUrl = await imageService.uploadImage(
            widget.itemType,
            createdItemId,
            _selectedImage!,
          );

          if (imageUrl == null) {
            // Image upload failed, but item was created/updated
            // Show warning but don't fail the whole operation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item saved, but image upload failed'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            // Image uploaded successfully - use granular cache clearing
            // 1. Clear old image from cache (if exists)
            if (_isEditMode && _oldImageUrl != null) {
              await DefaultCacheManager().removeFile(_oldImageUrl!);
            }
            // 2. Invalidate this item from provider state
            ItemProviderHelper.invalidateItem(ref, widget.itemType, createdItemId);
            // 3. Reload this item immediately so it's back in provider state
            await ItemProviderHelper.loadSpecificItems(ref, widget.itemType, [createdItemId]);
          }
        }

        // If image was removed, we already deleted it before the PUT
        // Just invalidate and reload to refresh the UI
        if (_imageRemoved && _isEditMode) {
          ItemProviderHelper.invalidateItem(ref, widget.itemType, createdItemId);
          await ItemProviderHelper.loadSpecificItems(ref, widget.itemType, [createdItemId]);
        }
      }

      if (success) {
        _showSuccessMessage();
        _navigateBack();
      } else {
        final error = ref.read(provider).error;
        setState(() {
          _error = error ??
              (_isEditMode
                  ? context.l10n.couldNotUpdateItem(
                      _localizedItemType.toLowerCase(),
                    )
                  : context.l10n.couldNotCreateItem(
                      _localizedItemType.toLowerCase(),
                    ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    final message = _isEditMode
        ? context.l10n.itemUpdated(_localizedItemType)
        : context.l10n.itemCreated(_localizedItemType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode
        ? context.l10n.editItem(widget.initialItem?.name ?? 'Item')
        : context.l10n.addNewItem(_localizedItemType);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: _isLoading ? null : _handleCancel,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: false,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: AppConstants.screenPadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message if any
                          if (_error != null) _buildErrorCard(),

                          // Main form card
                          _buildFormCard(),

                          const SizedBox(height: AppConstants.spacingXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom action buttons
              _buildActionButtons(),
            ],
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Column(
      children: [
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: AppConstants.cardPadding,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormHeader(),
              const SizedBox(height: AppConstants.spacingL),
              const Divider(),
              const SizedBox(height: AppConstants.spacingL),

              // Build fields from strategy - no conditionals!
              ..._buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Icon(
            _isEditMode ? Icons.edit : Icons.add_circle,
            color: AppConstants.primaryColor,
            size: AppConstants.iconL,
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode
                    ? context.l10n.editItemType(_localizedItemType)
                    : context.l10n.addNewItemType(_localizedItemType),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                _isEditMode
                    ? context.l10n.updateInfoBelow
                    : context.l10n.fillDetailsToAdd,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build form fields from strategy configuration
  /// 
  /// This method has ZERO item-type conditionals - it just iterates
  /// over the field configurations provided by the strategy.
  List<Widget> _buildFormFields() {
    final fields = _strategy.getFormFields();
    final widgets = <Widget>[];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];

      // Build appropriate widget for this field type
      widgets.add(_buildFieldWidget(field));

      // Add spacing between fields
      widgets.add(const SizedBox(height: AppConstants.spacingL));
    }

    // Add image picker after all other fields
    widgets.add(_buildImagePicker());
    widgets.add(const SizedBox(height: AppConstants.spacingL));

    return widgets;
  }

  /// Build a single field widget based on its configuration
  Widget _buildFieldWidget(FormFieldConfig field) {
    final controller = _controllers[field.key]!;

    switch (field.type) {
      case FormFieldType.text:
        return ItemPropertyField(
          controller: controller,
          labelText: field.getLabel(context),
          hintText: field.getHint(context),
          required: field.required,
          enabled: !_isLoading,
          prefixIcon: field.icon,
        );

      case FormFieldType.multiline:
        return _buildDescriptionField(field, controller);

      case FormFieldType.dropdown:
        return _buildDropdownField(field, controller);

      case FormFieldType.checkbox:
        return _buildCheckboxField(field, controller);
    }
  }

  Widget _buildDescriptionField(
    FormFieldConfig field,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: AppConstants.iconS,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              '${field.getLabel(context)}:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const Spacer(),
            Text(
              context.l10n.optional,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        ItemDescriptionField(
          controller: controller,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    FormFieldConfig field,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (field.icon != null) ...[
              Icon(
                field.icon,
                size: AppConstants.iconS,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: AppConstants.spacingS),
            ],
            Text(
              '${field.getLabel(context)}:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            if (field.required)
              Text(
                ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        if (field.getHelperText(context) != null) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            field.getHelperText(context)!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingS),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            hintText: field.getHint(context),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
          ),
          items: field.options!.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.getLabel(context)),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  if (value != null) {
                    controller.text = value;
                  }
                },
          validator: field.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return field.getLabel(context) + ' is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCheckboxField(
    FormFieldConfig field,
    TextEditingController controller,
  ) {
    // Controller holds 'true' or 'false' as string
    final isChecked = controller.text == 'true';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    controller.text = isChecked ? 'false' : 'true';
                  });
                },
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spacingS,
              horizontal: AppConstants.spacingXS,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.getLabel(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (field.getHelperText(context) != null) ...[
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          field.getHelperText(context)!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Checkbox(
                  value: isChecked,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            controller.text = value == true ? 'true' : 'false';
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: AppConstants.screenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleCancel,
                child: Text(context.l10n.cancel),
              ),
            ),

            const SizedBox(width: AppConstants.spacingM),

            // Submit button
            Expanded(
              child: ElevatedButton(
                onPressed: (_isLoading || !_isFormValid) ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isEditMode ? context.l10n.saveChanges : context.l10n.create,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildImagePicker() {
    return ItemImagePicker(
      currentImageUrl: _imageRemoved ? null : _getCurrentImageUrl(),
      selectedImage: _selectedImage,
      itemType: widget.itemType,
      enabled: !_isLoading,
      onImageSelected: (file) {
        setState(() {
          _selectedImage = file;
          _hasChanges = true;
          if (file == null && _getCurrentImageUrl() != null) {
            _imageRemoved = true;
          } else {
            _imageRemoved = false;
          }
        });
      },
      onImageRemoved: () {
        setState(() {
          _selectedImage = null;
          _imageRemoved = true;
          _hasChanges = true;
        });
      },
    );
  }
}
