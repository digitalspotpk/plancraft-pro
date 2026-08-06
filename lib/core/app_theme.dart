import 'package:flutter/material.dart';

/// PlanCraft Pro AI — Core color + theme system.
/// Dark base, neon cyan primary, neon purple secondary, glassmorphism everywhere.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF05050A);
  static const Color bgElevated = Color(0xFF0B0B14);
  static const Color cyan = Color(0xFF00F5FF);
  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFFF3EA5);
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFF9CA3C0);
  static const Color glassFill = Color(0x14FFFFFF); // white @ 8%
  static const Color glassBorder = Color(0x33FFFFFF); // white @ 20%
  static const Color success = Color(0xFF39FFB0);
  static const Color danger = Color(0xFFFF4D6D);

  static const LinearGradient cyanPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, purple],
  );

  static const List<Color> schemePalettes10Preview = [
    cyan,
    purple,
    pink,
    Color(0xFF39FFB0),
    Color(0xFFFFD23E),
    Color(0xFF3E8BFF),
    Color(0xFFFF6B3E),
    Color(0xFFB6FF3E),
    Color(0xFFFF3E6B),
    Color(0xFF7CFFF5),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData dark({Color accent = AppColors.cyan}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AppColors.purple,
        surface: AppColors.bgElevated,
        error: AppColors.danger,
      ),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  /// Neon glow box-shadow set, reused across glass cards / buttons.
  static List<BoxShadow> neonGlow(Color color, {double blur = 24, double spread = 0}) {
    return [
      BoxShadow(color: color.withOpacity(0.55), blurRadius: blur, spreadRadius: spread),
      BoxShadow(color: color.withOpacity(0.25), blurRadius: blur * 2, spreadRadius: spread),
    ];
  }
}
