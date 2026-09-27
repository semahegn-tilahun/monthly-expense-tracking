class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? positiveAmount(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return '$label must be greater than zero';
    return null;
  }

  static String? nonNegativeAmount(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null) return 'Enter a valid number';
    if (amount < 0) return '$label cannot be negative';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.trim().length < 4) return 'PIN must be at least 4 digits';
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'PIN must contain digits only';
    return null;
  }
}
