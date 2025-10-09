import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable loading banner widget
class LoadingBanner extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? indicatorColor;

  const LoadingBanner({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppConstants.primaryColor.withValues(alpha: 0.1);
    final txtColor = textColor ?? AppConstants.primaryColor;
    final indColor = indicatorColor ?? AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingM),
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: indColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(indColor),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}
