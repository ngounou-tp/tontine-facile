import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF16255A);
  static const slate = Color(0xFF4A4F5C);
  static const canvas = Color(0xFFEEF0F6);
  static const surface = Color(0xFFFFFFFF);
  static const indigo = Color(0xFF2F4590);
  static const success = Color(0xFF2F7D5D);
  static const warning = Color(0xFFC98A16);
  static const accent = Color(0xFFE2A03F);
  static const danger = Color(0xFFB5432F);
  static const line = Color(0xFFD3D8E4);
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const cardRadius = 16.0;
  static const controlRadius = 12.0;
}

abstract final class AppTypography {
  static const amountXl = TextStyle(fontFamily: 'Sora', fontSize: 34, fontWeight: FontWeight.w600, height: 40 / 34, color: AppColors.ink);
  static const screenTitle = TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24, color: AppColors.ink);
  static const amount = TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w500, height: 28 / 20, color: AppColors.ink);
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: AppColors.ink);
  static const secondary = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: AppColors.slate);
  static const micro = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, color: AppColors.slate);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.indigo,
        onPrimary: AppColors.surface,
        secondary: AppColors.accent,
        onSurface: AppColors.ink,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Inter').copyWith(
        headlineMedium: const TextStyle(color: AppColors.ink, fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
        titleLarge: const TextStyle(color: AppColors.ink, fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.4),
        bodyMedium: const TextStyle(color: AppColors.slate, fontSize: 14, height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius), side: const BorderSide(color: AppColors.line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.indigo, width: 2)),
      ),
    );
  }
}