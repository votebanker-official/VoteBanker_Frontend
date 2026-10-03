import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../models/website_document.dart';

/// Renders a [WebsiteDocument] as a page a visitor could publish.
class WebsiteRenderer extends StatefulWidget {
  const WebsiteRenderer({required this.document, super.key});

  final WebsiteDocument document;

  @override
  State<WebsiteRenderer> createState() => _WebsiteRendererState();
}

class WebsiteSiteView extends StatelessWidget {
  const WebsiteSiteView({required this.document, super.key});

  final WebsiteDocument document;

  @override
  Widget build(BuildContext context) {
    return WebsiteRenderer(document: document);
  }
}

class _Palette {
  const _Palette({
    required this.canvas,
    required this.band,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.heroA,
    required this.heroB,
    required this.radius,
    required this.display,
  });

  final Color canvas;
  final Color band;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color heroA;
  final Color heroB;
  final double radius;
  final double display;

  static _Palette forTheme(String theme) {
    return switch (theme) {
      'warm' => const _Palette(
        canvas: Color(0xFFFFF8F1),
        band: Color(0xFFF3E6D6),
        ink: Color(0xFF2C2118),
        muted: Color(0xFF6E5848),
        primary: Color(0xFFC4622D),
        onPrimary: Colors.white,
        accent: Color(0xFFE7B56A),
        heroA: Color(0xFF8C3E2F),
        heroB: Color(0xFFE39B4D),
        radius: 22,
        display: 64,
      ),
      'bold' => const _Palette(
        canvas: Color(0xFFF7F4F2),
        band: Color(0xFF1A1A1A),
        ink: Color(0xFF161616),
        muted: Color(0xFF5C564F),
        primary: Color(0xFFD23C2A),
        onPrimary: Colors.white,
        accent: Color(0xFFF0B429),
        heroA: Color(0xFF1A1A1A),
        heroB: Color(0xFF8E2A22),
        radius: 8,
        display: 68,
      ),
      'elegant' => const _Palette(
        canvas: Color(0xFFF7F5F2),
        band: Color(0xFFE7E2DA),
        ink: Color(0xFF1C2430),
        muted: Color(0xFF5E6872),
        primary: Color(0xFF1E4D45),
        onPrimary: Colors.white,
        accent: Color(0xFFB08968),
        heroA: Color(0xFF163E38),
        heroB: Color(0xFF3E6B62),
        radius: 4,
        display: 60,
      ),
      'creative' => const _Palette(
        canvas: Color(0xFFF6F3FB),
        band: Color(0xFFE7DFF6),
        ink: Color(0xFF221C33),
        muted: Color(0xFF655C78),
        primary: Color(0xFF5C4D9A),
        onPrimary: Colors.white,
        accent: Color(0xFFE07A5F),
        heroA: Color(0xFF2C2154),
        heroB: Color(0xFF8D6A4A),
        radius: 18,
        display: 66,
      ),
      'civic' => const _Palette(
        canvas: Color(0xFFF4F7F5),
        band: Color(0xFFE3EBE6),
        ink: Color(0xFF14241C),
        muted: Color(0xFF4E6258),
        primary: Color(0xFF1B4D3E),
        onPrimary: Colors.white,
        accent: Color(0xFFC4A35A),
        heroA: Color(0xFF14362C),
        heroB: Color(0xFF2F6A56),
        radius: 6,
        display: 58,
      ),
      'editorial' => const _Palette(
        canvas: Color(0xFFFAF7F2),
        band: Color(0xFFF0E7DC),
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF5A5148),
        primary: Color(0xFF1A1A1A),
        onPrimary: Color(0xFFFAF7F2),
        accent: Color(0xFF8C3A3A),
        heroA: Color(0xFF1A1A1A),
        heroB: Color(0xFF4A4038),
        radius: 0,
        display: 72,
      ),
      'minimal' => const _Palette(
        canvas: Color(0xFFFFFFFF),
        band: Color(0xFFF3F3F3),
        ink: Color(0xFF111111),
        muted: Color(0xFF666666),
        primary: Color(0xFF111111),
        onPrimary: Colors.white,
        accent: Color(0xFF111111),
        heroA: Color(0xFF222222),
        heroB: Color(0xFF555555),
        radius: 0,
        display: 56,
      ),
      _ => const _Palette(
        canvas: Color(0xFFF5F7FB),
        band: Color(0xFFE7EEF8),
        ink: Color(0xFF152033),
        muted: Color(0xFF5C6B82),
        primary: Color(0xFF1F4E9A),
        onPrimary: Colors.white,
        accent: Color(0xFF3E8EDE),
        heroA: Color(0xFF16356E),
        heroB: Color(0xFF3E7CC4),
        radius: 16,
        display: 62,
      ),
    };
  }
}

