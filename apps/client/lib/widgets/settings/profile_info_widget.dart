import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

// State providers for inline display name editing
final _isEditingDisplayNameProvider = StateProvider<bool>((ref) => false);
final _displayNameControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());

/// Inline editable profile information widget
class ProfileInfoWidget extends ConsumerWidget {
  final dynamic user;
  final Function(String displayName) onSaveDisplayName;

  const ProfileInfoWidget({
    super.key,
    required this.user,
    required this.onSaveDisplayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isEditing = ref.watch(_isEditingDisplayNameProvider);
    
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
          backgroundImage: user.avatar.isNotEmpty 
              ? NetworkImage(user.avatar)
              : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: user.avatar.isEmpty 
              ? Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: AppConstants.fontM,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isEditing 
                    ? _buildInlineEditor(context, ref, user, authState)
                    : _buildDisplayInfo(context, user),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isEditing
              ? _buildEditActions(context, ref, authState)
              : _buildEditButton(context, ref, user),
        ),
      ],
    );
  }
  
  Widget _buildDisplayInfo(BuildContext context, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildInlineEditor(BuildContext context, WidgetRef ref, dynamic user, dynamic authState) {
    final controller = ref.watch(_displayNameControllerProvider);
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: context.l10n.displayName,
        helperText: context.l10n.displayNameHelper,
        border: const OutlineInputBorder(),
        isDense: true,
        counterText: '', // Hide character counter for cleaner look
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
      ),
      textAlign: TextAlign.left,
      maxLength: 50,
      enabled: !authState.isLoading,
      autofocus: true,
    );
  }
  
  Widget _buildEditButton(BuildContext context, WidgetRef ref, dynamic user) {
    return IconButton(
      onPressed: () {
        ref.read(_displayNameControllerProvider.notifier).state.text = user.displayName;
        ref.read(_isEditingDisplayNameProvider.notifier).state = true;
      },
      icon: const Icon(Icons.edit),
      iconSize: AppConstants.iconM,
      color: AppConstants.primaryColor,
      tooltip: context.l10n.editDisplayName,
    );
  }
  
  Widget _buildEditActions(BuildContext context, WidgetRef ref, dynamic authState) {
    final controller = ref.watch(_displayNameControllerProvider);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Save button
        IconButton(
          onPressed: authState.isLoading || controller.text.trim().isEmpty
              ? null
              : () => _saveDisplayName(context, ref, controller.text.trim()),
          icon: authState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          iconSize: AppConstants.iconM,
          color: AppConstants.successColor,
          tooltip: context.l10n.save,
        ),
        // Cancel button
        IconButton(
          onPressed: authState.isLoading
              ? null
              : () {
                  ref.read(_isEditingDisplayNameProvider.notifier).state = false;
                  ref.read(_displayNameControllerProvider.notifier).state.clear();
                },
          icon: const Icon(Icons.close),
          iconSize: AppConstants.iconM,
          color: AppConstants.errorColor,
          tooltip: context.l10n.cancel,
        ),
      ],
    );
  }

  Future<void> _saveDisplayName(BuildContext context, WidgetRef ref, String displayName) async {
    final currentUser = ref.read(authProvider).user;
    
    // Check if the display name actually changed
    if (currentUser != null && currentUser.displayName == displayName.trim()) {
      // No change - just exit edit mode without API call
      ref.read(_isEditingDisplayNameProvider.notifier).state = false;
      ref.read(_displayNameControllerProvider.notifier).state.clear();
      return;
    }
    
    try {
      await onSaveDisplayName(displayName);
      if (context.mounted) {
        // Exit editing mode
        ref.read(_isEditingDisplayNameProvider.notifier).state = false;
        ref.read(_displayNameControllerProvider.notifier).state.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.displayNameUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Handle specific error cases
        String errorMessage;
        if (e.toString().contains('404')) {
          errorMessage = context.l10n.featureNotImplementedOnServer;
        } else if (e.toString().contains('400')) {
          errorMessage = context.l10n.invalidDisplayName;
        } else {
          errorMessage = context.l10n.errorUpdatingDisplayName;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}
