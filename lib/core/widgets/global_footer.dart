import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../app/routing/app_routes.dart';
import '../constants/app_assets.dart';

/// Shared VoteBanker footer. One instance is mounted by [AppFooterShell].
class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key});

  static const columnBreakpoint = 1080.0;

  static const navy = Color(0xFF102D68);
  static const blue = Color(0xFF1765C5);
  static const teal = Color(0xFF13B8C5);
  static const canvas = Color(0xFFF3F8FF);
  static const text = Color(0xFF263B60);
  static const pill = Color(0xFFD9F6FC);
  static const companyName = 'Voter Relationship Management Private Limited';
  static const copyrightLine =
      '© 2026 Voter Relationship Management Private Limited. All rights reserved.';

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
    _FooterDest('Help Center / FAQs', AppRoutes.helpCenter, 'footer-link-help'),
    _FooterDest(
      'Contact Support',
      AppRoutes.contactSupport,
      'footer-link-contact',
    ),
  ];

  static const _companyLinks = <_FooterDest>[
    _FooterDest('About Us', AppRoutes.about, 'footer-link-about'),
    _FooterDest('Campaign Guides', null, 'footer-link-guides'),
  ];

  static const _legalLinks = <_FooterDest>[
    _FooterDest(
      'Privacy Policy',
      AppRoutes.privacyPolicy,
      'footer-link-privacy',
      icon: Icons.shield_outlined,
    ),
    _FooterDest(
      'Terms & Conditions',
      AppRoutes.terms,
      'footer-link-terms',
      icon: Icons.description_outlined,
    ),
    _FooterDest(
      'Data Deletion',
      AppRoutes.dataDeletion,
      'footer-link-deletion',
      icon: Icons.delete_outline,
    ),
    _FooterDest(
      'Election Disclaimer',
      AppRoutes.electionDisclaimer,
      'footer-link-disclaimer',
      icon: Icons.balance_outlined,
    ),
    _FooterDest(
      'Refund & Shipping Policy',
      AppRoutes.refundPolicy,
      'footer-link-refund',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return CustomPaint(
      key: const Key('global-footer'),
      painter: const _FooterWavePainter(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final pad =
              width >= 1200
                  ? 32.0
                  : width >= 720
                  ? 22.0
                  : 16.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 22, pad, 18),
                child: _FooterBody(width: width),
              ),
              const ColoredBox(color: teal, child: SizedBox(height: 1)),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 14, pad, 14 + bottom),
                child: _BottomBar(wide: width >= 1100),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lays [child] out above [GlobalFooter] in one vertical scroll.
///
/// Short pages keep the footer on the bottom of the viewport. Long pages
/// scroll through the content and then the full footer. The footer is never
/// placed beside the page and is never height-capped.
class AppFooterShell extends StatefulWidget {
  const AppFooterShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppFooterShell> createState() => _AppFooterShellState();
}

class _AppFooterShellState extends State<AppFooterShell> {
  final _outer = ScrollController();
  final _pageKey = GlobalKey();
  final _footerKey = GlobalKey();
  double _footerHeight = 0;
  double _contentHeight = 0;
  double _appliedPageExtent = 0;
  bool _long = false;

  @override
  void dispose() {
    _outer.dispose();
    super.dispose();
  }

  double _pageExtent(double viewport) {
    if (viewport <= 0) return 0;
    if (_long && _contentHeight > 0) return _contentHeight;
    if (_long || _footerHeight <= 0) return viewport;
    final fitted = viewport - _footerHeight;
    if (fitted >= 160) return fitted;
    return math.min(viewport, math.max(160.0, viewport * 0.42));
  }

  double _overflowExtent() {
    final pageContext = _pageKey.currentContext;
    if (pageContext == null) return 0;
    var extent = 0.0;
    void walk(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        try {
          final position = state.position;
          if (position.hasContentDimensions) {
            extent = math.max(extent, position.maxScrollExtent);
          }
        } catch (_) {}
      }
      element.visitChildren(walk);
    }

    pageContext.visitChildElements(walk);
    return extent;
  }

  void _sync() {
    if (!mounted) return;
    final footerBox =
        _footerKey.currentContext?.findRenderObject() as RenderBox?;
    final footerHeight =
        footerBox != null && footerBox.hasSize
            ? footerBox.size.height
            : _footerHeight;
    final overflow = _overflowExtent();
    if (overflow > 2) {
      final contentHeight = _appliedPageExtent + overflow;
      final footerChanged = (footerHeight - _footerHeight).abs() > 0.5;
      if (!_long ||
          footerChanged ||
          (contentHeight - _contentHeight).abs() > 2) {
        setState(() {
          _long = true;
          _contentHeight = contentHeight;
          _footerHeight = footerHeight;
        });
      }
      return;
    }
    final footerChanged = (footerHeight - _footerHeight).abs() > 0.5;
    if (footerChanged) {
      setState(() => _footerHeight = footerHeight);
    }
  }

  bool _innerCanScroll(double delta) {
    final pageContext = _pageKey.currentContext;
    if (pageContext == null || delta == 0) return false;
    var can = false;
    void walk(Element element) {
      if (can) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        try {
          final position = (element.state as ScrollableState).position;
          if (!position.hasContentDimensions) return;
          if (delta > 0 && position.pixels < position.maxScrollExtent - 1) {
            can = true;
          }
          if (delta < 0 && position.pixels > position.minScrollExtent + 1) {
            can = true;
          }
        } catch (_) {}
      }
      element.visitChildren(walk);
    }

    pageContext.visitChildElements(walk);
    return can;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_outer.hasClients) return;
    final delta = event.scrollDelta.dy;
    if (delta == 0 || _innerCanScroll(delta)) return;
    final position = _outer.position;
    final next = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
    if ((next - position.pixels).abs() > 0.5) position.jumpTo(next);
  }

  bool _onOverscroll(OverscrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical || notification.depth == 0) {
      return false;
    }
    if (!_outer.hasClients) return false;
    final position = _outer.position;
    final next = (position.pixels + notification.overscroll).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if ((next - position.pixels).abs() > 0.5) {
      position.jumpTo(next);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final pageExtent = _pageExtent(height);
          _appliedPageExtent = pageExtent;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _sync();
            // #region agent log
            if (kIsWeb) {
              _logFooterPlacement(context, width, height, pageExtent, _long);
            }
            // #endregion
          });
          return SizedBox(
            width: width,
            height: height,
            child: Listener(
              onPointerSignal: _onPointerSignal,
              child: NotificationListener<OverscrollNotification>(
                onNotification: _onOverscroll,
                child: SingleChildScrollView(
                  controller: _outer,
                  primary: false,
                  child: _PageWithFooter(
                    minHeight: height,
                    pageHeight: pageExtent,
                    page: ClipRect(
                      child: KeyedSubtree(key: _pageKey, child: widget.child),
                    ),
                    footer: KeyedSubtree(
                      key: _footerKey,
                      child: const GlobalFooter(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageWithFooter extends MultiChildRenderObjectWidget {
  _PageWithFooter({
    required this.minHeight,
    required this.pageHeight,
    required Widget page,
    required Widget footer,
  }) : super(children: [page, footer]);

  final double minHeight;
  final double pageHeight;

  @override
  RenderPageWithFooter createRenderObject(BuildContext context) {
    return RenderPageWithFooter(minHeight: minHeight, pageHeight: pageHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPageWithFooter renderObject,
  ) {
    renderObject
      ..minHeight = minHeight
      ..pageHeight = pageHeight;
  }
}

class _PageFooterParentData extends ContainerBoxParentData<RenderBox> {}

/// Vertical page-then-footer layout. The page is given a real height so
/// existing scaffolds can lay out, and the footer is always placed after it
/// at its natural height.
class RenderPageWithFooter extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PageFooterParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PageFooterParentData> {
  RenderPageWithFooter({required double minHeight, required double pageHeight})
    : _minHeight = minHeight,
      _pageHeight = pageHeight;

  double _minHeight;
  double _pageHeight;

  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  set pageHeight(double value) {
    if (_pageHeight == value) return;
    _pageHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PageFooterParentData) {
      child.parentData = _PageFooterParentData();
    }
  }

  @override
  void performLayout() {
    final page = firstChild;
    final footer = page == null ? null : childAfter(page);
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    if (page == null || footer == null) {
      size = Size(
        width,
        constraints.hasBoundedHeight ? constraints.minHeight : 0,
      );
      return;
    }
    final pageHeight = math.max(0.0, _pageHeight);
    page.layout(
      BoxConstraints.tightFor(width: width, height: pageHeight),
      parentUsesSize: true,
    );
    footer.layout(
      BoxConstraints(minWidth: width, maxWidth: width),
      parentUsesSize: true,
    );
    final stacked = page.size.height + footer.size.height;
    final height = math.max(_minHeight, stacked);
    size = Size(width, height);
    (page.parentData! as _PageFooterParentData).offset = Offset.zero;
    final footerY =
        stacked + 0.5 < height ? height - footer.size.height : page.size.height;
    (footer.parentData! as _PageFooterParentData).offset = Offset(0, footerY);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

class _FooterBody extends StatelessWidget {
  const _FooterBody({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final touch = width < GlobalFooter.columnBreakpoint;
    final quick = _LinkColumn(
      icon: Icons.bolt_rounded,
      title: 'Quick Links',
      links: GlobalFooter._quickLinks,
      touch: touch,
    );
    final support = _LinkColumn(
      icon: Icons.headset_mic_outlined,
      title: 'Support',
      links: GlobalFooter._supportLinks,
      touch: touch,
    );
    final company = _LinkColumn(
      icon: Icons.groups_outlined,
      title: 'Company',
      links: GlobalFooter._companyLinks,
      touch: touch,
    );
    final follow = _FollowColumn(center: touch);
    if (width >= GlobalFooter.columnBreakpoint) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 5, child: _BrandBlock()),
          const SizedBox(width: 18),
          Expanded(flex: 3, child: quick),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: support),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: company),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: follow),
        ],
      );
    }
    final paired = width >= 560;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandBlock(),
        const SizedBox(height: 22),
        if (paired)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: quick),
              const SizedBox(width: 16),
              Expanded(child: support),
            ],
          )
        else ...[
          quick,
          const SizedBox(height: 18),
          support,
        ],
        const SizedBox(height: 18),
        company,
        const SizedBox(height: 18),
        follow,
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Logo(),
        SizedBox(width: 14),
        _BrandDivider(),
        SizedBox(width: 14),
        Expanded(child: _BrandCopy()),
      ],
    );
  }
}

