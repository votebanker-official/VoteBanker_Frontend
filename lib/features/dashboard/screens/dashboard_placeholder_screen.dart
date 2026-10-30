import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../widgets/dashboard_colors.dart';

class DashboardPlaceholderScreen extends StatefulWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  State<DashboardPlaceholderScreen> createState() =>
      _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState extends State<DashboardPlaceholderScreen> {
  final _search = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = DashboardColors.of(context);
    final name = OnboardingScope.of(context).draft.fullName.trim();
    final greeting = name.isEmpty ? l10n.welcomeTitle : l10n.welcomeBack(name);
    final modules = _modules(l10n);
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? modules
        : modules
            .where(
              (module) =>
                  module.title.toLowerCase().contains(query) ||
                  (module.subtitle ?? '').toLowerCase().contains(query),
            )
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.page,
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: colors.sidebar,
                  child: SafeArea(
                    child: _Sidebar(
                      colors: colors,
                      modules: modules,
                      selectedRoute: AppRoutes.dashboard,
                      onNavigate: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  SizedBox(
                    width: 248,
                    child: _Sidebar(
                      colors: colors,
                      modules: modules,
                      selectedRoute: AppRoutes.dashboard,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        colors: colors,
                        wide: wide,
                        name: name,
                        search: _search,
                        onSearch: () => setState(() {}),
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                wide ? 28 : 16,
                                20,
                                wide ? 28 : 16,
                                28,
                              ),
                              children: [
                                Text(
                                  l10n.dashboard,
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    greeting,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontSize: wide ? 28 : 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.dashboardSubtitle,
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (visible.isEmpty)
                                  Text(
                                    l10n.line('socialNoMatches'),
                                    style: TextStyle(color: colors.muted),
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (context, grid) {
                                      final columns = grid.maxWidth >= 900
                                          ? 3
                                          : grid.maxWidth >= 560
                                              ? 2
                                              : 1;
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: visible.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          mainAxisExtent: 118,
                                        ),
                                        itemBuilder: (context, index) {
                                          return _ModuleCard(
                                            colors: colors,
                                            module: visible[index],
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
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

  List<_Module> _modules(AppLocalizations l10n) {
    return [
      _Module(Icons.person_outline, l10n.cardProfile),
      _Module(
        Icons.groups_outlined,
        l10n.cardSocial,
        subtitle: l10n.line('socialCardBody'),
        route: AppRoutes.socialContacts,
      ),
      _Module(Icons.auto_awesome_outlined, l10n.cardContent),
      _Module(
        Icons.groups_outlined,
        l10n.cardVolunteers,
        subtitle: l10n.line('volCardBody'),
        route: AppRoutes.volunteers,
      ),
      _Module(
        Icons.groups_outlined,
        l10n.cardVrm,
        subtitle: l10n.line('vrmRecordsBody'),
        route: AppRoutes.vrmRecords,
      ),
      _Module(Icons.group_outlined, l10n.cardTeam),
      _Module(
        Icons.storefront_outlined,
        l10n.cardMarketplace,
        subtitle: l10n.line('merchOpen'),
        route: AppRoutes.merchandise,
      ),
      _Module(
        Icons.account_balance_outlined,
        l10n.line('cardAdministrations'),
        subtitle: l10n.line('administrationsCardBody'),
        route: AppRoutes.administrations,
      ),
      _Module(Icons.settings_outlined, l10n.cardSettings),
    ];
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.colors,
    required this.modules,
    this.selectedRoute = AppRoutes.dashboard,
    this.onNavigate,
  });

  final DashboardColors colors;
  final List<_Module> modules;
  final String selectedRoute;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  onTap: selectedRoute == AppRoutes.dashboard
                      ? null
                      : () {
                          onNavigate?.call();
                          AppRouter.replace(context, AppRoutes.dashboard);
                        },
                ),
                const SizedBox(height: 4),
                for (final module in modules) ...[
                  _NavTile(
                    colors: colors,
                    icon: module.icon,
                    label: module.title,
                    selected: module.route != null &&
                        module.route == selectedRoute,
                    onTap: module.route == null
                        ? null
                        : () {
                            onNavigate?.call();
                            if (module.route == selectedRoute) return;
                            AppRouter.open(context, module.route!);
                          },
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
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
              Icon(icon, size: 20, color: selected ? colors.onSelected : colors.accent),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.wide,
    required this.name,
    required this.search,
    required this.onSearch,
    required this.onMenu,
  });

  final DashboardColors colors;
  final bool wide;
  final String name;
  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPop = Navigator.of(context).canPop();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 20 : 8, 10, wide ? 20 : 8, 10),
        child: Row(
          children: [
            if (!wide) ...[
              IconButton(
                tooltip: l10n.dashboard,
                onPressed: onMenu,
                icon: Icon(Icons.menu, color: colors.accent),
              ),
              ClipOval(
                child: Image.asset(
                  AppAssets.logo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.appName,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (canPop)
              IconButton(
                tooltip: l10n.back,
                onPressed: () => AppRouter.popIfPossible(context),
                icon: Icon(Icons.arrow_back, color: colors.accent),
              ),
            Expanded(
              flex: 3,
              child: TextField(
                controller: search,
                onChanged: (_) => onSearch(),
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.field,
                  hintText: l10n.line('socialSearchHint'),
                  hintStyle: TextStyle(color: colors.muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: colors.accent, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.accent, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const ThemeToggle(),
            const SizedBox(width: 8),
            const LanguageSelector(),
            if (wide && name.isNotEmpty) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.colors, required this.module});

  final DashboardColors colors;
  final _Module module;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: module.route == null
            ? null
            : () => AppRouter.open(context, module.route!),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(module.icon, color: colors.accent),
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
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.subtitle ?? l10n.comingLater,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 13),
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

class _Module {
  const _Module(this.icon, this.title, {this.subtitle, this.route});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
}
