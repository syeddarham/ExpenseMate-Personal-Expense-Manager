import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  /// Fetches the live exchange rate from [fromCurrency] to [toCurrency] using free public APIs.
  static Future<double?> getExchangeRate(String fromCurrency, String toCurrency) async {
    final from = fromCurrency.trim().toUpperCase();
    final to = toCurrency.trim().toUpperCase();

    if (from == to) return 1.0;

    // 1. Primary Free Public API: open.er-api.com (No API key needed)
    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/$from');
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final rate = data['rates'][to];
          if (rate != null) {
            return (rate as num).toDouble();
          }
        }
      }
    } catch (_) {}

    // 2. Secondary Free Public API: exchangerate-api.com v4
    try {
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$from');
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['rates'] != null && data['rates'][to] != null) {
          final rate = data['rates'][to];
          return (rate as num).toDouble();
        }
      }
    } catch (_) {}

    return null;
  }
}
