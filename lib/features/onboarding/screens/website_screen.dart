import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../website/models/website_builder_draft.dart';
import '../../website/models/website_template_catalog.dart';
import '../../website/screens/website_builder_screen.dart';
import '../../website/services/portfolio_store.dart';
import '../../website/services/website_builder_store.dart';
import '../../website/widgets/website_builder_preview.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_frame.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await _restorePortfolio();
    if (!mounted) return;
    _ensureUnifiedTemplate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Apply the single template as soon as the session is available so the
    // preview does not wait on async draft restore.
    _ensureUnifiedTemplate(persist: false);
    _syncPartyFromProfile();
  }

  void _syncPartyFromProfile() {
    final session = OnboardingScope.of(context);
    session.websiteBuilder.applyPartyFromProfile(session.draft.party);
    if (session.websiteBuilder.fullName.trim().isEmpty) {
      session.websiteBuilder.fullName = session.draft.leaderName.trim();
    }
    if (session.websiteBuilder.designation.trim().isEmpty) {
      session.websiteBuilder.designation = session.draft.designation.trim();
    }
    if (session.websiteBuilder.constituency.trim().isEmpty) {
      session.websiteBuilder.constituency =
          session.draft.assemblyConstituency.trim();
    }
    if (session.websiteBuilder.district.trim().isEmpty) {
      session.websiteBuilder.district = session.draft.district.trim();
    }
    if (session.websiteBuilder.state.trim().isEmpty) {
      session.websiteBuilder.state = session.draft.state.trim();
    }
    if (session.websiteBuilder.phone.trim().isEmpty) {
      session.websiteBuilder.phone = session.draft.contactNumber.trim();
    }
    if (!session.websiteBuilder.profilePhoto.hasImage &&
        session.draft.photoBytes != null) {
      session.websiteBuilder.profilePhoto = MediaRef(
        base64: base64Encode(session.draft.photoBytes!),
      );
    }
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

  /// One professional leader website is offered. Older draft IDs still load.
  void _ensureUnifiedTemplate({bool persist = true}) {
    final session = OnboardingScope.of(context);
    final id = WebsiteTemplates.professional;
    if (session.draft.websiteTemplate == id &&
        session.websiteBuilder.templateId == id &&
        session.portfolio.templateId == id) {
      return;
    }
    session.draft.websiteTemplate = id;
    session.portfolio.selectTemplate(id);
    session.websiteBuilder.selectTemplate(id);
    if (persist) {
      unawaited(PortfolioStore.instance.save(session.portfolio));
      unawaited(WebsiteBuilderStore.instance.saveNow(session.websiteBuilder));
    }
  }

  void _prepare() {
    final session = OnboardingScope.of(context);
    final template = WebsiteTemplates.professional;
    session.draft.websiteTemplate = template;
    session.portfolio.selectTemplate(template);
    session.websiteBuilder.selectTemplate(template);
    session.website.applyStyle(WebsiteTemplates.styleId(template));
    session.website.seedFromProfile(session.draft);
    session.websiteBuilder.applyPartyFromProfile(session.draft.party);
    final photo = session.draft.photoBytes;
    if (photo != null && session.website.photos.isEmpty) {
      session.website.photos.add(photo);
    }
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

  Future<void> _previewWebsite() async {
    final session = OnboardingScope.of(context);
    final source = session.websiteBuilder;
    final draft = WebsiteBuilderDraft(templateId: WebsiteTemplates.professional)
      ..fullName = source.fullName.trim().isNotEmpty
          ? source.fullName.trim()
          : session.draft.leaderName.trim()
      ..designation = source.designation.trim().isNotEmpty
          ? source.designation.trim()
          : session.draft.designation.trim()
      ..constituency = source.constituency.trim().isNotEmpty
          ? source.constituency.trim()
          : session.draft.assemblyConstituency.trim()
      ..district = source.district
      ..state = source.state
      ..applyPartyFromProfile(session.draft.party)
      ..shortIntro = source.shortIntro
      ..biography = source.biography
      ..aboutLeader = source.aboutLeader
      ..goalsVision = source.goalsVision
      ..localPriorities = source.localPriorities
      ..phone = session.draft.contactNumber.trim().isNotEmpty
          ? session.draft.contactNumber.trim()
          : source.phone
      ..email = source.email
      ..achievements = source.achievements
      ..projects = source.projects
      ..gallery = source.gallery
      ..announcements = source.announcements
      ..events = source.events;
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
                WebsiteTemplateCatalog.professional.name,
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
    _syncPartyFromProfile();
    final builder = session.websiteBuilder;

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
                child: Text(
                  l10n.line('chooseWebsiteTemplate'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline(context),
                ),
              ),
              TextButton(
                onPressed: () => AppRouter.open(context, AppRoutes.domain),
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
          const SizedBox(height: 16),
          KeyedSubtree(
            key: const ValueKey('preview-professional'),
            child: WebsiteBuilderPreview(draft: builder),
          ),
          const SizedBox(height: 12),
          if (builder.shortIntro.trim().isNotEmpty ||
              builder.biography.trim().isNotEmpty)
            OutlinedButton.icon(
              key: const ValueKey('editWebsite'),
              onPressed: () => _openBuilder(continueOnboarding: false),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.line('portfolioEditWebsite')),
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
          OutlinedButton(
            key: const ValueKey('previewWebsite'),
            onPressed: _previewWebsite,
            child: Text(l10n.line('portfolioPreviewTemplate')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => AppRouter.open(context, AppRoutes.social),
            child: Text(l10n.skipForNow),
          ),
        ],
      ),
    );
  }
}
