import 'package:flutter/material.dart';

import '../../../app/localization/app_languages.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/website_draft.dart';
import '../services/website_services.dart';
import '../widgets/website_site_view.dart';
import '../widgets/website_stage.dart';

class WebsitePreviewScreen extends StatefulWidget {
  const WebsitePreviewScreen({super.key});

  @override
  State<WebsitePreviewScreen> createState() => _WebsitePreviewScreenState();
}

class _WebsitePreviewScreenState extends State<WebsitePreviewScreen> {
  int _device = 0;
  var _rebuilding = false;

  Future<void> _rebuild(WebsiteDraft website) async {
    if (_rebuilding) {
      return;
    }
    setState(() => _rebuilding = true);
    final l10n = AppLocalizations.of(context);
    final services = OnboardingScope.of(context).websiteServices;
    try {
      final preview = await services.generation.generate(website);
      if (!mounted) {
        return;
      }
      setState(() {
        website.preview = preview;
        _rebuilding = false;
      });
    } on WebsiteGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _rebuilding = false);
      final message = switch (error.code) {
        'website_ai_not_configured' => l10n.line('websiteAiNotConfigured'),
        'unreachable' => l10n.line('websiteGenerateUnreachable'),
        _ => l10n.line('websiteGenerateFailed'),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _rebuilding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.line('websiteGenerateFailed'))),
      );
    }
  }

  Future<void> _regenerate(WebsiteDraft website) async {
    website.layoutVariant = (website.layoutVariant + 1) % 3;
    website.regenerateInstruction =
        'Create a fresh layout variant ${website.layoutVariant}. Keep the same facts and do not invent new claims.';
    await _rebuild(website);
  }

  Future<void> _chooseStyle(WebsiteDraft website) async {
    final l10n = AppLocalizations.of(context);
    final styles = <(String, String)>[
      ('modern', l10n.line('themeModernLook')),
      ('elegant', l10n.line('themeElegant')),
      ('minimal', l10n.line('themeMinimal')),
      ('bold', l10n.line('themeBold')),
      ('warm', l10n.line('themeWarm')),
      ('editorial', l10n.line('themeEditorial')),
      ('civic', l10n.line('themeCivic')),
      ('creative', l10n.line('themeCreative')),
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.palette.surface,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final style in styles)
                  ListTile(
                    title: Text(style.$2),
                    onTap: () => Navigator.of(context).pop(style.$1),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    website.style = selected;
    await _rebuild(website);
  }

  Future<void> _chooseLanguage(WebsiteDraft website) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.palette.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final language in AppLanguages.all)
                ListTile(
                  title: Text(language.nativeName),
                  onTap: () => Navigator.of(context).pop(language.code),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    website
      ..websiteLanguage = selected
      ..languagesReady = true;
    await _rebuild(website);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final website = OnboardingScope.of(context).website;
    final preview = website.preview;

    return WebsiteStage(
      children: [
        if (_rebuilding)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (preview != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Action(
                label: l10n.line('previewDesktop'),
                selected: _device == 0,
                onPressed: () => setState(() => _device = 0),
              ),
              _Action(
                label: l10n.line('previewTablet'),
                selected: _device == 1,
                onPressed: () => setState(() => _device = 1),
              ),
              _Action(
                label: l10n.line('previewMobile'),
                selected: _device == 2,
                onPressed: () => setState(() => _device = 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preview.heroImageSource == 'stock' || preview.source == 'ai')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                preview.isAiGenerated
                    ? l10n.line('websiteAiSourceStock')
                    : l10n.line('websiteAiSourceStock'),
                style: AppTextStyles.muted(context),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _device == 2
                    ? 390
                    : _device == 1
                        ? 768
                        : double.infinity,
              ),
              child: WebsiteSiteView(document: preview),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.line('previewBody'), style: AppTextStyles.muted(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Action(
              label: l10n.line('editWebsite'),
              onPressed: _rebuilding
                  ? null
                  : () async {
                      await Navigator.of(context).pushNamed(AppRoutes.websiteEdit);
                      if (mounted) {
                        setState(() {});
                      }
                    },
            ),
            _Action(
              label: l10n.line('regenerate'),
              onPressed: _rebuilding ? null : () => _regenerate(website),
            ),
            _Action(
              label: l10n.line('changeStyle'),
              onPressed: _rebuilding ? null : () => _chooseStyle(website),
            ),
            _Action(
              label: l10n.line('changeLanguage'),
              onPressed: _rebuilding ? null : () => _chooseLanguage(website),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: l10n.line('continueAction'),
          onPressed: _rebuilding
              ? null
              : () => AppRouter.open(context, AppRoutes.websitePurchase),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, this.onPressed, this.selected = false});

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? context.palette.accent.withValues(alpha: 0.12)
            : null,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
