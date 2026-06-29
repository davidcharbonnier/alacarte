extension StringExtensions on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension ListExtensions<T> on List<T>? {
  T? get firstOrNull => this == null || this!.isEmpty ? null : this!.first;
}