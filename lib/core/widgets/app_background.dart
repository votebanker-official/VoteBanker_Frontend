import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071422),
            AppColors.background,
            Color(0xFF04070E),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -140,
            right: -90,
            child: _Glow(color: Color(0x332EC8FF), diameter: 340),
          ),
          const Positioned(
            bottom: -160,
            left: -110,
            child: _Glow(color: Color(0x221ED4C1), diameter: 300),
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
