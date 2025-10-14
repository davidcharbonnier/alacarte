/// Wine color enum with French values (matching SAQ standard)
enum WineColor {
  rouge('Rouge'),    // Red
  blanc('Blanc'),    // White
  rose('Rosé'),      // Rosé/Pink
  mousseux('Mousseux'), // Sparkling
  orange('Orange');  // Orange

  final String value;
  const WineColor(this.value);

  /// Get WineColor from string value
  static WineColor? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    
    try {
      return WineColor.values.firstWhere(
        (color) => color.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON string
  String toJson() => value;

  /// Create from JSON
  static WineColor? fromJson(String? json) => fromString(json);

  @override
  String toString() => value;
}
