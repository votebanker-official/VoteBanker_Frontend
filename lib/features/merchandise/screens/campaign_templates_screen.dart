import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/party_symbol.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import 'merchandise_design_screen.dart';

/// One campaign product at a time. A signed-in leader's party symbol and
/// profile photo are drawn on the product. Guests see the product only.
class CampaignTemplatesScreen extends StatefulWidget {
  const CampaignTemplatesScreen({this.service, super.key});

  final MerchandiseService? service;

  @override
  State<CampaignTemplatesScreen> createState() => _CampaignTemplatesScreenState();
}

class _CampaignTemplatesScreenState extends State<CampaignTemplatesScreen> {
  late final MerchandiseService _service = widget.service ?? MerchandiseService();
  final _pages = PageController();
  final _booked = <String>{};
  List<MerchandiseProduct> _products = campaignTemplateProducts;
  var _index = 0;
  var _burst = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final catalog = await _service.loadCatalog();
      if (!mounted || catalog.products.isEmpty) return;
      setState(() {
        _products = catalog.products;
        if (_index >= _products.length) _index = 0;
      });
    } catch (_) {
      // The built-in list stays on screen when the API cannot be reached.
    }
  }

  void _open(MerchandiseProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MerchandiseDesignScreen(
          product: product,
          service: _service,
        ),
      ),
    );
  }

  void _book(MerchandiseProduct product) {
    if (_booked.contains(product.slug)) return;
    setState(() {
      _booked.add(product.slug);
      _burst++;
    });
  }

  void _go(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = OnboardingScope.maybeOf(context)?.draft;
    final signedIn = AuthService.instance.isSignedIn;
    final party = signedIn ? PartyOption.findByName(draft?.party ?? '') : null;
    final photo = signedIn ? draft?.photoBytes : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => AppRouter.back(context, AppRoutes.social),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _products.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _ProductShowcase(
                    product: product,
                    party: party,
                    photo: photo,
                    index: index,
                    total: _products.length,
                    booked: _booked.contains(product.slug),
                    onDesign: () => _open(product),
                    onBook: () => _book(product),
                    onSkip: () => AppRouter.open(context, AppRoutes.vrm),
                    onPrevious: index == 0 ? null : () => _go(index - 1),
                    onNext: index == _products.length - 1 ? null : () => _go(index + 1),
                  );
                },
              ),
            ),
          ],
        ),
          ),
          if (_burst > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: _ConfettiBurst(key: ValueKey(_burst)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductShowcase extends StatelessWidget {
  const _ProductShowcase({
    required this.product,
    required this.index,
    required this.total,
    required this.booked,
    required this.onDesign,
    required this.onBook,
    required this.onSkip,
    this.party,
    this.photo,
    this.onPrevious,
    this.onNext,
  });

  final MerchandiseProduct product;
  final PartyOption? party;
  final Uint8List? photo;
  final int index;
  final int total;
  final bool booked;
  final VoidCallback onDesign;
  final VoidCallback onBook;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        final tagline = _taglineFor(product);
        return Padding(
          padding: EdgeInsets.fromLTRB(wide ? 36 : 16, 4, wide ? 36 : 16, wide ? 20 : 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: wide ? 32 : 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A8A),
                      ),
                      children: const [
                        TextSpan(text: 'Create Your '),
                        TextSpan(text: 'Campaign ', style: TextStyle(color: Color(0xFFF97316))),
                        TextSpan(text: 'Merchandise'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1} of $total',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: wide ? 12 : 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, artBox) {
                        final pad = wide ? 28.0 : 16.0;
                        final room = math.min(artBox.maxWidth - (wide ? 120 : 72), artBox.maxHeight);
                        final inner = room - pad * 2;
                        final size = inner <= 48 ? math.max(inner, 1.0) : math.min(inner, wide ? 460.0 : 320.0);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x140F172A), blurRadius: 28, offset: Offset(0, 14)),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(wide ? 28 : 16),
                                child: _ProductArt(
                                  slug: product.slug,
                                  party: party,
                                  photo: photo,
                                  size: size,
                                ),
                              ),
                            ),
                            if (onPrevious != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _PageArrow(icon: Icons.chevron_left, onPressed: onPrevious!),
                              ),
                            if (onNext != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: _PageArrow(icon: Icons.chevron_right, onPressed: onNext!),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: wide ? 16 : 8),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: wide ? 32 : 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xFF64748B), fontSize: wide ? 16 : 14),
                  ),
                  const SizedBox(height: 8),
                  _PageDots(count: total, index: index),
                  SizedBox(height: wide ? 16 : 8),
                  wide
                      ? Row(
                          children: [
                            Expanded(child: _DesignButton(onPressed: onDesign)),
                            const SizedBox(width: 12),
                            Expanded(child: _BookButton(booked: booked, onPressed: onBook)),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(width: double.infinity, child: _DesignButton(compact: true, onPressed: onDesign)),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: _BookButton(compact: true, booked: booked, onPressed: onBook)),
                          ],
                        ),
                  const SizedBox(height: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onSkip,
                    child: const Text('Skip now'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesignButton extends StatelessWidget {
  const _DesignButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 10 : 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Design & Order'),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.booked, required this.onPressed, this.compact = false});

  final bool booked;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: booked ? const Color(0xFF16A34A) : const Color(0xFFF97316),
        disabledBackgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 10 : 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      onPressed: booked ? null : onPressed,
      icon: Icon(booked ? Icons.check_circle : Icons.event_available_outlined, size: 18),
      label: Text(booked ? 'Booked' : 'Book Now'),
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({super.key});

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.origin,
    required this.spread,
    required this.reach,
    required this.delay,
    required this.spin,
    required this.color,
    required this.w,
    required this.h,
    required this.shape,
  });

  final double origin;
  final double spread;
  final double reach;
  final double delay;
  final double spin;
  final Color color;
  final double w;
  final double h;
  final int shape;
}

