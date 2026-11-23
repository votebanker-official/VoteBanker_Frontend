import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routing/app_routes.dart';
import '../constants/app_assets.dart';

/// Shared VoteBanker footer. One instance is mounted by [AppFooterShell].
class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key});

  static const columnBreakpoint = 900.0;

  static const navy = Color(0xFF102258);
  static const muted = Color(0xFF6F748B);
  static const line = Color(0xFFE0E2EA);
  static const rule = Color(0xFFE8E9EB);

  /// Official VoteBanker profiles. An empty value stays visible and does not
  /// open a guessed address.
  static const socialUrls = <String, String>{
    'facebook': '',
    'x': '',
    'instagram': '',
    'linkedin': '',
  };

  static const _quickLinks = <_FooterDest>[
    _FooterDest('Features', null, 'footer-link-features'),
    _FooterDest(
      'Website Builder',
      AppRoutes.website,
      'footer-link-website-builder',
    ),
    _FooterDest(
      'Voter Management',
      AppRoutes.vrmRecords,
      'footer-link-voter-management',
    ),
    _FooterDest(
      'Merchandise',
      AppRoutes.merchandise,
      'footer-link-merchandise',
    ),
  ];

  static const _supportLinks = <_FooterDest>[
    _FooterDest('Help Center / FAQs', null, 'footer-link-help'),
    _FooterDest('Contact Support', null, 'footer-link-contact'),
    _FooterDest('Pricing / Plans', null, 'footer-link-pricing'),
  ];

  static const _companyLinks = <_FooterDest>[
    _FooterDest('About Us', null, 'footer-link-about'),
    _FooterDest('Campaign Guides', null, 'footer-link-guides'),
  ];

  static const _legalLinks = <_FooterDest>[
    _FooterDest('Privacy Policy', null, 'footer-link-privacy'),
    _FooterDest('Terms & Conditions', null, 'footer-link-terms'),
    _FooterDest('Election Disclaimer', null, 'footer-link-disclaimer'),
    _FooterDest('Refund & Shipping Policy', null, 'footer-link-refund'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      key: const Key('global-footer'),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= columnBreakpoint;
          final pad =
              width >= 1200
                  ? 40.0
                  : width >= 1000
                  ? 28.0
                  : 20.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 22, pad, 18),
                child:
                    columns
                        ? const _DesktopColumns()
                        : const _StackedSections(),
              ),
              const Divider(height: 1, thickness: 1, color: rule),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 14, pad, 14 + bottom),
                child: _BottomBar(wide: width >= 1040),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Puts [child] in the remaining viewport and the footer along the bottom.
///
/// Wide, tall windows show the full footer. Narrow or short windows keep the
/// page usable and scroll the footer when it is taller than the slot.
class AppFooterShell extends StatelessWidget {
  const AppFooterShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= GlobalFooter.columnBreakpoint;
          final footer = const GlobalFooter();
          if (wide && constraints.maxHeight >= 680) {
            return Column(children: [Expanded(child: child), footer]);
          }
          final ratio = wide ? 0.4 : 0.5;
          final cap = math.min(
            wide ? 280.0 : 460.0,
            math.max(140.0, constraints.maxHeight * ratio),
          );
          final height = math.min(cap, math.max(0.0, constraints.maxHeight));
          return Column(
            children: [
              Expanded(child: child),
              SizedBox(
                height: height,
                child: SingleChildScrollView(primary: false, child: footer),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopColumns extends StatelessWidget {
  const _DesktopColumns();

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.topCenter, child: _Logo()),
          _VRule(),
          Expanded(flex: 5, child: _BrandCopy()),
          _VRule(),
          Expanded(
            flex: 4,
            child: _LinkColumn(
              title: 'Quick Links',
              links: GlobalFooter._quickLinks,
            ),
          ),
          _VRule(),
          Expanded(
            flex: 4,
            child: _LinkColumn(
              title: 'Support',
              links: GlobalFooter._supportLinks,
            ),
          ),
          _VRule(),
          Expanded(
            flex: 4,
            child: _LinkColumn(
              title: 'Company',
              links: GlobalFooter._companyLinks,
            ),
          ),
          _VRule(),
          Expanded(flex: 5, child: _FollowUs()),
        ],
      ),
    );
  }
}

class _StackedSections extends StatelessWidget {
  const _StackedSections();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandBlock(),
        SizedBox(height: 22),
        _LinkColumn(
          title: 'Quick Links',
          links: GlobalFooter._quickLinks,
          touch: true,
        ),
        SizedBox(height: 16),
        _LinkColumn(
          title: 'Support',
          links: GlobalFooter._supportLinks,
          touch: true,
        ),
        SizedBox(height: 16),
        _LinkColumn(
          title: 'Company',
          links: GlobalFooter._companyLinks,
          touch: true,
        ),
        SizedBox(height: 16),
        _FollowUs(),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_Logo(), SizedBox(width: 14), Expanded(child: _BrandCopy())],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: 58,
      height: 58,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'VoteBanker',
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VoteBanker',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: family,
            color: GlobalFooter.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Empowering Modern Political Campaigns & Voter Outreach.',
          style: TextStyle(
            fontFamily: family,
            color: GlobalFooter.navy,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({
    required this.title,
    required this.links,
    this.touch = false,
  });

  final String title;
  final List<_FooterDest> links;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: family,
            color: GlobalFooter.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: touch ? 6 : 8),
        for (final link in links)
          _FooterLink(dest: link, touch: touch, family: family),
      ],
    );
  }
}

