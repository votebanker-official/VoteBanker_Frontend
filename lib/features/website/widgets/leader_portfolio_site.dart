import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/utils/person_name.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/widgets/party_symbol.dart';
import '../models/website_builder_draft.dart';

/// Colors for the portfolio site, chosen from the saved party.
class PartyPalette {
  const PartyPalette({
    required this.id,
    required this.primary,
    required this.ink,
    required this.hero,
    required this.muted,
    required this.body,
    required this.accent,
    required this.onHero,
    required this.darkHero,
  });

  final String id;
  final Color primary;
  final Color ink;
  final Color hero;
  final Color muted;
  final Color body;
  final Color accent;
  final Color onHero;
  final bool darkHero;

  static const fallback = PartyPalette(
    id: 'default',
    primary: Color(0xFF1D4ED8),
    ink: Color(0xFF0F2A56),
    hero: Color(0xFFE8F0FB),
    muted: Color(0xFF64748B),
    body: Color(0xFF1E293B),
    accent: Color(0xFF93C5FD),
    onHero: Color(0xFF0F2A56),
    darkHero: false,
  );

  static PartyPalette forParty(String partyName) {
    final abbr = PartyOption.findByName(partyName.trim())?.abbreviation;
    return switch (abbr) {
      'BJP' => const PartyPalette(
        id: 'BJP',
        primary: Color(0xFFE8771A),
        ink: Color(0xFF6B2D00),
        hero: Color(0xFFFF8A1E),
        muted: Color(0xFF8A5A32),
        body: Color(0xFF3F2A1A),
        accent: Color(0xFF138808),
        onHero: Colors.white,
        darkHero: true,
      ),
      'INC' => const PartyPalette(
        id: 'INC',
        primary: Color(0xFF0E8A43),
        ink: Color(0xFF0B3D22),
        hero: Color(0xFF128A45),
        muted: Color(0xFF4E6B5A),
        body: Color(0xFF1E293B),
        accent: Color(0xFFFF9933),
        onHero: Colors.white,
        darkHero: true,
      ),
      'AAP' => const PartyPalette(
        id: 'AAP',
        primary: Color(0xFF0072CE),
        ink: Color(0xFF003A70),
        hero: Color(0xFF0B7AD1),
        muted: Color(0xFF4B6A86),
        body: Color(0xFF12324A),
        accent: Color(0xFF4FC3F7),
        onHero: Colors.white,
        darkHero: true,
      ),
      'BSP' => const PartyPalette(
        id: 'BSP',
        primary: Color(0xFF1A237E),
        ink: Color(0xFF0D1442),
        hero: Color(0xFF1A237E),
        muted: Color(0xFFD6DBF5),
        body: Color(0xFF1A1C3A),
        accent: Color(0xFF9FA8DA),
        onHero: Colors.white,
        darkHero: true,
      ),
      'CPI(M)' => const PartyPalette(
        id: 'CPI(M)',
        primary: Color(0xFFC62828),
        ink: Color(0xFF7F1010),
        hero: Color(0xFFB71C1C),
        muted: Color(0xFFFFCDD2),
        body: Color(0xFF3E1A1A),
        accent: Color(0xFFFF8A80),
        onHero: Colors.white,
        darkHero: true,
      ),
      'NPP' => const PartyPalette(
        id: 'NPP',
        primary: Color(0xFF2E7D32),
        ink: Color(0xFF1B5E20),
        hero: Color(0xFF2E7D32),
        muted: Color(0xFF4E7A52),
        body: Color(0xFF1B3320),
        accent: Color(0xFFC8E6C9),
        onHero: Colors.white,
        darkHero: true,
      ),
      _ => fallback,
    };
  }
}

class PartyTheme extends InheritedWidget {
  const PartyTheme({required this.palette, required super.child, super.key});

  final PartyPalette palette;

  static PartyPalette of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<PartyTheme>();
    return theme?.palette ?? PartyPalette.fallback;
  }

  @override
  bool updateShouldNotify(PartyTheme oldWidget) =>
      palette.id != oldWidget.palette.id;
}

