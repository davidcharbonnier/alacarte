import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rateable_item.dart';
import '../../models/cheese_item.dart';
import '../../models/gin_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/safe_navigation.dart';
import '../../widgets/forms/item_form_fields.dart';

/// Generic form screen with inline single-card design matching item detail style
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

  // Controllers for form fields
  late final TextEditingController _nameController;
  late final TextEditingController _typeController; // Used for cheese type
  late final TextEditingController _profileController; // Used for gin profile
  late final TextEditingController _originController;
  late final TextEditingController _producerController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    if (widget.initialItem != null && widget.initialItem is CheeseItem) {
      final cheese = widget.initialItem as CheeseItem;
      _nameController = TextEditingController(text: cheese.name);
      _typeController = TextEditingController(text: cheese.type);
      _profileController = TextEditingController(); // Not used for cheese
      _originController = TextEditingController(text: cheese.origin);
      _producerController = TextEditingController(text: cheese.producer);
      _descriptionController = TextEditingController(
        text: cheese.description ?? '',
      );
    } else if (widget.initialItem != null && widget.initialItem is GinItem) {
      final gin = widget.initialItem as GinItem;
      _nameController = TextEditingController(text: gin.name);
      _typeController = TextEditingController(); // Not used for gin
      _profileController = TextEditingController(text: gin.profile);
      _originController = TextEditingController(text: gin.origin);
      _producerController = TextEditingController(text: gin.producer);
      _descriptionController = TextEditingController(
        text: gin.description ?? '',
      );
    } else {
      _nameController = TextEditingController();
      _typeController = TextEditingController();
      _profileController = TextEditingController();
      _originController = TextEditingController();
      _producerController = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  void _setupChangeListeners() {
    void trackChanges() {
      setState(() {
        _hasChanges = true;
        // Force rebuild to update button state
      });
    }

    _nameController.addListener(trackChanges);
    _typeController.addListener(trackChanges);
    _profileController.addListener(trackChanges);
    _originController.addListener(trackChanges);
    _producerController.addListener(trackChanges);
    _descriptionController.addListener(trackChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _profileController.dispose();
    _originController.dispose();
    _producerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.itemId != null;

  String get _localizedItemType {
    return ItemTypeLocalizer.getLocalizedItemType(context, widget.itemType);
  }

  bool get _isFormValid {
    final baseValid =
        _nameController.text.trim().isNotEmpty &&
        _originController.text.trim().isNotEmpty &&
        _producerController.text.trim().isNotEmpty;

    if (widget.itemType == 'cheese') {
      return baseValid && _typeController.text.trim().isNotEmpty;
    } else if (widget.itemType == 'gin') {
      return baseValid && _profileController.text.trim().isNotEmpty;
    }

    return baseValid;
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.itemType == 'cheese') {
        final cheese = CheeseItem(
          id: widget.itemId,
          name: _nameController.text.trim(),
          type: _typeController.text.trim(),
          origin: _originController.text.trim(),
          producer: _producerController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

        final success = _isEditMode
            ? await ref
                  .read(cheeseItemProvider.notifier)
                  .updateItem(widget.itemId!, cheese)
            : await ref.read(cheeseItemProvider.notifier).createItem(cheese);

        if (success) {
          _showSuccessMessage();
          _navigateBack();
        } else {
          final error = ref.read(cheeseItemProvider).error;
          setState(() {
            _error =
                error ??
                (_isEditMode
                    ? context.l10n.couldNotUpdateItem(
                        _localizedItemType.toLowerCase(),
                      )
                    : context.l10n.couldNotCreateItem(
                        _localizedItemType.toLowerCase(),
                      ));
          });
        }
      } else if (widget.itemType == 'gin') {
        final gin = GinItem(
          id: widget.itemId,
          name: _nameController.text.trim(),
          producer: _producerController.text.trim(),
          origin: _originController.text.trim(),
          profile: _profileController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

        final success = _isEditMode
            ? await ref
                  .read(ginItemProvider.notifier)
                  .updateItem(widget.itemId!, gin)
            : await ref.read(ginItemProvider.notifier).createItem(gin);

        if (success) {
          _showSuccessMessage();
          _navigateBack();
        } else {
          final error = ref.read(ginItemProvider).error;
          setState(() {
            _error =
                error ??
                (_isEditMode
                    ? context.l10n.couldNotUpdateItem(
                        _localizedItemType.toLowerCase(),
                      )
                    : context.l10n.couldNotCreateItem(
                        _localizedItemType.toLowerCase(),
                      ));
          });
        }
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
                          if (_error != null) ...[
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
                          ],

                          // Main form card (inline style matching item detail)
                          Card(
                            child: Padding(
                              padding: AppConstants.cardPadding,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with icon and title (matching item detail style)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppConstants.spacingM,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusL,
                                            ),
                                          ),
                                          child: Icon(
                                            _isEditMode
                                                ? Icons.edit
                                                : Icons.add_circle,
                                            color: AppConstants.primaryColor,
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
                                                    ? context.l10n.editItemType(
                                                        _localizedItemType,
                                                      )
                                                    : context.l10n
                                                          .addNewItemType(
                                                            _localizedItemType,
                                                          ),
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
                                                    ? context
                                                          .l10n
                                                          .updateInfoBelow
                                                    : context
                                                          .l10n
                                                          .fillDetailsToAdd,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
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
                                    ),

                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),
                                    const Divider(),
                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),

                                    // Form fields with consistent spacing
                                    ItemNameField(
                                      controller: _nameController,
                                      itemType: _localizedItemType,
                                      enabled: !_isLoading,
                                    ),

                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),

                                    // Type/Profile field (cheese uses type, gin uses profile)
                                    if (widget.itemType == 'cheese') ...[
                                      CheeseTypeField(
                                        controller: _typeController,
                                        enabled: !_isLoading,
                                      ),
                                    ] else if (widget.itemType == 'gin') ...[
                                      ItemPropertyField(
                                        controller: _profileController,
                                        labelText: context.l10n.profileLabel,
                                        hintText: context.l10n.enterProfile,
                                        required: true,
                                        enabled: !_isLoading,
                                        prefixIcon: Icons.local_bar,
                                      ),
                                    ],

                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),

                                    // Origin field
                                    ItemPropertyField(
                                      controller: _originController,
                                      labelText: context.l10n.origin,
                                      hintText: context.l10n.enterOrigin,
                                      required: true,
                                      enabled: !_isLoading,
                                      prefixIcon: Icons.public,
                                    ),

                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),

                                    // Producer field
                                    ItemPropertyField(
                                      controller: _producerController,
                                      labelText: context.l10n.producer,
                                      hintText: context.l10n.enterProducer,
                                      required: true,
                                      enabled: !_isLoading,
                                      prefixIcon: Icons.business,
                                    ),

                                    const SizedBox(
                                      height: AppConstants.spacingL,
                                    ),

                                    // Description section with visual separation (matching detail style)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              size: AppConstants.iconS,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(
                                              width: AppConstants.spacingS,
                                            ),
                                            Text(
                                              '${context.l10n.description}:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppConstants.spacingS,
                                        ),
                                        ItemDescriptionField(
                                          controller: _descriptionController,
                                          enabled: !_isLoading,
                                        ),
                                      ],
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

              // Bottom action buttons (matching FormScaffold exactly)
              Container(
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

                      // Submit button (matching FormScaffold style exactly)
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_isFormValid)
                              ? null
                              : _submitForm,
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

          // Loading overlay (simplified)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
