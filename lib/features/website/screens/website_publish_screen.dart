import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_frame.dart';

class WebsitePublishScreen extends StatelessWidget {
  const WebsitePublishScreen({super.key});

  Future<void> _mock(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    await action();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).line('publishNotConnected'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final publishing = OnboardingScope.of(context).websiteServices.publishing;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('publishTitle'),
              description: l10n.line('publishBody'),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l10n.line('connectDomain'),
              icon: Icons.language,
              onPressed: () => _mock(context, publishing.connectDomain),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: l10n.line('useVbDomain'),
              icon: Icons.public,
              onPressed: () => _mock(context, publishing.usePlatformDomain),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: l10n.line('publishLater'),
              onPressed: () => AppRouter.open(context, AppRoutes.social),
            ),
          ],
        ),
      ),
    );
  }
}
