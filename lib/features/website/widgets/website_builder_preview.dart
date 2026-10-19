import 'package:flutter/material.dart';

import '../models/website_builder_draft.dart';
import '../models/website_template_catalog.dart';

/// Renders the selected template using the user's entered draft data only.
class WebsiteBuilderPreview extends StatelessWidget {
  const WebsiteBuilderPreview({
    required this.draft,
    this.isPreviewBanner = true,
    this.compact = false,
    super.key,
  });

  final WebsiteBuilderDraft draft;
  final bool isPreviewBanner;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = WebsiteTemplateCatalog.byId(draft.templateId);
    final primary = Color(draft.design.primaryColor);
    final accent = Color(draft.design.secondaryColor);
    final background = Color(draft.design.backgroundColor);
    final font = switch (draft.design.fontKey) {
      'serif' => 'serif',
      'mono' => 'monospace',
      _ => null,
    };

    TextStyle style(
      double size, {
      FontWeight weight = FontWeight.w500,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: font,
        fontSize: size,
        fontWeight: weight,
        color: color ?? const Color(0xFF111827),
        height: 1.35,
      );
    }

    final name = draft.fullName.trim();
    final title = draft.design.websiteName.trim().isNotEmpty
        ? draft.design.websiteName.trim()
        : name;
    final designation = draft.templateId == WebsiteTemplates.official &&
            draft.officialDesignation.trim().isNotEmpty
        ? draft.officialDesignation.trim()
        : draft.designation.trim();
    final meta = [
      designation,
      draft.constituency.trim(),
      draft.party.trim(),
    ].where((v) => v.isNotEmpty).join(' · ');

    final sections = <Widget>[
      if (isPreviewBanner)
        ColoredBox(
          color: const Color(0xFFFEF3C7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview only — not published yet',
                    style: style(12, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      _Hero(
        draft: draft,
        primary: primary,
        accent: accent,
        title: title.isEmpty ? info.name : title,
        meta: meta,
        intro: draft.shortIntro.trim(),
        style: style,
      ),
      if (_visible(draft, 'about') &&
          (draft.biography.trim().isNotEmpty ||
              draft.shortIntro.trim().isNotEmpty ||
              draft.aboutLeader.trim().isNotEmpty ||
              draft.communityIntro.trim().isNotEmpty))
        _Section(
          title: draft.templateId == WebsiteTemplates.community
              ? 'About our community'
              : 'About',
          body: _firstNonEmpty([
            draft.biography,
            draft.aboutLeader,
            draft.communityIntro,
            draft.shortIntro,
          ]),
          style: style,
        ),
      if (_visible(draft, 'background') &&
          _anyText([
            draft.education,
            draft.professionalExperience,
            draft.politicalJourney,
            draft.expertise,
            draft.previousPositions,
            draft.publicServiceExperience,
            draft.goalsVision,
            draft.localPriorities,
            draft.areasServed,
          ]))
        _Section(
          title: draft.templateId == WebsiteTemplates.official
              ? 'Official background'
              : draft.templateId == WebsiteTemplates.community
                  ? 'Community goals'
                  : 'Professional background',
          body: _joinBlocks([
            ('Education', draft.education),
            ('Experience', draft.professionalExperience),
            ('Political journey', draft.politicalJourney),
            ('Expertise', draft.expertise),
            ('Previous positions', draft.previousPositions),
            ('Public service', draft.publicServiceExperience),
            ('Goals and vision', draft.goalsVision),
            ('Local priorities', draft.localPriorities),
            ('Areas served', draft.areasServed),
          ]),
          style: style,
        ),
      if (_visible(draft, 'achievements'))
        for (final item in draft.achievements.where((e) => !e.isEmpty))
          _BulletCard(
            title: item.title,
            body: [
              if (item.dateOrYear.trim().isNotEmpty) item.dateOrYear.trim(),
              if (item.description.trim().isNotEmpty) item.description.trim(),
            ].join('\n'),
            accent: accent,
            style: style,
            image: item.photo,
          ),
      if (_visible(draft, 'projects'))
        for (final item in draft.projects.where((e) => !e.isEmpty))
          _BulletCard(
            title: item.name,
            body: [
              if (item.location.trim().isNotEmpty) item.location.trim(),
              'Status: ${item.status}',
              if (item.description.trim().isNotEmpty) item.description.trim(),
            ].where((v) => v.isNotEmpty).join('\n'),
            accent: accent,
            style: style,
            image: item.photo,
          ),
      if (_visible(draft, 'announcements'))
        for (final item in draft.announcements.where((e) => !e.isEmpty))
          _BulletCard(
            title: item.title,
            body: [
              if (item.publicationDate.trim().isNotEmpty)
                item.publicationDate.trim(),
              if (item.description.trim().isNotEmpty) item.description.trim(),
              if (item.externalLink.trim().isNotEmpty) item.externalLink.trim(),
            ].where((v) => v.isNotEmpty).join('\n'),
            accent: accent,
            style: style,
            image: item.photo,
          ),
      if (_visible(draft, 'events'))
        for (final item in draft.events.where((e) => !e.isEmpty))
          _BulletCard(
            title: item.name,
            body: [
              if (item.dateTime.trim().isNotEmpty) item.dateTime.trim(),
              if (item.venue.trim().isNotEmpty) item.venue.trim(),
              if (item.description.trim().isNotEmpty) item.description.trim(),
            ].where((v) => v.isNotEmpty).join('\n'),
            accent: accent,
            style: style,
            image: item.photo,
          ),
      if (_visible(draft, 'services') &&
          _anyText([
            draft.citizenAssistance,
            draft.serviceInstructions,
            draft.phone,
            draft.email,
          ]))
        _Section(
          title: 'Citizen services',
          body: _joinBlocks([
            ('Assistance', draft.citizenAssistance),
            ('How to request help', draft.serviceInstructions),
            ('Phone', draft.phone),
            ('Email', draft.email),
          ]),
          style: style,
        ),
      if (_visible(draft, 'office') &&
          _anyText([
            draft.officeName,
            draft.officeAddress,
            draft.visitingHours,
            draft.officialPhone,
            draft.officialEmail,
          ]))
        _Section(
          title: 'Office information',
          body: _joinBlocks([
            ('Office', draft.officeName),
            ('Address', draft.officeAddress),
            ('Visiting hours', draft.visitingHours),
            ('Phone', draft.officialPhone),
            ('Email', draft.officialEmail),
          ]),
          style: style,
        ),
      if (_visible(draft, 'gallery') && draft.gallery.any((g) => g.hasImage))
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gallery', style: style(18, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in draft.gallery.where((g) => g.hasImage))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: _Media(item),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      if (_visible(draft, 'contact') &&
          _anyText([
            draft.phone,
            draft.email,
            draft.officeAddress,
            draft.facebookUrl,
            draft.instagramUrl,
            draft.youtubeUrl,
            draft.twitterUrl,
            draft.linkedinUrl,
          ]))
        _Section(
          title: 'Contact',
          body: _joinBlocks([
            ('Phone', draft.phone),
            ('Email', draft.email),
            ('Address', draft.officeAddress),
            if (draft.design.socialVisibility['facebook'] != false)
              ('Facebook', draft.facebookUrl),
            if (draft.design.socialVisibility['instagram'] != false)
              ('Instagram', draft.instagramUrl),
            if (draft.design.socialVisibility['youtube'] != false)
              ('YouTube', draft.youtubeUrl),
            if (draft.design.socialVisibility['twitter'] != false)
              ('X', draft.twitterUrl),
            if (draft.design.socialVisibility['linkedin'] != false)
              ('LinkedIn', draft.linkedinUrl),
          ]),
          style: style,
        ),
      const SizedBox(height: 20),
    ];

    return DecoratedBox(
      key: ValueKey('builder-preview-${draft.templateId}'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: compact ? 360 : 560,
          child: ListView(padding: EdgeInsets.zero, children: sections),
        ),
      ),
    );
  }

