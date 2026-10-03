import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.gradientTop,
            palette.background,
            palette.gradientBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _Glow(color: palette.glowPrimary, diameter: 340),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: _Glow(color: palette.glowSecondary, diameter: 300),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
