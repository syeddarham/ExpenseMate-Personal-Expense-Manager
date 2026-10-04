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
          final isDark = expenseState.isDarkMode;
          final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
          final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

          return MaterialApp(
            title: 'ExpenseMate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: isDark ? Brightness.dark : Brightness.light,
                primary: AppColors.primary,
                surface: isDark ? AppColors.darkSurface : AppColors.surface,
              ),
              textTheme: textTheme.apply(
                bodyColor: isDark ? Colors.white : AppColors.textPrimary,
                displayColor: isDark ? Colors.white : AppColors.textPrimary,
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
