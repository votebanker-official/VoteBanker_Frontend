import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../onboarding/blue_tik/blue_tik_models.dart';
import '../merchandise_identity.dart';
import '../merchandise_intent.dart';
import '../models/merchandise_design.dart';
import '../widgets/personalized_merchandise.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/merchandise_pricing.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import '../widgets/merchandise_booking_confirmation.dart';
import '../widgets/merchandise_quantity_selector.dart';
import 'merchandise_design_screen.dart';

/// One campaign product at a time. A signed-in leader's party symbol and
/// profile photo are drawn on the product. Guests see the product only.
class CampaignTemplatesScreen extends StatefulWidget {
  const CampaignTemplatesScreen({this.service, this.products, super.key});

  final MerchandiseService? service;
  final List<MerchandiseProduct>? products;

  @override
  State<CampaignTemplatesScreen> createState() =>
      _CampaignTemplatesScreenState();
}

class _CampaignTemplatesScreenState extends State<CampaignTemplatesScreen> {
  late final MerchandiseService _service =
      widget.service ?? MerchandiseService();
  final _pages = PageController();
  final _booked = <String>{};
  final _quantities = <String, int>{};
  var _booking = false;
  List<MerchandiseProduct> _products = campaignTemplateProducts;
  var _index = 0;
  var _burst = 0;

  @override
  void initState() {
    super.initState();
    final supplied = widget.products;
    if (supplied != null && supplied.isNotEmpty) {
      _products = supplied;
    }
    _refresh();
    MerchandiseIdentityController.instance.addListener(_onPersonalization);
    MerchandiseDesignStore.instance.addListener(_onPersonalization);
    MerchandiseIdentityController.instance.refresh();
  }

  void _onPersonalization() {
    if (mounted) setState(() {});
  }

  Future<void> _resumePendingOrder() async {
    if (!mounted || !AuthService.instance.isSignedIn || _booking) return;
    final pending = await MerchandiseIntent.peek();
    if (pending == null || !mounted) return;
    MerchandiseProduct? product;
    for (final item in _products) {
      if (item.slug == pending.slug) product = item;
    }
    if (product == null) return;
    _quantities[product.slug] = pending.quantity;
    await _book(product);
  }

  @override
  void dispose() {
    MerchandiseIdentityController.instance.removeListener(_onPersonalization);
    MerchandiseDesignStore.instance.removeListener(_onPersonalization);
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
    await _resumePendingOrder();
  }

  int _quantityFor(MerchandiseProduct product) {
    return _quantities[product.slug] ?? merchandiseMinimumQuantity;
  }

  void _setQuantity(MerchandiseProduct product, int quantity) {
    if (!isMerchandiseQuantity(quantity)) {
      return;
    }
    setState(() => _quantities[product.slug] = quantity);
  }

