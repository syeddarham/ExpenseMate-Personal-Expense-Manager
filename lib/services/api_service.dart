import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/budget.dart';

class ApiService {
  // Configurable base URL for Node.js + Express backend
  static const String baseUrl = 'http://localhost:5000/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  /// Fetch overview metrics
  static Future<Map<String, dynamic>> getOverview() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/overview'), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'totalBalance': 4850.50,
      'totalIncome': 6200.00,
      'totalExpense': 1349.50,
    };
  }

  /// Fetch transactions
  static Future<List<FinancialTransaction>> getTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => FinancialTransaction.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Add a new transaction
  static Future<bool> addTransaction(FinancialTransaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
        body: jsonEncode(transaction.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch budgets
  static Future<List<Budget>> getBudgets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/budgets'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Budget.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
