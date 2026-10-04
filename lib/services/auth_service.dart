import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    // Simulated authentication for demo, ready for Node.js backend
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = User(
        id: 'usr_01',
        name: 'Arham Syed',
        email: email,
        preferredCurrency: 'USD',
      );
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
