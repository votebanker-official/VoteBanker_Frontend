import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import 'about_meta.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    applyAboutMeta();
  }

  @override
  void dispose() {
    restoreAboutMeta();
    super.dispose();
  }

  void _open(String route) => AppNav.open(context, route);

  void _contactSupport() => _open(AppRoutes.contactSupport);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        children: [
          _Header(onLogo: () => _open(AppRoutes.dashboard)),
          _PageBody(
            onExplore: () => _open(AppRoutes.dashboard),
            onContact: _contactSupport,
            onStart: () => _open(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogo});

  final VoidCallback onLogo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final brand = InkWell(
                key: const Key('about-logo'),
                onTap: onLogo,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 36,
                        height: 36,
                        semanticLabel: 'VoteBanker',
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'VoteBanker',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.wordmark(context).copyWith(
                            fontSize: constraints.maxWidth < 560 ? 16 : 22,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              const controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemeToggle(),
                  SizedBox(width: 8),
                  LanguageSelector(),
                ],
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: brand)]),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: controls,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: brand),
                  ),
                  controls,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.onExplore,
    required this.onContact,
    required this.onStart,
  });

  final VoidCallback onExplore;
  final VoidCallback onContact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pad =
            width >= 1100
                ? 48.0
                : width >= 700
                ? 28.0
                : 16.0;
        final columns =
            width >= 1000
                ? 4
                : width >= 700
                ? 2
                : 1;
        final pair = width >= 800;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 28, pad, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(wide: pair, onExplore: onExplore, onContact: onContact),
                  const SizedBox(height: 28),
                  _WhoWeAre(sideBySide: pair),
                  const SizedBox(height: 28),
                  _MissionVision(sideBySide: pair),
                  const SizedBox(height: 28),
                  _Offer(columns: columns),
                  const SizedBox(height: 28),
                  const _Trust(),
                  const SizedBox(height: 28),
                  _Values(columns: columns),
                  const SizedBox(height: 28),
                  _CallToAction(
                    wide: pair,
                    onStart: onStart,
                    onContact: onContact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.wide,
    required this.onExplore,
    required this.onContact,
  });

  final bool wide;
  final VoidCallback onExplore;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final explore = FilledButton.icon(
      key: const Key('about-explore'),
      onPressed: onExplore,
      icon: const Icon(Icons.explore_outlined),
      label: const Text('Explore Features'),
    );
    final contact = OutlinedButton.icon(
      key: const Key('about-contact'),
      onPressed: onContact,
      icon: const Icon(Icons.support_agent_outlined),
      label: const Text('Contact Support'),
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT VOTEBANKER', style: AppTextStyles.descriptor(context)),
          const SizedBox(height: 10),
          Text(
            'About VoteBanker',
            style: AppTextStyles.headline(
              context,
            ).copyWith(fontSize: wide ? 36 : 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Empowering Modern Political Campaigns & Voter Outreach.',
            style: AppTextStyles.sectionTitle(
              context,
            ).copyWith(color: palette.secondary),
          ),
          const SizedBox(height: 14),
          Text(
            'VoteBanker is a Voter Relationship Management (VRM) platform built to help candidates, campaign teams, and grassroots organizers manage voter outreach, coordinate field operations, and build stronger community connections in one centralized workspace.',
            style: AppTextStyles.body(context),
          ),
          const SizedBox(height: 20),
          if (wide)
            Wrap(spacing: 12, runSpacing: 12, children: [explore, contact])
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [explore, const SizedBox(height: 10), contact],
            ),
        ],
      ),
    );
  }
}

class _WhoWeAre extends StatelessWidget {
  const _WhoWeAre({required this.sideBySide});

  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final problem = const _InfoCard(
      icon: Icons.scatter_plot_outlined,
      title: 'The problem',
      body:
          'Campaigns often juggle voter spreadsheets, disconnected messaging tools, and ground teams that cannot see the same plan. Updates get lost, lists drift out of date, and coordinators spend the day reconciling work instead of meeting people.',
    );
    final answer = const _InfoCard(
      icon: Icons.account_tree_outlined,
      title: 'Why VoteBanker exists',
      body:
          'VoteBanker brings those moving parts into one organized digital workflow. Voter records, campaign pages, field teams, and outreach materials stay in a single workspace so everyone works from the same picture.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who we are', style: AppTextStyles.sectionTitle(context)),
        const SizedBox(height: 6),
        Text(
          'A practical workspace for candidates and the people who organize with them.',
          style: AppTextStyles.body(context),
        ),
        const SizedBox(height: 14),
        if (sideBySide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: problem),
                const SizedBox(width: 16),
                Expanded(child: answer),
              ],
            ),
          )
        else
          Column(children: [problem, const SizedBox(height: 12), answer]),
      ],
    );
  }
}

