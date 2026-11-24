import 'package:flutter/material.dart';

/// Palet diambil dari logo: hitam tinta, krem, merah dan biru tiang barber.
class AppColors {
  static const ink = Color(0xFF111111);
  static const cream = Color(0xFFF6F2EA);
  static const red = Color(0xFFC8102E); // aksen: satu tombol utama per layar
  static const navy = Color(0xFF1B3A4B);
  static const line = Color(0xFFD9D3C7);
  static const muted = Color(0xFF5A5650);
  static const faint = Color(0xFFB4B0A6);
  static const sand = Color(0xFFE9E5DB);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
    primary: AppColors.ink,
    onPrimary: AppColors.cream,
    secondary: AppColors.red,
    onSecondary: Colors.white,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    outline: AppColors.line,
    error: const Color(0xFFB3261E),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: shape,
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(64, 44), foregroundColor: AppColors.navy),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.ink, 1.5),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.5),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cream,
      indicatorColor: AppColors.sand,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: AppColors.cream, fontSize: 14),
      shape: shape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
  );
}
