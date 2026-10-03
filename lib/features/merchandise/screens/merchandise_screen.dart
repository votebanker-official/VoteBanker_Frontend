import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import 'merchandise_design_screen.dart';

class MerchandiseScreen extends StatefulWidget {
  const MerchandiseScreen({
    this.service,
    this.initialCatalog,
    super.key,
  });

  final MerchandiseService? service;
  final MerchandiseCatalog? initialCatalog;

  @override
  State<MerchandiseScreen> createState() => _MerchandiseScreenState();
}

class _MerchandiseScreenState extends State<MerchandiseScreen> {
  late final MerchandiseService _service = widget.service ?? MerchandiseService();
  MerchandiseCatalog? _catalog;
  List<MerchandiseOrder> _orders = const [];
  var _loading = true;
  var _failed = false;

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
        _failed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = _catalog;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => AppRouter.back(context, AppRoutes.dashboard),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(l10n.line('merchTitle'), style: AppTextStyles.wordmark(context).copyWith(fontSize: 16)),
                    ),
                    const ThemeToggle(),
                    const SizedBox(width: 8),
                    const LanguageSelector(),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppBreakpoints.dashboardMaxWidth),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        Text(l10n.line('merchTitle'), style: AppTextStyles.headline(context)),
                        const SizedBox(height: 8),
                        Text(l10n.line('merchBody'), style: AppTextStyles.muted(context)),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_failed || catalog == null)
                          Text(l10n.line('merchLoadError'), style: AppTextStyles.body(context))
                        else ...[
                          if (!catalog.storageReady)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(l10n.line('merchNotReady'), style: AppTextStyles.muted(context)),
                            ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 900
                                  ? 4
                                  : constraints.maxWidth >= 640
                                  ? 3
                                  : 2;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: catalog.products.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 168,
                                ),
                                itemBuilder: (context, index) {
                                  final item = catalog.products[index];
                                  return _ProductTile(
                                    product: item,
                                    action: l10n.line('merchOpen'),
                                    onTap: () async {
                                      final saved = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute<bool>(
                                          builder: (context) => MerchandiseDesignScreen(
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
                          Text(l10n.line('merchMyRequests'), style: AppTextStyles.label(context)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order.productName, style: AppTextStyles.label(context)),
                                    const SizedBox(height: 4),
                                    Text(order.campaignLine, style: AppTextStyles.body(context)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.action,
    required this.onTap,
  });

  final MerchandiseProduct product;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(product.slug), color: context.palette.accent),
              const Spacer(),
              Text(product.name, style: AppTextStyles.label(context)),
              const SizedBox(height: 4),
              Text(
                action,
                style: AppTextStyles.muted(context).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String slug) {
  return switch (slug) {
    't-shirt' => Icons.checkroom_outlined,
    'scarf' => Icons.dry_cleaning_outlined,
    'flag' => Icons.flag_outlined,
    'badge' => Icons.military_tech_outlined,
    'cap' => Icons.face_retouching_natural_outlined,
    'mug' => Icons.coffee_outlined,
    'poster' => Icons.image_outlined,
    'sticker' => Icons.sticky_note_2_outlined,
    'bag' => Icons.shopping_bag_outlined,
    'pen' => Icons.edit_outlined,
    'keychain' => Icons.vpn_key_outlined,
    'gift-box' => Icons.card_giftcard_outlined,
    _ => Icons.storefront_outlined,
  };
}
