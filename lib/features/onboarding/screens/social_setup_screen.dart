import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';
import '../widgets/setup_option.dart';

class SocialSetupScreen extends StatefulWidget {
  const SocialSetupScreen({super.key});

  @override
  State<SocialSetupScreen> createState() => _SocialSetupScreenState();
}

class _SocialSetupScreenState extends State<SocialSetupScreen> {
  void _toggle(String channel) {
    final channels = OnboardingScope.of(context).draft.socialChannels;
    setState(() {
      if (!channels.add(channel)) {
        channels.remove(channel);
      }
    });
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.socialLater)),
    );
    AppRouter.open(context, AppRoutes.vrm);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channels = OnboardingScope.of(context).draft.socialChannels;
    final options = <(String, IconData, String)>[
      ('instagram', Icons.photo_camera_outlined, l10n.socialInstagram),
      ('facebook', Icons.thumb_up_alt_outlined, l10n.socialFacebook),
      ('meta', Icons.hub_outlined, l10n.socialMeta),
    ];

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.socialTitle,
              description: '${l10n.optionalLabel}. ${l10n.socialBody}',
            ),
            const SizedBox(height: 18),
            for (final option in options) ...[
              SetupOption(
                icon: option.$2,
                title: option.$3,
                body: l10n.comingLater,
                selected: channels.contains(option.$1),
                onTap: () => _toggle(option.$1),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () => AppRouter.back(context, AppRoutes.website),
              primaryLabel: l10n.viewPlans,
              onPrimary: _continue,
              skipLabel: l10n.skipForNow,
              onSkip: () => AppRouter.open(context, AppRoutes.dashboard),
            ),
          ],
        ),
      ),
    );
  }
}
