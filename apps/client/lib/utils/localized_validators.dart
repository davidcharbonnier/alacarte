import 'package:flutter/material.dart';
import 'localization_utils.dart';

/// Form validation helper functions with localization support
class LocalizedValidators {
  /// Validate user name with localized error messages
  static String? validateUserName(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.nameRequired;
    }
    
    if (value.trim().length < 2) {
      return context.l10n.nameMinLength;
    }
    
    if (value.trim().length > 50) {
      return context.l10n.nameMaxLength;
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return context.l10n.nameInvalidCharacters;
    }
    
    return null; // Valid
  }
  
  /// Create a validator function that can be used with TextFormField
  static String? Function(String?) createUserNameValidator(BuildContext context) {
    return (String? value) => validateUserName(context, value);
  }
}
