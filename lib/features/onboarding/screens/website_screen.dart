import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../website/models/portfolio_config.dart';
import '../../website/models/website_builder_draft.dart';
import '../../website/models/website_template_catalog.dart';
import '../../website/screens/website_builder_screen.dart';
import '../../website/services/portfolio_store.dart';
import '../../website/services/website_builder_store.dart';
import '../../website/widgets/portfolio_live_preview.dart';
import '../../website/widgets/website_builder_preview.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_frame.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  var _showMine = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePortfolio());
  }

  Future<void> _restorePortfolio() async {
    if (!mounted) return;
    final session = OnboardingScope.of(context);
    if (session.portfolioRestored && session.websiteBuilderRestored) return;
    final saved = await PortfolioStore.instance.load();
    final builder = await WebsiteBuilderStore.instance.loadPreferred();
    if (!mounted) return;
    setState(() {
      session.portfolioRestored = true;
      session.websiteBuilderRestored = true;
      if (saved != null) {
        session.portfolio.templateId =
            WebsiteTemplates.normalize(saved.templateId);
        for (final entry in saved.templates.entries) {
          session.portfolio.templates[
              WebsiteTemplates.normalize(entry.key)] = entry.value;
        }
        session.draft.websiteTemplate ??=
            WebsiteTemplates.normalize(saved.templateId);
      }
      if (builder != null) {
        session.websiteBuilder = builder;
        session.draft.websiteTemplate ??= builder.templateId;
        session.portfolio.selectTemplate(builder.templateId);
      }
    });
  }

  String _templateId(String? stored) => WebsiteTemplates.normalize(stored);

  void _select(String template) {
    final session = OnboardingScope.of(context);
    final id = WebsiteTemplates.normalize(template);
    setState(() {
      session.draft.websiteTemplate = id;
      session.portfolio.selectTemplate(id);
      session.websiteBuilder.selectTemplate(id);
    });
    unawaited(PortfolioStore.instance.save(session.portfolio));
    unawaited(WebsiteBuilderStore.instance.saveNow(session.websiteBuilder));
  }

  void _prepare() {
    final session = OnboardingScope.of(context);
    final template = _templateId(session.draft.websiteTemplate);
    session.draft.websiteTemplate = template;
    session.portfolio.selectTemplate(template);
    session.websiteBuilder.selectTemplate(template);
    session.website.applyStyle(WebsiteTemplates.styleId(template));
    session.website.seedFromProfile(session.draft);
    final photo = session.draft.photoBytes;
    if (photo != null && session.website.photos.isEmpty) {
      session.website.photos.add(photo);
    }
  }

  PortfolioProfileFacts _facts(OnboardingController session) {
    final draft = session.draft;
    return PortfolioProfileFacts(
      name: draft.leaderName.trim(),
      designation: draft.designation.trim(),
      constituency: draft.assemblyConstituency.trim(),
      party: draft.party.trim(),
      location: [
        draft.district,
        draft.state,
        draft.country,
      ].where((value) => value.trim().isNotEmpty).join(', '),
      contact: draft.contactNumber.trim(),
      photo: draft.photoBytes,
    );
  }

  Future<void> _openBuilder({required bool continueOnboarding}) async {
    _prepare();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WebsiteBuilderScreen(
          continueOnboarding: continueOnboarding,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _previewTemplate(String template) async {
    final session = OnboardingScope.of(context);
    final draft = WebsiteBuilderDraft(templateId: template)
      ..fullName = session.draft.leaderName.trim()
      ..designation = session.draft.designation.trim()
      ..constituency = session.draft.assemblyConstituency.trim()
      ..party = session.draft.party.trim()
      ..shortIntro = session.websiteBuilder.shortIntro;
    if (session.draft.photoBytes != null) {
      draft.profilePhoto = MediaRef(
        base64: base64Encode(session.draft.photoBytes!),
      );
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                WebsiteTemplateCatalog.byId(template).name,
                style: AppTextStyles.headline(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: WebsiteBuilderPreview(draft: draft),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: AppLocalizations.of(context)
                    .line('portfolioCustomizeTemplate'),
                onPressed: () {
                  Navigator.pop(context);
                  _select(template);
                  _openBuilder(continueOnboarding: true);
                },
              ),
            ],
          ),
        );
      },
    );
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
                onPressed: () => AppRouter.back(context, AppRoutes.domain),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child:                 Text(
                  l10n.line('chooseWebsiteTemplate'),
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
          Text(
            l10n.line('chooseWebsiteTemplateBody'),
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
          const SizedBox(height: 12),
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
                  tooltip: l10n.line('portfolioCustomizeTemplate'),
                  onPressed: () => _openBuilder(continueOnboarding: true),
                  icon: Icon(Icons.arrow_forward, color: palette.accent),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final info in WebsiteTemplateCatalog.all) ...[
              _TemplateCard(
                key: ValueKey('template-${info.id}'),
                info: info,
                selected: template == info.id,
                photo: draft.photoBytes,
                selectLabel: l10n.line('portfolioSelectTemplate'),
                previewLabel: l10n.line('portfolioPreviewTemplate'),
                recommendedLabel: l10n.portfolioRecommended,
                onSelect: () => _select(info.id),
                onPreview: () => _previewTemplate(info.id),
              ),
              const SizedBox(height: 12),
            ],
            _InfoCard(
              title: l10n.portfolioMakeYours,
              body: l10n.portfolioMakeYoursBody,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              key: const ValueKey('continueTemplate'),
              label: l10n.line('portfolioCustomizeTemplate'),
              icon: Icons.arrow_forward,
              onPressed: () => _openBuilder(continueOnboarding: true),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('customizeTemplate'),
              onPressed: () => _openBuilder(continueOnboarding: true),
              child: Text(l10n.line('portfolioContinue')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => AppRouter.open(context, AppRoutes.social),
              child: Text(l10n.skipForNow),
            ),
          ] else
            _MyWebsite(
              l10n: l10n,
              design: session.portfolio.active,
              facts: _facts(session),
              builderDraft: session.websiteBuilder,
              headline: _headline(l10n, template),
              support: _support(l10n, template),
              onEdit: () => _openBuilder(continueOnboarding: false),
            ),
        ],
      ),
    );
  }

  String _headline(AppLocalizations l10n, String template) {
    return switch (WebsiteTemplates.normalize(template)) {
      WebsiteTemplates.official => l10n.portfolioHeadlineTraditional,
      WebsiteTemplates.community => l10n.portfolioHeadlinePeople,
      _ => l10n.portfolioHeadlineModern,
    };
  }

  String _support(AppLocalizations l10n, String template) {
    return switch (WebsiteTemplates.normalize(template)) {
      WebsiteTemplates.official => l10n.portfolioSupportTraditional,
      WebsiteTemplates.community => l10n.portfolioSupportPeople,
      _ => l10n.portfolioSupportModern,
    };
  }

  String _title(AppLocalizations l10n, String template) {
    return switch (WebsiteTemplates.normalize(template)) {
      WebsiteTemplates.official => l10n.portfolioTraditionalCampaign,
      WebsiteTemplates.community => l10n.portfolioPeopleCampaign,
      _ => l10n.portfolioModernCampaign,
    };
  }

  String _body(AppLocalizations l10n, String template) {
    return switch (WebsiteTemplates.normalize(template)) {
      WebsiteTemplates.official => l10n.portfolioTraditionalBody,
      WebsiteTemplates.community => l10n.portfolioPeopleBody,
      _ => l10n.portfolioModernBody,
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
    final normalized = WebsiteTemplates.normalize(template);
    final headline = switch (normalized) {
      WebsiteTemplates.official => l10n.portfolioHeadlineTraditional,
      WebsiteTemplates.community => l10n.portfolioHeadlinePeople,
      _ => l10n.portfolioHeadlineModern,
    };
    final support = switch (normalized) {
      WebsiteTemplates.official => l10n.portfolioSupportTraditional,
      WebsiteTemplates.community => l10n.portfolioSupportPeople,
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    super.key,
    required this.info,
    required this.selected,
    required this.photo,
    required this.selectLabel,
    required this.previewLabel,
    required this.recommendedLabel,
    required this.onSelect,
    required this.onPreview,
  });

  final WebsiteTemplateInfo info;
  final bool selected;
  final Uint8List? photo;
  final String selectLabel;
  final String previewLabel;
  final String recommendedLabel;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? Color(info.primaryColor) : palette.border,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: _PhotoFill(
                      photo: photo,
                      tint: Color(info.primaryColor).withValues(alpha: 0.25),
                    ),
                  ),
                ),
                if (info.recommended)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(info.primaryColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          recommendedLabel,
                          style: AppTextStyles.label(context)
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(info.name, style: AppTextStyles.headline(context)),
            const SizedBox(height: 4),
            Text(info.description, style: AppTextStyles.muted(context)),
            const SizedBox(height: 8),
            for (final feature in info.features.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: Color(info.primaryColor)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(feature, style: AppTextStyles.body(context)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: selectLabel,
                    onPressed: onSelect,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPreview,
                    child: Text(previewLabel),
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
    required this.design,
    required this.facts,
    required this.builderDraft,
    required this.headline,
    required this.support,
    required this.onEdit,
  });

  final AppLocalizations l10n;
  final PortfolioDesign design;
  final PortfolioProfileFacts facts;
  final WebsiteBuilderDraft builderDraft;
  final String headline;
  final String support;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasBuilderContent = builderDraft.fullName.trim().isNotEmpty ||
        builderDraft.shortIntro.trim().isNotEmpty ||
        builderDraft.design.websiteName.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasBuilderContent)
          WebsiteBuilderPreview(draft: builderDraft)
        else
          PortfolioLivePreview(
            design: design,
            profile: facts,
            fallbackHeadline: headline,
            fallbackSupport: support,
          ),
        const SizedBox(height: 12),
        if (builderDraft.status.isNotEmpty)
          Text(
            'Status: ${builderDraft.status}',
            style: AppTextStyles.muted(context),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('editWebsite'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.line('portfolioEditWebsite')),
        ),
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
