import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData light() => _build(AppPalette.light);

  static ThemeData _build(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = (p.isDark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: p.secondary,
      onSecondary: const Color(0xFF04221E),
      surface: p.surface,
      onSurface: p.text,
      error: p.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      extensions: <ThemeExtension<dynamic>>[p],
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
        bodyColor: p.text,
        displayColor: p.text,
      ),
      fallback,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: p.text),
      dividerColor: p.border,
      splashColor: p.accent.withValues(alpha: 0.12),
      highlightColor: p.accent.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSecondary,
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
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
          foregroundColor: p.text,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: p.border),
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
          foregroundColor: p.accent,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHighlight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceSecondary,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
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
