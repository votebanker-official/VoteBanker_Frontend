import 'package:flutter/material.dart';

/// Brand constants (the original dark values). Prefer [AppPalette] through
/// `context.palette` in widgets so colors follow the light/dark setting.
abstract final class AppColors {
  static const background = Color(0xFF050B14);
  static const backgroundRaised = Color(0xFF08111C);
  static const surface = Color(0xFF0C1626);
  static const surfaceSecondary = Color(0xFF101D2E);
  static const surfaceHighlight = Color(0xFF173049);
  static const primary = Color(0xFF1CB4FF);
  static const primaryDeep = Color(0xFF0B7CFF);
  static const secondary = Color(0xFF1ED4C1);
  static const campaign = Color(0xFFF4C96D);
  static const text = Color(0xFFF5F8FC);
  static const textMuted = Color(0xFF93A0B5);
  static const border = Color(0xFF2A4562);
  static const success = Color(0xFF3DDC97);
  static const danger = Color(0xFFFF6B7A);
}

/// Theme-aware colors. One instance for light mode, one for dark mode.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.backgroundRaised,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceHighlight,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.secondary,
    required this.campaign,
    required this.success,
    required this.danger,
    required this.gradientTop,
    required this.gradientBottom,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.cardShadow,
  });

  final bool isDark;
  final Color background;
  final Color backgroundRaised;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceHighlight;
  final Color text;
  final Color textMuted;
  final Color border;

  /// Blue used for buttons, links, icons and highlighted text.
  final Color accent;
  final Color secondary;
  final Color campaign;
  final Color success;
  final Color danger;

  final Color gradientTop;
  final Color gradientBottom;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color cardShadow;

  static const dark = AppPalette(
    isDark: true,
    background: Color(0xFF06111C),
    backgroundRaised: Color(0xFF0A1828),
    surface: Color(0xFF0F1D2D),
    surfaceSecondary: Color(0xFF13293B),
    surfaceHighlight: Color(0xFF183C50),
    text: AppColors.text,
    textMuted: AppColors.textMuted,
    border: Color(0xFF2A4562),
    accent: AppColors.primary,
    secondary: AppColors.secondary,
    campaign: AppColors.campaign,
    success: AppColors.success,
    danger: AppColors.danger,
    gradientTop: Color(0xFF071B2C),
    gradientBottom: Color(0xFF030A12),
    glowPrimary: Color(0x332EC8FF),
    glowSecondary: Color(0x221ED4C1),
    cardShadow: Color(0x401CB4FF),
  );

  static const light = AppPalette(
    isDark: false,
    background: Color(0xFFF5F9FF),
    backgroundRaised: Color(0xFFEDF4FD),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEEF5FB),
    surfaceHighlight: Color(0xFFE0ECF7),
    text: Color(0xFF0B1626),
    textMuted: Color(0xFF55657A),
    border: Color(0xFFC9D7E6),
    accent: Color(0xFF0A68D6),
    secondary: Color(0xFF0E9F8F),
    campaign: Color(0xFFB77C13),
    success: Color(0xFF138A5B),
    danger: Color(0xFFD92D3F),
    gradientTop: Color(0xFFE7F2FF),
    gradientBottom: Color(0xFFEAF1F7),
    glowPrimary: Color(0x261CB4FF),
    glowSecondary: Color(0x1A1ED4C1),
    cardShadow: Color(0x2A0A68D6),
  );

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? background,
    Color? backgroundRaised,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceHighlight,
    Color? text,
    Color? textMuted,
    Color? border,
    Color? accent,
    Color? secondary,
    Color? campaign,
    Color? success,
    Color? danger,
    Color? gradientTop,
    Color? gradientBottom,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? cardShadow,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      backgroundRaised: backgroundRaised ?? this.backgroundRaised,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
      campaign: campaign ?? this.campaign,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSecondary: glowSecondary ?? this.glowSecondary,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: mix(background, other.background),
      backgroundRaised: mix(backgroundRaised, other.backgroundRaised),
      surface: mix(surface, other.surface),
      surfaceSecondary: mix(surfaceSecondary, other.surfaceSecondary),
      surfaceHighlight: mix(surfaceHighlight, other.surfaceHighlight),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      border: mix(border, other.border),
      accent: mix(accent, other.accent),
      secondary: mix(secondary, other.secondary),
      campaign: mix(campaign, other.campaign),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      gradientTop: mix(gradientTop, other.gradientTop),
      gradientBottom: mix(gradientBottom, other.gradientBottom),
      glowPrimary: mix(glowPrimary, other.glowPrimary),
      glowSecondary: mix(glowSecondary, other.glowSecondary),
      cardShadow: mix(cardShadow, other.cardShadow),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Colors for the current light/dark theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
