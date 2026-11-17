import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/widgets/dashboard_colors.dart';
import '../../dashboard/widgets/dashboard_sidebar.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import 'campaign_templates_screen.dart';
import 'merchandise_design_screen.dart';

class MerchandiseScreen extends StatefulWidget {
  const MerchandiseScreen({this.service, this.initialCatalog, super.key});

  final MerchandiseService? service;
  final MerchandiseCatalog? initialCatalog;

  @override
  State<MerchandiseScreen> createState() => _MerchandiseScreenState();
}

class _MerchandiseScreenState extends State<MerchandiseScreen> {
  late final MerchandiseService _service =
      widget.service ?? MerchandiseService();
  MerchandiseCatalog? _catalog;
  List<MerchandiseOrder> _orders = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCatalog != null) {
      _catalog = widget.initialCatalog;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final catalog = await _service.loadCatalog();
      final orders = await _service.loadOrders();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = _catalog;

    final draft = OnboardingScope.maybeOf(context)?.draft;
    final signedIn = AuthService.instance.isSignedIn;
    final party = signedIn ? PartyOption.findByName(draft?.party ?? '') : null;
    final photo = signedIn ? draft?.photoBytes : null;
    final products =
        (catalog == null || catalog.products.isEmpty)
            ? campaignTemplateProducts
            : catalog.products;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= AppBreakpoints.tablet;
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: SafeArea(
            child: Row(
              children: [
                if (showSidebar)
                  SizedBox(
                    width: 248,
                    child: DashboardSidebar(
                      colors: DashboardColors.of(context),
                      items: dashboardSidebarItems(l10n),
                      selectedRoute: AppRoutes.merchandise,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed:
                                  () => AppRouter.back(
                                    context,
                                    AppRoutes.dashboard,
                                  ),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            const ThemeToggle(),
                            const SizedBox(width: 8),
                            const LanguageSelector(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                          children: [
                            const CampaignMerchandiseHero(),
                            const SizedBox(height: 16),
                            Text(
                              'Campaign Templates',
                              style: AppTextStyles.headline(
                                context,
                              ).copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 16),
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...[
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns =
                                      constraints.maxWidth >= 860 ? 2 : 1;
                                  final cardWidth =
                                      (constraints.maxWidth -
                                          (columns - 1) * 20) /
                                      columns;
                                  final extent =
                                      cardWidth < 430 ? 168.0 : 220.0;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          mainAxisSpacing: 20,
                                          crossAxisSpacing: 20,
                                          mainAxisExtent: extent,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = products[index];
                                      return CampaignTemplateCard(
                                        product: item,
                                        party: party,
                                        photo: photo,
                                        onOrder: () async {
                                          final saved = await Navigator.of(
                                            context,
                                          ).push<bool>(
                                            MaterialPageRoute<bool>(
                                              builder:
                                                  (context) =>
                                                      MerchandiseDesignScreen(
                                                        product: item,
                                                        service: _service,
                                                      ),
                                            ),
                                          );
                                          if (saved == true) {
                                            await _load();
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                              Text(
                                l10n.line('merchMyRequests'),
                                style: AppTextStyles.label(context),
                              ),
                              const SizedBox(height: 8),
                              if (_orders.isEmpty)
                                Text(
                                  l10n.line('merchNoRequests'),
                                  style: AppTextStyles.muted(context),
                                )
                              else
                                for (final order in _orders) ...[
                                  AppCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.productName,
                                          style: AppTextStyles.label(context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.campaignLine,
                                          style: AppTextStyles.body(context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${order.quantity} · ${l10n.line('merchStatusRequested')}',
                                          style: AppTextStyles.muted(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
