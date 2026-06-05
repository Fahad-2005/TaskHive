import 'package:flutter/material.dart';

/// Brand and semantic colors used across TaskHive.
class AppColors {
  AppColors._();

  static const Color brandPrimary = Color(0xFF6366F1);
  static const Color brandSecondary = Color(0xFF8B5CF6);
  static const Color hiveAccent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Light surfaces — cool slate, no brown tint
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark surfaces — deep blue-gray, not muddy olive
  static const Color darkBackground = Color(0xFF0B0D14);
  static const Color darkSurface = Color(0xFF141820);
  static const Color darkSurfaceElevated = Color(0xFF1C2230);
  static const Color darkBorder = Color(0xFF2A3142);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color cardBackground(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static BoxDecoration pageDecoration(BuildContext context) {
    final isDarkMode = isDark(context);
    return BoxDecoration(
      color: pageBackground(context),
      gradient: isDarkMode
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEEF2FF),
                AppColors.lightBackground,
              ],
              stops: [0.0, 0.35],
            ),
    );
  }
}
