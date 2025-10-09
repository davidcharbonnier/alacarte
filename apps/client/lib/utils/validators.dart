/// Form validation helper functions
class Validators {
  /// Validate user name
  static String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null; // Valid
  }
  
  /// Validate cheese name
  static String? validateCheeseName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cheese name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Cheese name must be at least 2 characters';
    }
    
    if (value.trim().length > 100) {
      return 'Cheese name must be less than 100 characters';
    }
    
    return null; // Valid
  }
  
  /// Validate rating grade
  static String? validateRatingGrade(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rating is required';
    }
    
    final grade = double.tryParse(value);
    if (grade == null) {
      return 'Please enter a valid number';
    }
    
    if (grade < 0.0 || grade > 5.0) {
      return 'Rating must be between 0 and 5';
    }
    
    return null; // Valid
  }
  
  /// Validate rating note
  static String? validateRatingNote(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Note is required';
    }
    
    if (value.trim().length < 3) {
      return 'Note must be at least 3 characters';
    }
    
    if (value.trim().length > 1000) {
      return 'Note must be less than 1000 characters';
    }
    
    return null; // Valid
  }
  
  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }
  
  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }
  
  /// Combine multiple validators
  static String? combineValidators(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