class _FollowUs extends StatelessWidget {
  const _FollowUs();

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow Us',
          style: TextStyle(
            fontFamily: family,
            color: GlobalFooter.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SocialButton(
              name: 'Facebook',
              urlKey: 'facebook',
              buttonKey: Key('footer-social-facebook'),
              background: Color(0xFF1877F2),
              child: Icon(Icons.facebook, color: Colors.white, size: 18),
            ),
            _SocialButton(
              name: 'X',
              urlKey: 'x',
              buttonKey: Key('footer-social-x'),
              background: Color(0xFF111111),
              child: _SvgMark(_xSvg),
            ),
            _SocialButton(
              name: 'Instagram',
              urlKey: 'instagram',
              buttonKey: Key('footer-social-instagram'),
              gradient: _instagramGradient,
              child: _SvgMark(_instagramSvg),
            ),
            _SocialButton(
              name: 'LinkedIn',
              urlKey: 'linkedin',
              buttonKey: Key('footer-social-linkedin'),
              background: Color(0xFF0A66C2),
              child: Text(
                'in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final copy = Text(
      '© 2026 VoteBanker. All rights reserved.',
      style: TextStyle(
        fontFamily: family,
        color: GlobalFooter.muted,
        fontSize: 13,
        height: 1.3,
      ),
    );
    final legal = _LegalLinks(family: family);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [copy, const SizedBox(height: 10), legal],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: copy),
        const SizedBox(width: 16),
        Expanded(child: Align(alignment: Alignment.centerRight, child: legal)),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.family});

  final String? family;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < GlobalFooter._legalLinks.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '|',
                style: TextStyle(
                  fontFamily: family,
                  color: GlobalFooter.muted,
                  fontSize: 13,
                ),
              ),
            ),
          _FooterLink(
            dest: GlobalFooter._legalLinks[i],
            family: family,
            muted: true,
          ),
        ],
      ],
    );
  }
}

class _FooterDest {
  const _FooterDest(this.label, this.route, this.keyName);

  final String label;
  final String? route;
  final String keyName;
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.dest,
    required this.family,
    this.touch = false,
    this.muted = false,
  });

  final _FooterDest dest;
  final String? family;
  final bool touch;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? GlobalFooter.muted : GlobalFooter.navy;
    final linked = dest.route != null;
    return MouseRegion(
      cursor: linked ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        key: Key(dest.keyName),
        onTap: linked ? () => _open(context, dest.route!) : null,
        borderRadius: BorderRadius.circular(4),
        hoverColor: const Color(0x14102258),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: touch ? 12 : 4),
          child: Text(
            dest.label,
            style: TextStyle(
              fontFamily: family,
              color: color,
              fontSize: muted ? 13 : 14,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current != null && current.isNotEmpty) {
      final path = Uri.parse(current).path;
      final normalized =
          path.length > 1 && path.endsWith('/')
              ? path.substring(0, path.length - 1)
              : path;
      if (normalized == route) return;
    }
    AppNav.open(context, route);
  }
}

class _VRule extends StatelessWidget {
  const _VRule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: VerticalDivider(width: 1, thickness: 1, color: GlobalFooter.line),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.name,
    required this.urlKey,
    required this.buttonKey,
    required this.child,
    this.background,
    this.gradient,
  });

  final String name;
  final String urlKey;
  final Key buttonKey;
  final Widget child;
  final Color? background;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final url = GlobalFooter.socialUrls[urlKey] ?? '';
    return Tooltip(
      message: name,
      child: Semantics(
        button: url.isNotEmpty,
        link: url.isNotEmpty,
        label: name,
        child: Material(
          color: gradient == null ? background : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: buttonKey,
            onTap: url.isEmpty ? null : () => _launch(url),
            customBorder: const CircleBorder(),
            child: Ink(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradient == null ? background : null,
                gradient: gradient,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SvgMark extends StatelessWidget {
  const _SvgMark(this.svg);

  final String svg;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(svg, width: 15, height: 15);
  }
}

const _instagramGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [
    Color(0xFFFEDA77),
    Color(0xFFF58529),
    Color(0xFFDD2A7B),
    Color(0xFF8134AF),
    Color(0xFF515BD4),
  ],
);

const _xSvg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path fill="#fff" d="M28.4 14h3.3l-7.2 8.2L33 34h-6.6l-5.2-6.8L15.4 34H12l7.7-8.8L15 14h6.8l4.7 6.2L28.4 14zm-1.2 18h1.8L20.9 16h-2l8.3 16z"/>
</svg>
''';

const _instagramSvg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="13" width="22" height="22" rx="7" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="24" cy="24" r="5.2" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="32.2" cy="15.8" r="1.7" fill="#fff"/>
</svg>
''';