  void _open(MerchandiseProduct product) {
    final quantity = _quantityFor(product);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => MerchandiseDesignScreen(
              product: product,
              service: _service,
              initialQuantity: quantity,
              onQuantityChanged: (value) => _setQuantity(product, value),
            ),
      ),
    );
  }

  Future<({String name, String phone, String email, String party})>
  _buyerContact() async {
    final draft = OnboardingScope.maybeOf(context)?.draft;
    try {
      final profile = await ProfileService.instance.fetchProfile();
      if (profile != null && draft != null) {
        ProfileService.applyProfile(draft, profile);
      }
    } catch (_) {
      // The session and draft still supply the contact details.
    }
    final session = AuthService.instance.session;
    String first(String? primary, String? secondary) {
      final lead = primary?.trim() ?? '';
      if (lead.isNotEmpty) return lead;
      return secondary?.trim() ?? '';
    }

    return (
      name: first(draft?.leaderName, session?.fullName),
      phone: first(draft?.contactNumber, session?.phone),
      email: first(session?.email, draft?.email),
      party: draft?.party.trim() ?? '',
    );
  }

  Future<void> _book(MerchandiseProduct product) async {
    if (_booking || _booked.contains(product.slug)) return;
    final quantity = _quantityFor(product);
    final local = quoteMerchandise(product.priceSlabs, quantity);
    if (!local.configured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            local.error == 'invalid_quantity'
                ? 'Choose a quantity of 50 or more, in multiples of 50.'
                : 'Price is not configured for ${product.name}. Booking stays closed.',
          ),
        ),
      );
      return;
    }

    setState(() => _booking = true);
    MerchandiseQuote confirmed;
    try {
      confirmed = await _service.quote(product.slug, quantity);
    } on MerchandiseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The price could not be confirmed. Booking stays closed.',
            ),
          ),
        );
        setState(() => _booking = false);
      }
      return;
    }
    if (!mounted || !confirmed.configured) {
      if (mounted) setState(() => _booking = false);
      return;
    }

    if (!AuthService.instance.isSignedIn) {
      await BlueTikIntent.clear();
      await MerchandiseIntent.remember(product.slug, confirmed.quantity);
      if (mounted) setState(() => _booking = false);
      if (!mounted) return;
      AppRouter.open(context, AppRoutes.login);
      return;
    }

    try {
      final buyer = await _buyerContact();
      if (!mounted) return;
      if (buyer.name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add your name on your profile before ordering.'),
          ),
        );
        return;
      }
      final identity = MerchandiseIdentityController.instance;
      final design = MerchandiseDesignStore.instance.of(product.slug);
      String? printPhoto;
      if (identity.hasPhoto) {
        final encoded = base64Encode(identity.photo!);
        if (encoded.length <= 900000) printPhoto = encoded;
      }
      await _service.placeOrder({
        'product_slug': product.slug,
        'quantity': confirmed.quantity,
        'contact_name': buyer.name,
        'contact_phone': buyer.phone,
        'contact_email': buyer.email,
        'campaign_line': buyer.party,
        if (identity.hasPhoto) 'notes': design.encode(),
        if (printPhoto != null) 'campaign_photo': printPhoto,
      });
      await MerchandiseIntent.clear();
      if (!mounted) return;
      await showMerchandiseBookingConfirmation(
        context,
        productName: product.name,
        quantity: confirmed.quantity,
        totalPaise: confirmed.lineTotalPaise,
        detail:
            identity.hasPhoto
                ? 'Your profile photo is printed in place of the original artwork.'
                : null,
        preview:
            identity.hasPhoto
                ? PersonalizedMerchandiseView(
                  slug: product.slug,
                  photo: identity.photo,
                  partyName: identity.hasParty ? identity.partyName : '',
                  design: design,
                )
                : null,
      );
      if (!mounted) return;
      setState(() {
        _booked.add(product.slug);
        _burst++;
      });
    } on MerchandiseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The order could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
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
    final palette = context.palette;
    final identity = MerchandiseIdentityController.instance;
    final signedIn = identity.signedIn;
    final party =
        signedIn && identity.hasParty
            ? PartyOption.findByName(identity.partyName)
            : null;
    final photo = signedIn ? identity.photo : null;
    final prompt =
        signedIn && identity.loaded && !identity.hasPhoto
            ? 'Add your profile photo on your profile to print it on this product.'
            : null;

    return Scaffold(
      backgroundColor:
          palette.isDark ? palette.background : const Color(0xFFF4F7FB),
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
                        onPressed:
                            () => AppRouter.back(context, AppRoutes.blueTik),
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
                        prompt: prompt,
                        index: index,
                        total: _products.length,
                        booked: _booked.contains(product.slug),
                        booking: _booking,
                        quantity: _quantityFor(product),
                        onQuantity: (value) => _setQuantity(product, value),
                        onDesign: () => _open(product),
                        onBook: () => _book(product),
                        onSkip: () => AppRouter.open(context, AppRoutes.ready),
                        onPrevious: index == 0 ? null : () => _go(index - 1),
                        onNext:
                            index == _products.length - 1
                                ? () => AppRouter.open(context, AppRoutes.ready)
                                : () => _go(index + 1),
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
    required this.booking,
    required this.quantity,
    required this.onQuantity,
    required this.onDesign,
    required this.onBook,
    required this.onSkip,
    this.party,
    this.photo,
    this.prompt,
    this.onPrevious,
    this.onNext,
  });

  final MerchandiseProduct product;
  final PartyOption? party;
  final Uint8List? photo;
  final String? prompt;
  final int index;
  final int total;
  final bool booked;
  final bool booking;
  final int quantity;
  final ValueChanged<int> onQuantity;
  final VoidCallback onDesign;
  final VoidCallback onBook;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final palette = context.palette;
        final wide = constraints.maxWidth >= 800;
        final stacked = constraints.maxWidth < 720;
        final tagline = _taglineFor(product);
        final quote = quoteMerchandise(product.priceSlabs, quantity);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 28 : 16,
            2,
            wide ? 28 : 16,
            wide ? 8 : 6,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: wide ? 30 : 22,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color:
                            palette.isDark
                                ? palette.text
                                : const Color(0xFF1E3A8A),
                      ),
                      children: const [
                        TextSpan(text: 'Create Your '),
                        TextSpan(
                          text: 'Campaign ',
                          style: TextStyle(color: Color(0xFFF97316)),
                        ),
                        TextSpan(text: 'Merchandise'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1} of $total',
                    style: TextStyle(
                      color:
                          palette.isDark
                              ? palette.textMuted
                              : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PageDots(count: total, index: index),
                  SizedBox(height: wide ? 10 : 8),
                  Expanded(
                    child: _ProductStage(
                      product: product,
                      party: party,
                      photo: photo,
                      prompt: prompt,
                      onPrevious: onPrevious,
                      onNext: onNext,
                    ),
                  ),
                  SizedBox(height: wide ? 12 : 8),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: wide ? 30 : 24,
                      fontWeight: FontWeight.w800,
                      color:
                          palette.isDark
                              ? palette.text
                              : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          palette.isDark
                              ? palette.textMuted
                              : const Color(0xFF64748B),
                      fontSize: wide ? 16 : 14,
                    ),
                  ),
                  SizedBox(height: wide ? 12 : 8),
                  _PurchaseRow(
                    product: product,
                    quantity: quantity,
                    quote: quote,
                    stacked: stacked,
                    onQuantity: onQuantity,
                  ),
                  SizedBox(height: wide ? 12 : 8),
                  wide
                      ? Row(
                        children: [
                          Expanded(child: _DesignButton(onPressed: onDesign)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BookButton(
                              booked: booked,
                              busy: booking,
                              onPressed: onBook,
                            ),
                          ),
                        ],
                      )
                      : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _DesignButton(
                              compact: true,
                              onPressed: onDesign,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _BookButton(
                              compact: true,
                              booked: booked,
                              busy: booking,
                              onPressed: onBook,
                            ),
                          ),
                        ],
                      ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          palette.isDark
                              ? palette.textMuted
                              : const Color(0xFF64748B),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({
    required this.product,
    required this.quantity,
    required this.quote,
    required this.stacked,
    required this.onQuantity,
  });

  final MerchandiseProduct product;
  final int quantity;
  final MerchandiseQuote quote;
  final bool stacked;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final quantitySide = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MerchandiseQuantitySelector(
          quantity: quantity,
          priceSlabs: product.priceSlabs,
          compact: stacked,
          onChanged: onQuantity,
        ),
        const SizedBox(height: 6),
        Text(
          quote.configured
              ? '${formatMerchandisePrice(quote.unitPricePaise!)} per piece'
              : 'Price is not configured',
          style: TextStyle(
            color:
                quote.configured
                    ? palette.isDark
                        ? palette.secondary
                        : const Color(0xFF1E3A8A)
                    : palette.isDark
                    ? const Color(0xFFFFB46A)
                    : const Color(0xFF9A3412),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final totalSide = Column(
      crossAxisAlignment:
          stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          'Total Price',
          style: TextStyle(
            color: palette.isDark ? palette.textMuted : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          quote.configured
              ? formatMerchandisePrice(quote.lineTotalPaise!)
              : '—',
          key: const ValueKey('merchPriceTotal'),
          style: TextStyle(
            color: palette.isDark ? palette.accent : const Color(0xFF1E3A8A),
            fontSize: stacked ? 26 : 32,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [quantitySide, const SizedBox(height: 10), totalSide],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: quantitySide),
        const SizedBox(width: 24),
        totalSide,
      ],
    );
  }
}

