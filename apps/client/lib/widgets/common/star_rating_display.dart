import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable star rating display widget with half-star support
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color? color;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starSize = AppConstants.iconS,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppConstants.primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final starValue = starNumber.toDouble();
        final halfStarValue = starNumber - 0.5;

        // Determine which icon to show
        IconData starIcon;
        if (rating >= starValue) {
          starIcon = Icons.star; // Full star
        } else if (rating >= halfStarValue) {
          starIcon = Icons.star_half; // Half star
        } else {
          starIcon = Icons.star_border; // Empty star
        }

        return Icon(
          starIcon,
          size: starSize,
          color: effectiveColor,
        );
      }),
    );
  }
}
