import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats double or num into INR currency representation (e.g. ₹5,00,000)
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Parses a currency string into double safely
  static double parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
