import 'package:flutter/material.dart';
import 'app.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (ApiService.isInsecureRemote) {
    debugPrint(
      '[ExpenseMate] WARNING: API_BASE_URL (${ApiService.baseUrl}) uses plain HTTP. '
      'Credentials and tokens are sent unencrypted. Use an https:// URL for production '
      '(--dart-define=API_BASE_URL=https://...).',
    );
  }
  runApp(const ExpenseMateApp());
}
