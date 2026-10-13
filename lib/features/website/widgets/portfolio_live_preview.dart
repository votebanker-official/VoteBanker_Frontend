import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/portfolio_config.dart';

class PortfolioProfileFacts {
  const PortfolioProfileFacts({
    this.name = '',
    this.designation = '',
    this.constituency = '',
    this.party = '',
    this.location = '',
    this.contact = '',
    this.photo,
  });

  final String name;
  final String designation;
  final String constituency;
  final String party;
  final String location;
  final String contact;
  final Uint8List? photo;
}

class PortfolioLivePreview extends StatelessWidget {
  const PortfolioLivePreview({
    required this.design,
    required this.profile,
    required this.fallbackHeadline,
    required this.fallbackSupport,
    this.height = 520,
    super.key,
  });

  final PortfolioDesign design;
  final PortfolioProfileFacts profile;
  final String fallbackHeadline;
  final String fallbackSupport;
  final double height;

  @override
  Widget build(BuildContext context) {
    final primary = Color(design.primaryColor);
    final accent = Color(design.accentColor);
    final font = switch (design.fontKey) {
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
        color: color ?? const Color(0xFF1A1A1A),
        height: 1.35,
      );
    }

    final title = _first([design.title, profile.name]);
    final tagline = _first([design.tagline, fallbackHeadline]);
    final contact = _first([design.contact, profile.contact, profile.location]);
    final facts = [
      profile.designation,
      profile.constituency,
      profile.party,
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return DecoratedBox(
      key: const ValueKey('portfolio-live-preview'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: height,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ColoredBox(
                color: primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.photo != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.memory(
                            profile.photo!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: style(22, weight: FontWeight.w800, color: Colors.white),
                        ),
                      if (tagline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tagline,
                          style: style(14, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                      if (design.tagline.trim().isEmpty && fallbackSupport.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          fallbackSupport,
                          style: style(13, color: Colors.white),
                        ),
                      ],
                      if (facts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(facts, style: style(12, color: Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
              for (final section in [
                ('About the Leader', design.about),
                ('Vision and Priorities', design.vision),
                ('Work and Achievements', design.achievements),
                ('News and Updates', design.news),
              ])
                if (section.$2.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.$1, style: style(18, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          section.$2,
                          style: style(14, weight: FontWeight.w400, color: const Color(0xFF3F3F46)),
                        ),
                      ],
                    ),
                  ),
              if (design.gallery.any((item) => item.image != null))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gallery', style: style(18, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: design.gallery.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final item = design.gallery[index];
                            if (item.image == null) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    item.image!,
                                    width: 140,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (item.caption.trim().isNotEmpty)
                                  Text(item.caption, style: style(11)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (contact.isNotEmpty || design.socialLinks.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact and Connect', style: style(18, weight: FontWeight.w700)),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact,
                          style: style(14, weight: FontWeight.w400, color: const Color(0xFF3F3F46)),
                        ),
                      ],
                      if (design.socialLinks.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          design.socialLinks,
                          style: style(14, weight: FontWeight.w400, color: const Color(0xFF3F3F46)),
                        ),
                      ],
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(
                            'Get in touch',
                            style: style(13, weight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _first(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
