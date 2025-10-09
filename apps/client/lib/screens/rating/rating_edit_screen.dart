import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/rating.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/safe_navigation.dart';
import '../../utils/item_provider_helper.dart';
import '../../models/rateable_item.dart' as rateable;
import '../../widgets/forms/form_scaffold.dart';
import '../../widgets/forms/star_rating_input.dart';

class RatingEditScreen extends ConsumerStatefulWidget {
  final int ratingId;

  const RatingEditScreen({super.key, required this.ratingId});

  @override
  ConsumerState<RatingEditScreen> createState() => _RatingEditScreenState();
}

class _RatingEditScreenState extends ConsumerState<RatingEditScreen> {
  final _noteController = TextEditingController();
  int _selectedRating = 0;
  Rating? _existingRating;
  bool _isLoadingRating = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingRating();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    setState(() {
      _isLoadingRating = true;
      _loadError = null;
    });

    try {
      // First check if rating is in current user's ratings
      final ratingState = ref.read(ratingProvider);
      _existingRating = ratingState.ratings
          .where((r) => r.id == widget.ratingId)
          .firstOrNull;

      if (_existingRating == null) {
        setState(() {
          _loadError = context.l10n.ratingNotFoundOrNoPermission;
          _isLoadingRating = false;
        });
        return;
      }

      // Check if current user can edit this rating
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;
      if (currentUserId == null ||
          !_existingRating!.canEditByUser(currentUserId)) {
        setState(() {
          _loadError = context.l10n.noPermissionToEdit;
          _isLoadingRating = false;
        });
        return;
      }

      // Pre-populate form with existing data
      _selectedRating = _existingRating!.starRating;
      _noteController.text = _existingRating!.note;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  void _onRatingChanged(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  bool get _canSubmit {
    return _selectedRating > 0 && _existingRating != null;
  }

  bool get _hasChanges {
    if (_existingRating == null) return false;
    return _selectedRating != _existingRating!.starRating ||
        _noteController.text.trim() != _existingRating!.note;
  }

  Future<void> _submitRating() async {
    if (!_canSubmit) return;

    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == null) {
      _showErrorSnackBar('No authenticated user');
      return;
    }

    final success = await ref
        .read(ratingProvider.notifier)
        .updateRating(
          widget.ratingId,
          grade: _selectedRating.toDouble(),
          note: _noteController.text.trim(),
        );

    if (success) {
      _showSuccessSnackBar(context.l10n.ratingUpdated);
      // Navigate back to item detail screen
      if (mounted) {
        // Use a delay to ensure the snackbar is shown before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          SafeNavigation.goBackFromRatingEdit(
            context,
            _existingRating!.itemType,
            _existingRating!.itemId,
          );
        }
      }
    } else {
      final error =
          ref.read(ratingProvider).error ?? context.l10n.couldNotUpdateRating;
      _showErrorSnackBar(error);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
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
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: context.l10n.dismiss,
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(ratingProvider);

    // Show loading screen while loading rating data
    if (_isLoadingRating) {
      return FormScaffold(
        title: context.l10n.editRating,
        isLoading: true,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen if rating couldn't be loaded
    if (_loadError != null || _existingRating == null) {
      return FormScaffold(
        title: context.l10n.editRating,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                _loadError ?? context.l10n.ratingNotFound,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              ElevatedButton(
                onPressed: () => SafeNavigation.goBack(context),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return FormScaffold(
      title: context.l10n.editRating,
      isLoading: ratingState.isLoading,
      onBack: () => SafeNavigation.goBackFromRatingEdit(
        context,
        _existingRating!.itemType,
        _existingRating!.itemId,
      ),
      onCancel: () => SafeNavigation.goBackFromRatingEdit(
        context,
        _existingRating!.itemType,
        _existingRating!.itemId,
      ),
      onSubmit: _hasChanges ? _submitRating : null,
      submitButtonText: context.l10n.saveChanges,
      isSubmitEnabled: _canSubmit && _hasChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating context card
          _buildRatingContextCard(),

          const SizedBox(height: AppConstants.spacingXL),

          // Rating input section
          StarRatingInput(
            initialRating: _selectedRating,
            onRatingChanged: _onRatingChanged,
            label: context.l10n.yourRating,
            helperText: context.l10n.selectRating,
          ),

          const SizedBox(height: AppConstants.spacingXL),

          // Notes input section
          _buildNotesSection(),

          // Show changes indicator
          if (_hasChanges) ...[
            const SizedBox(height: AppConstants.spacingL),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: AppConstants.primaryColor,
                    size: AppConstants.iconM,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    context.l10n.unsavedChanges,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingContextCard() {
    // Get the actual item name using ItemProviderHelper (works for any item type)
    String itemDisplayName = 'Unknown Item';

    // Try to get item from cache/provider
    final items = ItemProviderHelper.getItems(ref, _existingRating!.itemType);
    final item = items
        .where((item) => item.id == _existingRating!.itemId)
        .firstOrNull;
    
    if (item != null) {
      itemDisplayName = item.name;
    } else {
      // Fallback to item type + ID if not found in cache
      final localizedType = ItemTypeLocalizer.getLocalizedItemType(
        context,
        _existingRating!.itemType,
      );
      itemDisplayName = '$localizedType #${_existingRating!.itemId}';
    }

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            // Rating icon
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Icon(
                Icons.edit,
                size: AppConstants.iconL,
                color: AppConstants.primaryColor,
              ),
            ),

            const SizedBox(width: AppConstants.spacingM),

            // Rating info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.editingRatingFor,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    itemDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    context.l10n.originalRating(_existingRating!.starRating),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addNotes,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.l10n.notesHelper,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.newline,
          onChanged: (_) =>
              setState(() {}), // Trigger rebuild to update _hasChanges
        ),
      ],
    );
  }
}