class _WebsiteRendererState extends State<WebsiteRenderer> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final l10n = AppLocalizations.of(context);
    final palette = _Palette.forTheme(document.themeId);
    final hero = document.find(WebsiteSectionType.hero);

    return ColoredBox(
      color: palette.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width >= 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Navigation(
                document: document,
                palette: palette,
                wide: wide,
                open: _menuOpen,
                onMenu: () => setState(() => _menuOpen = !_menuOpen),
              ),
              if (document.translationPending)
                Container(
                  color: palette.band,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  child: Text(
                    l10n.line('translationPending'),
                    style: TextStyle(color: palette.ink, fontSize: 13, height: 1.4),
                  ),
                ),
              _HeroBlock(document: document, hero: hero, palette: palette, wide: wide),
              for (final section in document.sections)
                if (section.type != WebsiteSectionType.hero && section.enabled)
                  _SectionBlock(document: document, section: section, palette: palette, width: width),
              if (document.primaryCta.isNotEmpty || document.secondaryCta.isNotEmpty)
                _CallToAction(document: document, palette: palette),
              _Footer(document: document, palette: palette, madeWith: l10n.line('madeWith')),
            ],
          );
        },
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.document,
    required this.palette,
    required this.wide,
    required this.open,
    required this.onMenu,
  });

  final WebsiteDocument document;
  final _Palette palette;
  final bool wide;
  final bool open;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final labels = [
      for (final section in document.sections)
        if (section.heading.isNotEmpty) section.heading,
    ];
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (document.logo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(document.logo!, width: 36, height: 36, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          document.siteTitle,
          style: TextStyle(color: palette.ink, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
      ],
    );

    return Container(
      color: palette.canvas,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              brand,
              const Spacer(),
              if (wide)
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      for (final label in labels)
                        Text(label, style: TextStyle(color: palette.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                IconButton(onPressed: onMenu, icon: Icon(open ? Icons.close : Icons.menu, color: palette.ink)),
            ],
          ),
          if (!wide && open)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (final label in labels)
                    Text(label, style: TextStyle(color: palette.ink, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.document,
    required this.hero,
    required this.palette,
    required this.wide,
  });

  final WebsiteDocument document;
  final WebsiteSection? hero;
  final _Palette palette;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final line = hero?.content.isNotEmpty == true ? hero!.content : document.introduction;
    final text = _HeroCopy(document: document, line: line, palette: palette, light: _lightHero(document.heroLayout));
    final visual = _Visual(
      document: document,
      palette: palette,
      height: wide ? 460 : 300,
      bytes: document.portrait,
    );

    if (document.heroLayout == 'split' || document.heroLayout == 'editorial') {
      final children = [Expanded(flex: 6, child: text), const SizedBox(width: 28), Expanded(flex: 5, child: visual)];
      return Container(
        color: palette.canvas,
        padding: EdgeInsets.fromLTRB(wide ? 56 : 24, 12, wide ? 56 : 24, 48),
        child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: children) : Column(children: [text, const SizedBox(height: 24), visual]),
      );
    }

    if (document.heroLayout == 'minimal' || document.heroLayout == 'centered') {
      return Container(
        color: palette.canvas,
        padding: EdgeInsets.fromLTRB(wide ? 72 : 24, 28, wide ? 72 : 24, 48),
        child: Column(
          children: [
            text,
            const SizedBox(height: 28),
            visual,
          ],
        ),
      );
    }

    return ColoredBox(
      color: palette.heroA,
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 56 : 24, 8, wide ? 56 : 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            visual,
            const SizedBox(height: 28),
            text,
          ],
        ),
      ),
    );
  }

  bool _lightHero(String layout) => layout == 'gradient' || layout == 'full';
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.document,
    required this.line,
    required this.palette,
    required this.light,
  });

  final WebsiteDocument document;
  final String line;
  final _Palette palette;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : palette.ink;
    final bodyColor = light ? Colors.white.withValues(alpha: 0.9) : palette.muted;
    final align = document.heroLayout == 'centered' ? TextAlign.center : TextAlign.start;
    final cross = document.heroLayout == 'centered' ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        if (document.professionalTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              document.professionalTitle,
              textAlign: align,
              style: TextStyle(color: light ? palette.accent : palette.primary, fontSize: 13, letterSpacing: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        Text(
          document.heroTitle,
          textAlign: align,
          style: TextStyle(color: titleColor, fontSize: palette.display, height: 1.02, fontWeight: FontWeight.w700, letterSpacing: -1.2),
        ),
        if (document.organization.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(document.organization, textAlign: align, style: TextStyle(color: bodyColor, fontSize: 18)),
        ],
        if (line.isNotEmpty) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(line, textAlign: align, style: TextStyle(color: bodyColor, fontSize: 18, height: 1.5)),
          ),
        ],
        if (document.primaryCta.isNotEmpty || document.secondaryCta.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            alignment: document.heroLayout == 'centered' ? WrapAlignment.center : WrapAlignment.start,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (document.primaryCta.isNotEmpty)
                _SiteButton(label: document.primaryCta, palette: palette, filled: true, light: light),
              if (document.secondaryCta.isNotEmpty)
                _SiteButton(label: document.secondaryCta, palette: palette, filled: false, light: light),
            ],
          ),
        ],
      ],
    );
  }
}

