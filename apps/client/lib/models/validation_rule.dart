class ValidationRule {
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? pattern;
  final List<String>? options;

  const ValidationRule({
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.pattern,
    this.options,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      pattern: json['pattern'] as String?,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (minLength != null) map['minLength'] = minLength;
    if (maxLength != null) map['maxLength'] = maxLength;
    if (min != null) map['min'] = min;
    if (max != null) map['max'] = max;
    if (pattern != null) map['pattern'] = pattern;
    if (options != null) map['options'] = options;
    return map;
  }

  String? validate(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      if (minLength != null && value.length < minLength!) {
        return 'Minimum length is $minLength characters';
      }
      if (maxLength != null && value.length > maxLength!) {
        return 'Maximum length is $maxLength characters';
      }
      if (pattern != null) {
        final regex = RegExp(pattern!);
        if (!regex.hasMatch(value)) {
          return 'Invalid format';
        }
      }
    }

    if (value is num) {
      if (min != null && value < min!) {
        return 'Minimum value is $min';
      }
      if (max != null && value > max!) {
        return 'Maximum value is $max';
      }
    }

    if (options != null && value is String) {
      if (!options!.contains(value)) {
        return 'Value must be one of: ${options!.join(", ")}';
      }
    }

    return null;
  }

  @override
  String toString() =>
      'ValidationRule(minLength: $minLength, maxLength: $maxLength, min: $min, max: $max)';
}
