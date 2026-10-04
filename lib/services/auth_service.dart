import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  void setUser(User user, [String? token]) {
    _currentUser = user;
    _isAuthenticated = true;
    if (token != null) {
      ApiService.setToken(token);
    }
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Real backend registration
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? currencyCode,
    String? currencySymbol,
    String? country,
  }) async {
    return await ApiService.register(
      fullName: fullName,
      email: email,
      password: password,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      country: country,
    );
  }

  /// Real backend email verification
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final result = await ApiService.verifyEmail(email: email, code: code);
    if (result['success'] == true && result['user'] != null) {
      setUser(result['user'] as User, result['token'] as String?);
    }
    return result;
  }

  /// Real backend login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiService.login(email: email, password: password);
    if (result['success'] == true && result['user'] != null) {
      setUser(result['user'] as User, result['token'] as String?);
    }
    return result;
  }

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await ApiService.forgotPassword(email);
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await ApiService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  /// Refresh user profile from backend
  Future<void> refreshProfile() async {
    if (!ApiService.hasToken) return;
    final user = await ApiService.getMe();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    ApiService.clearToken();
    notifyListeners();
  }
}
