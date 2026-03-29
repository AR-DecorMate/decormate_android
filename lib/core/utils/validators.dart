class Validators {
  static final _emailRegex = RegExp(r'^[\w\-.+]+@[\w\-]+\.[\w\-.]+$');
  static final _phoneRegex = RegExp(r'^\+?[\d\s\-]{7,15}$');
  static final _dobRegex = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!_phoneRegex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? validateDob(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date of birth is required';
    final normalized = value.trim().replaceAll(' ', '');
    final match = _dobRegex.firstMatch(normalized);
    if (match == null) return 'Use dd/mm/yyyy';

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    if (month < 1 || month > 12) return 'Enter a valid date';

    final parsed = DateTime.tryParse(
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
    if (parsed == null || parsed.year != year || parsed.month != month || parsed.day != day) {
      return 'Enter a valid date';
    }
    if (parsed.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';

    return null;
  }
}