class _ProductStage extends StatelessWidget {
  const _ProductStage({
    required this.product,
    this.party,
    this.photo,
    this.prompt,
    this.onPrevious,
    this.onNext,
  });

  final MerchandiseProduct product;
  final PartyOption? party;
  final Uint8List? photo;
  final String? prompt;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.isDark ? palette.surfaceSecondary : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 12),
              child: SizedBox.expand(
                key: ValueKey('merchProductArt-${product.slug}'),
                child: PersonalizedMerchandiseView(
                  slug: product.slug,
                  photo: photo,
                  partyName: party?.name ?? '',
                  design: MerchandiseDesignStore.instance.of(product.slug),
                ),
              ),
            ),
          ),
        ),
        if (prompt != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    palette.isDark
                        ? palette.surface.withValues(alpha: 0.92)
                        : const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  prompt!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        palette.isDark ? palette.text : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        if (onPrevious != null)
          Align(
            alignment: Alignment.centerLeft,
            child: _PageArrow(
              icon: Icons.chevron_left,
              direction: 'previous',
              onPressed: onPrevious!,
            ),
          ),
        if (onNext != null)
          Align(
            alignment: Alignment.centerRight,
            child: _PageArrow(
              icon: Icons.chevron_right,
              direction: 'next',
              onPressed: onNext!,
            ),
          ),
      ],
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
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: compact ? 10 : 14,
        ),
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
  const _BookButton({
    required this.booked,
    required this.onPressed,
    this.busy = false,
    this.compact = false,
  });

  final bool booked;
  final bool busy;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor:
            booked ? const Color(0xFF16A34A) : const Color(0xFFF97316),
        disabledBackgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: compact ? 10 : 14,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      onPressed: booked || busy ? null : onPressed,
      icon: Icon(
        booked ? Icons.check_circle : Icons.event_available_outlined,
        size: 18,
      ),
      label: Text(
        booked
            ? 'Booked'
            : busy
            ? 'Saving…'
            : 'Order now',
      ),
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

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
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
          painter: _ConfettiPainter(
            progress: _controller.value,
            pieces: _pieces,
          ),
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
      final fade =
          t < 0.08
              ? t / 0.08
              : (t > 0.72 ? ((1 - t) / 0.28).clamp(0.0, 1.0) : 1.0);
      // Launch from 60% down the screen and shoot upward, then gravity pulls the pieces back.
      final vx = math.sin(piece.spread) * piece.reach;
      final vy = -math.cos(piece.spread) * piece.reach;
      final x = piece.origin * size.width + vx * t * size.width * 0.72;
      final y =
          size.height * 0.6 + vy * t * size.height + 0.95 * t * t * size.height;
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
              Rect.fromCenter(
                center: Offset.zero,
                width: piece.w * 0.45,
                height: piece.h,
              ),
              const Radius.circular(3),
            ),
            paint,
          );
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: piece.w,
                height: piece.w * 0.62,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PageArrow extends StatefulWidget {
  const _PageArrow({
    required this.icon,
    required this.onPressed,
    required this.direction,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String direction;

  @override
  State<_PageArrow> createState() => _PageArrowState();
}

class _PageArrowState extends State<_PageArrow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        key: ValueKey('merchArrow-${widget.direction}'),
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF1D4ED8) : const Color(0xFF1E40AF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x401E3A8A),
              blurRadius: _hover ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          iconSize: 26,
          splashRadius: 26,
          icon: Icon(widget.icon, color: Colors.white, size: 26),
        ),
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
              color:
                  i == index
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