class _SiteButton extends StatelessWidget {
  const _SiteButton({required this.label, required this.palette, required this.filled, required this.light});

  final String label;
  final _Palette palette;
  final bool filled;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(palette.radius.clamp(0, 28)));
    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: light ? Colors.white : palette.primary,
          foregroundColor: light ? palette.heroA : palette.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: shape,
        ),
        onPressed: () {},
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: light ? Colors.white : palette.ink,
        side: BorderSide(color: light ? Colors.white : palette.ink),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: shape,
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({
    required this.document,
    required this.palette,
    required this.height,
    this.bytes,
    this.caption = '',
  });

  final WebsiteDocument document;
  final _Palette palette;
  final double height;
  final Uint8List? bytes;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(palette.radius.clamp(0, 28)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: bytes == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.heroA, palette.heroB],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(document.websiteType), color: Colors.white.withValues(alpha: 0.92), size: height > 240 ? 72 : 40),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        caption.isEmpty ? document.siteTitle : caption,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: height > 240 ? 28 : 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            : Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity, height: height),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.document,
    required this.section,
    required this.palette,
    required this.width,
  });

  final WebsiteDocument document;
  final WebsiteSection section;
  final _Palette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final alternate = section.order.isEven;
    final pad = width >= 760 ? 56.0 : 24.0;
    final inner = (width - pad * 2).clamp(0, width).toDouble();
    return Container(
      color: alternate ? palette.band : palette.canvas,
      padding: EdgeInsets.fromLTRB(pad, 56, pad, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: TextStyle(color: palette.ink, fontSize: width >= 760 ? 36 : 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
          ),
          const SizedBox(height: 8),
          Container(width: 48, height: 3, color: palette.accent),
          const SizedBox(height: 22),
          _body(context, inner),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, double inner) {
    final cards = section.items.isNotEmpty &&
        const {
          WebsiteSectionType.favoriteThings,
          WebsiteSectionType.personality,
          WebsiteSectionType.services,
          WebsiteSectionType.menu,
          WebsiteSectionType.portfolio,
          WebsiteSectionType.priorities,
        }.contains(section.type);

    if (cards) {
      return _Cards(items: section.items, palette: palette, width: inner);
    }
    if (section.type == WebsiteSectionType.gallery) {
      return _Gallery(document: document, section: section, palette: palette, width: inner);
    }
    if (section.type == WebsiteSectionType.achievements && section.items.isNotEmpty) {
      return document.layoutVariant == 1
          ? _Timeline(items: section.items, palette: palette)
          : _Cards(items: section.items, palette: palette, width: inner);
    }
    if (section.type == WebsiteSectionType.events) {
      return _Timeline(items: section.items, palette: palette);
    }
    if (section.type == WebsiteSectionType.contact || section.type == WebsiteSectionType.social) {
      return _ContactList(section: section, palette: palette);
    }
    if (section.type == WebsiteSectionType.publicRequests) {
      return _Requests(section: section, palette: palette);
    }
    return _Prose(section: section, palette: palette);
  }
}

class _Prose extends StatelessWidget {
  const _Prose({required this.section, required this.palette});

