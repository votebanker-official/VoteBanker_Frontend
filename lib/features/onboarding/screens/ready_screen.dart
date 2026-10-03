import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../widgets/onboarding_frame.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key});

  void _dashboard(BuildContext context) {
    AppRouter.open(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.verified_outlined, color: context.palette.secondary, size: 42),
            const SizedBox(height: 12),
            OnboardingHeader(
              compact: true,
              title: l10n.readyTitle,
              description: l10n.readyBody,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: l10n.goToDashboard,
              icon: Icons.dashboard_outlined,
              onPressed: () => _dashboard(context),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.exploreFeatures,
              icon: Icons.explore_outlined,
              onPressed: () => _dashboard(context),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.joinNetwork,
              icon: Icons.groups_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.joinLater)),
                );
              },
            ),
            TextButton(
              onPressed: () => _dashboard(context),
              child: Text(l10n.skipForNow),
            ),
          ],
        ),
      ),
    );
  }
}