final campaignTemplateProducts = <MerchandiseProduct>[
  MerchandiseProduct(
    slug: 't-shirt',
    name: 'T-Shirt',
    description: 'Wear Your Support',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('t-shirt'),
  ),
  MerchandiseProduct(
    slug: 'scarf',
    name: 'Scarf',
    description: 'Wrap the Spirit',
    sizes: ['One size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('scarf'),
  ),
  MerchandiseProduct(
    slug: 'flag',
    name: 'Flag',
    description: 'Wave Your Support',
    sizes: ['Small', 'Medium', 'Large'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('flag'),
  ),
  MerchandiseProduct(
    slug: 'badge',
    name: 'Badge',
    description: 'Show Your Pride',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('badge'),
  ),
  MerchandiseProduct(
    slug: 'cap',
    name: 'Cap',
    description: 'Wear It Proudly',
    sizes: ['Free size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('cap'),
  ),
  MerchandiseProduct(
    slug: 'mug',
    name: 'Mug',
    description: 'Sip the Support',
    sizes: ['330 ml'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('mug'),
  ),
  MerchandiseProduct(
    slug: 'poster',
    name: 'Poster',
    description: 'Spread the Message',
    sizes: ['A4', 'A3', 'A2'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('poster'),
  ),
  MerchandiseProduct(
    slug: 'sticker',
    name: 'Sticker',
    description: 'Stick the Support',
    sizes: ['Small', 'Sheet'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('sticker'),
  ),
  MerchandiseProduct(
    slug: 'keychain',
    name: 'Keychain',
    description: 'Carry the Change',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('keychain'),
  ),
  MerchandiseProduct(
    slug: 'pen',
    name: 'Pen',
    description: 'Write for a Better India',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('pen'),
  ),
  MerchandiseProduct(
    slug: 'bag',
    name: 'Bag',
    description: 'Carry the Campaign',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('bag'),
  ),
  MerchandiseProduct(
    slug: 'gift-box',
    name: 'Gift box',
    description: 'Share the Support',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
    priceSlabs: configuredMerchandiseSlabs('gift-box'),
  ),
];

class CampaignMerchandiseHero extends StatelessWidget {
  const CampaignMerchandiseHero({super.key});

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
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 40,
                height: 1.12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
              ),
              children: [
                TextSpan(text: 'Create Your\n'),
                TextSpan(
                  text: 'Campaign ',
                  style: TextStyle(color: Color(0xFFF97316)),
                ),
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
    super.key,
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
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
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
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: compact ? 13 : 16,
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              visualDensity:
                                  compact
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
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
  const _ProductArt({
    required this.slug,
    this.party,
    this.photo,
    this.size = 168,
  });

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
      child: PersonalizedMerchandiseView(
        slug: slug,
        photo: photo,
        partyName: party?.name ?? '',
        design: MerchandiseDesignStore.instance.of(slug),
      ),
    );
  }
}