class _ConfettiBurstState extends State<_ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    const colors = <Color>[
      Color(0xFFFF9933),
      Color(0xFF138808),
      Color(0xFF1D4ED8),
      Color(0xFFF97316),
      Color(0xFFFFFFFF),
      Color(0xFFFACC15),
      Color(0xFFFB7185),
      Color(0xFF22C55E),
    ];
    _pieces = [
      for (var i = 0; i < 100; i++)
        _ConfettiPiece(
          origin: 0.5 + (random.nextDouble() - 0.5) * 0.08,
          // 70° fan aimed straight up, the same burst as confetti({ spread: 70 }).
          spread: (random.nextDouble() - 0.5) * 70 * math.pi / 180,
          reach: 0.72 + random.nextDouble() * 0.55,
          delay: random.nextDouble() * 0.08,
          spin: (random.nextDouble() - 0.5) * 12,
          color: colors[i % colors.length],
          w: 6 + random.nextDouble() * 8,
          h: 8 + random.nextDouble() * 12,
          shape: i % 3,
        ),
    ];
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(progress: _controller.value, pieces: _pieces),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final span = 1 - piece.delay;
      final t = ((progress - piece.delay) / span).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final fade = t < 0.08 ? t / 0.08 : (t > 0.72 ? ((1 - t) / 0.28).clamp(0.0, 1.0) : 1.0);
      // Launch from 60% down the screen and shoot upward, then gravity pulls the pieces back.
      final vx = math.sin(piece.spread) * piece.reach;
      final vy = -math.cos(piece.spread) * piece.reach;
      final x = piece.origin * size.width + vx * t * size.width * 0.72;
      final y = size.height * 0.6 + vy * t * size.height + 0.95 * t * t * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      final paint = Paint()..color = piece.color.withValues(alpha: fade);
      switch (piece.shape) {
        case 1:
          canvas.drawCircle(Offset.zero, piece.w / 2, paint);
        case 2:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: piece.w * 0.45, height: piece.h),
              const Radius.circular(3),
            ),
            paint,
          );
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: piece.w, height: piece.w * 0.62),
              const Radius.circular(2),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x330F172A),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == index ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

