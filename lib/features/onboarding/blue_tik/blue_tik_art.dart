import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';

class BlueTikTone {
  const BlueTikTone({
    required this.dark,
    required this.navy,
    required this.blue,
    required this.muted,
    required this.card,
    required this.line,
    required this.soft,
    required this.shadow,
  });

  factory BlueTikTone.of(BuildContext context) {
    final palette = context.palette;
    if (palette.isDark) {
      return BlueTikTone(
        dark: true,
        navy: palette.text,
        blue: const Color(0xFF4C8DFF),
        muted: palette.textMuted,
        card: palette.surface,
        line: palette.border,
        soft: palette.surfaceHighlight,
        shadow: palette.cardShadow,
      );
    }
    return const BlueTikTone(
      dark: false,
      navy: Color(0xFF102A56),
      blue: Color(0xFF1E6BF5),
      muted: Color(0xFF64748B),
      card: Colors.white,
      line: Color(0xFFE3EDF8),
      soft: Color(0xFFF3F8FF),
      shadow: Color(0x14102A56),
    );
  }

  final bool dark;
  final Color navy;
  final Color blue;
  final Color muted;
  final Color card;
  final Color line;
  final Color soft;
  final Color shadow;
}

class BlueTikPageBackground extends StatelessWidget {
  const BlueTikPageBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              dark
                  ? [
                    context.palette.background,
                    context.palette.backgroundRaised,
                  ]
                  : const [
                    Color(0xFFF8FBFF),
                    Color(0xFFE7F1FF),
                    Color(0xFFF5F9FF),
                  ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!dark) ...const [
            Positioned(
              top: -90,
              right: -50,
              child: _Blob(diameter: 260, color: Color(0x332563EB)),
            ),
            Positioned(
              bottom: -120,
              left: -70,
              child: _Blob(diameter: 300, color: Color(0x334DA3FF)),
            ),
            Positioned(
              top: 220,
              left: -30,
              child: _Blob(diameter: 160, color: Color(0x2238BDF8)),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class BlueTikBackButton extends StatelessWidget {
  const BlueTikBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tone = BlueTikTone.of(context);
    return IconButton(
      key: const Key('blue-tik-back'),
      tooltip: 'Back',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: tone.dark ? tone.soft : const Color(0xFFF3F6FB),
        foregroundColor: tone.navy,
        fixedSize: const Size(42, 42),
        shape: const CircleBorder(),
      ),
      icon: const Icon(Icons.arrow_back, size: 20),
    );
  }
}

class BlueTikPillButton extends StatelessWidget {
  const BlueTikPillButton({
    required this.label,
    required this.onPressed,
    this.showArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E6BF5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 6),
                const ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BlueTikMark extends StatelessWidget {
  const BlueTikMark(this.platform, {this.size = 56, super.key});

  final String platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (platform) {
      'instagram' => _InstagramMark(size: size),
      'facebook' => ClipOval(
        child: SvgPicture.string(_facebookSvg, width: size, height: size),
      ),
      'whatsapp' => ClipOval(
        child: SvgPicture.string(_whatsappSvg, width: size, height: size),
      ),
      _ => Icon(Icons.public, size: size),
    };
    return ExcludeSemantics(child: icon);
  }
}

class _InstagramMark extends StatelessWidget {
  const _InstagramMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFFEDA77),
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
          ),
        ),
        child: SvgPicture.string(_instagramSvg, width: size, height: size),
      ),
    );
  }
}

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({this.size = 112, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _SealPainter(),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: size * 0.42,
          ),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rayPaint =
        Paint()
          ..color = const Color(0xFF3B82F6)
          ..strokeWidth = math.max(2, size.width * 0.022)
          ..strokeCap = StrokeCap.round;
    final anchor = Offset(size.width * 0.18, size.height * 0.22);
    canvas.drawLine(
      anchor,
      anchor + Offset(-size.width * 0.08, -size.height * 0.07),
      rayPaint,
    );
    canvas.drawLine(
      anchor + Offset(size.width * 0.02, size.height * 0.08),
      anchor + Offset(-size.width * 0.05, size.height * 0.15),
      rayPaint,
    );
    canvas.drawLine(
      anchor + Offset(size.width * 0.08, 0),
      anchor + Offset(size.width * 0.15, -size.height * 0.07),
      rayPaint,
    );

    final path = Path();
    const points = 90;
    const waves = 14;
    final base = size.width * 0.36;
    final amp = size.width * 0.032;
    for (var i = 0; i <= points; i++) {
      final angle = (i / points) * math.pi * 2;
      final radius = base + amp * math.sin(waves * angle);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: const [
            Color(0xFF6CB6FF),
            Color(0xFF1E6BF5),
            Color(0xFF0C4ED8),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _instagramSvg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="13" width="22" height="22" rx="7" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="24" cy="24" r="5.2" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="32.2" cy="15.8" r="1.7" fill="#fff"/>
</svg>''';

const _facebookSvg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="24" fill="#1877F2"/>
  <path fill="#fff" d="M26.6 38V26.2h4l.6-4.6h-4.6v-2.9c0-1.3.4-2.2 2.3-2.2H31.4v-4.1c-.4 0-1.7-.2-3.2-.2-3.2 0-5.4 1.9-5.4 5.5v3.9H18.4v4.6h4.4V38h3.8z"/>
</svg>''';

const _whatsappSvg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="24" fill="#25D366"/>
  <path fill="#fff" d="M24 11.2c-6.7 0-12.1 5.4-12.1 12 0 2.1.6 4.1 1.6 5.9L12 36.8l7.9-2c1.7.9 3.6 1.4 5.6 1.4 6.7 0 12.1-5.4 12.1-12S30.7 11.2 24 11.2zm6.9 16.7c-.3.8-1.6 1.4-2.2 1.5-.6.1-1.1.1-3.6-.8-3-1.1-5-4-5.2-4.2-.2-.2-1.2-1.6-1.2-3.1 0-1.5.8-2.2 1-2.5.3-.3.6-.4.9-.4h.6c.2 0 .5 0 .7.6.3.7 1 2.4 1.1 2.6.1.2.1.4 0 .6-.1.2-.2.4-.3.6-.2.2-.3.4-.2.6.2.3.8 1.4 1.8 2.2 1.2 1.1 2.3 1.5 2.6 1.6.3.2.5.1.7-.1.2-.2.8-.9 1-1.3.2-.3.5-.3.7-.2.3.1 1.9.9 2.2 1 .3.2.5.2.6.4.1.1.1.8-.2 1.5z"/>
</svg>''';
