import 'package:flutter/material.dart';

/// Constants for consistent styling and configuration
class AppConstants {
  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color secondaryColor = Colors.purple;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;

  // Rating-specific colors for clear visual identity
  static const Color personalRatingColor =
      Colors.deepPurple; // Blue for personal ratings
  static const Color recommendationColor =
      Colors.green; // Green for friend recommendations
  static const Color communityRatingColor =
      Colors.orange; // Orange for community/public ratings

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double radiusXS = 2.0;
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  // Icon sizes
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Font sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;

  // Strings
  static const String appName = 'À la carte';
  static const String selectProfile = 'Welcome to À la carte';
  static const String createProfile = 'Create New Profile';
  static const String editProfile = 'Edit Profile';
  static const String deleteProfile = 'Delete Profile';
  static const String noProfilesMessage =
      'No profiles found. Create your first profile to get started!';
  static const String nameRequired = 'Name is required';
  static const String nameHint = 'Enter your name';
  static const String searchHint = 'Search profiles...';

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Layout
  static const double maxContentWidth = 600.0;
  static const EdgeInsets screenPadding = EdgeInsets.all(spacingM);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingM);
}