/// Sample copy for the demo preview. It is not saved profile data.
class _Sample {
  const _Sample({
    required this.slogan,
    required this.vision,
    required this.mission,
    required this.schemesLine,
    required this.joinLine,
    required this.about,
    required this.schemes,
    required this.news,
  });

  final String slogan;
  final String vision;
  final String mission;
  final String schemesLine;
  final String joinLine;
  final String about;
  final List<(IconData, String, String)> schemes;
  final List<(String, String)> news;

  static _Sample forId(String id) {
    return switch (id) {
      'BJP' => const _Sample(
        slogan: 'Sabka Saath, Sabka Vikas, Sabka Vishwas',
        vision: 'A developed India',
        mission: 'Inclusive growth',
        schemesLine: 'For a better tomorrow',
        joinLine: 'Be a part',
        about:
            'Sample text for this preview. A public representative working with citizens on development, welfare and local services. This is not a saved biography.',
        schemes: [
          (Icons.home_outlined, 'Housing support', 'Sample scheme'),
          (Icons.local_hospital_outlined, 'Health access', 'Sample scheme'),
          (Icons.devices_outlined, 'Digital services', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a development update for this preview.'),
          ('12 Oct', 'Sample: a youth programme notice.'),
          ('08 Oct', 'Sample: a rural outreach note.'),
        ],
      ),
      'INC' => const _Sample(
        slogan: 'Hand in Hand for a Better Tomorrow',
        vision: 'A progressive India',
        mission: 'People\'s welfare',
        schemesLine: 'Inclusive growth',
        joinLine: 'Stand together',
        about:
            'Sample text for this preview. A public representative focused on inclusion, welfare and equal opportunity. This is not a saved biography.',
        schemes: [
          (Icons.school_outlined, 'Education support', 'Sample scheme'),
          (Icons.favorite_outline, 'Welfare access', 'Sample scheme'),
          (Icons.groups_outlined, 'Community programmes', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a community update for this preview.'),
          ('12 Oct', 'Sample: an education notice.'),
          ('08 Oct', 'Sample: a welfare outreach note.'),
        ],
      ),
      'AAP' => const _Sample(
        slogan: 'Honest Politics. Better Governance.',
        vision: 'Corruption-free India',
        mission: 'People come first',
        schemesLine: 'Quality education',
        joinLine: 'Be the change',
        about:
            'Sample text for this preview. A public representative focused on schools, health and clean public services. This is not a saved biography.',
        schemes: [
          (Icons.school_outlined, 'School support', 'Sample scheme'),
          (Icons.local_hospital_outlined, 'Clinic access', 'Sample scheme'),
          (Icons.park_outlined, 'Clean neighbourhoods', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a civic update for this preview.'),
          ('12 Oct', 'Sample: a school notice.'),
          ('08 Oct', 'Sample: a health camp note.'),
        ],
      ),
      'BSP' => const _Sample(
        slogan: 'Sarvajan Hitay, Sarvajan Sukhay',
        vision: 'Social justice',
        mission: 'Equality for all',
        schemesLine: 'Empowerment',
        joinLine: 'For a prosperous India',
        about:
            'Sample text for this preview. A public representative focused on dignity, education and equal opportunity. This is not a saved biography.',
        schemes: [
          (Icons.school_outlined, 'Education for all', 'Sample scheme'),
          (Icons.work_outline, 'Livelihood support', 'Sample scheme'),
          (Icons.balance_outlined, 'Equal access', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a social justice update.'),
          ('12 Oct', 'Sample: an education notice.'),
          ('08 Oct', 'Sample: a community meeting note.'),
        ],
      ),
      'CPI(M)' => const _Sample(
        slogan: 'People\'s Power, Socialist Future',
        vision: 'A classless society',
        mission: 'Workers\' rights',
        schemesLine: 'People\'s welfare',
        joinLine: 'Fight for justice',
        about:
            'Sample text for this preview. A public representative focused on workers, public services and democratic rights. This is not a saved biography.',
        schemes: [
          (Icons.work_outline, 'Worker support', 'Sample scheme'),
          (Icons.home_outlined, 'Housing rights', 'Sample scheme'),
          (Icons.local_hospital_outlined, 'Public health', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a workers\' update for this preview.'),
          ('12 Oct', 'Sample: a public service notice.'),
          ('08 Oct', 'Sample: a community note.'),
        ],
      ),
      'NPP' => const _Sample(
        slogan: 'People\'s Voice, Our Strength',
        vision: 'Inclusive development',
        mission: 'People\'s participation',
        schemesLine: 'Better tomorrow',
        joinLine: 'Grow together',
        about:
            'Sample text for this preview. A public representative focused on education, health and local jobs. This is not a saved biography.',
        schemes: [
          (Icons.school_outlined, 'Education', 'Sample scheme'),
          (Icons.local_hospital_outlined, 'Healthcare', 'Sample scheme'),
          (Icons.work_outline, 'Employment', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a local development update.'),
          ('12 Oct', 'Sample: a health notice.'),
          ('08 Oct', 'Sample: a jobs programme note.'),
        ],
      ),
      _ => const _Sample(
        slogan: 'Working with people, every day',
        vision: 'Public service',
        mission: 'Community first',
        schemesLine: 'Local priorities',
        joinLine: 'Get involved',
        about:
            'Sample text for this preview. Add your own story after you generate the website. This is not a saved biography.',
        schemes: [
          (Icons.apartment_outlined, 'Local development', 'Sample scheme'),
          (Icons.groups_outlined, 'Citizen services', 'Sample scheme'),
          (Icons.park_outlined, 'Public spaces', 'Sample scheme'),
        ],
        news: [
          ('16 Oct', 'Sample: a preview update.'),
          ('12 Oct', 'Sample: a community notice.'),
          ('08 Oct', 'Sample: an event note.'),
        ],
      ),
    };
  }
}

/// Political-leader website. Only the name, party and hero photo are real.
class LeaderPortfolioSite extends StatelessWidget {
  const LeaderPortfolioSite({
    required this.draft,
    this.compact = false,
    this.scrollBody = true,
    this.themeParty,
    this.showDemoNote = true,
    super.key,
  });

  final WebsiteBuilderDraft draft;
  final bool compact;
  final bool showDemoNote;

  /// Shows this party's design. The leader name and photo still come from [draft].
  final String? themeParty;

  /// When false, the page grows with its content and the parent scrolls.
  final bool scrollBody;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partyName = (themeParty ?? draft.party).trim();
    final palette = PartyPalette.forParty(partyName);
    final displayName =
        draft.fullName.trim().isEmpty ? '' : formatPersonName(draft.fullName);
    final sample = _Sample.forId(palette.id);
    final nav = [
      l10n.portfolioNavHome,
      l10n.portfolioNavAbout,
      l10n.line('portfolioNavManifesto'),
      l10n.line('portfolioNavSchemes'),
      l10n.line('portfolioNavNews'),
      l10n.portfolioNavGallery,
      l10n.portfolioNavContact,
    ];
    final joinLabel =
        palette.id == PartyPalette.fallback.id
            ? l10n.line('portfolioJoinUs')
            : '${l10n.line('portfolioJoinUs').split(' ').first} ${palette.id}';
    final homeKey = GlobalKey();
    final aboutKey = GlobalKey();
    final schemeKey = GlobalKey();
    final newsKey = GlobalKey();
    final footerKey = GlobalKey();
    final sectionKeys = [
      homeKey,
      aboutKey,
      aboutKey,
      schemeKey,
      newsKey,
      newsKey,
      footerKey,
    ];
    void jump(int index) {
      final target = sectionKeys[index].currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 280),
        );
      }
    }

    return PartyTheme(
      key: ValueKey('party-theme-${palette.id}'),
      palette: palette,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final mobile = width < 768;
          final desktop = width >= 1024;
          final wide = !mobile;
          final columns = desktop ? 4 : (mobile ? 1 : 2);
          final pages = <Widget>[
            if (showDemoNote) const _DemoNote(),
            _Hero(
              key: homeKey,
              draft: draft,
              displayName: displayName,
              partyName: partyName,
              slogan: sample.slogan,
              joinLabel: joinLabel,
              knowMore: l10n.line('portfolioKnowMore'),
              wide: wide,
              onKnowMore: () {
                final target = aboutKey.currentContext;
                if (target != null) {
                  Scrollable.ensureVisible(
                    target,
                    duration: const Duration(milliseconds: 280),
                  );
                }
              },
            ),
            if (desktop)
              _QuickInfo(
                columns: columns,
                vision: sample.vision,
                mission: sample.mission,
                schemes: sample.schemesLine,
                join: sample.joinLine,
              ),
            _StoryRow(
              key: aboutKey,
              about: sample.about,
              vision: sample.vision,
              mission: sample.mission,
              wide: desktop,
            ),
            _SchemeCards(
              key: schemeKey,
              items: sample.schemes,
              columns: mobile ? 1 : 3,
            ),
            _GalleryNews(key: newsKey, news: sample.news, wide: desktop),
            if (desktop)
              _SiteFooter(
                key: footerKey,
                partyName: partyName,
                slogan: sample.slogan,
                nav: nav,
              ),
          ];
          final header = Material(
            elevation: 1,
            color: Colors.white,
            child: SizedBox(
              height: mobile ? 60 : 68,
              child: _Header(
                partyName: partyName,
                nav: nav,
                joinLabel: joinLabel,
                compact: mobile,
                onSelect: jump,
              ),
            ),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: pages,
          );
          if (!scrollBody) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, content],
            );
          }
          return Column(
            children: [
              header,
              Expanded(child: SingleChildScrollView(child: content)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.partyName,
    required this.nav,
    required this.joinLabel,
    required this.compact,
    required this.onSelect,
  });

  final String partyName;
  final List<String> nav;
  final String joinLabel;
  final bool compact;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final links = [
      for (var index = 0; index < nav.length; index++)
        InkWell(
          onTap: () => onSelect(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              nav[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: index == 0 ? FontWeight.w800 : FontWeight.w500,
                color: index == 0 ? palette.primary : palette.muted,
              ),
            ),
          ),
        ),
    ];
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (partyName.isNotEmpty) ...[
                  _PartyMark(partyName: partyName, diameter: 32),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      partyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                if (!compact)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bar) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: bar.maxWidth),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: links,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Spacer(),
                if (compact)
                  PopupMenuButton<int>(
                    tooltip: 'Menu',
                    icon: Icon(Icons.menu, color: palette.ink),
                    onSelected: onSelect,
                    itemBuilder:
                        (context) => [
                          for (var i = 0; i < nav.length; i++)
                            PopupMenuItem(value: i, child: Text(nav[i])),
                        ],
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => onSelect(nav.length - 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        joinLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 3, color: palette.accent),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    super.key,
    required this.draft,
    required this.displayName,
    required this.partyName,
    required this.slogan,
    required this.joinLabel,
    required this.knowMore,
    required this.wide,
    required this.onKnowMore,
  });

  final WebsiteBuilderDraft draft;
  final String displayName;
  final String partyName;
  final String slogan;
  final String joinLabel;
  final String knowMore;
  final bool wide;
  final VoidCallback onKnowMore;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final photo = SizedBox(
      key: const ValueKey('websiteHeroPhoto'),
      width: wide ? 160 : 140,
      height: wide ? 190 : 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child:
            draft.profilePhoto.hasImage
                ? _Media(draft.profilePhoto)
                : ColoredBox(
                  color:
                      palette.darkHero
                          ? Colors.white24
                          : const Color(0xFFCBD5E1),
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: palette.darkHero ? Colors.white : Colors.white,
                  ),
                ),
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (partyName.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PartyMark(partyName: partyName, diameter: wide ? 64 : 52),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  partyName,
                  key: const ValueKey('websitePartyName'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: wide ? 32 : 26,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
        if (slogan.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            slogan,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: wide ? 18 : 16,
            ),
          ),
        ],
        if (displayName.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.onHero,
            ),
          ),
          Text(
            'Sample role · Public representative · Sample constituency',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: palette.onHero.withValues(alpha: 0.85),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(label: knowMore, onPressed: onKnowMore, filled: true),
            _ActionButton(label: joinLabel, filled: false),
          ],
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [palette.hero, palette.primary, palette.accent],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24,
            top: 12,
            bottom: 12,
            width: wide ? 280 : 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.primary.withValues(alpha: 0.18),
                    palette.accent.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          if (palette.id == 'NPP')
            const Positioned(left: 0, right: 0, bottom: 0, child: _Hill()),
          Padding(
            padding: EdgeInsets.fromLTRB(20, wide ? 36 : 20, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child:
                    wide
                        ? Row(
                          key: const ValueKey('hero-layout-row'),
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: copy),
                            const SizedBox(width: 28),
                            photo,
                          ],
                        )
                        : Column(
                          key: const ValueKey('hero-layout-column'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [copy, const SizedBox(height: 16), photo],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hill extends StatelessWidget {
  const _Hill();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HillPainter(PartyTheme.of(context).accent),
      size: const Size(double.infinity, 36),
    );
  }
}

