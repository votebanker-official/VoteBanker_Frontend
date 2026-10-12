import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/merchandise_product.dart';

/// The product beside the form, with the typed line printed on it.
class MerchandiseLivePreview extends StatelessWidget {
  const MerchandiseLivePreview({
    required this.product,
    required this.line,
    required this.hint,
    required this.size,
    required this.color,
    required this.quantity,
    required this.previewLabel,
    required this.standardLabel,
    required this.qtyLabel,
    super.key,
  });

  final MerchandiseProduct product;
  final String line;
  final String hint;
  final String size;
  final String color;
  final int quantity;
  final String previewLabel;
  final String standardLabel;
  final String qtyLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typed = line.trim();
    final shown = typed.isEmpty ? hint : typed;
    final fill = merchandiseFill(color);
    final ink = fill.computeLuminance() < 0.45 ? Colors.white : const Color(0xFF1C2430);
    final colorLabel = color.isEmpty ? standardLabel : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceSecondary : const Color(0xFFF3F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            Text(
              previewLabel,
              style: AppTextStyles.muted(context).copyWith(
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.05,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bounds = _printBounds(product.slug, constraints.biggest);
                  final vertical = product.slug == 'pen';
                  final label = Text(
                    shown,
                    key: const Key('merchPreviewLine'),
                    textAlign: TextAlign.center,
                    maxLines: vertical ? 1 : 4,
                    softWrap: !vertical,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink.withValues(alpha: typed.isEmpty ? 0.72 : 1),
                      fontSize: vertical ? 13 : 16,
                      height: 1.25,
                      letterSpacing: vertical ? 1.2 : 0,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _ProductArtPainter(slug: product.slug, fill: fill),
                      ),
                      Positioned.fromRect(
                        rect: bounds,
                        child: Center(
                          child: vertical
                              ? RotatedBox(quarterTurns: 3, child: label)
                              : label,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (size.isNotEmpty) _MetaChip(label: '[ $size ]'),
                _MetaChip(label: '[ $colorLabel ]'),
                _MetaChip(label: '[ $qtyLabel: $quantity ]'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Text(label, style: AppTextStyles.muted(context).copyWith(fontSize: 12)),
    );
  }
}

Color merchandiseFill(String color) {
  return switch (color.toLowerCase()) {
    'black' => const Color(0xFF2C3138),
    'navy' => const Color(0xFF1E3A5F),
    'saffron' => const Color(0xFFFF9933),
    'green' => const Color(0xFF1F8A4C),
    'red' => const Color(0xFFD64545),
    'white' => const Color(0xFFF7F8FA),
    'cyan' => const Color(0xFF5EC8E8),
    'magenta' => const Color(0xFFE85CAD),
    'yellow' => const Color(0xFFF6D34D),
    _ => const Color(0xFFF4F6F8),
  };
}

Rect _printBounds(String slug, Size size) {
  final w = size.width;
  final h = size.height;
  return switch (slug) {
    't-shirt' => Rect.fromLTWH(w * 0.32, h * 0.40, w * 0.36, h * 0.22),
    'scarf' => Rect.fromLTWH(w * 0.30, h * 0.34, w * 0.40, h * 0.16),
    'mug' => Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.28, h * 0.20),
    'cap' => Rect.fromLTWH(w * 0.34, h * 0.36, w * 0.32, h * 0.14),
    'gift-box' => Rect.fromLTWH(w * 0.32, h * 0.50, w * 0.36, h * 0.16),
    'bag' => Rect.fromLTWH(w * 0.32, h * 0.46, w * 0.36, h * 0.16),
    'flag' => Rect.fromLTWH(w * 0.36, h * 0.30, w * 0.34, h * 0.20),
    'badge' => Rect.fromLTWH(w * 0.34, h * 0.38, w * 0.32, h * 0.18),
    'pen' => Rect.fromLTWH(w * 0.40, h * 0.30, w * 0.20, h * 0.36),
    'keychain' => Rect.fromLTWH(w * 0.34, h * 0.46, w * 0.32, h * 0.18),
    'sticker' => Rect.fromLTWH(w * 0.30, h * 0.36, w * 0.40, h * 0.20),
    _ => Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.40, h * 0.24),
  };
}

class _ProductArtPainter extends CustomPainter {
  const _ProductArtPainter({required this.slug, required this.fill});

  final String slug;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x220B1626)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.9),
        width: size.width * 0.46,
        height: size.height * 0.06,
      ),
      shadow,
    );

    switch (slug) {
      case 't-shirt':
        _shirt(canvas, size);
      case 'scarf':
        _scarf(canvas, size);
      case 'mug':
        _mug(canvas, size);
      case 'cap':
        _cap(canvas, size);
      case 'gift-box':
        _gift(canvas, size);
      case 'bag':
        _bag(canvas, size);
      case 'flag':
        _flag(canvas, size);
      case 'badge':
        _badge(canvas, size);
      case 'pen':
        _pen(canvas, size);
      case 'keychain':
        _keychain(canvas, size);
      case 'sticker':
        _sticker(canvas, size);
      default:
        _poster(canvas, size);
    }
  }

  void _shirt(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.30, h * 0.24)
      ..lineTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.22, h * 0.48)
      ..lineTo(w * 0.30, h * 0.40)
      ..lineTo(w * 0.30, h * 0.82)
      ..quadraticBezierTo(w * 0.50, h * 0.88, w * 0.70, h * 0.82)
      ..lineTo(w * 0.70, h * 0.40)
      ..lineTo(w * 0.78, h * 0.48)
      ..lineTo(w * 0.88, h * 0.38)
      ..lineTo(w * 0.70, h * 0.24)
      ..quadraticBezierTo(w * 0.62, h * 0.32, w * 0.50, h * 0.30)
      ..quadraticBezierTo(w * 0.38, h * 0.32, w * 0.30, h * 0.24)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final collar = Path()
      ..moveTo(w * 0.42, h * 0.28)
      ..quadraticBezierTo(w * 0.50, h * 0.36, w * 0.58, h * 0.28);
    canvas.drawPath(
      collar,
      Paint()
        ..color = const Color(0x550B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _scarf(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final shade = Color.lerp(fill, Colors.black, dark ? 0.18 : 0.10)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.20 : 0.38)!;
    final stroke = Paint()
      ..color = const Color(0x330B1626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    Paint fabric(Rect bounds) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, fill, shade],
        stops: const [0, 0.48, 1],
      ).createShader(bounds);

    // Back loop behind the knot.
    final loop = Path()
      ..moveTo(w * 0.28, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.18, w * 0.72, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.28, h * 0.34)
      ..close();
    canvas.drawPath(loop, fabric(Rect.fromLTWH(w * 0.28, h * 0.18, w * 0.44, h * 0.18)));
    canvas.drawPath(loop, stroke);

    // Left hanging end.
    final left = Path()
      ..moveTo(w * 0.30, h * 0.36)
      ..quadraticBezierTo(w * 0.24, h * 0.48, w * 0.22, h * 0.68)
      ..lineTo(w * 0.34, h * 0.72)
      ..quadraticBezierTo(w * 0.36, h * 0.50, w * 0.40, h * 0.40)
      ..close();
    canvas.drawPath(left, fabric(Rect.fromLTWH(w * 0.20, h * 0.34, w * 0.22, h * 0.40)));
    canvas.drawPath(left, stroke);

    // Right hanging end.
    final right = Path()
      ..moveTo(w * 0.70, h * 0.36)
      ..quadraticBezierTo(w * 0.76, h * 0.48, w * 0.78, h * 0.68)
      ..lineTo(w * 0.66, h * 0.72)
      ..quadraticBezierTo(w * 0.64, h * 0.50, w * 0.60, h * 0.40)
      ..close();
    canvas.drawPath(right, fabric(Rect.fromLTWH(w * 0.58, h * 0.34, w * 0.22, h * 0.40)));
    canvas.drawPath(right, stroke);

    // Center folded band where the line is printed.
    final band = Path()
      ..moveTo(w * 0.28, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.30, w * 0.72, h * 0.36)
      ..quadraticBezierTo(w * 0.74, h * 0.44, w * 0.70, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.30, h * 0.50)
      ..quadraticBezierTo(w * 0.26, h * 0.44, w * 0.28, h * 0.36)
      ..close();
    canvas.drawPath(band, fabric(Rect.fromLTWH(w * 0.26, h * 0.30, w * 0.48, h * 0.28)));
    canvas.drawPath(band, stroke);

    // Soft fold crease across the band.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.32, h * 0.42)
        ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.68, h * 0.42),
      Paint()
        ..color = dark ? Colors.white24 : const Color(0x448AA0B5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Fringe on both ends.
    final fringe = Paint()
      ..color = dark ? Colors.white54 : const Color(0x998AA0B5)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      canvas.drawLine(
        Offset(w * (0.22 + t * 0.12), h * 0.70),
        Offset(w * (0.20 + t * 0.12), h * 0.80),
        fringe,
      );
      canvas.drawLine(
        Offset(w * (0.66 + t * 0.12), h * 0.70),
        Offset(w * (0.68 + t * 0.12), h * 0.80),
        fringe,
      );
    }
  }

  void _mug(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final rimInner = dark ? const Color(0xFF1A1F26) : const Color(0xFFE6EDF4);
    final rimEdge = dark ? Colors.white38 : const Color(0xFF9AA8B6);
    final shade = Color.lerp(fill, Colors.black, dark ? 0.22 : 0.10)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.18 : 0.35)!;

    // Handle behind the cup rim attachment points.
    final handleOuter = Path()
      ..moveTo(w * 0.58, h * 0.38)
      ..cubicTo(w * 0.78, h * 0.34, w * 0.82, h * 0.66, w * 0.58, h * 0.68);
    final handleInner = Path()
      ..moveTo(w * 0.58, h * 0.44)
      ..cubicTo(w * 0.70, h * 0.42, w * 0.72, h * 0.60, w * 0.58, h * 0.62);
    canvas.drawPath(
      handleOuter,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      handleOuter,
      Paint()
        ..color = rimEdge.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      handleOuter,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      handleInner,
      Paint()
        ..color = dark ? const Color(0x22000000) : const Color(0x14000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cup body: tapered cylinder.
    final body = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..lineTo(w * 0.60, h * 0.32)
      ..quadraticBezierTo(w * 0.64, h * 0.54, w * 0.60, h * 0.74)
      ..lineTo(w * 0.28, h * 0.74)
      ..quadraticBezierTo(w * 0.24, h * 0.54, w * 0.28, h * 0.32)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [shade, fill, highlight, fill, shade],
          stops: const [0, 0.22, 0.48, 0.72, 1],
        ).createShader(Rect.fromLTWH(w * 0.24, h * 0.30, w * 0.42, h * 0.46)),
    );

    // Bottom ellipse for the base.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.74), width: w * 0.34, height: h * 0.07),
      Paint()..color = shade,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.74), width: w * 0.34, height: h * 0.07),
      Paint()
        ..color = rimEdge.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Top rim: outer lip + inner opening.
    final top = Rect.fromCenter(center: Offset(w * 0.44, h * 0.31), width: w * 0.36, height: h * 0.10);
    canvas.drawOval(top, Paint()..color = fill);
    canvas.drawOval(
      top,
      Paint()
        ..color = rimEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.315), width: w * 0.28, height: h * 0.07),
      Paint()..color = rimInner,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.315), width: w * 0.28, height: h * 0.07),
      Paint()
        ..color = rimEdge.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Soft front face highlight so printed text reads on ceramic.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.34, h * 0.42, w * 0.20, h * 0.20),
        const Radius.circular(10),
      ),
      Paint()..color = highlight.withValues(alpha: 0.18),
    );
  }

  void _bag(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.36, w * 0.44, h * 0.42),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = fill);
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final handles = Paint()
      ..color = const Color(0xFF8AA0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(w * 0.34, h * 0.22, w * 0.14, h * 0.22), 3.4, 2.5, false, handles);
    canvas.drawArc(Rect.fromLTWH(w * 0.52, h * 0.22, w * 0.14, h * 0.22), 3.4, 2.5, false, handles);
  }

  void _cap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final shade = Color.lerp(fill, Colors.black, dark ? 0.20 : 0.10)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.18 : 0.36)!;
    final seam = dark ? Colors.white24 : const Color(0x558AA0B5);
    final cx = w * 0.50;

    // Brim / visor first so crown sits over it.
    final brim = Path()
      ..moveTo(w * 0.22, h * 0.54)
      ..quadraticBezierTo(cx, h * 0.62, w * 0.78, h * 0.54)
      ..quadraticBezierTo(cx, h * 0.72, w * 0.22, h * 0.54)
      ..close();
    canvas.drawPath(
      brim,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, fill, shade],
        ).createShader(Rect.fromLTWH(w * 0.20, h * 0.52, w * 0.60, h * 0.20)),
    );
    canvas.drawPath(
      brim,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Brim underside lip.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.26, h * 0.56)
        ..quadraticBezierTo(cx, h * 0.64, w * 0.74, h * 0.56),
      Paint()
        ..color = shade.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Domed crown.
    final crown = Path()
      ..moveTo(w * 0.26, h * 0.54)
      ..quadraticBezierTo(w * 0.28, h * 0.28, cx, h * 0.24)
      ..quadraticBezierTo(w * 0.72, h * 0.28, w * 0.74, h * 0.54)
      ..quadraticBezierTo(cx, h * 0.58, w * 0.26, h * 0.54)
      ..close();
    canvas.drawPath(
      crown,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, fill, shade],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(w * 0.26, h * 0.24, w * 0.48, h * 0.34)),
    );
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Panel seams.
    final seams = Paint()
      ..color = seam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * 0.25)
        ..quadraticBezierTo(w * 0.42, h * 0.40, w * 0.34, h * 0.54),
      seams,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * 0.25)
        ..quadraticBezierTo(w * 0.58, h * 0.40, w * 0.66, h * 0.54),
      seams,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * 0.25)
        ..lineTo(cx, h * 0.54),
      seams,
    );

    // Top button.
    canvas.drawCircle(Offset(cx, h * 0.255), w * 0.018, Paint()..color = shade);
    canvas.drawCircle(Offset(cx, h * 0.25), w * 0.014, Paint()..color = highlight);

    // Soft front print area.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.24, height: h * 0.10),
        const Radius.circular(8),
      ),
      Paint()..color = highlight.withValues(alpha: 0.16),
    );
  }

  void _gift(Canvas canvas, Size size) {
    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.26, size.height * 0.42, size.width * 0.48, size.height * 0.36),
      const Radius.circular(8),
    );
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.32, size.width * 0.56, size.height * 0.12),
      const Radius.circular(6),
    );
    canvas.drawRRect(front, Paint()..color = fill);
    canvas.drawRRect(lid, Paint()..color = fill);
    final ribbon = Paint()
      ..color = const Color(0xFF1A6F82)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.32),
      Offset(size.width * 0.50, size.height * 0.78),
      ribbon,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.56),
      Offset(size.width * 0.74, size.height * 0.56),
      ribbon,
    );
  }

  void _flag(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final shade = Color.lerp(fill, Colors.black, dark ? 0.18 : 0.10)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.20 : 0.36)!;
    final pole = dark ? const Color(0xFFB7C0C9) : const Color(0xFF8D98A6);
    final poleLite = dark ? const Color(0xFFD8DEE5) : const Color(0xFFC2CAD3);
    final px = w * 0.30;

    // Ground base.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px, h * 0.86), width: w * 0.16, height: h * 0.04),
      Paint()..color = pole.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px, h * 0.84), width: w * 0.10, height: h * 0.04),
        const Radius.circular(4),
      ),
      Paint()..color = pole,
    );

    // Flagpole.
    canvas.drawLine(
      Offset(px, h * 0.16),
      Offset(px, h * 0.84),
      Paint()
        ..color = pole
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(px - 1.2, h * 0.16),
      Offset(px - 1.2, h * 0.84),
      Paint()
        ..color = poleLite.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Ball finial.
    canvas.drawCircle(Offset(px, h * 0.15), w * 0.022, Paint()..color = poleLite);
    canvas.drawCircle(Offset(px, h * 0.15), w * 0.022, Paint()
      ..color = const Color(0x330B1626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Waving cloth with folds.
    final cloth = Path()
      ..moveTo(px + 3, h * 0.20)
      ..cubicTo(w * 0.46, h * 0.16, w * 0.58, h * 0.28, w * 0.74, h * 0.22)
      ..cubicTo(w * 0.70, h * 0.34, w * 0.78, h * 0.42, w * 0.72, h * 0.52)
      ..cubicTo(w * 0.58, h * 0.58, w * 0.46, h * 0.46, px + 3, h * 0.54)
      ..close();
    canvas.drawPath(
      cloth,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, fill, shade, fill],
          stops: const [0, 0.35, 0.7, 1],
        ).createShader(Rect.fromLTWH(px, h * 0.16, w * 0.48, h * 0.42)),
    );
    canvas.drawPath(
      cloth,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Wave fold lines.
    final folds = Paint()
      ..color = dark ? Colors.white24 : const Color(0x448AA0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, h * 0.24)
        ..cubicTo(w * 0.48, h * 0.32, w * 0.44, h * 0.42, w * 0.50, h * 0.50),
      folds,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.56, h * 0.24)
        ..cubicTo(w * 0.62, h * 0.32, w * 0.58, h * 0.40, w * 0.64, h * 0.48),
      folds,
    );

    // Soft print plate.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.52, h * 0.36), width: w * 0.24, height: h * 0.12),
        const Radius.circular(8),
      ),
      Paint()..color = highlight.withValues(alpha: 0.16),
    );
  }

  void _badge(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    canvas.drawCircle(center, size.width * 0.22, Paint()..color = const Color(0xFFE4C56A));
    canvas.drawCircle(center, size.width * 0.16, Paint()..color = fill);
  }

  void _pen(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final metal = dark ? const Color(0xFFB8C0C8) : const Color(0xFF8A96A4);
    final metalLite = dark ? const Color(0xFFD7DDE4) : const Color(0xFFC5CDD6);
    final shade = Color.lerp(fill, Colors.black, dark ? 0.18 : 0.08)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.22 : 0.40)!;
    final cx = w * 0.50;
    final barrelLeft = w * 0.455;
    final barrelWidth = w * 0.09;

    // Pocket clip.
    final clip = Path()
      ..moveTo(w * 0.545, h * 0.18)
      ..lineTo(w * 0.60, h * 0.18)
      ..quadraticBezierTo(w * 0.63, h * 0.28, w * 0.60, h * 0.40)
      ..lineTo(w * 0.545, h * 0.40)
      ..close();
    canvas.drawPath(clip, Paint()..color = metal);
    canvas.drawCircle(Offset(w * 0.575, h * 0.18), w * 0.018, Paint()..color = metalLite);

    // Cap / top button.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.16), width: barrelWidth * 0.85, height: h * 0.06),
        const Radius.circular(8),
      ),
      Paint()..color = metal,
    );

    // Main barrel with ceramic/plastic sheen.
    final barrel = RRect.fromRectAndRadius(
      Rect.fromLTWH(barrelLeft, h * 0.20, barrelWidth, h * 0.42),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [shade, fill, highlight, fill, shade],
          stops: const [0, 0.25, 0.5, 0.75, 1],
        ).createShader(Rect.fromLTWH(barrelLeft, h * 0.20, barrelWidth, h * 0.42)),
    );

    // Print band area edge.
    canvas.drawRRect(
      barrel,
      Paint()
        ..color = const Color(0x220B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Grip section.
    final grip = RRect.fromRectAndRadius(
      Rect.fromLTWH(barrelLeft + 1, h * 0.62, barrelWidth - 2, h * 0.10),
      const Radius.circular(6),
    );
    canvas.drawRRect(grip, Paint()..color = shade);
    final gripLines = Paint()
      ..color = dark ? Colors.white24 : const Color(0x668AA0B5)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final y = h * (0.64 + i * 0.018);
      canvas.drawLine(Offset(barrelLeft + 4, y), Offset(barrelLeft + barrelWidth - 4, y), gripLines);
    }

    // Metal collar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barrelLeft - 1, h * 0.585, barrelWidth + 2, h * 0.035),
        const Radius.circular(4),
      ),
      Paint()..color = metalLite,
    );

    // Tip cone + writing point.
    final tip = Path()
      ..moveTo(barrelLeft + 2, h * 0.72)
      ..lineTo(barrelLeft + barrelWidth - 2, h * 0.72)
      ..lineTo(cx + w * 0.012, h * 0.84)
      ..lineTo(cx - w * 0.012, h * 0.84)
      ..close();
    canvas.drawPath(tip, Paint()..color = metal);
    canvas.drawPath(
      tip,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(Offset(cx, h * 0.855), w * 0.012, Paint()..color = const Color(0xFF2C3138));
  }

  void _keychain(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = fill.computeLuminance() < 0.45;
    final metal = dark ? const Color(0xFFC2CAD2) : const Color(0xFF8F9AA8);
    final metalLite = dark ? const Color(0xFFE0E5EA) : const Color(0xFFC9D1DA);
    final shade = Color.lerp(fill, Colors.black, dark ? 0.18 : 0.08)!;
    final highlight = Color.lerp(fill, Colors.white, dark ? 0.20 : 0.38)!;
    final cx = w * 0.50;

    // Split ring.
    final ringCenter = Offset(cx, h * 0.24);
    canvas.drawCircle(
      ringCenter,
      w * 0.10,
      Paint()
        ..color = metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawCircle(
      ringCenter,
      w * 0.10,
      Paint()
        ..color = metalLite.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Split gap on the ring.
    canvas.drawArc(
      Rect.fromCircle(center: ringCenter, radius: w * 0.10),
      -0.35,
      0.55,
      false,
      Paint()
        ..color = dark ? const Color(0xFF0F1A24) : const Color(0xFFF3F7FB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.butt,
    );

    // Connector jump ring.
    canvas.drawCircle(
      Offset(cx, h * 0.36),
      w * 0.028,
      Paint()
        ..color = metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Fob body with rounded top for the hole.
    final fob = Path()
      ..moveTo(w * 0.34, h * 0.46)
      ..quadraticBezierTo(w * 0.34, h * 0.40, w * 0.42, h * 0.40)
      ..lineTo(w * 0.58, h * 0.40)
      ..quadraticBezierTo(w * 0.66, h * 0.40, w * 0.66, h * 0.46)
      ..lineTo(w * 0.66, h * 0.70)
      ..quadraticBezierTo(w * 0.66, h * 0.78, w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.34, h * 0.78, w * 0.34, h * 0.70)
      ..close();
    canvas.drawPath(
      fob,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, fill, shade],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(w * 0.34, h * 0.40, w * 0.32, h * 0.38)),
    );
    canvas.drawPath(
      fob,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Attachment hole through the fob.
    canvas.drawCircle(Offset(cx, h * 0.42), w * 0.022, Paint()..color = metalLite);
    canvas.drawCircle(
      Offset(cx, h * 0.42),
      w * 0.014,
      Paint()..color = dark ? const Color(0xFF0F1A24) : const Color(0xFFE8EEF4),
    );

    // Soft print plate on the face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.58), width: w * 0.22, height: h * 0.14),
        const Radius.circular(8),
      ),
      Paint()..color = highlight.withValues(alpha: 0.16),
    );
  }

  void _sticker(Canvas canvas, Size size) {
    final sheet = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.24, size.height * 0.28, size.width * 0.52, size.height * 0.40),
      const Radius.circular(18),
    );
    canvas.drawRRect(sheet, Paint()..color = fill);
    canvas.drawRRect(
      sheet,
      Paint()
        ..color = const Color(0x330B1626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _poster(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.12, size.width * 0.56, size.height * 0.58),
      const Radius.circular(6),
    );
    canvas.drawRRect(frame, Paint()..color = const Color(0xFFD5DDE6));
    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.26, size.height * 0.16, size.width * 0.48, size.height * 0.50),
      const Radius.circular(2),
    );
    canvas.drawRRect(page, Paint()..color = fill);
    final leg = Paint()
      ..color = const Color(0xFFC5CED8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.70),
      Offset(size.width * 0.28, size.height * 0.90),
      leg,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.70),
      Offset(size.width * 0.72, size.height * 0.90),
      leg,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.78),
      Offset(size.width * 0.66, size.height * 0.78),
      leg..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant _ProductArtPainter oldDelegate) {
    return oldDelegate.slug != slug || oldDelegate.fill != fill;
  }
}
