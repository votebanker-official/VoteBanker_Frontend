import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/widgets/party_symbol.dart';
import '../models/website_builder_draft.dart';

/// One professional political-leader website. Party name and logo come from
/// the Leader Profile party; they are never hardcoded to a single party.
class LeaderPortfolioSite extends StatelessWidget {
  const LeaderPortfolioSite({
    required this.draft,
    this.compact = false,
    super.key,
  });

  final WebsiteBuilderDraft draft;
  final bool compact;

  static const _navy = Color(0xFF0F2A56);
  static const _blue = Color(0xFF1D4ED8);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final partyName = draft.party.trim();
    final displayName = draft.fullName.trim().isEmpty
        ? l10n.line('portfolioYourName')
        : draft.fullName.trim();
    final designation = draft.officialDesignation.trim().isNotEmpty
        ? draft.officialDesignation.trim()
        : draft.designation.trim();
    final location = [
      draft.constituency.trim(),
      draft.district.trim(),
      draft.state.trim(),
    ].where((value) => value.isNotEmpty).toSet().join(', ');
    final intro = draft.shortIntro.trim();
    final about = [
      draft.biography,
      draft.aboutLeader,
    ].map((value) => value.trim()).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => l10n.line('portfolioBioPlaceholder'),
        );
    final vision = [
      draft.goalsVision,
      draft.localPriorities,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
    final achievements = draft.achievements.where((item) => !item.isEmpty);
    final projects = draft.projects.where((item) => !item.isEmpty);
    final gallery = draft.gallery.where((item) => item.hasImage);
    final updates = draft.announcements.where((item) => !item.isEmpty);
    final events = draft.events.where((item) => !item.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(partyName: partyName, compact: compact),
        _Hero(
          draft: draft,
          displayName: displayName,
          designation: designation,
          location: location,
          intro: intro,
          partyName: partyName,
        ),
        _AboutLeader(body: about),
        _Vision(items: vision),
        _Work(achievements: achievements, projects: projects),
        _GalleryAndUpdates(gallery: gallery, updates: updates, events: events),
        _Contact(draft: draft, location: location, partyName: partyName),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.partyName, required this.compact});

  final String partyName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = l10n.portfolioNavHome;
    final nav = [
      home,
      l10n.portfolioNavAbout,
      l10n.line('portfolioNavVisionFull'),
      l10n.line('portfolioNavAchievements'),
      l10n.portfolioNavGallery,
      l10n.portfolioNavContact,
    ];
    final partyLabel = partyName.isEmpty
        ? l10n.line('portfolioPoliticalParty')
        : partyName;
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                _PartyMark(partyName: partyName, diameter: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    partyLabel,
                    key: const ValueKey('websitePartyName'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: LeaderPortfolioSite._navy,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: LeaderPortfolioSite._blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            l10n.line('portfolioJoinMission'),
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
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                for (final label in nav)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          label == home ? FontWeight.w700 : FontWeight.w500,
                      color: label == home
                          ? LeaderPortfolioSite._blue
                          : LeaderPortfolioSite._muted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.draft,
    required this.displayName,
    required this.designation,
    required this.location,
    required this.intro,
    required this.partyName,
  });

  final WebsiteBuilderDraft draft;
  final String displayName;
  final String designation;
  final String location;
  final String intro;
  final String partyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xFFE8F0FB),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  key: const ValueKey('websiteHeroPhoto'),
                  width: 92,
                  height: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: draft.profilePhoto.hasImage
                        ? _Media(draft.profilePhoto)
                        : const ColoredBox(
                            color: Color(0xFFCBD5E1),
                            child: Icon(Icons.person, size: 42, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: LeaderPortfolioSite._navy,
                        ),
                      ),
                      if (designation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          designation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: LeaderPortfolioSite._blue,
                          ),
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: LeaderPortfolioSite._muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        intro.isEmpty
                            ? l10n.line('portfolioIntroPlaceholder')
                            : intro,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: LeaderPortfolioSite._ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: LeaderPortfolioSite._blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            l10n.line('portfolioKnowMyVision'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PartyMark(partyName: partyName, diameter: 36),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      partyName.isEmpty
                          ? l10n.line('portfolioPoliticalParty')
                          : partyName,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LeaderPortfolioSite._navy,
                      ),
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
}

