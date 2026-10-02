import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF04221E),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
    );

    final fallback = <String>[
      GoogleFonts.notoSansKannada().fontFamily ?? 'Noto Sans Kannada',
      GoogleFonts.notoSansDevanagari().fontFamily ?? 'Noto Sans Devanagari',
      GoogleFonts.notoSansTelugu().fontFamily ?? 'Noto Sans Telugu',
      GoogleFonts.notoSansTamil().fontFamily ?? 'Noto Sans Tamil',
      GoogleFonts.notoSansMalayalam().fontFamily ?? 'Noto Sans Malayalam',
    ];

    final textTheme = _withFallback(
      GoogleFonts.notoSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      fallback,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.text),
      dividerColor: AppColors.border,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceSecondary,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static Future<void> preloadFonts() {
    return GoogleFonts.pendingFonts([
      GoogleFonts.notoSans(),
      GoogleFonts.notoSansKannada(),
      GoogleFonts.notoSansDevanagari(),
      GoogleFonts.notoSansTelugu(),
      GoogleFonts.notoSansTamil(),
      GoogleFonts.notoSansMalayalam(),
    ]);
  }
}

TextTheme _withFallback(TextTheme theme, List<String> fallback) {
  TextStyle? map(TextStyle? style) {
    return style?.copyWith(fontFamilyFallback: fallback);
  }

  return theme.copyWith(
    displayLarge: map(theme.displayLarge),
    displayMedium: map(theme.displayMedium),
    displaySmall: map(theme.displaySmall),
    headlineLarge: map(theme.headlineLarge),
    headlineMedium: map(theme.headlineMedium),
    headlineSmall: map(theme.headlineSmall),
    titleLarge: map(theme.titleLarge),
    titleMedium: map(theme.titleMedium),
    titleSmall: map(theme.titleSmall),
    bodyLarge: map(theme.bodyLarge),
    bodyMedium: map(theme.bodyMedium),
    bodySmall: map(theme.bodySmall),
    labelLarge: map(theme.labelLarge),
    labelMedium: map(theme.labelMedium),
    labelSmall: map(theme.labelSmall),
  );
}
