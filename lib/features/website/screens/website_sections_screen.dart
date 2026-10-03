import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_actions.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../models/website_draft.dart';

class WebsiteSectionsScreen extends StatefulWidget {
  const WebsiteSectionsScreen({super.key});

  @override
  State<WebsiteSectionsScreen> createState() => _WebsiteSectionsScreenState();
}

class _WebsiteSectionsScreenState extends State<WebsiteSectionsScreen> {

  static const _labels = <String, String>{
    'home': 'secHome',
    'about': 'secAbout',
    'vision': 'secVision',
    'mission': 'secMission',
    'work': 'secWork',
    'achievements': 'secAchievements',
    'updates': 'secUpdates',
    'events': 'secEvents',
    'requests': 'secRequests',
    'contact': 'secContact',
    'social': 'secSocial',
    'gallery': 'secGallery',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final website = OnboardingScope.of(context).website;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('sectionsTitle'),
              description: l10n.line('sectionsBody'),
            ),
            const SizedBox(height: 16),
            for (final id in WebsiteDraft.sectionIds)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: website.sections.contains(id),
                activeColor: context.palette.accent,
                checkColor: context.palette.isDark
                    ? context.palette.background
                    : Colors.white,
                title: Text(l10n.line(_labels[id]!), style: AppTextStyles.body(context)),
                onChanged: (checked) {
                  if (checked ?? false) {
                    website.sections.add(id);
                  } else {
                    website.sections.remove(id);
                  }
                  website.sectionsReady = true;
                  setState(() {});
                },
              ),
            const SizedBox(height: 8),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () => AppRouter.back(context, AppRoutes.websiteQuestions),
              primaryLabel: l10n.line('continueAction'),
              onPrimary: () => AppRouter.open(context, AppRoutes.websiteGenerating),
              skipLabel: l10n.skipForNow,
              onSkip: () => AppRouter.open(context, AppRoutes.social),
            ),
          ],
        ),
      ),
    );
  }
}
