import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';

class VrmSetupScreen extends StatelessWidget {
  const VrmSetupScreen({super.key});

  void _continue(BuildContext context) {
    OnboardingScope.of(context).draft.vrmRequested = true;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.vrmLater)),
    );
    AppRouter.open(context, AppRoutes.ready);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = <(IconData, String)>[
      (Icons.contacts_outlined, l10n.vrmPointContacts),
      (Icons.groups_outlined, l10n.vrmPointTeam),
      (Icons.assignment_outlined, l10n.vrmPointIssues),
    ];

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.vrmTitle,
              description: '${l10n.optionalLabel}. ${l10n.vrmBody}',
            ),
            const SizedBox(height: 18),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(point.$1, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(point.$2, style: AppTextStyles.body(context)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () => AppRouter.back(context, AppRoutes.social),
              primaryLabel: l10n.vrmSetup,
              onPrimary: () => _continue(context),
              skipLabel: l10n.skipForNow,
              onSkip: () => AppRouter.open(context, AppRoutes.dashboard),
            ),
          ],
        ),
      ),
    );
  }
}
