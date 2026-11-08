import 'dart:convert';

import 'package:expense_mate/models/category.dart';
import 'package:expense_mate/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Unit tests for the rewritten ApiService (Assignment 02, Part C).
/// A MockClient stands in for the network, so no backend is needed.
void main() {
  late List<http.Request> requests;

  /// Routes every request to [handler] and records it.
  void respondWith(http.Response Function(http.Request request) handler) {
    ApiService.httpClient = MockClient((request) async {
      requests.add(request);
      return handler(request);
    });
  }

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  Map<String, dynamic> sentBody(int i) => jsonDecode(requests[i].body) as Map<String, dynamic>;

  const user = {
    'id': '7',
    'name': 'Test User',
    'email': 'test@example.com',
    'preferred_currency': 'USD',
    'currency_symbol': '\$',
    'email_verified': true,
  };

  setUp(() {
    requests = [];
    ApiService.baseUrl = 'http://localhost:5000';
    ApiService.clearToken();
  });

  group('configuration', () {
    test('baseUrl is normalised to end in /api', () {
      ApiService.baseUrl = 'https://api.example.com/';
      expect(ApiService.baseUrl, 'https://api.example.com/api');
    });

    test('isInsecureRemote flags plain HTTP to remote hosts only', () {
      ApiService.baseUrl = 'http://localhost:5000/api';
      expect(ApiService.isInsecureRemote, isFalse);
      ApiService.baseUrl = 'https://api.example.com/api';
      expect(ApiService.isInsecureRemote, isFalse);
      ApiService.baseUrl = 'http://203.0.113.10:5000/api';
      expect(ApiService.isInsecureRemote, isTrue);
    });
  });

  group('authentication', () {
    test('register normalises the e-mail and reports success', () async {
      respondWith((_) => json({'message': 'Account created.', 'email': 'a@b.com'}, 201));
      final result = await ApiService.register(fullName: 'A', email: '  A@B.com ', password: 'Secret123!');

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/auth/register');
      expect(sentBody(0)['email'], 'a@b.com');
      expect(sentBody(0).containsKey('currency_code'), isFalse, reason: 'optional fields are omitted');
      expect(result['success'], isTrue);
      expect(result['message'], 'Account created.');
    });

    test('register surfaces the backend error message', () async {
      respondWith((_) => json({
            'error': {'message': 'An account with this email already exists', 'code': 'EMAIL_TAKEN'}
          }, 409));
      final result = await ApiService.register(fullName: 'A', email: 'a@b.com', password: 'Secret123!');
      expect(result['success'], isFalse);
      expect(result['error'], 'An account with this email already exists');
    });

    test('login stores the token and later requests send it', () async {
      respondWith((request) => request.url.path.endsWith('/login')
          ? json({'token': 'jwt-123', 'user': user})
          : json({'user': user}));

      final result = await ApiService.login(email: 'test@example.com', password: 'x');
      expect(result['success'], isTrue);
      expect(ApiService.token, 'jwt-123');
      expect(requests[0].headers.containsKey('Authorization'), isFalse);

      final me = await ApiService.getMe();
      expect(me?.name, 'Test User');
      expect(requests[1].headers['Authorization'], 'Bearer jwt-123');
    });

    test('login reports unverified accounts so the app can open the OTP screen', () async {
      respondWith((_) => json({
            'error': {'message': 'Please verify your email to continue', 'code': 'EMAIL_NOT_VERIFIED'}
          }, 403));
      final result = await ApiService.login(email: 'a@b.com', password: 'x');
      expect(result['success'], isFalse);
      expect(result['needsVerification'], isTrue);
      expect(ApiService.hasToken, isFalse);
    });

    test('a network failure becomes a friendly error, never an exception', () async {
      respondWith((_) => throw http.ClientException('Connection refused'));
      final result = await ApiService.login(email: 'a@b.com', password: 'x');
      expect(result['success'], isFalse);
      expect(result['error'], startsWith('Could not connect to server'));
    });
  });

  group('data endpoints', () {
    test('getAccounts parses the list; errors and bad JSON give an empty list', () async {
      respondWith((_) => json({
            'accounts': [
              {'id': 1, 'name': 'Cash', 'type': 'cash', 'opening_balance': 10, 'balance': 4.5}
            ]
          }));
      final accounts = await ApiService.getAccounts();
      expect(accounts.single.name, 'Cash');
      expect(accounts.single.balance, 4.5);

      respondWith((_) => json({'error': {'message': 'boom'}}, 500));
      expect(await ApiService.getAccounts(), isEmpty);

      respondWith((_) => http.Response('<html>proxy error</html>', 502));
      expect(await ApiService.getAccounts(), isEmpty);
    });

    test('getCategories falls back to the built-in defaults when offline', () async {
      respondWith((_) => throw http.ClientException('offline'));
      expect(await ApiService.getCategories(), TransactionCategory.defaultCategories);
    });

    test('getTransactions sends filters as query parameters', () async {
      respondWith((_) => json({'transactions': []}));
      await ApiService.getTransactions(type: 'expense', categoryId: '4', limit: 20);
      expect(requests.single.url.queryParameters, {
        'limit': '20',
        'offset': '0',
        'type': 'expense',
        'category_id': '4',
      });
    });

    test('getBudgets only adds ?month= when a month is given', () async {
      respondWith((_) => json({'budgets': []}));
      await ApiService.getBudgets();
      await ApiService.getBudgets(month: '2026-11');
      expect(requests[0].url.hasQuery, isFalse);
      expect(requests[1].url.queryParameters, {'month': '2026-11'});
    });

    test('updateMe sends the currency as preferred_currency (defect D4)', () async {
      respondWith((_) => json({'user': user}));
      await ApiService.updateMe(currencyCode: 'EUR', currencySymbol: '€');
      expect(sentBody(0), {'preferred_currency': 'EUR', 'currency_symbol': '€'});
    });

    test('deleteCategory returns the backend reason when deletion is refused', () async {
      respondWith((_) => json({
            'error': {'message': 'Cannot delete "Food" because it is linked to 3 transaction(s).', 'code': 'CATEGORY_IN_USE'}
          }, 400));
      final result = await ApiService.deleteCategory('5');
      expect(requests.single.method, 'DELETE');
      expect(result.success, isFalse);
      expect(result.error, contains('linked to 3 transaction'));
    });

    test('exportTransactions maps the export fields', () async {
      respondWith((_) => json({
            'message': 'Export successfully generated',
            'emailSent': false,
            'filename': 'ExpenseMate_Transactions_2026-11-08.csv',
            'base64': 'SUQ=',
            'recordCount': 3,
          }));
      final result = await ApiService.exportTransactions(sendEmail: false);
      expect(sentBody(0), {'format': 'csv', 'send_email': false});
      expect(result['success'], isTrue);
      expect(result['emailSent'], isFalse);
      expect(result['recordCount'], 3);
      expect(result['filename'], endsWith('.csv'));
    });
  });
}