class _HillPainter extends CustomPainter {
  _HillPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.55);
    final path =
        Path()
          ..moveTo(0, size.height)
          ..quadraticBezierTo(
            size.width * 0.25,
            0,
            size.width * 0.5,
            size.height * 0.7,
          )
          ..quadraticBezierTo(
            size.width * 0.75,
            size.height,
            size.width,
            size.height * 0.2,
          )
          ..lineTo(size.width, size.height)
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HillPainter oldDelegate) => oldDelegate.color != color;
}

String _partyHeadline(String id) {
  return switch (id) {
    'BJP' => 'Sabka Saath, Sabka Vikas, Sabka Vishwas',
    'INC' => 'Hand in Hand for a Better Tomorrow',
    'AAP' => 'Honest Politics. Better Governance.',
    'BSP' => 'Sarvajan Hitay, Sarvajan Sukhay',
    'CPI(M)' => 'People\'s Power, Socialist Future',
    'NPP' => 'People\'s Voice, Our Strength',
    _ => '',
  };
}

List<(IconData, String)> _focusItems(String id) {
  return switch (id) {
    'BJP' => [
      (Icons.apartment_outlined, 'Development'),
      (Icons.account_balance_outlined, 'Good Governance'),
      (Icons.devices_outlined, 'Digital India'),
      (Icons.flag_outlined, 'Self-Reliant India'),
    ],
    'INC' => [
      (Icons.public_outlined, 'A Progressive India'),
      (Icons.favorite_outline, 'People\'s Welfare'),
      (Icons.groups_outlined, 'Inclusive Growth'),
      (Icons.handshake_outlined, 'Stronger Together'),
    ],
    'AAP' => [
      (Icons.school_outlined, 'Free Education'),
      (Icons.local_hospital_outlined, 'Better Healthcare'),
      (Icons.park_outlined, 'Clean & Green'),
      (Icons.trending_up, 'Development for All'),
    ],
    'BSP' => [
      (Icons.balance_outlined, 'Social Justice'),
      (Icons.school_outlined, 'Education for All'),
      (Icons.show_chart, 'Economic Growth'),
      (Icons.volunteer_activism_outlined, 'Empowerment'),
    ],
    'CPI(M)' => [
      (Icons.groups_outlined, 'People\'s Power'),
      (Icons.work_outline, 'Workers\' Rights'),
      (Icons.gavel_outlined, 'Social Justice'),
      (Icons.flag_outlined, 'Democratic India'),
    ],
    'NPP' => [
      (Icons.school_outlined, 'Education'),
      (Icons.local_hospital_outlined, 'Healthcare'),
      (Icons.work_outline, 'Employment'),
      (Icons.account_balance_outlined, 'Good Governance'),
    ],
    _ => [
      (Icons.visibility_outlined, 'Public Service'),
      (Icons.groups_outlined, 'Community'),
      (Icons.apartment_outlined, 'Development'),
      (Icons.flag_outlined, 'Our Priorities'),
    ],
  };
}

