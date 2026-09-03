import 'package:flutter/material.dart';

/// Olive marketplace palette, converted from the OKLCH tokens the web
/// frontend defines in `src/index.css` so both clients read as one brand.
class AppColors {
  AppColors._();

  /// oklch(0.42 0.07 125) — deep olive, the primary brand colour.
  static const Color primary = Color(0xFF445427);
  static const Color primaryForeground = Color(0xFFFAF9F2);

  /// oklch(0.995 0.004 95) — warm near-white page ground.
  static const Color background = Color(0xFFFDFCF7);
  static const Color surface = Color(0xFFFFFFFF);

  /// oklch(0.24 0.02 120) — warm charcoal used for body copy.
  static const Color foreground = Color(0xFF1E2116);
  static const Color mutedForeground = Color(0xFF6F7566);

  /// Warm neutrals used for section bands and chips.
  static const Color muted = Color(0xFFF4F1E8);
  static const Color mist = Color(0xFFEDE8D9);
  static const Color cream = Color(0xFFF4EEE0);
  static const Color accent = Color(0xFFE5EAD7);
  static const Color accentForeground = Color(0xFF3B4A26);

  static const Color border = Color(0xFFE3DFD2);
  static const Color destructive = Color(0xFFC1392C);
  static const Color star = Color(0xFFE0A32E);

  /// Soft tints behind the category tiles, mirroring the web's category art.
  static const List<Color> categoryTints = [
    Color(0xFFE8F1F8),
    Color(0xFFF8E9EF),
    Color(0xFFF3EBDD),
    Color(0xFFEDE8F5),
    Color(0xFFE5F3F0),
    Color(0xFFF8EFE4),
  ];

  /// Shadow used on cards — a soft olive-tinted lift, not a grey drop shadow.
  static const Color cardShadow = Color(0x14283220);
}
