import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';

class VrmGetMoreScreen extends StatelessWidget {
  const VrmGetMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final offers = [
      l10n.line('vrmOffer100'),
      l10n.line('vrmOffer1000'),
      l10n.line('vrmOffer10000'),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => AppRouter.back(context, AppRoutes.vrmRecords),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l10n.back,
                    ),
                    Expanded(
                      child: Text(
                        l10n.line('vrmGetMoreTitle'),
                        style: AppTextStyles.headline(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.line('vrmGetMoreBody'),
                    style: AppTextStyles.muted(context),
                  ),
                ),
                const SizedBox(height: 20),
                for (final offer in offers) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: Text(offer, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
