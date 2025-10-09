/// Extension methods for common Dart types
extension StringExtensions on String {
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.capitalized)
        .join(' ');
  }
  
  /// Remove extra whitespace
  String get cleaned => trim().replaceAll(RegExp(r'\s+'), ' ');
}

extension IntExtensions on int? {
  /// Check if int is null or zero
  bool get isNullOrZero => this == null || this == 0;
  
  /// Get value or default
  int orDefault(int defaultValue) => this ?? defaultValue;
}

extension DoubleExtensions on double {
  /// Format rating for display (1 decimal place)
  String get formatRating => toStringAsFixed(1);
  
  /// Convert to star rating (0-5 scale)
  int get toStarRating => clamp(0.0, 5.0).round();
}

extension DateTimeExtensions on DateTime? {
  /// Format date for display
  String get formatDate {
    if (this == null) return 'Unknown';
    final date = this!;
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Format relative time (e.g., "2 days ago")
  String get formatRelative {
    if (this == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(this!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

extension ListExtensions<T> on List<T>? {
  /// Check if list is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  
  /// Get length or 0 if null
  int get lengthOrZero => this?.length ?? 0;
  
  /// Get first item or null
  T? get firstOrNull => isNullOrEmpty ? null : this!.first;
}
