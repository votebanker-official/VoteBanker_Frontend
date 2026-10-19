import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';

/// Placeholder for additional VRM access. No price or purchase claim.
class VrmGetMoreScreen extends StatelessWidget {
  const VrmGetMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

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
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.line('vrmGetMoreBody'),
                        style: AppTextStyles.body(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.line('vrmPricingSoon'),
                        style: AppTextStyles.muted(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
