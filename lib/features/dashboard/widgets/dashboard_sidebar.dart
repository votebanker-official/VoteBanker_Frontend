import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../admin/admin_access.dart';
import 'dashboard_colors.dart';

class DashboardNavEntry {
  const DashboardNavEntry({
    required this.icon,
    required this.label,
    this.route,
  });

  final IconData icon;
  final String label;
  final String? route;
}

List<DashboardNavEntry> dashboardSidebarItems(AppLocalizations l10n) {
  return [
    DashboardNavEntry(icon: Icons.person_outline, label: l10n.cardProfile),
    DashboardNavEntry(
      icon: Icons.share_outlined,
      label: l10n.line('smiNav'),
      route: AppRoutes.socialIntegration,
    ),
    DashboardNavEntry(
      icon: Icons.auto_awesome_outlined,
      label: l10n.cardContent,
    ),
    DashboardNavEntry(
      icon: Icons.groups_outlined,
      label: l10n.cardVrm,
      route: AppRoutes.vrmRecords,
    ),
    DashboardNavEntry(
      icon: Icons.group_outlined,
      label: l10n.cardTeam,
      route: AppRoutes.team,
    ),
    DashboardNavEntry(
      icon: Icons.storefront_outlined,
      label: l10n.cardMarketplace,
      route: AppRoutes.merchandise,
    ),
    DashboardNavEntry(
      icon: Icons.account_balance_outlined,
      label: l10n.line('cardAdministrations'),
      route: AppRoutes.administrations,
    ),
    DashboardNavEntry(icon: Icons.settings_outlined, label: l10n.cardSettings),
  ];
}

class DashboardSidebar extends StatefulWidget {
  const DashboardSidebar({
    required this.colors,
    required this.items,
    this.selectedRoute = AppRoutes.dashboard,
    this.onNavigate,
    this.footer,
    super.key,
  });

  final DashboardColors colors;
  final List<DashboardNavEntry> items;
  final String selectedRoute;
  final VoidCallback? onNavigate;
  final Widget? footer;

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  @override
  void initState() {
    super.initState();
    AdminAccess.instance.ensureLoaded();
    AdminAccess.instance.addListener(_onAccess);
  }

  @override
  void dispose() {
    AdminAccess.instance.removeListener(_onAccess);
    super.dispose();
  }

  void _onAccess() {
    if (mounted) setState(() {});
  }

  List<DashboardNavEntry> _items(AppLocalizations l10n) {
    final items = widget.items;
    if (!AdminAccess.instance.isAdmin) return items;
    if (items.any((item) => item.route == AppRoutes.admin)) return items;
    final admin = DashboardNavEntry(
      icon: Icons.admin_panel_settings_outlined,
      label: l10n.line('adminPanel'),
      route: AppRoutes.admin,
    );
    final settings = items.indexWhere((item) => item.icon == Icons.settings_outlined);
    if (settings < 0) return [...items, admin];
    return [
      ...items.sublist(0, settings),
      admin,
      ...items.sublist(settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = widget.colors;
    final items = _items(l10n);
    final selectedRoute = widget.selectedRoute;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [
                _NavTile(
                  colors: colors,
                  icon: Icons.space_dashboard_outlined,
                  label: l10n.dashboard,
                  selected: selectedRoute == AppRoutes.dashboard,
                  onTap:
                      selectedRoute == AppRoutes.dashboard
                          ? null
                          : () {
                            widget.onNavigate?.call();
                            AppRouter.replace(context, AppRoutes.dashboard);
                          },
                ),
                const SizedBox(height: 4),
                for (final item in items) ...[
                  _NavTile(
                    colors: colors,
                    icon: item.icon,
                    label: item.label,
                    selected: item.route != null && item.route == selectedRoute,
                    onTap:
                        item.route == null
                            ? null
                            : () {
                              widget.onNavigate?.call();
                              if (item.route == selectedRoute) return;
                              AppRouter.open(context, item.route!);
                            },
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.colors,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final DashboardColors colors;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? colors.onSelected : colors.text;
    return Material(
      color: selected ? colors.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.onSelected : colors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
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
