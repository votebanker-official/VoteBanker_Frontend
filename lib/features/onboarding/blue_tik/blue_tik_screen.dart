import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../merchandise/merchandise_intent.dart';
import '../state/onboarding_controller.dart';
import 'blue_tik_art.dart';
import 'blue_tik_booking_screen.dart';
import 'blue_tik_models.dart';

typedef BlueTikSaver = Future<void> Function(BlueTikApplication application);

class BlueTikScreen extends StatefulWidget {
  const BlueTikScreen({this.saver, super.key});

  /// Replaces the API save in tests.
  final BlueTikSaver? saver;

  @override
  State<BlueTikScreen> createState() => _BlueTikScreenState();
}

class _BlueTikScreenState extends State<BlueTikScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resumePendingOffer());
    });
  }

  Future<void> _resumePendingOffer() async {
    if (!mounted || !AuthService.instance.isSignedIn) return;
    final offer = BlueTikCatalog.byId(await BlueTikIntent.peek());
    if (offer == null || !mounted) return;
    await BlueTikIntent.clear();
    if (!mounted) return;
    _openForm(offer);
  }

  void _open(BlueTikOffer offer) {
    if (!AuthService.instance.isSignedIn) {
      unawaited(MerchandiseIntent.clear());
      unawaited(BlueTikIntent.remember(offer.id));
      AppRouter.open(context, AppRoutes.login);
      return;
    }
    unawaited(BlueTikIntent.clear());
    _openForm(offer);
  }

  void _openForm(BlueTikOffer offer) {
    final draft = OnboardingScope.maybeOf(context)?.draft;
    final session = AuthService.instance.session;
    final initialName = draft?.leaderName.trim() ?? '';
    final draftMobile = draft?.contactNumber.trim() ?? '';
    final sessionEmail = session?.email.trim() ?? '';
    final draftEmail = draft?.email.trim() ?? '';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => BlueTikBookingScreen(
              offer: offer,
              initialName: initialName,
              initialMobile:
                  draftMobile.isNotEmpty ? draftMobile : (session?.phone ?? ''),
              initialEmail: sessionEmail.isNotEmpty ? sessionEmail : draftEmail,
              saver: widget.saver,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = _open;

    return Scaffold(
      key: const Key('blue-tik-screen'),
      backgroundColor: BlueTikTone.of(context).card,
      body: BlueTikPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 12,
                  8,
                  wide ? 28 : 12,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: _Sheet(
                      wide: wide,
                      disclaimer: l10n.line('blueTikDisclaimer'),
                      skipLabel: l10n.line('blueTikSkip'),
                      onBack: () => AppNav.back(context, AppRoutes.social),
                      onSkip: () => AppNav.open(context, AppRoutes.voterLists),
                      onBook: open,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.wide,
    required this.disclaimer,
    required this.skipLabel,
    required this.onBack,
    required this.onSkip,
    required this.onBook,
  });

  final bool wide;
  final String disclaimer;
  final String skipLabel;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final ValueChanged<BlueTikOffer> onBook;

  @override
  Widget build(BuildContext context) {
    final tone = BlueTikTone.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.card,
        borderRadius: BorderRadius.circular(wide ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: tone.shadow,
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          wide ? 26 : 16,
          8,
          wide ? 26 : 16,
          wide ? 26 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BlueTikBackButton(onPressed: onBack),
            ),
            const SizedBox(height: 6),
            _Heading(wide: wide),
            const SizedBox(height: 22),
            _IndividualCards(wide: wide, onBook: onBook),
            const SizedBox(height: 16),
            _BundleCard(
              wide: wide,
              onBook: () => onBook(BlueTikCatalog.bundle),
            ),
            const SizedBox(height: 18),
            Text(
              disclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(color: tone.muted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 16),
            Align(
              child: SizedBox(
                width: wide ? 240 : double.infinity,
                height: 48,
                child: OutlinedButton(
                  key: const Key('blue-tik-skip'),
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E6BF5),
                    backgroundColor: tone.card,
                    side: const BorderSide(
                      color: Color(0xFFBFD6F5),
                      width: 1.4,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: Text(skipLabel),
                ),
              ),
            ),
          ],
        ),
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
    final tone = BlueTikTone.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = wide ? 40.0 : (width < 380 ? 26.0 : 30.0);
    final badgeSize = wide ? 118.0 : (width < 380 ? 64.0 : 76.0);
    final titleStyle = TextStyle(
      fontSize: titleSize,
      height: 1.05,
      fontWeight: FontWeight.w800,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                label:
                    '${l10n.line('blueTikLead')} ${l10n.line('blueTikAccent')}',
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    key: const Key('blue-tik-title'),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${l10n.line('blueTikLead')} ',
                          style: titleStyle.copyWith(color: tone.navy),
                        ),
                        TextSpan(
                          text: l10n.line('blueTikAccent'),
                          style: titleStyle.copyWith(color: tone.blue),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.line('blueTikSubtitle'),
                style: TextStyle(
                  color: tone.muted,
                  fontSize: wide ? 16 : 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        VerificationBadge(size: badgeSize),
      ],
    );
  }
}

