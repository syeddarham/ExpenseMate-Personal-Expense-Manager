import 'package:flutter/material.dart';

/// App-wide design constants and theme tokens
class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF10B981); // Emerald / Fresh Finance Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color accent = Color(0xFF6366F1); // Indigo Accent

  // Financial indicators
  static const Color income = Color(0xFF10B981); // Positive / Inflow Green
  static const Color expense = Color(0xFFEF4444); // Negative / Outflow Red
  static const Color warning = Color(0xFFF59E0B); // Budget Alert Amber

  // Neutrals & Backgrounds (Light Theme)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
}

class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withAlpha(10),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withAlpha(18),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
