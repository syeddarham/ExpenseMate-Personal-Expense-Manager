import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/onboarding/splash_page.dart';
import 'services/expense_state.dart';
import 'utils/constants.dart';

class ExpenseMateApp extends StatelessWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseState(),
      child: Consumer<ExpenseState>(
        builder: (context, expenseState, _) {
          final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

          return MaterialApp(
            title: 'ExpenseMate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
                primary: AppColors.primary,
                surface: AppColors.surface,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: const CardThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              textTheme: textTheme.apply(
                bodyColor: AppColors.textPrimary,
                displayColor: AppColors.textPrimary,
                fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Noto Sans', 'Arial', 'sans-serif'],
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
