import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color accent = Color(0xFF0EA5E9); // Sky 500

  // Dark Palette
  static const Color darkBg = Color(0xFF09090B); // Zinc 950
  static const Color darkCard = Color(0xFF18181B); // Zinc 900
  static const Color darkCardBorder = Color(0xFF27272A); // Zinc 800
  static const Color darkInputBg = Color(0xFF27272A);
  static const Color darkText = Color(0xFFF4F4F5); // Zinc 100
  static const Color darkSubtext = Color(0xFFA1A1AA); // Zinc 400

  // Light Palette
  static const Color lightBg = Color(0xFFF4F4F5); // Zinc 100
  static const Color lightCard = Colors.white;
  static const Color lightCardBorder = Color(0xFFE4E4E7); // Zinc 200
  static const Color lightText = Color(0xFF18181B); // Zinc 900
  static const Color lightSubtext = Color(0xFF71717A); // Zinc 500

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.primary,
        surface: AppColors.darkCard,
        error: AppColors.danger,
      ),
      cardColor: AppColors.darkCard,
      dialogBackgroundColor: AppColors.darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkSubtext, fontSize: 13),
      ),
    );
  }
}
