import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/localization_utils.dart';
import '../../utils/safe_navigation.dart';

/// Reusable scaffold for form screens with standard layout and functionality
class FormScaffold extends ConsumerWidget {
  final String title;
  final Widget child;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final String? submitButtonText;
  final bool isSubmitEnabled;

  const FormScaffold({
    super.key,
    required this.title,
    required this.child,
    this.isLoading = false,
    this.onBack,
    this.onCancel,
    this.onSubmit,
    this.submitButtonText,
    this.isSubmitEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: isLoading
              ? null
              : (onBack ?? () => SafeNavigation.goBack(context)),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: false, // Keep forms focused
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
                      child: child,
                    ),
                  ),
                ),
              ),

              // Action buttons
              if (onCancel != null || onSubmit != null)
                _buildActionButtons(context),
            ],
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppConstants.screenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            if (onCancel != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel,
                  child: Text(context.l10n.cancel),
                ),
              ),

            if (onCancel != null && onSubmit != null)
              const SizedBox(width: AppConstants.spacingM),

            // Submit button
            if (onSubmit != null)
              Expanded(
                flex: onCancel != null ? 1 : 2,
                child: ElevatedButton(
                  onPressed: (isLoading || !isSubmitEnabled) ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(submitButtonText ?? context.l10n.save),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