class _MissionVision extends StatelessWidget {
  const _MissionVision({required this.sideBySide});

  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final mission = const _InfoCard(
      icon: Icons.flag_outlined,
      eyebrow: 'Our Mission',
      title: 'Tools for transparent engagement',
      body:
          'To equip candidates, campaign managers, and grassroots teams with accessible, well-organized digital tools for transparent and effective voter engagement.',
    );
    final vision = const _InfoCard(
      icon: Icons.visibility_outlined,
      eyebrow: 'Our Vision',
      title: 'Modern, accountable outreach',
      body:
          'To modernize campaign operations through reliable technology that strengthens community connection and accountable outreach.',
    );
    if (!sideBySide) {
      return Column(children: [mission, const SizedBox(height: 12), vision]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: mission),
          const SizedBox(width: 16),
          Expanded(child: vision),
        ],
      ),
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    const modules = <_Module>[
      _Module(
        icon: Icons.groups_outlined,
        title: 'Voter Relationship Management (VRM)',
        body:
            'Organize voter records, segment lists, and track outreach cleanly.',
        route: AppRoutes.vrmRecords,
      ),
      _Module(
        icon: Icons.web_outlined,
        title: 'Website Builder',
        body:
            'Launch mobile-friendly campaign websites quickly to share updates and initiatives.',
        route: AppRoutes.website,
      ),
      _Module(
        icon: Icons.badge_outlined,
        title: 'Team & Volunteer Coordination',
        body:
            'Assign tasks, manage booth and area coordinators, and align field teams.',
        route: AppRoutes.team,
      ),
      _Module(
        icon: Icons.storefront_outlined,
        title: 'Merchandise',
        body:
            'Manage branded campaign materials and outreach essentials in one place.',
        route: AppRoutes.merchandise,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What we offer', style: AppTextStyles.sectionTitle(context)),
        const SizedBox(height: 6),
        Text(
          'Platform modules that are already available in VoteBanker.',
          style: AppTextStyles.body(context),
        ),
        const SizedBox(height: 14),
        _Grid(
          columns: columns,
          children: [for (final module in modules) _ModuleCard(module: module)],
        ),
      ],
    );
  }
}

class _Module {
  const _Module({
    required this.icon,
    required this.title,
    required this.body,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final String route;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _Module module;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(module.icon, color: palette.accent, size: 26),
                const SizedBox(height: 12),
                Text(
                  module.title,
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(module.body, style: AppTextStyles.body(context)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _ModuleOpenButton(route: module.route),
          ),
        ],
      ),
    );
  }
}

class _ModuleOpenButton extends StatelessWidget {
  const _ModuleOpenButton({required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton.icon(
      key: Key('about-module-$route'),
      onPressed: () => AppNav.open(context, route),
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        iconSize: 16,
      ),
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: const Text('Open'),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data responsibility',
            style: AppTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 8),
          Text(
            'VoteBanker workspaces use role-based access so candidates, managers, and field staff see only the records their role needs. We treat campaign data as confidential and expect teams to collect and use it for legitimate outreach.',
            style: AppTextStyles.body(context),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.secondary.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: palette.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VoteBanker is an independent campaign software platform and is not affiliated with, endorsed by, or part of any government body or election commission.',
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Values extends StatelessWidget {
  const _Values({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    const values = <({IconData icon, String title, String body})>[
      (
        icon: Icons.lightbulb_outline,
        title: 'Clarity',
        body: 'Intuitive tools field teams can adopt quickly.',
      ),
      (
        icon: Icons.verified_outlined,
        title: 'Reliability',
        body: 'Dependable performance during fast-paced campaign schedules.',
      ),
      (
        icon: Icons.lock_outline,
        title: 'Security & Privacy',
        body:
            'Respecting campaign confidentiality and responsible record handling.',
      ),
      (
        icon: Icons.accessibility_new_outlined,
        title: 'Accessibility',
        body:
            'Practical, scalable software for local and large-scale teams alike.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Core values', style: AppTextStyles.sectionTitle(context)),
        const SizedBox(height: 14),
        _Grid(
          columns: columns,
          children: [
            for (final value in values)
              _InfoCard(icon: value.icon, title: value.title, body: value.body),
          ],
        ),
      ],
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction({
    required this.wide,
    required this.onStart,
    required this.onContact,
  });

  final bool wide;
  final VoidCallback onStart;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final start = FilledButton.icon(
      key: const Key('about-start'),
      onPressed: onStart,
      icon: const Icon(Icons.rocket_launch_outlined),
      label: const Text('Get Started'),
    );
    final contact = OutlinedButton.icon(
      onPressed: onContact,
      icon: const Icon(Icons.support_agent_outlined),
      label: const Text('Contact Support'),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Column(
          children: [
            Text(
              'Ready to Organize Your Campaign?',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover how VoteBanker streamlines voter outreach and campaign coordination.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 18),
            if (wide)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [start, contact],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [start, const SizedBox(height: 10), contact],
              ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final end = i + columns > children.length ? children.length : i + columns;
      final slice = children.sublist(i, end);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: j < slice.length ? slice[j] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.eyebrow,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.accent),
          if (eyebrow != null) ...[
            const SizedBox(height: 10),
            Text(eyebrow!, style: AppTextStyles.descriptor(context)),
          ],
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.sectionTitle(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.body(context)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(child: child);
  }
}
