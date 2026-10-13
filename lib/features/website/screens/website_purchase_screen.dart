import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/website_builder_draft.dart';
import '../services/website_builder_store.dart';
import '../widgets/website_builder_preview.dart';
import '../widgets/website_site_view.dart';
import '../widgets/website_stage.dart';

class WebsitePurchaseScreen extends StatefulWidget {
  const WebsitePurchaseScreen({super.key});

  @override
  State<WebsitePurchaseScreen> createState() => _WebsitePurchaseScreenState();
}

class _WebsitePurchaseScreenState extends State<WebsitePurchaseScreen> {
  var _method = 'upi';
  var _busy = false;

  Future<void> _purchase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final builder = session.websiteBuilder;
    final reasons = builder.publishBlockingReasons();
    if (reasons.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reasons.first)),
      );
      return;
    }

    setState(() => _busy = true);
    builder.status = WebsiteStatus.pendingPayment;
    await WebsiteBuilderStore.instance.saveNow(builder);

    final attempt = await session.websiteServices.payment.startWebsitePurchase();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!attempt.connected) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text(l10n.line('paymentLater'))),
      );
      // Do not mark paid or published from the client.
      AppRouter.open(this.context, AppRoutes.websitePublish);
      return;
    }

    AppRouter.open(this.context, AppRoutes.websitePublish);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final preview = session.website.preview;
    final builder = session.websiteBuilder;
    final palette = context.palette;

    return WebsiteStage(
      children: [
        if (builder.fullName.trim().isNotEmpty ||
            builder.shortIntro.trim().isNotEmpty)
          WebsiteBuilderPreview(draft: builder, compact: true)
        else if (preview != null) ...[
          WebsiteSiteView(document: preview),
        ],
        const SizedBox(height: 22),
        Text(l10n.line('purchaseTitle'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 6),
        Text(l10n.line('purchaseBody'), style: AppTextStyles.muted(context)),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.line('wbPlanTitle'),
                    style: AppTextStyles.headline(context)),
                const SizedBox(height: 6),
                Text(l10n.line('wbPlanBody'),
                    style: AppTextStyles.muted(context)),
                const SizedBox(height: 10),
                Text(
                  '₹999',
                  style: AppTextStyles.headline(context).copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Payment method', style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const [
              ('upi', 'UPI'),
              ('card', 'Card'),
              ('netbanking', 'Net Banking'),
            ])
              ChoiceChip(
                label: Text(entry.$2),
                selected: _method == entry.$1,
                onSelected: (_) => setState(() => _method = entry.$1),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        PrimaryButton(
          label: _busy ? l10n.line('wbSaving') : 'Pay Now',
          onPressed: _busy ? null : () => _purchase(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure & Encrypted Payments',
          textAlign: TextAlign.center,
          style: AppTextStyles.muted(context),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.line('continueEditing'),
          onPressed: () => AppRouter.back(context, AppRoutes.website),
        ),
      ],
    );
  }
}