class _FocusAreas extends StatelessWidget {
  const _FocusAreas({required this.partyId, required this.columns});

  final String partyId;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final items = _focusItems(partyId);
    return ColoredBox(
      color: palette.hero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Focus Areas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.darkHero ? palette.ink : palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 3.2 : 1.6,
                  children: [
                    for (final item in items)
                      _InfoCard(icon: item.$1, title: item.$2, body: ''),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  const _QuickInfo({
    required this.columns,
    required this.vision,
    required this.mission,
    required this.schemes,
    required this.join,
  });

  final int columns;
  final String vision;
  final String mission;
  final String schemes;
  final String join;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      (Icons.visibility_outlined, l10n.line('portfolioOurVision'), vision),
      (Icons.flag_outlined, l10n.line('portfolioOurMission'), mission),
      (
        Icons.account_balance_outlined,
        l10n.line('portfolioOurSchemes'),
        schemes,
      ),
      (Icons.groups_outlined, l10n.line('portfolioJoinUs'), join),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, box) {
              final tile = (box.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: tile,
                      child: _InfoCard(
                        icon: card.$1,
                        title: card.$2,
                        body: card.$3,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.ink,
                fontSize: 13,
              ),
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: palette.body,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.parts, required this.photo, required this.wide});

  final List<(String, String)> parts;
  final MediaRef photo;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final part in parts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              part.$2,
              style: TextStyle(fontSize: 14, height: 1.5, color: palette.body),
            ),
          ),
      ],
    );
    return Padding(
      key: const ValueKey('aboutTheLeader'),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioAboutLeader'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (wide && photo.hasImage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 140,
                    height: 168,
                    child: _Media(photo),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: text),
              ],
            )
          else ...[
            if (photo.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _Media(photo),
                ),
              ),
              const SizedBox(height: 10),
            ],
            text,
          ],
        ],
      ),
    );
  }
}

