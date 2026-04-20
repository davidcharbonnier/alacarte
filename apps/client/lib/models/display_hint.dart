class DisplayHint {
  final bool isPrimary;
  final bool isSecondary;
  final bool isVisible;
  final int? width;
  final int? height;
  final String? placeholder;

  const DisplayHint({
    this.isPrimary = false,
    this.isSecondary = false,
    this.isVisible = true,
    this.width,
    this.height,
    this.placeholder,
  });

  factory DisplayHint.fromJson(Map<String, dynamic> json) {
    return DisplayHint(
      isPrimary: json['isPrimary'] as bool? ?? false,
      isSecondary: json['isSecondary'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      width: json['width'] as int?,
      height: json['height'] as int?,
      placeholder: json['placeholder'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPrimary': isPrimary,
      'isSecondary': isSecondary,
      'isVisible': isVisible,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (placeholder != null) 'placeholder': placeholder,
    };
  }

  @override
  String toString() =>
      'DisplayHint(isPrimary: $isPrimary, isSecondary: $isSecondary, isVisible: $isVisible)';
}