  final WebsiteSection section;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final text = [section.subtitle, section.content].where((part) => part.trim().isNotEmpty).join('\n\n');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Text(text, style: TextStyle(color: palette.ink, fontSize: 18, height: 1.6)),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.items, required this.palette, required this.width});

  final List<WebsiteItem> items;
  final _Palette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final columns = width >= 860 ? 3 : width >= 520 ? 2 : 1;
    final tile = columns == 1 ? width : ((width - 16 * (columns - 1)) / columns) - 1;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final item in items)
          SizedBox(
            width: tile,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(palette.radius.clamp(8, 24)),
                boxShadow: [
                  BoxShadow(color: palette.ink.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: palette.band, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.auto_awesome, color: palette.primary, size: 20),
                    ),
                    const SizedBox(height: 14),
                    Text(item.title, style: TextStyle(color: palette.ink, fontSize: 20, fontWeight: FontWeight.w700)),
                    if (item.description.isNotEmpty && item.description.toLowerCase() != item.title.toLowerCase()) ...[
                      const SizedBox(height: 8),
                      Text(item.description, style: TextStyle(color: palette.muted, fontSize: 15, height: 1.45)),
                    ],
                    if (item.meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(item.meta, style: TextStyle(color: palette.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.document,
    required this.section,
    required this.palette,
    required this.width,
  });

  final WebsiteDocument document;
  final WebsiteSection section;
  final _Palette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final photos = <Uint8List>[
      if (document.portrait != null) document.portrait!,
      ...document.gallery,
    ];
    final columns = width >= 760 ? 3 : width >= 480 ? 2 : 1;
    final tile = columns == 1 ? width : ((width - 12 * (columns - 1)) / columns) - 1;
    if (photos.isNotEmpty) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final photo in photos)
            ClipRRect(
              borderRadius: BorderRadius.circular(palette.radius.clamp(8, 20)),
              child: Image.memory(photo, width: tile, height: 200, fit: BoxFit.cover),
            ),
        ],
      );
    }
    final labels = section.items.isEmpty ? [document.siteTitle] : section.items.map((item) => item.title).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final label in labels)
          SizedBox(
            width: tile,
            child: _Visual(document: document, palette: palette, height: 190, caption: label),
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items, required this.palette});

  final List<WebsiteItem> items;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(color: palette.ink, fontSize: 18, fontWeight: FontWeight.w700)),
                      if (item.meta.isNotEmpty) Text(item.meta, style: TextStyle(color: palette.primary, fontSize: 13)),
                      if (item.description.isNotEmpty) Text(item.description, style: TextStyle(color: palette.muted, fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({required this.section, required this.palette});

  final WebsiteSection section;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) {
      return _Prose(section: section, palette: palette);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.content.isNotEmpty) _Prose(section: section, palette: palette),
        for (final item in section.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              item.description.isEmpty ? item.title : '${item.title} · ${item.description}',
              style: TextStyle(color: palette.ink, fontSize: 17, height: 1.4),
            ),
          ),
      ],
    );
  }
}

class _Requests extends StatelessWidget {
  const _Requests({required this.section, required this.palette});

  final WebsiteSection section;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.content.isNotEmpty) _Prose(section: section, palette: palette),
        const SizedBox(height: 16),
        Text(l10n.line('requestPrompt'), style: TextStyle(color: palette.ink, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(l10n.line('requestBody'), style: TextStyle(color: palette.muted, fontSize: 15)),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.line('requestLater'))));
          },
          child: Text(l10n.line('submitRequest')),
        ),
      ],
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction({required this.document, required this.palette});

  final WebsiteDocument document;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final headline = document.websiteType == 'pet' ? "Follow ${document.siteTitle}'s adventures" : document.heroTitle;
    return Container(
      color: palette.heroA,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (document.primaryCta.isNotEmpty) _SiteButton(label: document.primaryCta, palette: palette, filled: true, light: true),
              if (document.secondaryCta.isNotEmpty) _SiteButton(label: document.secondaryCta, palette: palette, filled: false, light: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.document, required this.palette, required this.madeWith});

  final WebsiteDocument document;
  final _Palette palette;
  final String madeWith;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.ink,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        children: [
          if (document.logo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(document.logo!, width: 40, height: 40, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
          ],
          Text(document.siteTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(madeWith, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
        ],
      ),
    );
  }
}

IconData _iconFor(String type) {
  return switch (type) {
    'pet' => Icons.pets,
    'business' => Icons.bakery_dining,
    'photographer' || 'artist' => Icons.photo_camera_outlined,
    'healthcare' => Icons.local_hospital_outlined,
    'leadership' => Icons.account_balance_outlined,
    _ => Icons.auto_awesome,
  };
}