class _VisionBlock extends StatelessWidget {
  const _VisionBlock({
    required this.vision,
    required this.mission,
    required this.priorities,
  });

  final String vision;
  final String mission;
  final String priorities;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    final blocks = [
      if (vision.isNotEmpty) (l10n.line('portfolioOurVision'), vision),
      if (mission.isNotEmpty) (l10n.line('portfolioOurMission'), mission),
      if (priorities.isNotEmpty)
        (l10n.line('portfolioVisionMission'), priorities),
    ];
    return ColoredBox(
      color: palette.darkHero ? const Color(0xFFFFF7F7) : palette.hero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.line('portfolioVisionMission'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final block in blocks) ...[
              Text(
                block.$1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                block.$2,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: palette.body,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.items, required this.wide});

  final Iterable<AchievementEntry> items;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              l10n.line('portfolioAchievementsWork'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.ink,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = wide ? 3 : 1;
              final tile =
                  (constraints.maxWidth - 10 * (columns - 1)) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tile,
                      child: _InfoCard(
                        icon: Icons.workspace_premium_outlined,
                        title: item.title.trim(),
                        body: [
                          if (item.dateOrYear.trim().isNotEmpty)
                            item.dateOrYear.trim(),
                          if (item.description.trim().isNotEmpty)
                            item.description.trim(),
                        ].join('\n'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Schemes extends StatelessWidget {
  const _Schemes({required this.items});

  final Iterable<ProjectEntry> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioSchemesTitle'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E5E4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.photo.hasImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: _Media(item.photo),
                          ),
                        ),
                      if (item.name.trim().isNotEmpty)
                        Text(
                          item.name.trim(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                          ),
                        ),
                      if (item.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.body, fontSize: 13),
                        ),
                        TextButton(
                          onPressed:
                              () => _showCopy(
                                context,
                                item.name.trim(),
                                item.description.trim(),
                              ),
                          child: Text(l10n.line('portfolioReadMore')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.items, required this.columns});

  final Iterable<MediaRef> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portfolioNavGallery,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final tile =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    GestureDetector(
                      onTap: () => _openImage(context, item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: tile,
                          height: tile,
                          child: _Media(item),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _News extends StatelessWidget {
  const _News({required this.items});

  final Iterable<AnnouncementEntry> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioNewsUpdates'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            if (item.title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InfoCard(
                  icon: Icons.newspaper_outlined,
                  title: [
                    if (item.publicationDate.trim().isNotEmpty)
                      item.publicationDate.trim(),
                    item.title.trim(),
                  ].join(' · '),
                  body: item.description.trim(),
                ),
              ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({
    required this.draft,
    required this.location,
    required this.partyName,
  });

  final WebsiteBuilderDraft draft;
  final String location;
  final String partyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    final lines = <String>[
      if (draft.phone.trim().isNotEmpty) draft.phone.trim(),
      if (draft.officialPhone.trim().isNotEmpty) draft.officialPhone.trim(),
      if (draft.email.trim().isNotEmpty) draft.email.trim(),
      if (draft.officialEmail.trim().isNotEmpty) draft.officialEmail.trim(),
      if (draft.officeAddress.trim().isNotEmpty) draft.officeAddress.trim(),
      if (location.isNotEmpty) location,
    ];
    final socials = <String>[
      draft.facebookUrl,
      draft.instagramUrl,
      draft.youtubeUrl,
      draft.twitterUrl,
      draft.linkedinUrl,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty);
    if (lines.isEmpty && socials.isEmpty && partyName.isEmpty) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: palette.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.portfolioNavContact,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            for (final link in socials)
              Text(
                link,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            if (partyName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _PartyMark(partyName: partyName, diameter: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.partyName,
    required this.nav,
    required this.phone,
    required this.email,
  });

  final String partyName;
  final List<String> nav;
  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final year = DateTime.now().year;
    final owner = partyName.isNotEmpty ? partyName : 'Political party';
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (partyName.isNotEmpty)
              Row(
                children: [
                  _PartyMark(partyName: partyName, diameter: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final label in nav)
                  Text(
                    label,
                    style: TextStyle(color: palette.accent, fontSize: 12),
                  ),
              ],
            ),
            if (phone.isNotEmpty)
              Text(
                phone,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            if (email.isNotEmpty)
              Text(
                email,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Text(
              '© $year $owner',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: filled ? Colors.white : Colors.white),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: filled ? palette.primary : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyMark extends StatelessWidget {
  const _PartyMark({required this.partyName, required this.diameter});

  final String partyName;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    if (partyName.trim().isEmpty)
      return SizedBox(width: diameter, height: diameter);
    return PartySymbol(
      partyName,
      key: ValueKey('websitePartyLogo-${PartyOption.symbolFor(partyName)}'),
      diameter: diameter,
    );
  }
}

class _Media extends StatelessWidget {
  const _Media(this.ref);

  final MediaRef ref;

  @override
  Widget build(BuildContext context) {
    final bytes = ref.bytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (ref.url.trim().isNotEmpty) {
      return Image.network(
        ref.url,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => const ColoredBox(
              color: Color(0xFFE5E7EB),
              child: Icon(Icons.broken_image_outlined),
            ),
      );
    }
    return const ColoredBox(
      color: Color(0xFFE5E7EB),
      child: Icon(Icons.image_outlined),
    );
  }
}

void _showCopy(BuildContext context, String title, String body) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title.isEmpty ? body : title),
        content: title.isEmpty ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _DemoNote extends StatelessWidget {
  const _DemoNote();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFF7ED),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Demo preview. Only the leader name, party and hero photo are from the saved profile. Every other detail is sample text.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9A3412),
          ),
        ),
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({
    required this.about,
    required this.vision,
    required this.mission,
    required this.wide,
    super.key,
  });

  final String about;
  final String vision;
  final String mission;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = PartyTheme.of(context);
    final aboutCard = Padding(
      key: const ValueKey('aboutTheLeader'),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioAboutLeader'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            about,
            style: TextStyle(fontSize: 13, height: 1.45, color: palette.body),
          ),
        ],
      ),
    );
    final visionCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vision & Mission',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.visibility_outlined,
          title: 'Our Vision',
          body: vision,
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.track_changes,
          title: 'Our Mission',
          body: mission,
        ),
      ],
    );
    const stats = [
      ('100+', 'Development Projects'),
      ('50+', 'Welfare Schemes'),
      ('1M+', 'Happy Citizens'),
      ('100%', 'Commitment'),
    ];
    final statCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.line('portfolioAchievementsWork'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stat in stats)
              SizedBox(
                width: 120,
                child: _InfoCard(
                  icon: Icons.bar_chart,
                  title: stat.$1,
                  body: stat.$2,
                ),
              ),
          ],
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child:
              wide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: aboutCard),
                      Expanded(child: visionCard),
                      Expanded(child: statCard),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [aboutCard],
                  ),
        ),
      ),
    );
  }
}

