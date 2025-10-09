import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../routes/route_names.dart';
import '../utils/constants.dart';
import '../utils/localization_utils.dart';

/// Helper class for building standard AppBar actions across the app
class AppBarHelper {
  /// Build standard action buttons that appear in most app bars
  /// Includes user profile menu only (connectivity handled by fullscreen overlay)
  static List<Widget> buildStandardActions(
    BuildContext context, 
    WidgetRef ref, {
    bool showUserProfile = true,
    VoidCallback? onUserProfilePressed,
    List<Widget> extraActions = const [],
  }) {
    final authState = ref.watch(authProvider);
    
    return [
      // User profile picture/menu (if authenticated and requested)
      if (showUserProfile && authState.isAuthenticated && authState.user != null) ...[
        _buildUserProfileAction(context, ref, authState.user!, onUserProfilePressed),
      ],
      
      // Extra actions (if any)
      ...extraActions,
      
      // Final spacing
      const SizedBox(width: AppConstants.spacingS),
    ];
  }
  
  /// Build the user profile action button
  static Widget _buildUserProfileAction(
    BuildContext context, 
    WidgetRef ref, 
    dynamic user,
    VoidCallback? customAction,
  ) {
    return _UserProfileButton(
      user: user,
      onProfilePressed: () {
        // Navigate to settings screen
        GoRouter.of(context).go(RouteNames.settings);
      },
      onSignOutPressed: () => _showSignOutDialog(context, ref),
    );
  }
  
  /// Helper method to get user initials
  static String _getUserInitials(dynamic user) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.fullName;
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
  
  /// Show sign out confirmation dialog
  static void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.signOut),
        content: Text(context.l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              
              navigator.pop(); // Close confirmation dialog
              
              // Perform sign-out
              await ref.read(authProvider.notifier).signOut();
              
              // Navigate directly to auth screen
              router.go(RouteNames.auth);
            },
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
    );
  }
}

/// Custom user profile button with elegant dropdown
class _UserProfileButton extends StatefulWidget {
  final dynamic user;
  final VoidCallback onProfilePressed;
  final VoidCallback onSignOutPressed;
  
  const _UserProfileButton({
    required this.user,
    required this.onProfilePressed,
    required this.onSignOutPressed,
  });
  
  @override
  State<_UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<_UserProfileButton> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();
  
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  void _showUserMenu(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _UserMenuOverlay(
        user: widget.user,
        buttonOffset: offset,
        buttonSize: size,
        onProfilePressed: () {
          _removeOverlay();
          widget.onProfilePressed();
        },
        onSignOutPressed: () {
          _removeOverlay();
          widget.onSignOutPressed();
        },
        onDismiss: _removeOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: () => _showUserMenu(context),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXS),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
          backgroundImage: widget.user.avatar.isNotEmpty 
              ? NetworkImage(widget.user.avatar)
              : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: widget.user.avatar.isEmpty 
              ? Text(
                  AppBarHelper._getUserInitials(widget.user),
                  style: TextStyle(
                    fontSize: AppConstants.fontM, 
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Custom overlay for user menu dropdown - styled to match app's visual system
class _UserMenuOverlay extends StatelessWidget {
  final dynamic user;
  final Offset buttonOffset;
  final Size buttonSize;
  final VoidCallback onProfilePressed;
  final VoidCallback onSignOutPressed;
  final VoidCallback onDismiss;
  
  const _UserMenuOverlay({
    required this.user,
    required this.buttonOffset,
    required this.buttonSize,
    required this.onProfilePressed,
    required this.onSignOutPressed,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate position - show below button, align to right edge
    const cardWidth = 280.0;
    final left = (buttonOffset.dx + buttonSize.width) - cardWidth;
    final top = buttonOffset.dy + buttonSize.height + AppConstants.spacingS;
    
    // Ensure dropdown stays on screen
    final adjustedLeft = left < AppConstants.spacingM 
        ? AppConstants.spacingM 
        : (left + cardWidth > screenSize.width - AppConstants.spacingM
            ? screenSize.width - cardWidth - AppConstants.spacingM
            : left);
    
    return Stack(
      children: [
        // Transparent background to capture taps
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Dropdown card - matching app's Card style
        Positioned(
          left: adjustedLeft,
          top: top,
          child: Card(
            child: Container(
              width: cardWidth,
              padding: AppConstants.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info section
                  Row(
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
                                AppBarHelper._getUserInitials(user),
                                style: TextStyle(
                                  fontSize: AppConstants.fontL, 
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
                            Text(
                              user.displayName.isNotEmpty ? user.displayName : user.email,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user.displayName.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingXS),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Divider - matching app's divider style
                  const Divider(),
                  
                  const SizedBox(height: AppConstants.spacingS),
                  
                  // Action buttons - styled like app's components
                  _buildMenuOption(
                    context,
                    icon: Icons.settings,
                    title: context.l10n.settings,
                    onTap: onProfilePressed,
                  ),
                  
                  const SizedBox(height: AppConstants.spacingXS),
                  
                  _buildMenuOption(
                    context,
                    icon: Icons.logout,
                    title: context.l10n.signOut,
                    onTap: onSignOutPressed,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive 
        ? AppConstants.errorColor
        : Theme.of(context).colorScheme.onSurface;
    final iconColor = isDestructive 
        ? AppConstants.errorColor
        : AppConstants.primaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingS,
          vertical: AppConstants.spacingM,
        ),
        child: Row(
          children: [
            // Icon with background - matching app's style
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                size: AppConstants.iconS,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
