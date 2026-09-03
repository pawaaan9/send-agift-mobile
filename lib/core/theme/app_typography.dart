import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale shared across the app.
///
/// `display` is Fraunces (the web's `font-display`) and is reserved for hero
/// and section headings; everything else uses Geist.
class AppTypography {
  AppTypography._();

  static const String displayFamily = 'Fraunces';
  static const String sansFamily = 'Geist';

  /// Fraunces heading. Sizes stay tight and tracking slightly negative to
  /// match the web's `tracking-tight` display treatment.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.foreground,
    double height = 1.12,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.4,
    );
  }

  /// Uppercase eyebrow label above hero and section titles.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: sansFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedForeground,
    letterSpacing: 1.9,
    height: 1.2,
  );

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: displayFamily,
          fontSize: 40,
          fontWeight: FontWeight.w600,
          height: 1.08,
          letterSpacing: -0.8,
          color: AppColors.foreground,
        ),
        displayMedium: TextStyle(
          fontFamily: displayFamily,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.12,
          letterSpacing: -0.5,
          color: AppColors.foreground,
        ),
        headlineSmall: TextStyle(
          fontFamily: displayFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: -0.3,
          color: AppColors.foreground,
        ),
        titleLarge: TextStyle(
          fontFamily: sansFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleMedium: TextStyle(
          fontFamily: sansFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleSmall: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        bodyLarge: TextStyle(
          fontFamily: sansFamily,
          fontSize: 15,
          height: 1.55,
          color: AppColors.foreground,
        ),
        bodyMedium: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13.5,
          height: 1.55,
          color: AppColors.mutedForeground,
        ),
        bodySmall: TextStyle(
          fontFamily: sansFamily,
          fontSize: 12,
          height: 1.45,
          color: AppColors.mutedForeground,
        ),
        labelLarge: TextStyle(
          fontFamily: sansFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        labelSmall: TextStyle(
          fontFamily: sansFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
        ),
      );
}