class _AboutLeader extends StatelessWidget {
  const _AboutLeader({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('aboutTheLeader'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioAboutLeader'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LeaderPortfolioSite._navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: LeaderPortfolioSite._ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vision extends StatelessWidget {
  const _Vision({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioVisionPriorities'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LeaderPortfolioSite._navy,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              l10n.line('portfolioVisionPlaceholder'),
              style: const TextStyle(
                fontSize: 14,
                color: LeaderPortfolioSite._muted,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: LeaderPortfolioSite._ink,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Work extends StatelessWidget {
  const _Work({required this.achievements, required this.projects});

  final Iterable<AchievementEntry> achievements;
  final Iterable<ProjectEntry> projects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = achievements.isEmpty && projects.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioAchievementsWork'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LeaderPortfolioSite._navy,
            ),
          ),
          const SizedBox(height: 8),
          if (empty)
            Text(
              l10n.line('portfolioAchievementsPlaceholder'),
              style: const TextStyle(
                fontSize: 14,
                color: LeaderPortfolioSite._muted,
              ),
            )
          else ...[
            for (final item in achievements)
              _TextCard(
                title: item.title,
                body: [
                  if (item.dateOrYear.trim().isNotEmpty) item.dateOrYear.trim(),
                  if (item.description.trim().isNotEmpty) item.description.trim(),
                ].join('\n'),
                image: item.photo,
              ),
            for (final item in projects)
              _TextCard(
                title: item.name,
                body: [
                  if (item.location.trim().isNotEmpty) item.location.trim(),
                  if (item.description.trim().isNotEmpty) item.description.trim(),
                ].join('\n'),
                image: item.photo,
              ),
          ],
        ],
      ),
    );
  }
}

class _GalleryAndUpdates extends StatelessWidget {
  const _GalleryAndUpdates({
    required this.gallery,
    required this.updates,
    required this.events,
  });

  final Iterable<MediaRef> gallery;
  final Iterable<AnnouncementEntry> updates;
  final Iterable<EventEntry> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = gallery.isEmpty && updates.isEmpty && events.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('portfolioGalleryUpdates'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LeaderPortfolioSite._navy,
            ),
          ),
          const SizedBox(height: 8),
          if (empty)
            Text(
              l10n.line('portfolioGalleryPlaceholder'),
              style: const TextStyle(
                fontSize: 14,
                color: LeaderPortfolioSite._muted,
              ),
            )
          else ...[
            if (gallery.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in gallery)
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
            for (final item in updates)
              _TextCard(
                title: item.title,
                body: [
                  if (item.publicationDate.trim().isNotEmpty)
                    item.publicationDate.trim(),
                  if (item.description.trim().isNotEmpty) item.description.trim(),
                ].join('\n'),
                image: item.photo,
              ),
            for (final item in events)
              _TextCard(
                title: item.name,
                body: [
                  if (item.dateTime.trim().isNotEmpty) item.dateTime.trim(),
                  if (item.venue.trim().isNotEmpty) item.venue.trim(),
                  if (item.description.trim().isNotEmpty) item.description.trim(),
                ].join('\n'),
                image: MediaRef(),
              ),
          ],
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
    final phone = draft.phone.trim();
    final email = draft.email.trim();
    return ColoredBox(
      color: LeaderPortfolioSite._navy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.line('portfolioGetInTouch'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              phone.isEmpty
                  ? l10n.line('portfolioContactPlaceholder')
                  : phone,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(color: Colors.white, fontSize: 13)),
            if (location.isNotEmpty)
              Text(
                location,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PartyMark(partyName: partyName, diameter: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    partyName.isEmpty
                        ? l10n.line('portfolioPoliticalParty')
                        : partyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.title,
    required this.body,
    required this.image,
  });

  final String title;
  final String body;
  final MediaRef image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: LeaderPortfolioSite._navy,
              ),
            ),
          if (body.trim().isNotEmpty)
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: LeaderPortfolioSite._ink,
              ),
            ),
          if (image.hasImage) ...[
            const SizedBox(height: 6),
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
    );
  }
}

class _PartyMark extends StatelessWidget {
  const _PartyMark({required this.partyName, required this.diameter});

  final String partyName;
  final double diameter;

  @override
  Widget build(BuildContext context) {
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
