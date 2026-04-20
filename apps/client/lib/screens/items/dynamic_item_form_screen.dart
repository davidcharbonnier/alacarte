import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/api_response.dart';
import '../../models/dynamic_item.dart';
import '../../providers/dynamic_item_provider.dart';
import '../../providers/schema_provider.dart';
import '../../routes/route_names.dart';
import '../../services/image_service.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/constants.dart';
import '../../utils/item_provider_helper.dart';
import '../../utils/localization_utils.dart';
import '../../utils/schema_icon_utils.dart';
import '../../widgets/forms/dynamic_form.dart';
import '../../widgets/items/item_image_picker.dart';

class DynamicItemFormScreen extends ConsumerStatefulWidget {
  final String itemType;
  final int? itemId;

  const DynamicItemFormScreen({super.key, required this.itemType, this.itemId});

  @override
  ConsumerState<DynamicItemFormScreen> createState() =>
      _DynamicItemFormScreenState();
}

class _DynamicItemFormScreenState extends ConsumerState<DynamicItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  DynamicItem? _item;
  bool _isLoading = true;
  String? _error;
  File? _selectedImage;
  bool _imageRemoved = false;
  String? _oldImageUrl;
  Map<String, dynamic> _formValues = {};

  bool get _isEditMode => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItem();
    });
  }

  Future<void> _loadItem() async {
    if (_isEditMode) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ref
          .read(dynamicItemProvider.notifier)
          .getItemById(widget.itemType, widget.itemId!);

      if (response is ApiSuccess<DynamicItem>) {
        if (mounted) {
          setState(() {
            _item = response.data;
            _oldImageUrl = response.data.imageUrl;
            _isLoading = false;
          });
        }
      } else if (response is ApiError<DynamicItem>) {
        if (mounted) {
          setState(() {
            _error = response.message.isNotEmpty
                ? response.message
                : 'Failed to load item';
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageRemoved &&
        _isEditMode &&
        _oldImageUrl != null &&
        _oldImageUrl!.isNotEmpty &&
        widget.itemId != null) {
      final imageService = ref.read(imageServiceProvider);
      final bool deleted = await imageService.deleteImage(
        widget.itemType,
        widget.itemId!,
      );
      if (deleted) {
        await CachedNetworkImage.evictFromCache(_oldImageUrl!);
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final name = _formValues['name'] as String? ?? '';
    final description = _formValues['description'] as String?;

    final fieldValues = <String, dynamic>{};
    for (final entry in _formValues.entries) {
      if (entry.key != 'name' && entry.key != 'description') {
        fieldValues[entry.key] = entry.value;
      }
    }

    final item = DynamicItem(
      id: widget.itemId,
      name: name,
      schemaName: widget.itemType,
      description: description?.isNotEmpty == true ? description : null,
      fieldValues: fieldValues,
    );

    try {
      if (_isEditMode) {
        final response = await ref
            .read(dynamicItemProvider.notifier)
            .updateItem(widget.itemType, widget.itemId!, item);

        if (response is ApiSuccess<DynamicItem>) {
          await _handleImageUpload(response.data.id!);
          if (mounted) {
            _showSuccessMessage();
            _navigateBack();
          }
        } else if (response is ApiError<DynamicItem>) {
          if (mounted) {
            setState(() {
              _error = response.message;
              _isLoading = false;
            });
          }
        }
      } else {
        final response = await ref
            .read(dynamicItemProvider.notifier)
            .createItem(widget.itemType, item);

        if (response is ApiSuccess<DynamicItem>) {
          await _handleImageUpload(response.data.id!);
          if (mounted) {
            _showSuccessMessage();
            _navigateBack();
          }
        } else if (response is ApiError<DynamicItem>) {
          if (mounted) {
            setState(() {
              _error = response.message;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleImageUpload(int itemId) async {
    if (_selectedImage != null) {
      final imageService = ref.read(imageServiceProvider);
      final imageUrl = await imageService.uploadImage(
        widget.itemType,
        itemId,
        _selectedImage!,
      );

      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item saved, but image upload failed'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (imageUrl != null) {
        if (_isEditMode && _oldImageUrl != null) {
          await CachedNetworkImage.evictFromCache(_oldImageUrl!);
        }
        ItemProviderHelper.invalidateItem(ref, widget.itemType, itemId);
        await ItemProviderHelper.loadSpecificItems(ref, widget.itemType, [
          itemId,
        ]);
      }
    }

    if (_imageRemoved && _isEditMode) {
      ItemProviderHelper.invalidateItem(ref, widget.itemType, itemId);
      await ItemProviderHelper.loadSpecificItems(ref, widget.itemType, [
        itemId,
      ]);
    }
  }

  void _navigateBack() {
    if (_isEditMode && widget.itemId != null) {
      context.pop();
    } else {
      context.pop();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isEditMode
                    ? 'Item updated successfully!'
                    : 'Item created successfully!',
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
    final schemaState = ref.watch(schemaProvider);
    final schema = schemaState.getSchema(widget.itemType);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Loading...' : 'Create Item'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _item == null && _isEditMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Item not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final color = schema != null
        ? SchemaIconUtils.parseColor(schema.color)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'Edit ${schema?.displayName ?? widget.itemType}'
              : 'Create ${schema?.displayName ?? widget.itemType}',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: _isLoading ? null : () => context.pop(),
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
                          if (_error != null)
                            Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              child: Padding(
                                padding: AppConstants.cardPadding,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(
                                      width: AppConstants.spacingS,
                                    ),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: AppConstants.spacingM),
                          Card(
                            child: Padding(
                              padding: AppConstants.cardPadding,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppConstants.spacingM,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusL,
                                            ),
                                          ),
                                          child: Icon(
                                            schema != null
                                                ? SchemaIconUtils.getIcon(
                                                    schema.icon,
                                                  )
                                                : Icons.add_circle,
                                            color: color,
                                            size: AppConstants.iconL,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppConstants.spacingM,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isEditMode
                                                    ? 'Edit ${schema?.displayName ?? widget.itemType}'
                                                    : 'Create ${schema?.displayName ?? widget.itemType}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: AppConstants.spacingXS,
                                              ),
                                              Text(
                                                _isEditMode
                                                    ? 'Update information below'
                                                    : 'Fill in the details below',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),
                                    const Divider(),
                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),
                                    if (schema != null) ...[
                                      TextFormField(
                                        initialValue: _item?.name ?? '',
                                        decoration: const InputDecoration(
                                          labelText: 'Name *',
                                          border: OutlineInputBorder(),
                                        ),
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Name is required';
                                          }
                                          if (value.trim().length < 2) {
                                            return 'Name must be at least 2 characters';
                                          }
                                          return null;
                                        },
                                        onChanged: (value) {
                                          _formValues['name'] = value;
                                        },
                                      ),
                                      const SizedBox(
                                        height: AppConstants.spacingL,
                                      ),
                                      DynamicForm(
                                        schema: schema,
                                        initialItem: _item,
                                        onChanged: (values) {
                                          _formValues = values;
                                        },
                                        enabled: !_isLoading,
                                      ),
                                    ] else ...[
                                      TextFormField(
                                        initialValue: _item?.name ?? '',
                                        decoration: const InputDecoration(
                                          labelText: 'Name *',
                                          border: OutlineInputBorder(),
                                        ),
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Name is required';
                                          }
                                          return null;
                                        },
                                        onChanged: (value) {
                                          _formValues['name'] = value;
                                        },
                                      ),
                                      const SizedBox(
                                        height: AppConstants.spacingL,
                                      ),
                                      TextFormField(
                                        initialValue: _item?.description ?? '',
                                        decoration: const InputDecoration(
                                          labelText: 'Description',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 3,
                                        enabled: !_isLoading,
                                        onChanged: (value) {
                                          _formValues['description'] = value;
                                        },
                                      ),
                                    ],
                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),
                                    ItemImagePicker(
                                      currentImageUrl: _imageRemoved
                                          ? null
                                          : (_item?.imageUrl),
                                      selectedImage: _selectedImage,
                                      itemType: widget.itemType,
                                      enabled: !_isLoading,
                                      onImageSelected: (file) {
                                        setState(() {
                                          _selectedImage = file;
                                          if (file == null &&
                                              _item?.imageUrl != null) {
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
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: AppConstants.screenPadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go(
                                  '${RouteNames.itemType}/${widget.itemType}',
                                ),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isEditMode
                                ? context.l10n.saveChanges
                                : context.l10n.create,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
