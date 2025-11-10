import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Reusable star rating input widget with draggable stars for selecting ratings from 0-5 (with half-star support)
class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final String? label;
  final String? helperText;
  final bool enabled;
  final double starSize;

  const StarRatingInput({
    super.key,
    this.initialRating = 0.0,
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
  late double _currentRating;

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

  void _updateRatingFromPosition(Offset localPosition, BoxConstraints constraints) {
    if (!widget.enabled) return;

    // Calculate rating based on horizontal position
    final width = constraints.maxWidth;
    final position = localPosition.dx.clamp(0.0, width);
    final ratio = position / width;
    
    // Convert to rating (0-5 with 0.5 increments)
    final rawRating = ratio * 5.0;
    final rating = (rawRating * 2).round() / 2; // Round to nearest 0.5
    
    if (rating != _currentRating) {
      setState(() {
        _currentRating = rating.clamp(0.0, 5.0);
      });
      widget.onRatingChanged(_currentRating);
    }
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

        // Interactive draggable star rating
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: widget.enabled ? (details) {
                _updateRatingFromPosition(details.localPosition, constraints);
              } : null,
              onPanUpdate: widget.enabled ? (details) {
                _updateRatingFromPosition(details.localPosition, constraints);
              } : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return _buildStarDisplay(index);
                }),
              ),
            );
          },
        ),

        // Rating text indicator
        if (_currentRating > 0) ...[
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '${_currentRating.toStringAsFixed(1)}/5',
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStarDisplay(int index) {
    final starNumber = index + 1;
    final starValue = starNumber.toDouble();
    final halfStarValue = starNumber - 0.5;
    
    // Determine which icon to show
    IconData starIcon;
    if (_currentRating >= starValue) {
      starIcon = Icons.star; // Full star
    } else if (_currentRating >= halfStarValue) {
      starIcon = Icons.star_half; // Half star
    } else {
      starIcon = Icons.star_border; // Empty star
    }
    
    final isActive = _currentRating >= halfStarValue;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Icon(
        starIcon,
        size: widget.starSize,
        color: widget.enabled
            ? (isActive 
                ? AppConstants.primaryColor
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))
            : Theme.of(context).disabledColor,
      ),
    );
  }
}
