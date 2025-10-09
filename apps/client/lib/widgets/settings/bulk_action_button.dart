import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable bulk action button for privacy settings
class BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color buttonColor;
  final VoidCallback onPressed;
  final bool isComingSoon;

  const BulkActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonColor,
    required this.onPressed,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isComingSoon ? null : onPressed,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: AppConstants.cardPadding,
        decoration: BoxDecoration(
          color: isComingSoon 
              ? Colors.grey.withValues(alpha: 0.05)
              : buttonColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isComingSoon 
                ? Colors.grey.withValues(alpha: 0.2)
                : buttonColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppConstants.iconM,
              color: isComingSoon ? Colors.grey : buttonColor,
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
                      color: isComingSoon 
                          ? Colors.grey 
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isComingSoon 
                          ? Colors.grey 
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!isComingSoon)
              Icon(
                Icons.arrow_forward_ios,
                size: AppConstants.iconS,
                color: buttonColor.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