class _IndividualCards extends StatelessWidget {
  const _IndividualCards({required this.wide, required this.onBook});

  final bool wide;
  final ValueChanged<BlueTikOffer> onBook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      for (final offer in BlueTikCatalog.individuals)
        _PlatformCard(
          key: Key('blue-tik-card-${offer.id}'),
          offer: offer,
          wide: wide,
          title: blueTikServiceTitle(l10n, offer),
          description: blueTikServiceDescription(l10n, offer),
          bookLabel: l10n.line('blueTikBookNow'),
          onBook: () => onBook(offer),
        ),
    ];
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.offer,
    required this.wide,
    required this.title,
    required this.description,
    required this.bookLabel,
    required this.onBook,
    super.key,
  });

  final BlueTikOffer offer;
  final bool wide;
  final String title;
  final String description;
  final String bookLabel;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final tone = BlueTikTone.of(context);
    final price = Text(
      formatInr(offer.priceInr),
      textAlign: wide ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: tone.blue,
        fontSize: wide ? 28 : 20,
        fontWeight: FontWeight.w800,
      ),
    );
    final name = Text(
      title,
      textAlign: wide ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: tone.navy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
    final body = Text(
      description,
      textAlign: wide ? TextAlign.center : TextAlign.start,
      style: TextStyle(color: tone.muted, fontSize: 13, height: 1.35),
    );
    final button = BlueTikPillButton(
      key: Key('blue-tik-book-${offer.id}'),
      label: bookLabel,
      showArrow: true,
      onPressed: onBook,
    );

    return DecoratedBox(
      decoration: _cardDecoration(tone),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child:
            wide
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: BlueTikMark(offer.id, size: 58)),
                    const SizedBox(height: 14),
                    name,
                    const SizedBox(height: 4),
                    body,
                    const SizedBox(height: 12),
                    price,
                    const SizedBox(height: 14),
                    button,
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BlueTikMark(offer.id, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [name, const SizedBox(height: 2), body],
                          ),
                        ),
                        const SizedBox(width: 8),
                        price,
                      ],
                    ),
                    const SizedBox(height: 12),
                    button,
                  ],
                ),
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.wide, required this.onBook});

  final bool wide;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = BlueTikTone.of(context);
    final title = Text(
      l10n.line('blueTikBundle'),
      style: TextStyle(
        color: tone.navy,
        fontSize: wide ? 20 : 17,
        fontWeight: FontWeight.w800,
      ),
    );
    final price = Text(
      formatInr(BlueTikCatalog.bundle.priceInr),
      style: TextStyle(
        color: tone.blue,
        fontSize: wide ? 28 : 22,
        fontWeight: FontWeight.w800,
      ),
    );
    final button = BlueTikPillButton(
      key: const Key('blue-tik-book-bundle'),
      label: l10n.line('blueTikBookNow'),
      showArrow: true,
      onPressed: onBook,
    );
    final marks = const _MarkRow(size: 34);

    return DecoratedBox(
      key: const Key('blue-tik-card-bundle'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              tone.dark
                  ? [tone.soft, tone.card]
                  : const [Color(0xFFF4F9FF), Color(0xFFE7F2FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child:
            wide
                ? Row(
                  children: [
                    marks,
                    Container(
                      width: 1,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: tone.line,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 2), price],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 168, child: button),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _MarkRow(size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [title, const SizedBox(height: 2), price],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    button,
                  ],
                ),
      ),
    );
  }
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlueTikMark('instagram', size: size),
        const SizedBox(width: 6),
        BlueTikMark('facebook', size: size),
        const SizedBox(width: 6),
        BlueTikMark('whatsapp', size: size),
      ],
    );
  }
}

BoxDecoration _cardDecoration(BlueTikTone tone) {
  return BoxDecoration(
    color: tone.card,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: tone.line),
    boxShadow: [
      BoxShadow(
        color: tone.shadow,
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
