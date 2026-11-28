import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../../core/utils/person_name.dart';
import '../../admin/admin_access.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../widgets/dashboard_colors.dart';
import '../widgets/dashboard_sidebar.dart';

class DashboardPlaceholderScreen extends StatefulWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  State<DashboardPlaceholderScreen> createState() =>
      _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState
    extends State<DashboardPlaceholderScreen> {
  final _search = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    AdminAccess.instance.addListener(_onAdmin);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AdminAccess.instance.reload();
    });
  }

  @override
  void dispose() {
    AdminAccess.instance.removeListener(_onAdmin);
    _search.dispose();
    super.dispose();
  }

  void _onAdmin() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = DashboardColors.of(context);
    final draft = OnboardingScope.of(context).draft;
    final name = formatPersonName(draft.fullName);
    final greeting = name.isEmpty ? l10n.welcomeTitle : l10n.welcomeBack(name);
    final modules = _modules(l10n);
    final query = _search.text.trim().toLowerCase();
    final visible =
        query.isEmpty
            ? modules
            : modules
                .where(
                  (module) =>
                      module.title.toLowerCase().contains(query) ||
                      (module.subtitle ?? '').toLowerCase().contains(query),
                )
                .toList();

    Widget sidebar({VoidCallback? onNavigate}) {
      return DashboardSidebar(
        colors: colors,
        items: [
          for (final module in modules)
            if (module.route != AppRoutes.campaignTemplates) ...[
              if (module.icon == Icons.settings_outlined &&
                  AdminAccess.instance.showInSidebar)
                DashboardNavEntry(
                  icon: Icons.shield_outlined,
                  label: l10n.line('adminPanel'),
                  route: AppRoutes.admin,
                ),
              DashboardNavEntry(
                icon: module.icon,
                label: module.title,
                route: module.route,
              ),
            ],
        ],
        selectedRoute: AppRoutes.dashboard,
        onNavigate: onNavigate,
        footer: _SidebarFooter(
          colors: colors,
          name: name,
          role: draft.designation.trim(),
          photo: draft.photoBytes,
          onStart: () => AppRouter.open(context, AppRoutes.merchandise),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.page,
          drawer:
              wide
                  ? null
                  : Drawer(
                    backgroundColor: colors.sidebar,
                    child: SafeArea(
                      child: sidebar(
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) SizedBox(width: 232, child: sidebar()),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        colors: colors,
                        wide: wide,
                        photo: draft.photoBytes,
                        search: _search,
                        onSearch: () => setState(() {}),
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1160),
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                wide ? 24 : 16,
                                16,
                                wide ? 24 : 16,
                                24,
                              ),
                              children: [
                                _WelcomeBanner(
                                  colors: colors,
                                  greeting: greeting,
                                  subtitle: l10n.dashboardSubtitle,
                                  status: l10n.line('dashCampaignActive'),
                                  photo: draft.photoBytes,
                                ),
                                const SizedBox(height: 16),
                                if (visible.isEmpty)
                                  Text(
                                    l10n.line('socialNoMatches'),
                                    style: TextStyle(color: colors.muted),
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (context, grid) {
                                      final columns =
                                          grid.maxWidth >= 740
                                              ? 3
                                              : grid.maxWidth >= 520
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
                                              mainAxisExtent: 92,
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
                                const SizedBox(height: 16),
                                _Overview(colors: colors, l10n: l10n),
                                const SizedBox(height: 14),
                                _PromoBanner(
                                  colors: colors,
                                  narrow: constraints.maxWidth < 720,
                                  title: l10n.line('dashPromoTitle'),
                                  body: l10n.line('dashPromoBody'),
                                  action: l10n.line('dashStartCampaign'),
                                  onStart:
                                      () => AppRouter.open(
                                        context,
                                        AppRoutes.merchandise,
                                      ),
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
      _Module(
        Icons.person_outline,
        l10n.cardProfile,
        subtitle: l10n.line('dashPortfolioBody'),
        color: const Color(0xFF2563EB),
      ),
      _Module(
        Icons.share_outlined,
        l10n.line('smiNav'),
        subtitle: l10n.line('dashSocialBody'),
        color: const Color(0xFF2563EB),
        route: AppRoutes.socialIntegration,
      ),
      _Module(
        Icons.auto_awesome_outlined,
        l10n.cardContent,
        subtitle: l10n.line('dashContentBody'),
        color: const Color(0xFF7C3AED),
      ),
      _Module(
        Icons.groups_outlined,
        l10n.cardVrm,
        subtitle: l10n.line('dashVotersBody'),
        color: const Color(0xFF2563EB),
        route: AppRoutes.vrmRecords,
      ),
      _Module(
        Icons.group_outlined,
        l10n.cardTeam,
        subtitle: l10n.line('dashTeamBody'),
        color: const Color(0xFF3B82F6),
        route: AppRoutes.team,
      ),
      _Module(
        Icons.calendar_month_outlined,
        l10n.cardMarketplace,
        subtitle: l10n.line('dashCampaignBody'),
        color: const Color(0xFF10B981),
        route: AppRoutes.merchandise,
      ),
      _Module(
        Icons.account_balance_outlined,
        l10n.line('cardAdministrations'),
        subtitle: l10n.line('dashAdminBody'),
        color: const Color(0xFF2563EB),
        route: AppRoutes.administrations,
      ),
      _Module(
        Icons.settings_outlined,
        l10n.cardSettings,
        subtitle: l10n.line('dashSettingsBody'),
        color: const Color(0xFF64748B),
        route: AppRoutes.settings,
      ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.wide,
    required this.photo,
    required this.search,
    required this.onSearch,
    required this.onMenu,
  });

  final DashboardColors colors;
  final bool wide;
  final Uint8List? photo;
  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchField = TextField(
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
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
      ),
    );
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colors.accentSoft,
      backgroundImage: photo == null ? null : MemoryImage(photo!),
      child:
          photo == null
              ? Icon(Icons.person, size: 18, color: colors.accent)
              : null,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 16 : 8, 8, wide ? 16 : 8, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final brand = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Flexible(
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
              ],
            );
            if (wide) {
              return Row(
                children: [
                  Expanded(child: searchField),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                  const SizedBox(width: 8),
                  Icon(Icons.notifications_none, color: colors.accent),
                  const SizedBox(width: 10),
                  avatar,
                ],
              );
            }
            if (!compact) {
              return Row(
                children: [
                  IconButton(
                    tooltip: l10n.dashboard,
                    onPressed: onMenu,
                    icon: Icon(Icons.menu, color: colors.accent),
                  ),
                  Expanded(child: brand),
                  const SizedBox(width: 8),
                  SizedBox(width: 220, child: searchField),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                  const SizedBox(width: 8),
                  avatar,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.dashboard,
                      onPressed: onMenu,
                      icon: Icon(Icons.menu, color: colors.accent),
                    ),
                    Expanded(child: brand),
                    Icon(Icons.notifications_none, color: colors.accent),
                    const SizedBox(width: 8),
                    avatar,
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    const ThemeToggle(),
                    const SizedBox(width: 8),
                    const LanguageSelector(),
                  ],
                ),
              ],
            );
          },
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
    final iconColor =
        colors.isDark
            ? Color.lerp(module.color, Colors.white, 0.35)!
            : module.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: colors.accent.withValues(alpha: 0.07),
        onTap:
            module.route == null
                ? null
                : () => AppRouter.open(context, module.route!),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        module.subtitle ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Module {
  const _Module(
    this.icon,
    this.title, {
    required this.color,
    this.subtitle,
    this.route,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? route;
  final Color color;
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.colors,
    required this.greeting,
    required this.subtitle,
    required this.status,
    required this.photo,
  });

  final DashboardColors colors;
  final String greeting;
  final String subtitle;
  final String status;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                colors.isDark
                    ? [const Color(0xFF12345A), const Color(0xFF0E7490)]
                    : const [
                      Color(0xFFEFF6FF),
                      Color(0xFFE0F2FE),
                      Color(0xFFFFF7ED),
                    ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, wide ? 12 : 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _WelcomeBackButton(colors: colors, compact: !wide),
                        SizedBox(width: wide ? 12 : 10),
                        Expanded(
                          child: Text(
                            greeting,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: wide ? 28 : 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (photo != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    photo!,
                    width: wide ? 120 : 72,
                    height: wide ? 120 : 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBackButton extends StatelessWidget {
  const _WelcomeBackButton({required this.colors, required this.compact});

  final DashboardColors colors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = compact ? 36.0 : 40.0;
    return IconButton(
      key: const Key('dashboard-welcome-back'),
      tooltip: l10n.back,
      onPressed: () => AppRouter.back(context, AppRoutes.ready),
      style: IconButton.styleFrom(
        backgroundColor: colors.accentSoft,
        foregroundColor: colors.accent,
        hoverColor: colors.accent.withValues(alpha: 0.16),
        highlightColor: colors.accent.withValues(alpha: 0.12),
        fixedSize: Size(size, size),
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
      ),
      icon: Icon(
        Icons.arrow_back,
        size: compact ? 18 : 20,
        color: colors.accent,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.colors, required this.l10n});

  final DashboardColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final chartHeight = MediaQuery.sizeOf(context).width < 560 ? 108.0 : 144.0;
    final stats = [
      _Stat(
        l10n.line('dashTotalVoters'),
        '12,500',
        '12%',
        const Color(0xFF2563EB),
      ),
      _Stat(l10n.line('dashEngaged'), '8,200', '15%', const Color(0xFF7C3AED)),
      _Stat(l10n.line('dashReach'), '2.5M', '20%', const Color(0xFF10B981)),
      _Stat(
        l10n.line('dashEngagementRate'),
        '95%',
        '5%',
        const Color(0xFFF97316),
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: colors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.line('dashOverview'),
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.field,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      l10n.line('dashLast30'),
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 4 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: constraints.maxWidth < 280 ? 104 : 88,
                  ),
                  itemBuilder:
                      (context, index) =>
                          _StatTile(colors: colors, stat: stats[index]),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: chartHeight,
              child: CustomPaint(painter: _ReachPainter(colors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.change, this.color);

  final String label;
  final String value;
  final String change;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.colors, required this.stat});

  final DashboardColors colors;
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: colors.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stat.value,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            Text(
              '↑ ${stat.change}',
              style: TextStyle(
                color:
                    colors.isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReachPainter extends CustomPainter {
  const _ReachPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
    final fill =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size);
    const points = [0.72, 0.64, 0.68, 0.52, 0.58, 0.4, 0.46, 0.28];
    final path = Path();
    final shape = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * points[i];
      if (i == 0) {
        path.moveTo(x, y);
        shape.moveTo(x, size.height);
        shape.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        shape.lineTo(x, y);
      }
    }
    shape.lineTo(size.width, size.height);
    shape.close();
    canvas.drawPath(shape, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _ReachPainter || oldDelegate.color != color;
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.colors,
    required this.narrow,
    required this.title,
    required this.body,
    required this.action,
    required this.onStart,
  });

  final DashboardColors colors;
  final bool narrow;
  final String title;
  final String body;
  final String action;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final announcementColor =
        colors.isDark ? colors.accent : const Color(0xFF2563EB);
    final copy = Row(
      children: [
        Icon(Icons.campaign_outlined, color: announcementColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final button = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const StadiumBorder(),
      ),
      onPressed: onStart,
      child: Text(action),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.isDark ? colors.cardAlt : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: colors.isDark ? Border.all(color: colors.border) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child:
            narrow
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: button),
                  ],
                )
                : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 12),
                    button,
                  ],
                ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.colors,
    required this.name,
    required this.role,
    required this.photo,
    required this.onStart,
  });

  final DashboardColors colors;
  final String name;
  final String role;
  final Uint8List? photo;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.isDark ? colors.cardAlt : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: colors.isDark ? Border.all(color: colors.border) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.campaign,
                    color:
                        colors.isDark ? colors.accent : const Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.line('dashGrowTitle'),
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.line('dashGrowBody'),
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onStart,
                    child: Text(l10n.line('dashGetStarted')),
                  ),
                ],
              ),
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.accentSoft,
                  backgroundImage: photo == null ? null : MemoryImage(photo!),
                  child:
                      photo == null
                          ? Icon(Icons.person, size: 16, color: colors.accent)
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (role.isNotEmpty)
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
