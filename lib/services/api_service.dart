import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/user.dart';

class ApiService {
  // Configurable base URL for Node.js + Express backend
  static String baseUrl = 'http://localhost:5000/api';

  static String? _token;

  static String? get token => _token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static void setToken(String? token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------
  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Register new user account
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? currencyCode,
    String? currencySymbol,
    String? country,
  }) async {
    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (currencyCode != null && currencyCode.isNotEmpty) payload['currency_code'] = currencyCode;
      if (currencySymbol != null && currencySymbol.isNotEmpty) payload['currency_symbol'] = currencySymbol;
      if (country != null && country.isNotEmpty) payload['country'] = country;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] as String? ?? 'Registration successful',
          'debug_code': body['debug_code'] as String?,
          'email': email,
        };
      }
      return {
        'success': false,
        'error': body['error']?['message'] ?? body['message'] ?? 'Registration failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server: $e'};
    }
  }

  /// Verify 6-digit email code
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final token = body['token'] as String;
        setToken(token);
        final user = User.fromJson(body['user'] as Map<String, dynamic>);
        return {'success': true, 'token': token, 'user': user};
      }
      return {
        'success': false,
        'error': body['error']?['message'] ?? body['message'] ?? 'Verification failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server: $e'};
    }
  }

  /// Resend verification or reset code
  static Future<Map<String, dynamic>> resendCode({
    required String email,
    String purpose = 'email_verification',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/resend-code'),
        headers: _headers,
        body: jsonEncode({'email': email.trim().toLowerCase(), 'purpose': purpose}),
      );
      final body = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': body['message'] ?? 'Code sent',
        'debug_code': body['debug_code'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Sign in user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final token = body['token'] as String;
        setToken(token);
        final user = User.fromJson(body['user'] as Map<String, dynamic>);
        return {'success': true, 'token': token, 'user': user};
      }
      final errCode = body['error']?['code'] ?? '';
      return {
        'success': false,
        'needsVerification': errCode == 'EMAIL_NOT_VERIFIED',
        'error': body['error']?['message'] ?? body['message'] ?? 'Sign in failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server: $e'};
    }
  }

  /// Request forgot password reset code
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );
      final body = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': body['message'] ?? 'Reset instructions sent',
        'debug_code': body['debug_code'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Reset password with OTP code
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'new_password': newPassword,
        }),
      );
      final body = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': body['message'] ?? (res.statusCode == 200 ? 'Password reset successfully' : 'Reset failed'),
        'error': body['error']?['message'] ?? body['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  static Future<User?> getMe() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/me'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return User.fromJson(body['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<User?> updateMe({
    String? fullName,
    String? email,
    String? avatarUrl,
    String? primaryColor,
    String? country,
    String? currencyCode,
    String? currencySymbol,
    bool? darkMode,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) payload['full_name'] = fullName;
      if (email != null) payload['email'] = email;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
      if (primaryColor != null) payload['primary_color'] = primaryColor;
      if (country != null) payload['country'] = country;
      if (currencyCode != null) payload['currency_code'] = currencyCode;
      if (currencySymbol != null) payload['currency_symbol'] = currencySymbol;
      if (darkMode != null) payload['dark_mode'] = darkMode;

      final res = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return User.fromJson(body['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/me/password'),
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      final body = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': body['message'] ?? (res.statusCode == 200 ? 'Password updated' : 'Update failed'),
        'error': body['error']?['message'] ?? body['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> exportTransactions({
    String format = 'csv',
    bool sendEmail = true,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/transactions/export'),
        headers: _headers,
        body: jsonEncode({
          'format': format,
          'send_email': sendEmail,
        }),
      );
      final body = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': body['message'] ?? 'Export generated',
        'emailSent': body['emailSent'] == true,
        'filename': body['filename'],
        'base64': body['base64'],
        'recordCount': body['recordCount'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> convertCurrency({
    required String currencyCode,
    required String currencySymbol,
    required bool convertAmounts,
    double rate = 1.0,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/me/currency'),
        headers: _headers,
        body: jsonEncode({
          'currency_code': currencyCode,
          'currency_symbol': currencySymbol,
          'convert_amounts': convertAmounts,
          'rate': rate,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  static Future<List<Account>> getAccounts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/accounts'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List list = body['accounts'] ?? [];
        return list.map((item) => Account.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Account?> createAccount({
    required String name,
    required String type,
    double openingBalance = 0.0,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/accounts'),
        headers: _headers,
        body: jsonEncode({'name': name, 'type': type, 'opening_balance': openingBalance}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return Account.fromJson(body['account'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  static Future<List<TransactionCategory>> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List list = body['categories'] ?? [];
        return list.map((item) => TransactionCategory.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return TransactionCategory.defaultCategories;
  }

  static Future<TransactionCategory?> createCategory({
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'icon': icon,
          'color': color,
          'is_expense': isExpense,
        }),
      );
      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return TransactionCategory.fromJson(body['category'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<TransactionCategory?> updateCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'icon': icon,
          'color': color,
          'is_expense': isExpense,
        }),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return TransactionCategory.fromJson(body['category'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<({bool success, String? error})> deleteCategory(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return (success: true, error: null);
      }
      final body = jsonDecode(res.body);
      final msg = body['error']?['message']?.toString() ?? 'Failed to delete category';
      return (success: false, error: msg);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  static Future<List<FinancialTransaction>> getTransactions({
    String? type,
    String? categoryId,
    String? accountId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (type != null) params['type'] = type;
      if (categoryId != null) params['category_id'] = categoryId;
      if (accountId != null) params['account_id'] = accountId;

      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List list = body['transactions'] ?? [];
        return list.map((item) => FinancialTransaction.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<FinancialTransaction?> addTransaction(FinancialTransaction tx) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
        body: jsonEncode({
          'title': tx.title,
          'amount': tx.amount,
          'type': tx.type == TransactionType.income ? 'income' : 'expense',
          'category_id': tx.category.id,
          'account': tx.account,
          'date': tx.date.toIso8601String(),
          'note': tx.note,
          'receipt_url': tx.receiptUrl,
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['transaction'] != null) {
          return FinancialTransaction.fromJson(body['transaction'] as Map<String, dynamic>);
        }
        return tx;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteTransaction(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/transactions/$id'), headers: _headers);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  static Future<List<Budget>> getBudgets({String? month}) async {
    try {
      final uri = Uri.parse('$baseUrl/budgets').replace(
        queryParameters: month != null ? {'month': month} : null,
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List list = body['budgets'] ?? [];
        return list.map((item) => Budget.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> setBudget({
    required String categoryId,
    required double limitAmount,
    String? month,
  }) async {
    try {
      final payload = <String, dynamic>{'limit_amount': limitAmount};
      if (month != null) payload['month'] = month;
      final res = await http.put(
        Uri.parse('$baseUrl/budgets/$categoryId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Overview & Analytics
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> getOverview() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/overview'), headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['overview'] as Map<String, dynamic>? ?? body as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getAnalytics({String? month}) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics').replace(
        queryParameters: month != null ? {'month': month} : null,
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['analytics'] as Map<String, dynamic>? ?? body as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