const _schemePhotos = [
  'assets/images/website_samples/scheme_housing.jpg',
  'assets/images/website_samples/scheme_health.jpg',
  'assets/images/website_samples/scheme_education.jpg',
];

const _galleryPhotos = [
  'assets/images/website_samples/gallery_crowd.jpg',
  'assets/images/website_samples/gallery_village.jpg',
  'assets/images/website_samples/gallery_meeting.jpg',
  'assets/images/website_samples/gallery_youth.jpg',
  'assets/images/website_samples/gallery_books.jpg',
  'assets/images/website_samples/gallery_hills.jpg',
];

const _newsPhotos = [
  'assets/images/website_samples/news_farm.jpg',
  'assets/images/website_samples/news_youth.jpg',
  'assets/images/website_samples/news_road.jpg',
];

Widget _schemeTile(
  PartyPalette palette,
  (IconData, String, String) item,
  String photo,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              photo,
              height: 92,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
                Text(
                  item.$3,
                  style: TextStyle(fontSize: 12, color: palette.body),
                ),
                Text(
                  'Know More',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SchemeCards extends StatelessWidget {
  const _SchemeCards({super.key, required this.items, required this.columns});

  final List<(IconData, String, String)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schemes and Initiatives',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) {
                  final gaps = columns - 1;
                  final tile = (box.maxWidth - 12 * gaps) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          width: tile,
                          child: _schemeTile(
                            palette,
                            items[i],
                            _schemePhotos[i % _schemePhotos.length],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryNews extends StatelessWidget {
  const _GalleryNews({super.key, required this.news, required this.wide});

  final List<(String, String)> news;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final gallery = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final photo in _galleryPhotos)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  photo,
                  width: 96,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ],
    );
    final updates = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'News & Updates',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text('Sample headlines', style: TextStyle(fontSize: 12)),
        for (var i = 0; i < news.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _newsPhotos[i % _newsPhotos.length],
                    width: 72,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news[i].$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.primary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        news[i].$2,
                        style: TextStyle(fontSize: 13, color: palette.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child:
              wide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: gallery),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: updates),
                    ],
                  )
                  : Column(
                    children: [gallery, const SizedBox(height: 16), updates],
                  ),
        ),
      ),
    );
  }
}

class _SiteFooter extends StatelessWidget {
  const _SiteFooter({
    super.key,
    required this.partyName,
    required this.slogan,
    required this.nav,
  });

  final String partyName;
  final String slogan;
  final List<String> nav;

  @override
  Widget build(BuildContext context) {
    final palette = PartyTheme.of(context);
    final name = partyName.isEmpty ? 'Your party' : partyName;
    return ColoredBox(
      color: palette.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 28,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (partyName.isNotEmpty)
                            Row(
                              children: [
                                _PartyMark(partyName: partyName, diameter: 36),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Text(
                            slogan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Links',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          for (final label in nav.take(5))
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Sample · 00000 00000',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'sample@example.com',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Sample office address',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '© ${DateTime.now().year} $name. Sample preview. All rights reserved.',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openImage(BuildContext context, MediaRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 280, width: double.infinity, child: _Media(ref)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
  );
}
