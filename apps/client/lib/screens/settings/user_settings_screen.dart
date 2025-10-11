import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/constants.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/localization_utils.dart';
import '../../utils/notification_helper.dart';
import '../../utils/safe_navigation.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/settings_row.dart';
import '../../widgets/settings/language_selector.dart';
import '../../widgets/settings/profile_info_widget.dart';

/// Comprehensive settings screen with app preferences and profile management
class UserSettingsScreen extends ConsumerWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appState = ref.watch(appProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () => SafeNavigation.goBackToHub(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main settings card
                _buildSettingsCard(context, ref, appState, user),
                
                const SizedBox(height: AppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );  
  }
  
  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.displayLanguage),
        content: const LanguageSelector(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    dynamic appState,
    dynamic user,
  ) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Preferences Section
            SettingsSectionHeader(
              icon: Icons.tune,
              title: context.l10n.appPreferences,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            SettingsRow(
              icon: Icons.dark_mode,
              title: context.l10n.darkMode,
              subtitle: context.l10n.darkModeDescription,
              trailing: Switch(
                value: appState.isDarkMode,
                onChanged: (value) => ref.read(appProvider.notifier).toggleDarkMode(),
              ),
            ),
            
            SettingsRow(
              icon: Icons.language,
              title: context.l10n.displayLanguage,
              subtitle: context.l10n.displayLanguageDescription,
              onTap: () => _showLanguageDialog(context, ref),
              showArrow: true,
            ),
            
            // Profile & Account Section
            if (user != null) ...[
              const SizedBox(height: AppConstants.spacingL),
              const Divider(),
              const SizedBox(height: AppConstants.spacingL),
              
              SettingsSectionHeader(
                icon: Icons.person,
                title: context.l10n.profileAndAccount,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Profile info with inline editing
              ProfileInfoWidget(
                user: user,
                onSaveDisplayName: (displayName) async {
                  await ref.read(authProvider.notifier).updateDisplayName(displayName);
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              SettingsRow(
                icon: Icons.shield,
                title: context.l10n.privacySettings,
                subtitle: context.l10n.managePrivacyAndDiscovery,
                onTap: () => GoRouter.of(context).go(RouteNames.privacySettings),
                showArrow: true,
              ),
              
              // Danger Zone
              const SizedBox(height: AppConstants.spacingM),
              SettingsRow(
                icon: Icons.delete_forever,
                title: context.l10n.deleteAccount,
                subtitle: context.l10n.deleteAccountDescription,
                onTap: () => _showDeleteAccountDialog(context, ref),
                showArrow: true,
                isDestructive: true,
              ),
            ],
            
            // About Section
            const SizedBox(height: AppConstants.spacingL),
            const Divider(),
            const SizedBox(height: AppConstants.spacingL),
            
            SettingsSectionHeader(
              icon: Icons.info_outline,
              title: context.l10n.about,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            SettingsRow(
              icon: Icons.info,
              title: context.l10n.appVersion,
              subtitle: AppConfig.appVersion,
            ),
            
            SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: context.l10n.privacyPolicy,
              subtitle: context.l10n.learnAboutPrivacy,
              onTap: () => _showPrivacyPolicy(context),
              showArrow: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user == null) return;
    
    // Since app only works when online, no need to check connectivity here
    final confirmationController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final isConfirmationValid = confirmationController.text.trim() == user.displayName;
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: AppConstants.errorColor,
                  size: AppConstants.iconM,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(dialogContext.l10n.deleteAccount),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogContext.l10n.deleteAccountWarning,
                  style: Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                
                // Consequences warning
                Container(
                  padding: AppConstants.cardPadding,
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: AppConstants.errorColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppConstants.iconS,
                        color: AppConstants.errorColor,
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          dialogContext.l10n.deleteAccountConsequences,
                          style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingL),
                
                // Confirmation input
                Text(
                  dialogContext.l10n.typeDisplayNameToConfirm(user.displayName),
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                TextField(
                  controller: confirmationController,
                  decoration: InputDecoration(
                    hintText: user.displayName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide(color: AppConstants.errorColor),
                    ),
                  ),
                  onChanged: (value) => setState(() {}), // Trigger rebuild
                ),
                
                const SizedBox(height: AppConstants.spacingL),
                
                Text(
                  dialogContext.l10n.thisActionCannotBeUndone,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogContext.l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: isConfirmationValid
                    ? () {
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          _performAccountDeletion(context, ref, user);
                        }
                      }
                    : null,
                child: Text(dialogContext.l10n.deleteAccount),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context, WidgetRef ref, dynamic user) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              dialogContext.l10n.deletingAccount,
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              dialogContext.l10n.deletionMayTakeTime,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
    
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show success message - router will handle redirect to auth automatically
        NotificationHelper.showSuccess(context, context.l10n.accountDeleted);
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error message with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.errorDeletingAccount}: $e'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: context.l10n.retry,
              textColor: Colors.white,
              onPressed: () => _performAccountDeletion(context, ref, user),
            ),
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.privacyPolicy),
        content: SingleChildScrollView(
          child: Text(context.l10n.privacyPolicyContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }
}
