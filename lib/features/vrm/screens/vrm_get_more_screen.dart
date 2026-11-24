import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/auth_service.dart';
import '../services/vrm_service.dart';

/// Lets signed-in users request one of the available voter packages.
class VrmGetMoreScreen extends StatelessWidget {
  const VrmGetMoreScreen({super.key, this.service});

  final VrmService? service;

  static const _navy = Color(0xFF1B2559);
  static const _muted = Color(0xFF8B93A7);
  static const wideBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Stack(
        children: [
          const Positioned.fill(child: _PageWash()),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: _Dunes(),
          ),
          Positioned.fill(child: _GetMoreBody(service: service)),
        ],
      ),
    );
  }
}

class _GetMoreBody extends StatefulWidget {
  const _GetMoreBody({this.service});

  final VrmService? service;

  @override
  State<_GetMoreBody> createState() => _GetMoreBodyState();
}

class _GetMoreBodyState extends State<_GetMoreBody> {
  late final VrmService _service;
  var _requesting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? VrmService();
  }

  Future<void> _requestPackage(_Offer offer) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await _service.requestPackage(offer.packageCode);
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).line('vrmRequestSuccess'));
    } on VrmException catch (error) {
      if (!mounted) return;
      final key = switch (error.code) {
        'unauthorized' => 'vrmRequestSignIn',
        'profile_details_required' => 'vrmRequestProfileRequired',
        _ => 'vrmRequestError',
      };
      _showMessage(AppLocalizations.of(context).line(key), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(context).line('vrmRequestError'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFB42318) : const Color(0xFF16794A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offers = <_Offer>[
      _Offer(
        packageCode: 'voters_100',
        label: l10n.line('vrmOffer100'),
        icon: Icons.groups_rounded,
        color: const Color(0xFF3B82F6),
        background: const Color(0xFFE8F1FF),
      ),
      _Offer(
        packageCode: 'voters_1000',
        label: l10n.line('vrmOffer1000'),
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E5),
        crown: true,
      ),
      _Offer(
        packageCode: 'voters_10000',
        label: l10n.line('vrmOffer10000'),
        icon: Icons.diamond_rounded,
        color: const Color(0xFF8B5CF6),
        background: const Color(0xFFF3E8FF),
        gem: true,
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= VrmGetMoreScreen.wideBreakpoint;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 16,
                    20,
                    wide ? 28 : 16,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE8EEF6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x143B82F6),
                              blurRadius: 40,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 36 : 16,
                            wide ? 28 : 18,
                            wide ? 36 : 16,
                            wide ? 32 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Heading(wide: wide),
                              const SizedBox(height: 8),
                              Text(
                                l10n.line('vrmRequestDisclaimer'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: wide ? 28 : 18),
                              for (final offer in offers) ...[
                                _OfferCard(
                                  offer: offer,
                                  loading: _requesting,
                                  onPressed:
                                      () => unawaited(_requestPackage(offer)),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Offer {
  const _Offer({
    required this.packageCode,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    this.crown = false,
    this.gem = false,
  });

  final String packageCode;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool crown;
  final bool gem;
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5A524), width: 2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop =
              constraints.maxWidth >= VrmGetMoreScreen.wideBreakpoint;
          return SizedBox(
            height: 64,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 8),
              child: Row(
                children: [
                  if (!desktop)
                    PopupMenuButton<String>(
                      tooltip: l10n.line('vrmNavHome'),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: VrmGetMoreScreen._navy,
                      ),
                      onSelected: (value) => _open(context, value),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: AppRoutes.dashboard,
                              child: Text(l10n.line('vrmNavHome')),
                            ),
                            PopupMenuItem(
                              value: AppRoutes.vrmRecords,
                              child: Text(l10n.line('vrmNavRecords')),
                            ),
                          ],
                    ),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Brand(),
                    ),
                  ),
                  if (desktop) ...[
                    _NavLink(
                      icon: Icons.home_rounded,
                      label: l10n.line('vrmNavHome'),
                      onPressed:
                          () => AppRouter.open(context, AppRoutes.dashboard),
                    ),
                    const SizedBox(width: 8),
                    _NavLink(
                      icon: Icons.bar_chart_rounded,
                      label: l10n.line('vrmNavRecords'),
                      onPressed:
                          () => AppRouter.open(context, AppRoutes.vrmRecords),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const _ProfileMenu(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, String route) {
    AppRouter.open(context, route);
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppAssets.logo,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            semanticLabel: l10n.appName,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            l10n.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VrmGetMoreScreen._navy,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: VrmGetMoreScreen._navy,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatar = AuthService.instance.session?.avatarUrl.trim() ?? '';
    return PopupMenuButton<String>(
      tooltip: l10n.cardProfile,
      offset: const Offset(0, 46),
      onSelected: (value) {
        if (value == AppRoutes.profile) {
          AppRouter.open(context, AppRoutes.profile);
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: AppRoutes.profile,
              child: Text(l10n.cardProfile),
            ),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8F1FF),
            backgroundImage: avatar.isEmpty ? null : NetworkImage(avatar),
            child:
                avatar.isEmpty
                    ? const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    )
                    : null,
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: VrmGetMoreScreen._muted,
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackButton(
              tooltip: l10n.back,
              onPressed: () => AppRouter.back(context, AppRoutes.vrmRecords),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.line('vrmGetMoreTitle'),
                style: TextStyle(
                  color: VrmGetMoreScreen._navy,
                  fontSize: wide ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            l10n.line('vrmGetMoreBody'),
            style: TextStyle(
              color: VrmGetMoreScreen._muted,
              fontSize: wide ? 16 : 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );

    final art = const SizedBox(
      width: 168,
      height: 132,
      child: CustomPaint(painter: _BallotPainter()),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          const SizedBox(height: 8),
          Align(alignment: Alignment.center, child: art),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: copy), const SizedBox(width: 12), art],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF4F7FB),
        foregroundColor: VrmGetMoreScreen._navy,
        fixedSize: const Size(40, 40),
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
    );
  }
}

class _OfferIcon extends StatelessWidget {
  const _OfferIcon({required this.offer});

  final _Offer offer;

  @override
  Widget build(BuildContext context) {
    if (offer.crown) {
      return CustomPaint(
        painter: _CrownPainter(offer.color),
        child: const SizedBox(width: 24, height: 24),
      );
    }
    if (offer.gem) {
      return CustomPaint(
        painter: _GemPainter(offer.color),
        child: const SizedBox(width: 24, height: 24),
      );
    }
    return Icon(offer.icon, color: offer.color, size: 24);
  }
}

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.offer,
    required this.onPressed,
    this.loading = false,
  });

  final _Offer offer;
  final VoidCallback onPressed;
  final bool loading;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover ? const Color(0xFF93C5FD) : const Color(0xFFD7E3F4),
          ),
          boxShadow: [
            BoxShadow(
              color: _hover ? const Color(0x223B82F6) : const Color(0x0F1B2559),
              blurRadius: _hover ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.loading ? null : widget.onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: offer.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(child: _OfferIcon(offer: offer)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        offer.label,
                        style: const TextStyle(
                          color: VrmGetMoreScreen._navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageWash extends StatelessWidget {
  const _PageWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6EA), Color(0xFFF7F9FC), Color(0xFFEEF5FF)],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _Dunes extends StatelessWidget {
  const _Dunes();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _DunePainter());
  }
}

class _DunePainter extends CustomPainter {
  const _DunePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final saffron = Paint()..color = const Color(0xFFF8E7D2);
    final blue = Paint()..color = const Color(0xFFE4EEF8);
    final front =
        Path()
          ..moveTo(0, size.height * 0.55)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.15,
            size.width * 0.55,
            size.height * 0.5,
          )
          ..quadraticBezierTo(
            size.width * 0.8,
            size.height * 0.78,
            size.width,
            size.height * 0.35,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    final back =
        Path()
          ..moveTo(0, size.height * 0.75)
          ..quadraticBezierTo(
            size.width * 0.35,
            size.height * 0.35,
            size.width * 0.7,
            size.height * 0.7,
          )
          ..quadraticBezierTo(
            size.width * 0.85,
            size.height * 0.85,
            size.width,
            size.height * 0.55,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(back, blue);
    canvas.drawPath(front, saffron);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BallotPainter extends CustomPainter {
  const _BallotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Paint()..color = const Color(0xFFF3D7A6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.42),
        width: 46,
        height: 18,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height * 0.38),
        width: 42,
        height: 16,
      ),
      leaf,
    );

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.34,
        size.width * 0.46,
        size.height * 0.5,
      ),
      const Radius.circular(10),
    );
    final boxPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC857), Color(0xFFF5A524)],
          ).createShader(box.outerRect);
    canvas.drawRRect(box, boxPaint);
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE09212),
    );

    final slot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.51, size.height * 0.4),
        width: size.width * 0.22,
        height: 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(slot, Paint()..color = const Color(0xFFC47A10));

    final paper = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.28),
        width: 34,
        height: 42,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(
      paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFD6E0EA),
    );

    final check =
        Paint()
          ..color = const Color(0xFF3B82F6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
    final mark =
        Path()
          ..moveTo(size.width * 0.52, size.height * 0.28)
          ..lineTo(size.width * 0.56, size.height * 0.33)
          ..lineTo(size.width * 0.66, size.height * 0.22);
    canvas.drawPath(mark, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path =
        Path()
          ..moveTo(size.width * 0.1, size.height * 0.74)
          ..lineTo(size.width * 0.16, size.height * 0.36)
          ..lineTo(size.width * 0.34, size.height * 0.56)
          ..lineTo(size.width * 0.5, size.height * 0.18)
          ..lineTo(size.width * 0.66, size.height * 0.56)
          ..lineTo(size.width * 0.84, size.height * 0.36)
          ..lineTo(size.width * 0.9, size.height * 0.74)
          ..close();
    canvas.drawPath(path, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.74,
          size.width * 0.72,
          size.height * 0.12,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GemPainter extends CustomPainter {
  const _GemPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path =
        Path()
          ..moveTo(size.width * 0.5, size.height * 0.06)
          ..lineTo(size.width * 0.9, size.height * 0.36)
          ..lineTo(size.width * 0.5, size.height * 0.94)
          ..lineTo(size.width * 0.1, size.height * 0.36)
          ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.36),
      Offset(size.width * 0.82, size.height * 0.36),
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) =>
      oldDelegate.color != color;
}
