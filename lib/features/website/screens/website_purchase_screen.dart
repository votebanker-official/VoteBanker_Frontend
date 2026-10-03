import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../widgets/website_site_view.dart';
import '../widgets/website_stage.dart';

class WebsitePurchaseScreen extends StatelessWidget {
  const WebsitePurchaseScreen({super.key});

  Future<void> _purchase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = OnboardingScope.of(context).websiteServices;
    await services.payment.startWebsitePurchase();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.line('paymentLater'))),
    );
    AppRouter.open(context, AppRoutes.websitePublish);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = OnboardingScope.of(context).website.preview;

    return WebsiteStage(
      children: [
        if (preview != null) ...[
          WebsiteSiteView(document: preview),
          const SizedBox(height: 22),
        ],
        Text(l10n.line('purchaseTitle'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 6),
        Text(l10n.line('purchaseBody'), style: AppTextStyles.muted(context)),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.websiteOffer,
          onPressed: () => _purchase(context),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.line('continueEditing'),
          onPressed: () => AppRouter.back(context, AppRoutes.websitePreview),
        ),
      ],
    );
  }
}
