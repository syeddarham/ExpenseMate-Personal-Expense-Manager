import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/user.dart';

/// HTTP status and decoded JSON body of one API call.
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;

  const ApiResponse(this.statusCode, this.body);

  bool get ok => statusCode >= 200 && statusCode < 300;

  /// The backend's error message (`{"error": {"message": ...}}`), or a plain `message`.
  String? get errorMessage {
    final error = body['error'];
    if (error is Map && error['message'] != null) return error['message'].toString();
    return body['message']?.toString();
  }

  /// Machine-readable error code such as `EMAIL_NOT_VERIFIED`.
  String? get errorCode {
    final error = body['error'];
    return error is Map ? error['code']?.toString() : null;
  }

  dynamic operator [](String key) => body[key];
}

/// No HTTP response was received (offline, DNS failure, timeout).
class ApiConnectionException implements Exception {
  final Object cause;
  const ApiConnectionException(this.cause);

  @override
  String toString() => cause.toString();
}

/// Client for the ExpenseMate REST API (Node.js + Express backend).
///
/// Rewritten in Assignment 02: every endpoint goes through [_send], which
/// builds the request, attaches the token, applies a timeout and decodes
/// JSON in one place. The public methods keep their Assignment 01
/// signatures and result shapes, so callers did not change.
class ApiService {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Base URL for the backend, set at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api
  /// Production builds should always use an https:// URL so tokens and
  /// passwords are encrypted in transit.
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://213.136.94.160:5000/api',
  );

  static const Duration _timeout = Duration(seconds: 60);
  static const Duration _healthTimeout = Duration(seconds: 3);

  static String _baseUrl = _defaultBaseUrl;
  static String? _token;
  static http.Client _client = http.Client();

  static String get baseUrl => _baseUrl;
  static set baseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) trimmed = trimmed.substring(0, trimmed.length - 1);
    if (!trimmed.endsWith('/api')) trimmed = '$trimmed/api';
    _baseUrl = trimmed;
  }

  /// True when requests go over unencrypted HTTP to a non-local host.
  static bool get isInsecureRemote {
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null || uri.scheme != 'http') return false;
    return !const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  /// Replaces the HTTP client; tests pass a `MockClient`.
  @visibleForTesting
  static set httpClient(http.Client client) => _client = client;

  static String? get token => _token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static void setToken(String? token) => _token = token;
  static void clearToken() => _token = null;

  // ---------------------------------------------------------------------------
  // Core request pipeline
  // ---------------------------------------------------------------------------

  /// Sends one request. Throws [ApiConnectionException] when no response arrives;
  /// any HTTP status (including 4xx/5xx) is returned as an [ApiResponse].
  static Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Duration timeout = _timeout,
  }) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);

    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers.addAll(hasToken ? {'Authorization': 'Bearer $_token'} : const {});
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed).timeout(timeout);
      return ApiResponse(response.statusCode, _decode(response.body));
    } on TimeoutException catch (e) {
      throw ApiConnectionException(e);
    } on http.ClientException catch (e) {
      throw ApiConnectionException(e);
    }
  }

  static Map<String, dynamic> _decode(String text) {
    if (text.isEmpty) return {};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      return {'raw': text};
    }
  }

  /// For data endpoints: `onSuccess(response)` on 2xx, otherwise [fallback].
  /// Never throws, so screens can show cached data when offline.
  static Future<T> _fetch<T>(Future<ApiResponse> Function() request, T Function(ApiResponse) onSuccess, T fallback) async {
    try {
      final res = await request();
      return res.ok ? onSuccess(res) : fallback;
    } catch (e) {
      debugPrint('[ApiService] request failed: $e');
      return fallback;
    }
  }

  /// For action endpoints used by forms: always a `{success, message, error, ...}` map.
  static Future<Map<String, dynamic>> _outcome(
    Future<ApiResponse> Function() request, {
    required String successMessage,
    required String failureMessage,
    String networkPrefix = 'Network error',
    Map<String, dynamic> Function(ApiResponse res)? extra,
  }) async {
    try {
      final res = await request();
      return {
        'success': res.ok,
        'message': res['message'] ?? (res.ok ? successMessage : failureMessage),
        if (!res.ok) 'error': res.errorMessage ?? failureMessage,
        if (!res.ok) 'code': res.errorCode,
        ...?extra?.call(res),
      };
    } catch (e) {
      return {'success': false, 'error': '$networkPrefix: $e'};
    }
  }

  static List<T> _list<T>(ApiResponse res, String key, T Function(Map<String, dynamic>) fromJson) {
    final items = res[key];
    if (items is! List) return <T>[];
    return items.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  static Future<bool> checkHealth() =>
      _fetch(() => _send('GET', '/health', timeout: _healthTimeout), (_) => true, false);

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
  }) {
    return _outcome(
      () => _send('POST', '/auth/register', body: {
        'full_name': fullName,
        'email': _normaliseEmail(email),
        'password': password,
        if (currencyCode != null && currencyCode.isNotEmpty) 'currency_code': currencyCode,
        if (currencySymbol != null && currencySymbol.isNotEmpty) 'currency_symbol': currencySymbol,
        if (country != null && country.isNotEmpty) 'country': country,
      }),
      successMessage: 'Registration successful',
      failureMessage: 'Registration failed',
      networkPrefix: 'Could not connect to server',
      extra: (res) => res.ok ? {'debug_code': res['debug_code'], 'email': email} : {},
    );
  }

  /// Verify 6-digit email code; stores the token on success.
  static Future<Map<String, dynamic>> verifyEmail({required String email, required String code}) {
    return _signIn(
      () => _send('POST', '/auth/verify-email', body: {'email': _normaliseEmail(email), 'code': code.trim()}),
      failureMessage: 'Verification failed',
    );
  }

  /// Resend verification or reset code
  static Future<Map<String, dynamic>> resendCode({required String email, String purpose = 'email_verification'}) {
    return _outcome(
      () => _send('POST', '/auth/resend-code', body: {'email': _normaliseEmail(email), 'purpose': purpose}),
      successMessage: 'Code sent',
      failureMessage: 'Could not send code',
      extra: (res) => {'debug_code': res['debug_code']},
    );
  }

  /// Sign in user; stores the token on success.
  static Future<Map<String, dynamic>> login({required String email, required String password}) {
    return _signIn(
      () => _send('POST', '/auth/login', body: {'email': _normaliseEmail(email), 'password': password}),
      failureMessage: 'Sign in failed',
    );
  }

  /// Request forgot password reset code
  static Future<Map<String, dynamic>> forgotPassword(String email) {
    return _outcome(
      () => _send('POST', '/auth/forgot-password', body: {'email': _normaliseEmail(email)}),
      successMessage: 'Reset instructions sent',
      failureMessage: 'Could not send reset code',
      extra: (res) => {'debug_code': res['debug_code']},
    );
  }

  /// Reset password with OTP code
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _outcome(
      () => _send('POST', '/auth/reset-password', body: {
        'email': _normaliseEmail(email),
        'code': code.trim(),
        'new_password': newPassword,
      }),
      successMessage: 'Password reset successfully',
      failureMessage: 'Reset failed',
    );
  }

  /// Shared by login and e-mail verification: both return `{token, user}`.
  static Future<Map<String, dynamic>> _signIn(Future<ApiResponse> Function() request, {required String failureMessage}) async {
    try {
      final res = await request();
      if (res.ok) {
        final token = res['token'] as String;
        setToken(token);
        return {'success': true, 'token': token, 'user': User.fromJson(res['user'] as Map<String, dynamic>)};
      }
      return {
        'success': false,
        'needsVerification': res.errorCode == 'EMAIL_NOT_VERIFIED',
        'code': res.errorCode,
        'error': res.errorMessage ?? failureMessage,
      };
    } catch (e) {
      return {'success': false, 'error': 'Could not connect to server: $e'};
    }
  }

  static String _normaliseEmail(String email) => email.trim().toLowerCase();

  // ---------------------------------------------------------------------------
  // User profile
  // ---------------------------------------------------------------------------

  static User _user(ApiResponse res) => User.fromJson(res['user'] as Map<String, dynamic>);

  static Future<User?> getMe() => _fetch(() => _send('GET', '/users/me'), _user, null);

  static Future<User?> updateMe({
    String? fullName,
    String? email,
    String? avatarUrl,
    String? primaryColor,
    String? country,
    String? currencyCode,
    String? currencySymbol,
    bool? darkMode,
  }) {
    return _fetch(
      () => _send('PUT', '/users/me', body: {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (primaryColor != null) 'primary_color': primaryColor,
        if (country != null) 'country': country,
        // The backend field is `preferred_currency`; Assignment 01 sent
        // `currency_code`, which the API ignored (defect D4).
        if (currencyCode != null) 'preferred_currency': currencyCode,
        if (currencySymbol != null) 'currency_symbol': currencySymbol,
        if (darkMode != null) 'dark_mode': darkMode,
      }),
      _user,
      null,
    );
  }

  static Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword}) {
    return _outcome(
      () => _send('PUT', '/users/me/password', body: {'current_password': currentPassword, 'new_password': newPassword}),
      successMessage: 'Password updated',
      failureMessage: 'Update failed',
    );
  }

  static Future<Map<String, dynamic>> exportTransactions({String format = 'csv', bool sendEmail = true}) {
    return _outcome(
      () => _send('POST', '/transactions/export', body: {'format': format, 'send_email': sendEmail}),
      successMessage: 'Export generated',
      failureMessage: 'Export failed',
      extra: (res) => {
        'emailSent': res['emailSent'] == true,
        'filename': res['filename'],
        'base64': res['base64'],
        'recordCount': res['recordCount'],
      },
    );
  }

  static Future<bool> convertCurrency({
    required String currencyCode,
    required String currencySymbol,
    required bool convertAmounts,
    double rate = 1.0,
  }) {
    return _fetch(
      () => _send('PUT', '/users/me/currency', body: {
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'convert_amounts': convertAmounts,
        'rate': rate,
      }),
      (_) => true,
      false,
    );
  }

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  static Account _account(ApiResponse res) => Account.fromJson(res['account'] as Map<String, dynamic>);

  static Future<List<Account>> getAccounts() =>
      _fetch(() => _send('GET', '/accounts'), (res) => _list(res, 'accounts', Account.fromJson), <Account>[]);

  static Future<Account?> createAccount({required String name, required String type, double openingBalance = 0.0}) {
    return _fetch(
      () => _send('POST', '/accounts', body: {'name': name, 'type': type, 'opening_balance': openingBalance}),
      _account,
      null,
    );
  }

  static Future<Account?> updateAccount({required String id, String? name, String? type, double? openingBalance}) {
    return _fetch(
      () => _send('PUT', '/accounts/$id', body: {
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (openingBalance != null) 'opening_balance': openingBalance,
      }),
      _account,
      null,
    );
  }

  static Future<bool> deleteAccount(String id) => _fetch(() => _send('DELETE', '/accounts/$id'), (_) => true, false);

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  static TransactionCategory _category(ApiResponse res) =>
      TransactionCategory.fromJson(res['category'] as Map<String, dynamic>);

  static Future<List<TransactionCategory>> getCategories() => _fetch(
        () => _send('GET', '/categories'),
        (res) => _list(res, 'categories', TransactionCategory.fromJson),
        TransactionCategory.defaultCategories,
      );

  static Future<TransactionCategory?> createCategory({
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) {
    return _fetch(
      () => _send('POST', '/categories', body: {'name': name, 'icon': icon, 'color': color, 'is_expense': isExpense}),
      _category,
      null,
    );
  }

  static Future<TransactionCategory?> updateCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
    required bool isExpense,
  }) {
    return _fetch(
      () => _send('PUT', '/categories/$id', body: {'name': name, 'icon': icon, 'color': color, 'is_expense': isExpense}),
      _category,
      null,
    );
  }

  static Future<({bool success, String? error})> deleteCategory(String id) async {
    try {
      final res = await _send('DELETE', '/categories/$id');
      return res.ok
          ? (success: true, error: null)
          : (success: false, error: res.errorMessage ?? 'Failed to delete category');
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
  }) {
    return _fetch(
      () => _send('GET', '/transactions', query: {
        'limit': '$limit',
        'offset': '$offset',
        if (type != null) 'type': type,
        if (categoryId != null) 'category_id': categoryId,
        if (accountId != null) 'account_id': accountId,
      }),
      (res) => _list(res, 'transactions', FinancialTransaction.fromJson),
      <FinancialTransaction>[],
    );
  }

  static Future<FinancialTransaction?> addTransaction(FinancialTransaction tx) {
    return _fetch(
      () => _send('POST', '/transactions', body: {
        'title': tx.title,
        'amount': tx.amount,
        'type': tx.type == TransactionType.income ? 'income' : 'expense',
        'category_id': tx.category.id,
        'account': tx.account,
        'date': tx.date.toIso8601String(),
        'note': tx.note,
        'receipt_url': tx.receiptUrl,
      }),
      (res) => res['transaction'] is Map<String, dynamic>
          ? FinancialTransaction.fromJson(res['transaction'] as Map<String, dynamic>)
          : tx,
      null,
    );
  }

  static Future<bool> deleteTransaction(String id) =>
      _fetch(() => _send('DELETE', '/transactions/$id'), (_) => true, false);

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  static Future<List<Budget>> getBudgets({String? month}) {
    return _fetch(
      () => _send('GET', '/budgets', query: {if (month != null) 'month': month}),
      (res) => _list(res, 'budgets', Budget.fromJson),
      <Budget>[],
    );
  }

  static Future<bool> setBudget({required String categoryId, required double limitAmount, String? month}) {
    return _fetch(
      () => _send('PUT', '/budgets/$categoryId', body: {
        'limit_amount': limitAmount,
        if (month != null) 'month': month,
      }),
      (_) => true,
      false,
    );
  }

  // ---------------------------------------------------------------------------
  // Overview & Analytics
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> getOverview() => _fetch(
        () => _send('GET', '/overview'),
        (res) => res['overview'] as Map<String, dynamic>? ?? res.body,
        null,
      );

  static Future<Map<String, dynamic>?> getAnalytics({String? month}) => _fetch(
        () => _send('GET', '/analytics', query: {if (month != null) 'month': month}),
        (res) => res['analytics'] as Map<String, dynamic>? ?? res.body,
        null,
      );
}
