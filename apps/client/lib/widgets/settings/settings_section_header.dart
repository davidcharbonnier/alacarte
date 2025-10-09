import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable settings section header with icon and title
class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppConstants.iconM,
          color: iconColor ?? AppConstants.primaryColor,
        ),
        const SizedBox(width: AppConstants.spacingM),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor ?? AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }
}