  bool _visible(WebsiteBuilderDraft draft, String key) {
    return draft.design.sectionVisibility[key] != false;
  }

  bool _anyText(List<String> values) =>
      values.any((v) => v.trim().isNotEmpty);

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _joinBlocks(List<(String, String)> blocks) {
    return blocks
        .where((b) => b.$2.trim().isNotEmpty)
        .map((b) => '${b.$1}\n${b.$2.trim()}')
        .join('\n\n');
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.draft,
    required this.primary,
    required this.accent,
    required this.title,
    required this.meta,
    required this.intro,
    required this.style,
  });

  final WebsiteBuilderDraft draft;
  final Color primary;
  final Color accent;
  final String title;
  final String meta;
  final String intro;
  final TextStyle Function(
    double size, {
    FontWeight weight,
    Color? color,
  }) style;

  @override
  Widget build(BuildContext context) {
    final cover = draft.design.heroImage.hasImage
        ? draft.design.heroImage
        : draft.coverPhoto;
    return ColoredBox(
      color: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cover.hasImage)
            SizedBox(height: 120, child: _Media(cover, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.profilePhoto.hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _Media(draft.profilePhoto),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: style(
                          22,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meta, style: style(12, color: Colors.white)),
                      ],
                      if (intro.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(intro, style: style(13, color: Colors.white)),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Contact',
                              style: style(
                                12,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.style,
  });

  final String title;
  final String body;
  final TextStyle Function(
    double size, {
    FontWeight weight,
    Color? color,
  }) style;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style(18, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: style(14)),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.body,
    required this.accent,
    required this.style,
    required this.image,
  });

  final String title;
  final String body;
  final Color accent;
  final MediaRef image;
  final TextStyle Function(
    double size, {
    FontWeight weight,
    Color? color,
  }) style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.trim().isNotEmpty)
                  Text(title, style: style(15, weight: FontWeight.w700)),
                if (body.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: style(13)),
                ],
                if (image.hasImage) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 96,
                      width: double.infinity,
                      child: _Media(image),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media(this.ref, {this.fit = BoxFit.cover});

  final MediaRef ref;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = ref.bytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: fit);
    }
    if (ref.url.trim().isNotEmpty) {
      return Image.network(
        ref.url,
        fit: fit,
        errorBuilder: (_, __, ___) => const ColoredBox(
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
