import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../widgets/dashboard_colors.dart';
import '../widgets/dashboard_sidebar.dart';

class AdministrationsScreen extends StatefulWidget {
  const AdministrationsScreen({super.key});

  @override
  State<AdministrationsScreen> createState() => _AdministrationsScreenState();
}

class _AdministrationsScreenState extends State<AdministrationsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final modules = <_AdminModule>[
      _AdminModule(
        icon: Icons.groups_outlined,
        title: l10n.line('speechCard'),
        subtitle: l10n.line('speechCardBody'),
        color: const Color(0xFF2563EB),
        route: AppRoutes.speech,
      ),
      _AdminModule(
        icon: Icons.mail_outline,
        title: l10n.line('letterCard'),
        subtitle: l10n.line('letterCardBody'),
        color: const Color(0xFF7C3AED),
        route: AppRoutes.letter,
      ),
      _AdminModule(
        icon: Icons.calendar_month_outlined,
        title: l10n.cardEvents,
        color: const Color(0xFF10B981),
      ),
      _AdminModule(
        icon: Icons.bar_chart_rounded,
        title: l10n.cardCampaign,
        color: const Color(0xFFF97316),
      ),
      _AdminModule(
        icon: Icons.show_chart_rounded,
        title: l10n.cardAnalytics,
        color: const Color(0xFF2563EB),
      ),
      _AdminModule(
        icon: Icons.description_outlined,
        title: l10n.cardIssues,
        color: const Color(0xFF10B981),
      ),
      _AdminModule(
        icon: Icons.credit_card_outlined,
        title: l10n.cardBilling,
        color: const Color(0xFF7C3AED),
      ),
    ];

    final pageColor =
        palette.isDark ? palette.background : const Color(0xFFF5F8FC);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 960;
        final colors = DashboardColors.of(context);
        final sidebar = DashboardSidebar(
          colors: colors,
          items: dashboardSidebarItems(l10n),
          selectedRoute: AppRoutes.administrations,
        );
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: pageColor,
          drawer:
              showSidebar
                  ? null
                  : Drawer(
                    backgroundColor: colors.sidebar,
                    child: SafeArea(
                      child: DashboardSidebar(
                        colors: colors,
                        items: dashboardSidebarItems(l10n),
                        selectedRoute: AppRoutes.administrations,
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
          body: SafeArea(
            child: Row(
              children: [
                if (showSidebar) SizedBox(width: 248, child: sidebar),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdminTopBar(
                        showBrand: !showSidebar,
                        onMenu:
                            showSidebar
                                ? null
                                : () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final gutter = wide ? 28.0 : 16.0;
                            return ListView(
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                8,
                                gutter,
                                28,
                              ),
                              children: [
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1200,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _AdminHero(
                                          title: l10n.line(
                                            'cardAdministrations',
                                          ),
                                          subtitle: l10n.line(
                                            'administrationsSubtitle',
                                          ),
                                          backLabel: l10n.line(
                                            'backToDashboard',
                                          ),
                                          onBack:
                                              () => AppRouter.back(
                                                context,
                                                AppRoutes.dashboard,
                                              ),
                                        ),
                                        const SizedBox(height: 18),
                                        _AdminGrid(
                                          modules: modules,
                                          laterLabel: l10n.comingLater,
                                        ),
                                        const SizedBox(height: 16),
                                        _HelpCard(
                                          title: l10n.line('adminNeedHelp'),
                                          body: l10n.line('adminNeedHelpBody'),
                                          action: l10n.line('adminGetSupport'),
                                          compact: !wide,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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

class _AdminModule {
  const _AdminModule({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.route,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final String? route;
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.showBrand, this.onMenu});

  final bool showBrand;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(
          children: [
            if (onMenu != null)
              IconButton(
                tooltip: l10n.line('cardAdministrations'),
                onPressed: onMenu,
                icon: Icon(Icons.menu, color: titleColor),
              ),
            if (showBrand) ...[
              ClipOval(
                child: Image.asset(
                  AppAssets.logo,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: narrow ? 14 : 15,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            const ThemeToggle(),
            const SizedBox(width: 8),
            const LanguageSelector(),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  palette.isDark
                      ? palette.surfaceHighlight
                      : const Color(0xFFD7E6F5),
              child: Icon(Icons.person, size: 18, color: titleColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors:
                    palette.isDark
                        ? [palette.surface, palette.backgroundRaised]
                        : const [Color(0xFFF7FBFF), Color(0xFFE7F6F1)],
              ),
            ),
            child: Stack(
              children: [
                if (wide)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 360,
                    child: _HeroArt(isDark: palette.isDark),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 22 : 12,
                    12,
                    wide ? 280 : 12,
                    wide ? 20 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: muted,
                          backgroundColor:
                              palette.isDark
                                  ? palette.surfaceHighlight
                                  : Colors.white.withValues(alpha: 0.72),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                        label: Text(backLabel),
                      ),
                      SizedBox(height: wide ? 16 : 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.settings,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: wide ? 34 : 26,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: wide ? 15 : 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fade = isDark ? const Color(0xFF0F1D2D) : const Color(0xFFF7FBFF);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/profile/leader-profile-hero.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                fade,
                fade.withValues(alpha: 0.8),
                fade.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminGrid extends StatelessWidget {
  const _AdminGrid({required this.modules, required this.laterLabel});

  final List<_AdminModule> modules;
  final String laterLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: columns == 1 ? 84 : 92,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];
            return _AdminToolCard(
              module: module,
              description: module.subtitle ?? laterLabel,
              onTap:
                  module.route == null
                      ? null
                      : () => AppRouter.open(context, module.route!),
            );
          },
        );
      },
    );
  }
}

class _AdminToolCard extends StatefulWidget {
  const _AdminToolCard({
    required this.module,
    required this.description,
    required this.onTap,
  });

  final _AdminModule module;
  final String description;
  final VoidCallback? onTap;

  @override
  State<_AdminToolCard> createState() => _AdminToolCardState();
}

class _AdminToolCardState extends State<_AdminToolCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                _hover
                    ? widget.module.color.withValues(alpha: 0.35)
                    : const Color(0xFFE2EAF4),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  palette.isDark ? palette.cardShadow : const Color(0x12102A56),
              blurRadius: _hover ? 18 : 12,
              offset: Offset(0, _hover ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.module.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        widget.module.icon,
                        color: widget.module.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          palette.isDark
                              ? palette.surfaceHighlight
                              : const Color(0xFFF4F7FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.title,
    required this.body,
    required this.action,
    required this.compact,
  });

  final String title;
  final String body;
  final String action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    final copy = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(color: muted, fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
    // No support destination exists yet, so this stays visible and does not navigate.
    final button = TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        backgroundColor:
            palette.isDark ? palette.surfaceHighlight : Colors.white,
        disabledForegroundColor: const Color(0xFF2563EB),
        disabledBackgroundColor:
            palette.isDark ? palette.surfaceHighlight : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const StadiumBorder(),
        side: const BorderSide(color: Color(0xFFD6E4F5)),
      ),
      onPressed: null,
      icon: const Icon(Icons.headset_mic_outlined, size: 16),
      label: Text(action),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surface : const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.isDark ? palette.border : const Color(0xFFE2EAF4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child:
            compact
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
