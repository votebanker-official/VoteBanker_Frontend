import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../services/theme_controller.dart';

/// Round light/dark switch. Sits to the left of the language selector.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({this.diameter = 48, super.key});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = ThemeScope.of(context);
    final isDark = palette.isDark;
    final label = isDark ? 'Switch to light mode' : 'Switch to dark mode';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: palette.surfaceSecondary,
          shape: CircleBorder(side: BorderSide(color: palette.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap:
                () => controller.setMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: diameter <= 36 ? 18 : 20,
                color: palette.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
