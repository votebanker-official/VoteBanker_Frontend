import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface.withValues(alpha: 0.98),
            palette.surfaceSecondary.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border.withValues(alpha: 0.88), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // Transparent Material so list tiles / checkboxes inside the card paint
      // their ink correctly instead of hiding behind the card's color.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
