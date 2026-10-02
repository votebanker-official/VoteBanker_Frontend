import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/language_selector.dart';

class DashboardPlaceholderScreen extends StatelessWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modules = <_Module>[
      _Module(Icons.person_outline, l10n.cardProfile),
      _Module(Icons.language, l10n.cardDomain),
      _Module(Icons.share_outlined, l10n.cardSocial),
      _Module(Icons.auto_awesome_outlined, l10n.cardContent),
      _Module(Icons.groups_outlined, l10n.cardVrm),
      _Module(Icons.volunteer_activism_outlined, l10n.cardVolunteers),
      _Module(Icons.event_outlined, l10n.cardEvents),
      _Module(Icons.assignment_outlined, l10n.cardIssues),
      _Module(Icons.group_outlined, l10n.cardTeam),
      _Module(Icons.insights_outlined, l10n.cardAnalytics),
      _Module(Icons.storefront_outlined, l10n.cardMarketplace),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= AppBreakpoints.wide
                  ? 32.0
                  : 16.0;
              final columns = AppBreakpoints.dashboardColumns(constraints.maxWidth);

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            AppAssets.logo,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            semanticLabel: l10n.appName,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.appName,
                            style: AppTextStyles.wordmark(context).copyWith(fontSize: 16),
                          ),
                        ),
                        const LanguageSelector(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.dashboardMaxWidth,
                        ),
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            20,
                            horizontal,
                            28,
                          ),
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.dashboard,
                                style: AppTextStyles.headline(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.dashboardSubtitle,
                              style: AppTextStyles.muted(context),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 118,
                              ),
                              itemBuilder: (context, index) {
                                final module = modules[index];
                                return AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(module.icon, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              module.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.label(context),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.comingLater,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.muted(context).copyWith(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Module {
  const _Module(this.icon, this.title);

  final IconData icon;
  final String title;
}
