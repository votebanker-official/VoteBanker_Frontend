import 'package:flutter/material.dart';

/// Colors used only by the dashboard shell. Other screens keep the app theme.
@immutable
class DashboardColors {
  const DashboardColors._(this.isDark);

  final bool isDark;

  factory DashboardColors.of(BuildContext context) {
    return DashboardColors._(Theme.of(context).brightness == Brightness.dark);
  }

  Color get page => isDark ? const Color(0xFF07111C) : const Color(0xFFF3F7FC);
  Color get sidebar => isDark ? const Color(0xFF0A1628) : const Color(0xFFFFFFFF);
  Color get topBar => isDark ? const Color(0xFF0C1A2C) : const Color(0xFFFFFFFF);
  Color get card => isDark ? const Color(0xFF101E32) : const Color(0xFFFFFFFF);
  Color get cardAlt => isDark ? const Color(0xFF14283F) : const Color(0xFFF7FAFE);
  Color get border => isDark ? const Color(0xFF1E628C) : const Color(0xFFD3E1EF);
  Color get text => isDark ? const Color(0xFFF4F8FC) : const Color(0xFF0E1726);
  Color get muted => isDark ? const Color(0xFF93A6BD) : const Color(0xFF5C6D82);
  Color get accent => isDark ? const Color(0xFF2EC8FF) : const Color(0xFF0A68D6);
  Color get accentSoft =>
      accent.withValues(alpha: isDark ? 0.16 : 0.10);
  Color get selected => accent;
  Color get onSelected => Colors.white;
  Color get field => isDark ? const Color(0xFF0E1C30) : const Color(0xFFF4F8FC);
  Color get shadow => isDark ? const Color(0x66000000) : const Color(0x140A2744);
}