const campaignTemplateProducts = <MerchandiseProduct>[
  MerchandiseProduct(
    slug: 't-shirt',
    name: 'T-Shirt',
    description: 'Wear Your Support',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'scarf',
    name: 'Scarf',
    description: 'Wrap the Spirit',
    sizes: ['One size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'flag',
    name: 'Flag',
    description: 'Wave Your Support',
    sizes: ['Small', 'Medium', 'Large'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'badge',
    name: 'Badge',
    description: 'Show Your Pride',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'cap',
    name: 'Cap',
    description: 'Wear It Proudly',
    sizes: ['Free size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'mug',
    name: 'Mug',
    description: 'Sip the Support',
    sizes: ['330 ml'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'poster',
    name: 'Poster',
    description: 'Spread the Message',
    sizes: ['A4', 'A3', 'A2'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'sticker',
    name: 'Sticker',
    description: 'Stick the Support',
    sizes: ['Small', 'Sheet'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'keychain',
    name: 'Keychain',
    description: 'Carry the Change',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'pen',
    name: 'Pen',
    description: 'Write for a Better India',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'bag',
    name: 'Bag',
    description: 'Carry the Campaign',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'gift-box',
    name: 'Gift box',
    description: 'Share the Support',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
];

class CampaignMerchandiseHero extends StatelessWidget {
  const CampaignMerchandiseHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFECFDF3)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 40, height: 1.12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
              children: [
                TextSpan(text: 'Create Your\n'),
                TextSpan(text: 'Campaign ', style: TextStyle(color: Color(0xFFF97316))),
                TextSpan(text: 'Merchandise'),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Show your support with pride!',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class CampaignTemplateCard extends StatelessWidget {
  const CampaignTemplateCard({
    required this.product,
    required this.onOrder,
    this.party,
    this.photo,
  });

  final MerchandiseProduct product;
  final PartyOption? party;
  final Uint8List? photo;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOrder,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              padding: EdgeInsets.all(compact ? 14 : 22),
              child: Row(
                children: [
                  _ProductArt(
                    slug: product.slug,
                    party: party,
                    photo: photo,
                    size: compact ? 104 : 168,
                  ),
                  SizedBox(width: compact ? 12 : 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 18 : 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _taglineFor(product),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: const Color(0xFF64748B), fontSize: compact ? 13 : 16),
                        ),
                        SizedBox(height: compact ? 8 : 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 12 : 18,
                                vertical: compact ? 8 : 14,
                              ),
                              textStyle: TextStyle(
                                fontSize: compact ? 13 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: onOrder,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Design & Order'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

String _taglineFor(MerchandiseProduct product) {
    const lines = {
      't-shirt': 'Wear Your Support',
      'scarf': 'Wrap the Spirit',
      'flag': 'Wave Your Support',
      'badge': 'Show Your Pride',
      'cap': 'Wear It Proudly',
      'mug': 'Sip the Support',
      'poster': 'Spread the Message',
      'sticker': 'Stick the Support',
      'keychain': 'Carry the Change',
      'pen': 'Write for a Better India',
      'bag': 'Carry the Campaign',
      'gift-box': 'Share the Support',
    };
    return lines[product.slug] ?? product.description;
}

class _ProductArt extends StatelessWidget {
  const _ProductArt({required this.slug, this.party, this.photo, this.size = 168});

  final String slug;
  final PartyOption? party;
  final Uint8List? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFECFDF3)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              _asset(slug),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (party != null)
            Positioned(
              left: 6,
              top: 6,
              child: PartySymbol(party!.name, diameter: (size * 0.18).clamp(24, 64)),
            ),
          if (photo != null && photo!.isNotEmpty)
            Positioned(
              right: 6,
              bottom: 6,
              child: ClipOval(
                child: Image.memory(
                  photo!,
                  width: (size * 0.2).clamp(28, 72),
                  height: (size * 0.2).clamp(28, 72),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _asset(String slug) {
    const files = {
      't-shirt': 'assets/images/merchandise/merch-tshirt.jpg',
      'scarf': 'assets/images/merchandise/merch-scarf.jpg',
      'flag': 'assets/images/merchandise/merch-flag.jpg',
      'badge': 'assets/images/merchandise/merch-badge.jpg',
      'cap': 'assets/images/merchandise/merch-cap.jpg',
      'mug': 'assets/images/merchandise/merch-mug.jpg',
      'poster': 'assets/images/merchandise/merch-poster.jpg',
      'sticker': 'assets/images/merchandise/merch-sticker.jpg',
      'keychain': 'assets/images/merchandise/merch-keychain.jpg',
      'pen': 'assets/images/merchandise/merch-pen.jpg',
      'bag': 'assets/images/merchandise/merch-bag.jpg',
      'gift-box': 'assets/images/merchandise/merch-gift.jpg',
    };
    return files[slug] ?? 'assets/images/merchandise/merch-tshirt.jpg';
  }
}
