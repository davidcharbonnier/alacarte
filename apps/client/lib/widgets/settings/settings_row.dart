import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable settings row with icon, title, subtitle, and optional trailing widget
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isDestructive;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive 
        ? AppConstants.errorColor 
        : Theme.of(context).colorScheme.onSurface;
    final iconColor = isDestructive 
        ? AppConstants.errorColor 
        : AppConstants.primaryColor.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingM,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppConstants.iconM,
              color: iconColor,
            ),
            const SizedBox(width: AppConstants.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[  
            const SizedBox(width: AppConstants.spacingM),
            trailing!,
            ] else if (showArrow) ...[
              const SizedBox(width: AppConstants.spacingM),
              Icon(
                Icons.arrow_forward_ios,
                size: AppConstants.iconS,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
