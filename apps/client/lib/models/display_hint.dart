class DisplayHint {
  final bool badge;
  final bool primary;
  final bool secondary;

  const DisplayHint({
    this.badge = false,
    this.primary = false,
    this.secondary = false,
  });

  factory DisplayHint.fromJson(Map<String, dynamic> json) {
    return DisplayHint(
      badge: json['badge'] as bool? ?? false,
      primary: json['primary'] as bool? ?? false,
      secondary: json['secondary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge,
      'primary': primary,
      'secondary': secondary,
    };
  }

  @override
  String toString() => 'DisplayHint(badge: $badge, primary: $primary, secondary: $secondary)';
}