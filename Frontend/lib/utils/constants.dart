import 'package:flutter/material.dart';

/// App-wide design constants and theme tokens
class AppColors {
  // Brand colors (dynamically changeable by user in Settings)
  static Color _primary = const Color(0xFF059669);
  static Color get primary => _primary;
  static Color _primaryDark = const Color(0xFF047857);
  static Color get primaryDark => _primaryDark;
  static Color _primaryLight = const Color(0xFFD1FAE5);
  static Color get primaryLight => _primaryLight;

  static void setPrimary(Color c) {
    _primary = c;
    _primaryDark = Color.lerp(c, Colors.black, 0.25) ?? c;
    _primaryLight = Color.lerp(c, Colors.white, 0.75) ?? c;
  }

  static const Color defaultPrimary = Color(0xFF059669);

  static const List<Map<String, dynamic>> primaryPalette = [
    {'name': 'Emerald Green', 'hex': '#059669', 'color': Color(0xFF059669)},
    {'name': 'Royal Blue', 'hex': '#2563EB', 'color': Color(0xFF2563EB)},
    {'name': 'Deep Violet', 'hex': '#7C3AED', 'color': Color(0xFF7C3AED)},
    {'name': 'Sunset Orange', 'hex': '#EA580C', 'color': Color(0xFFEA580C)},
    {'name': 'Ruby Rose', 'hex': '#E11D48', 'color': Color(0xFFE11D48)},
    {'name': 'Teal Cyan', 'hex': '#0D9488', 'color': Color(0xFF0D9488)},
    {'name': 'Warm Amber', 'hex': '#D97706', 'color': Color(0xFFD97706)},
    {'name': 'Crimson Red', 'hex': '#DC2626', 'color': Color(0xFFDC2626)},
  ];

  static Color parseHex(String hex, [Color fallback = defaultPrimary]) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  static String toHex(Color c) {
    final r = ((c.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((c.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((c.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

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
