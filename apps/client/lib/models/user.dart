import 'package:flutter/foundation.dart';

/// OAuth-enabled User model for À la carte authentication
class User {
  final int? id;
  final String googleId;
  final String email;
  final String fullName;
  final String displayName;
  final String avatar;
  final bool discoverable;
  final bool profileCompleted; // Explicit profile completion flag
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    this.id,
    required this.googleId,
    required this.email,
    required this.fullName,
    required this.displayName,
    required this.avatar,
    this.discoverable = true,
    this.profileCompleted = false,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (backend returns snake_case)
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['ID'] as int?,
        googleId: (json['google_id'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        fullName: (json['full_name'] as String?) ?? '',
        displayName: (json['display_name'] as String?) ?? '',
        avatar: (json['avatar'] as String?) ?? '',
        discoverable: (json['discoverable'] as bool?) ?? true,
        profileCompleted: (json['profile_completed'] as bool?) ?? false,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'] as String)
            : null,
        createdAt: json['CreatedAt'] != null
            ? DateTime.tryParse(json['CreatedAt'] as String)
            : null,
        updatedAt: json['UpdatedAt'] != null
            ? DateTime.tryParse(json['UpdatedAt'] as String)
            : null,
      );
    } catch (e) {
      if (kDebugMode) print('Error parsing User JSON: $e');
      rethrow;
    }
  }

  /// Convert to JSON (backend expects snake_case)
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'google_id': googleId,
      'email': email,
      'full_name': fullName,
      'display_name': displayName,
      'avatar': avatar,
      'discoverable': discoverable,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields updated
  User copyWith({
    int? id,
    String? googleId,
    String? email,
    String? fullName,
    String? displayName,
    String? avatar,
    bool? discoverable,
    bool? profileCompleted,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      discoverable: discoverable ?? this.discoverable,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName);

  @override
  String toString() =>
      'User(id: $id, email: $email, displayName: $displayName)';
}

/// Extension for User convenience methods
extension UserExtension on User {
  /// UI display name (fallback to email if no display name)
  String get uiDisplayName => displayName.isNotEmpty ? displayName : email;

  /// Check if user is new (no ID)
  bool get isNew => id == null;

  /// Check if profile setup is complete (uses explicit flag)
  bool get hasCompletedSetup => profileCompleted;

  /// Check if user needs profile setup (uses explicit flag)
  bool get needsProfileSetup => !profileCompleted;

  /// Get first name from full name
  String get firstName {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Get initials from display name or full name
  String get initials {
    final name = displayName.isNotEmpty ? displayName : fullName;
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
