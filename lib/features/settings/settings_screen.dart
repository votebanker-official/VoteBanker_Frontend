import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        children: [
          Material(
            color: palette.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('settings-back'),
                    tooltip: 'Back',
                    onPressed: () => AppNav.back(context, AppRoutes.dashboard),
                    icon: Icon(Icons.arrow_back, color: palette.accent),
                  ),
                  Image.asset(AppAssets.logo, width: 32, height: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.cardSettings,
                      style: AppTextStyles.sectionTitle(
                        context,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  child: Column(
                    children: [
                      _SettingsLink(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Policy',
                        body:
                            'How VoteBanker handles account, voter, and campaign data.',
                        onTap:
                            () => AppNav.open(context, AppRoutes.privacyPolicy),
                      ),
                      Divider(color: palette.border, height: 1),
                      _SettingsLink(
                        icon: Icons.delete_outline,
                        title: 'Account & data deletion',
                        body:
                            'Disconnect social accounts or ask for the workspace to be erased.',
                        onTap:
                            () => AppNav.open(context, AppRoutes.dataDeletion),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label(context)),
                  const SizedBox(height: 2),
                  Text(body, style: AppTextStyles.muted(context)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
