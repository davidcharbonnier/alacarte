import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable star rating input widget for selecting ratings from 0-5
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final String? label;
  final String? helperText;
  final bool enabled;
  final double starSize;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.label,
    this.helperText,
    this.enabled = true,
    this.starSize = AppConstants.iconL,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(StarRatingInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRating != oldWidget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  void _onStarTapped(int starIndex) {
    if (!widget.enabled) return;

    setState(() {
      // If tapping the same star that's currently selected, set to 0
      // Otherwise set to the tapped star (1-based)
      _currentRating = (_currentRating == starIndex + 1) ? 0 : starIndex + 1;
    });
    
    widget.onRatingChanged(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
        ],

        // Star rating row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = starNumber <= _currentRating;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () => _onStarTapped(index),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: widget.starSize,
                    color: widget.enabled
                        ? (isSelected 
                            ? AppConstants.primaryColor
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            );
          }),
        ),

        // Rating text indicator
        if (_currentRating > 0) ...[
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '$_currentRating/5',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Helper text
        if (widget.helperText != null) ...[
          const SizedBox(height: AppConstants.spacingS),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
