import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';

class AdministrationsScreen extends StatelessWidget {
  const AdministrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modules = <_AdminModule>[
      _AdminModule(
        Icons.record_voice_over_outlined,
        l10n.line('speechCard'),
        subtitle: l10n.line('speechCardBody'),
        route: AppRoutes.speech,
      ),
      _AdminModule(
        Icons.mail_outline,
        l10n.line('letterCard'),
        subtitle: l10n.line('letterCardBody'),
        route: AppRoutes.letter,
      ),
      _AdminModule(Icons.event_outlined, l10n.cardEvents),
      _AdminModule(Icons.campaign_outlined, l10n.cardCampaign),
      _AdminModule(Icons.insights_outlined, l10n.cardAnalytics),
      _AdminModule(Icons.assignment_outlined, l10n.cardIssues),
      _AdminModule(Icons.receipt_long_outlined, l10n.cardBilling),
    ];

    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal =
                  constraints.maxWidth >= AppBreakpoints.wide ? 32.0 : 16.0;
              final columns =
                  AppBreakpoints.dashboardColumns(constraints.maxWidth);

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: l10n.back,
                          onPressed: () =>
                              AppRouter.back(context, AppRoutes.dashboard),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            l10n.line('cardAdministrations'),
                            style: AppTextStyles.headline(context),
                          ),
                        ),
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
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            20,
                            horizontal,
                            28,
                          ),
                          children: [
                            Text(
                              l10n.line('administrationsSubtitle'),
                              style: AppTextStyles.muted(context),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 118,
                              ),
                              itemBuilder: (context, index) {
                                final module = modules[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: module.route == null
                                        ? null
                                        : () => AppRouter.open(
                                              context,
                                              module.route!,
                                            ),
                                    child: AppCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: context.palette.accent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              module.icon,
                                              color: context.palette.accent,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  module.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.label(
                                                    context,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  module.subtitle ??
                                                      l10n.comingLater,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.muted(
                                                    context,
                                                  ).copyWith(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

class _AdminModule {
  const _AdminModule(this.icon, this.title, {this.subtitle, this.route});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
}