class _BrandDivider extends StatelessWidget {
  const _BrandDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 72,
      child: ColoredBox(color: Color(0xFFD3E3F4)),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: 72,
      height: 72,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = constraints.maxWidth >= 220 ? 18.0 : 16.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GlobalFooter.companyName,
              softWrap: true,
              style: TextStyle(
                fontFamily: family,
                color: GlobalFooter.navy,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empowering Modern Political Campaigns & Voter Outreach.',
              softWrap: true,
              style: TextStyle(
                fontFamily: family,
                color: GlobalFooter.text,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 3,
              decoration: BoxDecoration(
                color: GlobalFooter.teal,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({
    required this.icon,
    required this.title,
    required this.links,
    this.touch = false,
  });

  final IconData icon;
  final String title;
  final List<_FooterDest> links;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(icon: icon, title: title, family: family),
        SizedBox(height: touch ? 8 : 10),
        for (final link in links)
          _FooterLink(dest: link, touch: touch, family: family),
      ],
    );
  }
}

class _FollowColumn extends StatelessWidget {
  const _FollowColumn({required this.center});

  final bool center;

  @override
  Widget build(BuildContext context) {
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          icon: Icons.share_outlined,
          title: 'Follow Us',
          family: family,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final available =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
            final size = math.min(65.0, math.max(44.0, (available - 36) / 4));
            final icons = Wrap(
              alignment: center ? WrapAlignment.center : WrapAlignment.start,
              spacing: 12,
              runSpacing: 12,
              children: [
                _SocialButton(
                  name: 'Facebook',
                  urlKey: 'facebook',
                  buttonKey: const Key('footer-social-facebook'),
                  background: const Color(0xFF1877F2),
                  size: size,
                  child: Icon(
                    Icons.facebook,
                    color: Colors.white,
                    size: size * 0.46,
                  ),
                ),
                _SocialButton(
                  name: 'X',
                  urlKey: 'x',
                  buttonKey: const Key('footer-social-x'),
                  background: const Color(0xFF111111),
                  size: size,
                  child: _SvgMark(_xSvg, size: size * 0.4),
                ),
                _SocialButton(
                  name: 'Instagram',
                  urlKey: 'instagram',
                  buttonKey: const Key('footer-social-instagram'),
                  gradient: _instagramGradient,
                  size: size,
                  child: _SvgMark(_instagramSvg, size: size * 0.46),
                ),
                _SocialButton(
                  name: 'LinkedIn',
                  urlKey: 'linkedin',
                  buttonKey: const Key('footer-social-linkedin'),
                  background: const Color(0xFF0A66C2),
                  size: size,
                  child: Text(
                    'in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            );
            return icons;
          },
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.family,
  });

  final IconData icon;
  final String title;
  final String? family;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: GlobalFooter.teal)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: family,
              color: GlobalFooter.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
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
      GlobalFooter.copyrightLine,
      style: TextStyle(
        fontFamily: family,
        color: GlobalFooter.text,
        fontSize: 12.5,
        height: 1.35,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: copy),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: Align(alignment: Alignment.centerRight, child: legal),
        ),
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
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < GlobalFooter._legalLinks.length; i++) ...[
          if (i > 0)
            const SizedBox(
              width: 1,
              height: 18,
              child: ColoredBox(color: Color(0xFFB9D7E6)),
            ),
          _FooterLink(
            dest: GlobalFooter._legalLinks[i],
            family: family,
            pill: true,
          ),
        ],
      ],
    );
  }
}

