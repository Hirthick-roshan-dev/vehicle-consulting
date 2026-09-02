class Validators {
  static String? requiredField(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle number is required';
    }
    final cleaned = value.trim().toUpperCase();
    if (cleaned.length < 4) {
      return 'Enter a valid vehicle number';
    }
    return null;
  }

  static String? positiveAmount(String? value, [String fieldName = 'Amount']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numVal = double.tryParse(value.trim());
    if (numVal == null) {
      return 'Enter a valid numeric amount';
    }
    if (numVal < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? strictlyPositiveAmount(String? value, [String fieldName = 'Amount']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numVal = double.tryParse(value.trim());
    if (numVal == null) {
      return 'Enter a valid numeric amount';
    }
    if (numVal <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates that value contains exactly 10 numeric digits.
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = extract10Digits(value);
    if (digits.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Extracts the 10-digit base phone number without prefix/formatting.
  static String extract10Digits(String? value) {
    if (value == null) return '';
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Formats a 10-digit phone number with Indian country code (+91 XXXXXXXXXX).
  static String formatIndianPhone(String? value) {
    final digits = extract10Digits(value);
    if (digits.isEmpty) return '';
    return '+91 $digits';
  }

  static String? year(String? value, [String fieldName = 'Year']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final y = int.tryParse(value.trim());
    if (y == null || y < 1900 || y > DateTime.now().year + 1) {
      return 'Enter a valid year';
    }
    return null;
  }

  static String? validatePayment({
    required double advancePaid,
    required double totalSaleAmount,
  }) {
    if (totalSaleAmount <= 0) {
      return 'Total sale amount must be greater than 0';
    }
    if (advancePaid < 0) {
      return 'Advance payment cannot be negative';
    }
    if (advancePaid > totalSaleAmount) {
      return 'Advance payment (₹$advancePaid) cannot exceed total sale amount (₹$totalSaleAmount)';
    }
    return null;
  }
}
