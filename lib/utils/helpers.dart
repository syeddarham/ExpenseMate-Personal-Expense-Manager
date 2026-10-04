import 'package:intl/intl.dart';

class AppHelpers {
  /// Format a double amount into currency string e.g. "$1,250.00"
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format DateTime into readable string e.g. "Oct 24, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format DateTime into time string e.g. "02:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Format relative or friendly date
  static String formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today, ${formatTime(date)}';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${formatTime(date)}';
    } else {
      return formatDate(date);
    }
  }
}
