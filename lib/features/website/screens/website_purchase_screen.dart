import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/website_builder_draft.dart';
import '../services/website_builder_api.dart';
import '../services/website_builder_store.dart';
import '../widgets/website_builder_preview.dart';
import '../widgets/website_stage.dart';

class WebsitePurchaseScreen extends StatefulWidget {
  const WebsitePurchaseScreen({super.key});

  @override
  State<WebsitePurchaseScreen> createState() => _WebsitePurchaseScreenState();
}

class _WebsitePurchaseScreenState extends State<WebsitePurchaseScreen> {
  var _method = 'upi';
  var _busy = false;
  var _publishing = false;
  String? _publishError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBuilderFromProfile();
  }

  void _syncBuilderFromProfile() {
    final session = OnboardingScope.of(context);
    final draft = session.draft;
    final builder = session.websiteBuilder;
    builder.applyPartyFromProfile(draft.party);
    if (builder.fullName.trim().isEmpty) {
      builder.fullName = draft.leaderName.trim();
    }
    if (builder.designation.trim().isEmpty) {
      builder.designation = draft.designation.trim();
    }
    if (builder.constituency.trim().isEmpty) {
      builder.constituency = draft.assemblyConstituency.trim();
    }
    if (builder.district.trim().isEmpty) {
      builder.district = draft.district.trim();
    }
    if (builder.state.trim().isEmpty) {
      builder.state = draft.state.trim();
    }
    if (builder.phone.trim().isEmpty) {
      builder.phone = draft.contactNumber.trim();
    }
    if (!builder.profilePhoto.hasImage && draft.photoBytes != null) {
      builder.profilePhoto = MediaRef(base64: base64Encode(draft.photoBytes!));
    }
  }

  Future<void> _purchase() async {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final builder = session.websiteBuilder;
    _syncBuilderFromProfile();
    final reasons = builder.publishBlockingReasons();
    if (reasons.isNotEmpty) {
      setState(() => _publishError = reasons.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reasons.first)),
      );
      return;
    }

    setState(() {
      _busy = true;
      _publishError = null;
    });
    builder.status = WebsiteStatus.pendingPayment;
    await WebsiteBuilderStore.instance.saveNow(builder);

    final attempt = await session.websiteServices.payment.startWebsitePurchase();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!attempt.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.line('paymentLater'))),
      );
    }
    AppRouter.open(context, AppRoutes.websitePublish);
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final builder = session.websiteBuilder;
    _syncBuilderFromProfile();
    final reasons = builder.publishBlockingReasons();
    if (reasons.isNotEmpty) {
      setState(() => _publishError = reasons.first);
      return;
    }

    setState(() {
      _publishing = true;
      _publishError = null;
    });
    await WebsiteBuilderStore.instance.saveNow(builder);
    final result = await WebsiteBuilderApi.instance.publish(builder);
    if (!mounted) return;
    setState(() => _publishing = false);

    if (result.error != null) {
      setState(() {
        _publishError = switch (result.error) {
          'payment_required' => l10n.line('wbPaymentRequired'),
          'sign_in_required' => l10n.line('wbSignInRequired'),
          'validation_failed' => builder.publishBlockingReasons().join(' '),
          _ => l10n.line('wbPublishFailed'),
        };
      });
      return;
    }
    if (result.draft != null) {
      session.websiteBuilder = result.draft!;
      await WebsiteBuilderStore.instance.saveLocal(result.draft!);
    }
    if (!mounted) return;
    AppRouter.open(context, AppRoutes.websitePublish);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final builder = session.websiteBuilder;
    final palette = context.palette;
    final busy = _busy || _publishing;

    return WebsiteStage(
      children: [
        Text(
          l10n.line('purchaseTitle'),
          style: AppTextStyles.headline(context),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.line('purchaseBody'),
          style: AppTextStyles.muted(context),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: const ValueKey('purchaseWebsitePreview'),
          child: WebsiteBuilderPreview(draft: builder),
        ),
        const SizedBox(height: 18),
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
                Text(
                  l10n.line('wbPlanTitle'),
                  style: AppTextStyles.headline(context),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.line('wbPlanBody'),
                  style: AppTextStyles.muted(context),
                ),
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
        Text(
          l10n.line('paymentMethod'),
          style: AppTextStyles.headline(context),
        ),
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
                onSelected: busy
                    ? null
                    : (_) => setState(() => _method = entry.$1),
              ),
          ],
        ),
        if (_publishError != null) ...[
          const SizedBox(height: 12),
          Text(
            _publishError!,
            style: AppTextStyles.body(context).copyWith(color: palette.danger),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          key: const ValueKey('payWebsite'),
          label: busy ? l10n.line('wbSaving') : l10n.portfolioGetWebsite,
          onPressed: busy ? null : _purchase,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          key: const ValueKey('publishWebsite'),
          label: l10n.line('wbPublish'),
          onPressed: busy ? () {} : _publish,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.line('securePayments'),
          textAlign: TextAlign.center,
          style: AppTextStyles.muted(context),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.line('continueEditing'),
          onPressed: busy
              ? () {}
              : () => AppRouter.open(context, AppRoutes.website),
        ),
      ],
    );
  }
}