class _FooterDest {
  const _FooterDest(this.label, this.route, this.keyName, {this.icon});

  final String label;
  final String? route;
  final String keyName;
  final IconData? icon;
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.dest,
    required this.family,
    this.touch = false,
    this.pill = false,
  });

  final _FooterDest dest;
  final String? family;
  final bool touch;
  final bool pill;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final linked = widget.dest.route != null;
    final color =
        widget.pill
            ? (_hover || _focus ? const Color(0xFF0B2454) : GlobalFooter.navy)
            : (_hover || _focus ? GlobalFooter.teal : GlobalFooter.navy);
    final iconColor = widget.pill ? color : GlobalFooter.teal;
    final label = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      style: TextStyle(
        fontFamily: widget.family,
        color: color,
        fontSize: widget.pill ? 13 : 13.5,
        fontWeight: widget.pill ? FontWeight.w700 : FontWeight.w600,
        height: 1.3,
      ),
      child: Text(widget.dest.label),
    );
    final row = Row(
      mainAxisSize: widget.pill ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!widget.pill)
          const ExcludeSemantics(
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: GlobalFooter.teal,
            ),
          ),
        if (widget.dest.icon != null) ...[
          ExcludeSemantics(
            child: Icon(widget.dest.icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 6),
        ],
        if (widget.pill) Flexible(child: label) else Expanded(child: label),
      ],
    );
    return MouseRegion(
      cursor: linked ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.pill ? GlobalFooter.pill : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.pill ? 999 : 6),
          border: Border.all(
            color: _focus ? GlobalFooter.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          key: Key(widget.dest.keyName),
          onTap: linked ? () => _open(context, widget.dest.route!) : null,
          onFocusChange: (focused) {
            final keyboard =
                FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional;
            setState(() => _focus = focused && keyboard);
          },
          borderRadius: BorderRadius.circular(widget.pill ? 999 : 6),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding:
                widget.pill
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                    : EdgeInsets.symmetric(
                      vertical: widget.touch ? 8 : 4,
                      horizontal: 4,
                    ),
            child: row,
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.name,
    required this.urlKey,
    required this.buttonKey,
    required this.child,
    required this.size,
    this.background,
    this.gradient,
  });

  final String name;
  final String urlKey;
  final Key buttonKey;
  final Widget child;
  final double size;
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
              width: size,
              height: size,
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
  const _SvgMark(this.svg, {required this.size});

  final String svg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(svg, width: size, height: size);
  }
}

