import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../services/theme_controller.dart';

/// Round light/dark switch. Sits to the left of the language selector.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

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
            onTap: controller.toggle,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
                color: palette.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
