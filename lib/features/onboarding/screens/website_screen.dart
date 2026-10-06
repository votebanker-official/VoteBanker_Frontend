import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../website/models/website_document.dart';
import '../../website/widgets/website_site_view.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_frame.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  var _showMine = false;

  String _templateId(String? stored) {
    return switch (stored) {
      'traditional' || 'work' => 'traditional',
      'peopleFirst' || 'issue' => 'peopleFirst',
      _ => 'modern',
    };
  }

  String _styleId(String template) {
    return switch (template) {
      'traditional' => 'work',
      'peopleFirst' => 'issue',
      _ => 'public',
    };
  }

  void _select(String template) {
    setState(() {
      OnboardingScope.of(context).draft.websiteTemplate = template;
    });
  }

  void _prepare() {
    final session = OnboardingScope.of(context);
    final template = _templateId(session.draft.websiteTemplate);
    session.draft.websiteTemplate = template;
    session.website.applyStyle(_styleId(template));
    session.website.seedFromProfile(session.draft);
    final photo = session.draft.photoBytes;
    if (photo != null && session.website.photos.isEmpty) {
      session.website.photos.add(photo);
    }
  }

  void _openPurchase() {
    _prepare();
    AppRouter.open(context, AppRoutes.websitePurchase);
  }

  void _openBuilder() {
    _prepare();
    AppRouter.open(context, AppRoutes.websiteInfo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final draft = session.draft;
    final template = _templateId(draft.websiteTemplate);
    final palette = context.palette;

    return OnboardingFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed: () => AppRouter.back(context, AppRoutes.profile),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  l10n.websiteTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline(context),
                ),
              ),
              TextButton(
                onPressed: () => AppRouter.open(context, AppRoutes.social),
                child: Text(l10n.portfolioSkip),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TabSwitcher(
            templatesLabel: l10n.portfolioTemplates,
            mineLabel: l10n.portfolioMyWebsite,
            showMine: _showMine,
            onChanged: (mine) => setState(() => _showMine = mine),
          ),
          const SizedBox(height: 16),
          if (!_showMine) ...[
            _FeaturedPreview(
              l10n: l10n,
              template: template,
              leaderName: draft.leaderName.trim(),
              constituency: draft.assemblyConstituency.trim(),
              party: draft.party.trim(),
              designation: draft.designation.trim(),
              photo: draft.photoBytes,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(l10n, template),
                        style: AppTextStyles.headline(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _body(l10n, template),
                        style: AppTextStyles.muted(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('openTemplate'),
                  tooltip: l10n.portfolioTemplates,
                  onPressed: _openBuilder,
                  icon: Icon(Icons.arrow_forward, color: palette.accent),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final id in const [
                  'modern',
                  'traditional',
                  'peopleFirst',
                ]) ...[
                  Expanded(
                    child: _TemplateChoice(
                      key: ValueKey('template-$id'),
                      label: _choiceLabel(l10n, id),
                      selected: template == id,
                      photo: draft.photoBytes,
                      onTap: () => _select(id),
                    ),
                  ),
                  if (id != 'peopleFirst') const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: l10n.portfolioMakeYours,
              body: l10n.portfolioMakeYoursBody,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l10n.portfolioGetWebsite,
              icon: Icons.language,
              onPressed: _openPurchase,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.portfolioOneTime,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(context),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => AppRouter.open(context, AppRoutes.social),
              child: Text(l10n.skipForNow),
            ),
          ] else
            _MyWebsite(
              l10n: l10n,
              templateLabel: _title(l10n, template),
              leaderName: draft.leaderName.trim(),
              constituency: draft.assemblyConstituency.trim(),
              party: draft.party.trim(),
              designation: draft.designation.trim(),
              country: draft.country.trim(),
              state: draft.state.trim(),
              district: draft.district.trim(),
              contact: draft.contactNumber.trim(),
              photo: draft.photoBytes,
              preview: session.website.preview,
            ),
        ],
      ),
    );
  }

  String _title(AppLocalizations l10n, String template) {
    return switch (template) {
      'traditional' => l10n.portfolioTraditionalCampaign,
      'peopleFirst' => l10n.portfolioPeopleCampaign,
      _ => l10n.portfolioModernCampaign,
    };
  }

  String _body(AppLocalizations l10n, String template) {
    return switch (template) {
      'traditional' => l10n.portfolioTraditionalBody,
      'peopleFirst' => l10n.portfolioPeopleBody,
      _ => l10n.portfolioModernBody,
    };
  }

  String _choiceLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'traditional' => l10n.portfolioTraditional,
      'peopleFirst' => l10n.portfolioPeople,
      _ => l10n.portfolioModern,
    };
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.templatesLabel,
    required this.mineLabel,
    required this.showMine,
    required this.onChanged,
  });

  final String templatesLabel;
  final String mineLabel;
  final bool showMine;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                icon: Icons.grid_view_rounded,
                label: templatesLabel,
                selected: !showMine,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _Tab(
                icon: Icons.language,
                label: mineLabel,
                selected: showMine,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : palette.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(color: selected ? Colors.white : palette.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPreview extends StatelessWidget {
  const _FeaturedPreview({
    required this.l10n,
    required this.template,
    required this.leaderName,
    required this.constituency,
    required this.party,
    required this.designation,
    required this.photo,
  });

  final AppLocalizations l10n;
  final String template;
  final String leaderName;
  final String constituency;
  final String party;
  final String designation;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final headline = switch (template) {
      'traditional' => l10n.portfolioHeadlineTraditional,
      'peopleFirst' => l10n.portfolioHeadlinePeople,
      _ => l10n.portfolioHeadlineModern,
    };
    final support = switch (template) {
      'traditional' => l10n.portfolioSupportTraditional,
      'peopleFirst' => l10n.portfolioSupportPeople,
      _ => l10n.portfolioSupportModern,
    };
    final details = [
      constituency,
      party,
      designation,
    ].where((value) => value.isNotEmpty).join(' · ');

    return DecoratedBox(
      key: ValueKey('preview-$template'),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent, width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          l10n.portfolioRecommended,
                          style: AppTextStyles.label(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final label in [
                    l10n.portfolioNavHome,
                    l10n.portfolioNavAbout,
                    l10n.portfolioNavVision,
                    l10n.portfolioNavGallery,
                    l10n.portfolioNavContact,
                  ])
                    Text(
                      label,
                      style: AppTextStyles.muted(
                        context,
                      ).copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PhotoFill(photo: photo, tint: palette.surfaceHighlight),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          palette.background.withValues(alpha: 0.15),
                          palette.background.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          headline,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline(
                            context,
                          ).copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          support,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(context),
                        ),
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08A24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.portfolioJoin,
                              style: AppTextStyles.label(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (leaderName.isNotEmpty || details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leaderName.isNotEmpty)
                      Text(leaderName, style: AppTextStyles.headline(context)),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(details, style: AppTextStyles.muted(context)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateChoice extends StatelessWidget {
  const _TemplateChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.photo,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Uint8List? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: _PhotoFill(
                          photo: photo,
                          tint: palette.surfaceHighlight,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          color: palette.accent,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(color: selected ? Colors.white : palette.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline(context)),
                  const SizedBox(height: 4),
                  Text(body, style: AppTextStyles.muted(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyWebsite extends StatelessWidget {
  const _MyWebsite({
    required this.l10n,
    required this.templateLabel,
    required this.leaderName,
    required this.constituency,
    required this.party,
    required this.designation,
    required this.country,
    required this.state,
    required this.district,
    required this.contact,
    required this.photo,
    required this.preview,
  });

  final AppLocalizations l10n;
  final String templateLabel;
  final String leaderName;
  final String constituency;
  final String party;
  final String designation;
  final String country;
  final String state;
  final String district;
  final String contact;
  final Uint8List? photo;
  final WebsiteDocument? preview;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lines = [
      leaderName,
      designation,
      constituency,
      party,
      [district, state, country].where((value) => value.isNotEmpty).join(', '),
      contact,
    ].where((value) => value.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.accent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(templateLabel, style: AppTextStyles.headline(context)),
                const SizedBox(height: 8),
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      photo!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                for (final line in lines) ...[
                  const SizedBox(height: 6),
                  Text(line, style: AppTextStyles.body(context)),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.portfolioNotReady,
                  style: AppTextStyles.muted(context),
                ),
              ],
            ),
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: 16),
          WebsiteSiteView(document: preview!),
        ],
      ],
    );
  }
}

class _PhotoFill extends StatelessWidget {
  const _PhotoFill({required this.photo, required this.tint});

  final Uint8List? photo;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Image.memory(photo!, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: tint,
      child: Icon(Icons.person, size: 42, color: context.palette.textMuted),
    );
  }
}
