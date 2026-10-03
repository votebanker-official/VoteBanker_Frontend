import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';
import '../widgets/setup_option.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  void _continue() {
    final session = OnboardingScope.of(context);
    session.website.applyStyle(session.draft.websiteTemplate);
    session.website.seedFromProfile(session.draft);
    AppRouter.open(context, AppRoutes.websiteInfo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final options = <(String, IconData, String, String)>[
      ('public', Icons.web_outlined, l10n.templatePublic, l10n.templatePublicBody),
      ('work', Icons.account_balance_outlined, l10n.templateWork, l10n.templateWorkBody),
      ('issue', Icons.forum_outlined, l10n.templateIssue, l10n.templateIssueBody),
    ];

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.websiteTitle,
              description: l10n.websiteBody,
            ),
            const SizedBox(height: 18),
            for (final option in options) ...[
              SetupOption(
                icon: option.$2,
                title: option.$3,
                body: option.$4,
                selected: draft.websiteTemplate == option.$1,
                onTap: () => setState(() => draft.websiteTemplate = option.$1),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () => AppRouter.back(context, AppRoutes.domain),
              primaryLabel: l10n.line('continueAction'),
              onPrimary: _continue,
              skipLabel: l10n.skipForNow,
              onSkip: () => AppRouter.open(context, AppRoutes.social),
            ),
          ],
        ),
      ),
    );
  }
}
