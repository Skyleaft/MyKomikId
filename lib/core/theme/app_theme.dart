import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'app_theme_scheme.dart';

class AppTheme {
  static ThemeData buildTheme({
    required Brightness brightness,
    required AppThemeScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : Colors.black;

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: scheme.primary,
      brightness: brightness,
      primary: scheme.primary,
      secondary: scheme.secondary,
      surface: surfaceColor,
    );

    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: scheme.primary,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardDark : Colors.white,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        baseTheme.textTheme,
      ).apply(bodyColor: textColor, displayColor: textColor),
    );
  }

  static ThemeData get lightTheme => buildTheme(
        brightness: Brightness.light,
        scheme: AppThemeScheme.defaultScheme,
      );

  static ThemeData get darkTheme => buildTheme(
        brightness: Brightness.dark,
        scheme: AppThemeScheme.defaultScheme,
      );
}