class _FooterWavePainter extends CustomPainter {
  const _FooterWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GlobalFooter.canvas);
    final wash =
        Path()
          ..moveTo(0, size.height * 0.62)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.46,
            size.width * 0.58,
            size.height * 0.68,
          )
          ..quadraticBezierTo(
            size.width * 0.84,
            size.height * 0.86,
            size.width,
            size.height * 0.6,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(wash, Paint()..color = const Color(0xFFE4F3FB));
    final crest =
        Path()
          ..moveTo(0, size.height * 0.78)
          ..quadraticBezierTo(
            size.width * 0.4,
            size.height * 0.58,
            size.width,
            size.height * 0.74,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(crest, Paint()..color = const Color(0xFFF7FBFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

// #region agent log
void _logFooterPlacement(
  BuildContext context,
  double maxWidth,
  double maxHeight,
  double pageExtent,
  bool long,
) {
  try {
    final shell = context.findRenderObject();
    if (shell is! RenderBox || !shell.hasSize) return;
    RenderBox? footer;
    void walk(Element element) {
      if (element.widget.key == const Key('global-footer') &&
          element.renderObject is RenderBox) {
        footer = element.renderObject! as RenderBox;
      }
      if (footer == null) element.visitChildren(walk);
    }

    context.visitChildElements(walk);
    final footerBox = footer;
    if (footerBox == null || !footerBox.hasSize) return;
    final shellOrigin = shell.localToGlobal(Offset.zero);
    final footerOrigin = footerBox.localToGlobal(Offset.zero);
    final dx = footerOrigin.dx - shellOrigin.dx;
    final dy = footerOrigin.dy - shellOrigin.dy;
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c',
          ),
          headers: const {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '133bb1',
          },
          body: jsonEncode({
            'sessionId': '133bb1',
            'runId': 'post-fix',
            'hypothesisId': 'A',
            'location': 'global_footer.dart:AppFooterShell',
            'message': 'footer placement',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': {
              'maxWidth': maxWidth,
              'maxHeight': maxHeight,
              'pageExtent': pageExtent,
              'long': long,
              'shellWidth': shell.size.width,
              'footerWidth': footerBox.size.width,
              'footerDx': dx,
              'footerDy': dy,
              'beside': dx.abs() > 1,
              'below': dy > 0 && dx.abs() <= 1,
              'fullWidth': (footerBox.size.width - shell.size.width).abs() < 1,
            },
          }),
        )
        .then((_) {}, onError: (_) {});
  } catch (_) {}
}

// #endregion
