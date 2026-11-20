class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^[0-9]{10,15}$',
  );

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Sign-in only checks presence; existing backend passwords predate the
  /// 8-character rule.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int minLength, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int maxLength, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
