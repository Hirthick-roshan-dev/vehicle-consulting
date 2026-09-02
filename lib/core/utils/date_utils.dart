import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Formats DateTime or ISO string for user UI display (e.g. 05 Sep 2026)
  static String formatDisplay(dynamic date) {
    if (date == null) return '-';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date);
    }
    if (dt == null) return '-';
    return _displayFormat.format(dt);
  }

  /// Formats DateTime to ISO String (yyyy-MM-dd) for SQLite storage
  static String toIso(DateTime dt) {
    return _isoFormat.format(dt);
  }

  /// Parses ISO String to DateTime safely
  static DateTime parseIso(String isoString) {
    return DateTime.tryParse(isoString) ?? DateTime.now();
  }
}
