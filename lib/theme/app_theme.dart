import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final generated = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
    );

    final scheme = generated.copyWith(
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: AppColors.hiveAccent,
      surface: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      onSurface: isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      onSurfaceVariant:
          isLight ? AppColors.lightTextSecondary : AppColors.darkTextSecondary,
      surfaceContainerLowest:
          isLight ? AppColors.lightSurface : AppColors.darkSurface,
      surfaceContainerLow:
          isLight ? AppColors.lightSurfaceElevated : AppColors.darkSurfaceElevated,
      surfaceContainer: isLight
          ? AppColors.lightSurfaceElevated
          : AppColors.darkSurfaceElevated,
      surfaceContainerHigh: isLight
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF252D3D),
      surfaceContainerHighest: isLight
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF2A3142),
      outline: isLight ? AppColors.lightBorder : AppColors.darkBorder,
      outlineVariant: isLight
          ? AppColors.lightBorder
          : AppColors.darkBorder.withValues(alpha: 0.7),
      primaryContainer: isLight
          ? const Color(0xFFEEF2FF)
          : const Color(0xFF1E1B4B),
      onPrimaryContainer:
          isLight ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE),
      secondaryContainer: isLight
          ? const Color(0xFFF5F3FF)
          : const Color(0xFF2E1065),
      onSecondaryContainer:
          isLight ? const Color(0xFF5B21B6) : const Color(0xFFDDD6FE),
      tertiaryContainer: isLight
          ? const Color(0xFFFFFBEB)
          : const Color(0xFF422006),
      onTertiaryContainer:
          isLight ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.lightSurfaceElevated
            : AppColors.darkSurfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.lightTextPrimary : AppColors.darkSurfaceElevated,
        contentTextStyle: TextStyle(color: isLight ? Colors.white : scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
