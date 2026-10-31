import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../dashboard/widgets/dashboard_colors.dart';
import '../models/team_member.dart';
import '../services/team_service.dart';

const _blue = Color(0xFF0866E8);
const _roles = [
  'Campaign Manager',
  'Coordinator',
  'Field Lead',
  'Content Manager',
  'Data Analyst',
  'Member',
];
const _permissions = [
  'View dashboard',
  'Manage voters',
  'Manage volunteers',
  'Manage content',
  'Manage events',
  'Full access',
];

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key, this.repository, this.initialMembers});

  final TeamRepository? repository;
  final List<TeamMember>? initialMembers;

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _search = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TeamRepository _repository;
  List<TeamMember> _members = const [];
  var _loading = true;
  var _loaded = false;
  var _statusFilter = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TeamService();
    if (widget.initialMembers != null) {
      _members = [...widget.initialMembers!];
      _loading = false;
      _loaded = true;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TeamStats get _stats => TeamStats.fromMembers(_members);

  List<TeamMember> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _members.where((member) {
      if (_statusFilter.isNotEmpty && member.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      final blob = [
        member.fullName,
        member.mobile,
        member.email,
        member.designation,
        member.role,
        member.location,
      ].join(' ').toLowerCase();
      return blob.contains(query);
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _repository.list();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
        _loaded = true;
        _error = null;
      });
    } on TeamException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'request_failed';
      });
    }
  }

  Future<void> _openForm({TeamMember? existing}) async {
    var saved = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MemberDialog(
        existing: existing,
        onSubmit: (draft) async {
          if (existing == null) {
            await _repository.create(draft.toJson());
          } else {
            await _repository.update(existing.id, draft.toJson());
          }
          final members = await _repository.list();
          if (!mounted) return;
          setState(() {
            _members = members;
            _loaded = true;
            _error = null;
          });
          saved = true;
        },
      ),
    );
    if (saved && mounted) {
      _showMessage(existing == null ? 'Team member added.' : 'Team member updated.');
    }
  }

  Future<void> _view(TeamMember member) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _MemberDetails(member: member),
    );
  }

  Future<void> _delete(TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team member'),
        content: Text('Remove ${member.fullName} from your team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.delete(member.id);
      if (!mounted) return;
      setState(() {
        _members = _members.where((row) => row.id != member.id).toList();
      });
    } on TeamException catch (error) {
      _showMessage(_errorText(error.code));
    } catch (_) {
      _showMessage('Could not delete that team member.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(String code) {
    switch (code) {
      case 'unauthorized':
        return 'Sign in to manage your team.';
      case 'duplicate_mobile':
        return 'A team member with this mobile number already exists.';
      case 'invalid_phone':
        return 'Enter a valid mobile number.';
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'unreachable':
        return 'Could not reach the team service. Please try again.';
      case 'team_members_not_ready':
        return 'Team storage is not ready yet.';
      case 'not_found':
        return 'The team service is not available on the API server yet.';
      case 'load_failed':
      case 'save_failed':
        return 'The team database rejected the request. Please try again.';
      default:
        return 'Could not update team members. Please try again.';
    }
  }

  void _goBack() => AppRouter.back(context, AppRoutes.dashboard);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = DashboardColors.of(context);
    final items = _navItems(l10n);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.isDark ? colors.page : const Color(0xFFF3F8FD),
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: colors.sidebar,
                  child: SafeArea(
                    child: _Sidebar(
                      colors: colors,
                      items: items,
                      onNavigate: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
          body: SafeArea(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: colors.isDark
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8FBFE), Color(0xFFEAF3FB)],
                      ),
              ),
              child: Row(
                children: [
                  if (wide)
                    SizedBox(
                      width: 248,
                      child: _Sidebar(colors: colors, items: items),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          colors: colors,
                          wide: wide,
                          search: _search,
                          onSearch: () => setState(() {}),
                          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                          onBack: _goBack,
                        ),
                        Expanded(child: _body(colors, wide)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(DashboardColors colors, bool wide) {
    final stats = _stats;
    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 22, wide ? 28 : 16, 28),
      children: [
        _Header(wide: wide, colors: colors, onAdd: () => _openForm(), onBack: _goBack),
        const SizedBox(height: 18),
        _StatGrid(colors: colors, stats: stats, unavailable: _error != null && !_loaded),
        const SizedBox(height: 16),
        if (_members.isNotEmpty) ...[
          _FilterRow(
            colors: colors,
            value: _statusFilter,
            onChanged: (value) => setState(() => _statusFilter = value),
          ),
          const SizedBox(height: 12),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator(color: _blue)),
          )
        else if (_error != null && _members.isEmpty)
          _MessageCard(
            colors: colors,
            title: 'Could not load team members',
            body: _errorText(_error!),
            action: 'Retry',
            onPressed: _load,
          )
        else if (_members.isEmpty)
          _EmptyState(colors: colors, onAdd: () => _openForm())
        else
          _MemberTable(
            colors: colors,
            members: _visible,
            onView: _view,
            onEdit: (member) => _openForm(existing: member),
            onDelete: _delete,
          ),
      ],
    );
  }
}

List<_NavItem> _navItems(AppLocalizations l10n) {
  return [
    _NavItem(Icons.space_dashboard_outlined, l10n.dashboard, AppRoutes.dashboard),
    _NavItem(Icons.person_outline, l10n.cardProfile, null),
    _NavItem(Icons.groups_outlined, l10n.cardSocial, AppRoutes.socialContacts),
    _NavItem(Icons.share_outlined, l10n.line('smiNav'), AppRoutes.socialIntegration),
    _NavItem(Icons.auto_awesome_outlined, l10n.cardContent, null),
    _NavItem(Icons.groups_outlined, l10n.cardVolunteers, AppRoutes.volunteers),
    _NavItem(Icons.person_outline, l10n.cardTeam, AppRoutes.team),
    _NavItem(Icons.storefront_outlined, l10n.cardMarketplace, AppRoutes.merchandise),
    _NavItem(Icons.account_balance_outlined, l10n.line('cardAdministrations'), AppRoutes.administrations),
    _NavItem(Icons.settings_outlined, l10n.cardSettings, null),
  ];
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String? route;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.colors, required this.items, this.onNavigate});

  final DashboardColors colors;
  final List<_NavItem> items;
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
                  child: Image.asset(AppAssets.logo, width: 36, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [
                for (final item in items) ...[
                  _NavTile(
                    colors: colors,
                    item: item,
                    selected: item.route == AppRoutes.team,
                    onTap: item.route == null || item.route == AppRoutes.team
                        ? null
                        : () {
                            onNavigate?.call();
                            if (item.route == AppRoutes.dashboard) {
                              AppRouter.replace(context, AppRoutes.dashboard);
                            } else {
                              AppRouter.open(context, item.route!);
                            }
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
    required this.item,
    required this.selected,
    this.onTap,
  });

  final DashboardColors colors;
  final _NavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : colors.text;
    return Material(
      color: selected ? _blue : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: selected ? Colors.white : _blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
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
    required this.search,
    required this.onSearch,
    required this.onMenu,
    required this.onBack,
  });

  final DashboardColors colors;
  final bool wide;
  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onMenu;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar.withValues(alpha: colors.isDark ? 1 : 0.92),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 16 : 8, 10, wide ? 16 : 8, 10),
        child: Row(
          children: [
            if (!wide)
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu, color: _blue),
              ),
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: _blue),
            ),
            Expanded(
              child: TextField(
                key: const Key('team-search'),
                controller: search,
                onChanged: (_) => onSearch(),
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.field,
                  hintText: 'Search by name, mobile number or designation...',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: _blue, size: 20),
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
                    borderSide: const BorderSide(color: _blue, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const ThemeToggle(),
            const SizedBox(width: 8),
            const LanguageSelector(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.wide,
    required this.colors,
    required this.onAdd,
    required this.onBack,
  });

  final bool wide;
  final DashboardColors colors;
  final VoidCallback onAdd;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back, color: _blue),
            ),
            Expanded(
              child: Text(
                'My Team',
                style: TextStyle(
                  color: colors.text,
                  fontSize: wide ? 28 : 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            'Manage your team members, assign roles, and track their progress.',
            style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
    final button = _AddButton(key: const Key('add-team-member'), onPressed: onAdd);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 12),
          button,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        button,
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.colors, required this.stats, required this.unavailable});

  final DashboardColors colors;
  final TeamStats stats;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        key: const Key('team-stat-total'),
        icon: Icons.groups_outlined,
        color: _blue,
        value: stats.total,
        unavailable: unavailable,
        title: 'Total Members',
        body: 'All registered team members',
      ),
      _StatData(
        key: const Key('team-stat-active'),
        icon: Icons.person_outline,
        color: const Color(0xFF16A34A),
        value: stats.active,
        unavailable: unavailable,
        title: 'Active Members',
        body: 'Currently working',
      ),
      _StatData(
        key: const Key('team-stat-pending'),
        icon: Icons.schedule,
        color: const Color(0xFFF59E0B),
        value: stats.pending,
        unavailable: unavailable,
        title: 'Pending Invitations',
        body: 'Waiting to join',
      ),
      _StatData(
        key: const Key('team-stat-inactive'),
        icon: Icons.person_off_outlined,
        color: const Color(0xFFEF4444),
        value: stats.inactive,
        unavailable: unavailable,
        title: 'Inactive Members',
        body: 'Not currently active',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 108,
          ),
          itemBuilder: (context, index) => _StatCard(colors: colors, data: cards[index]),
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.unavailable,
    required this.title,
    required this.body,
  });

  final Key key;
  final IconData icon;
  final Color color;
  final int value;
  final bool unavailable;
  final String title;
  final String body;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.colors, required this.data});

  final DashboardColors colors;
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.unavailable ? '—' : '${data.value}',
                    key: data.key,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    data.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors, required this.onAdd});

  final DashboardColors colors;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          children: [
            const _EmptyArt(),
            const SizedBox(height: 18),
            Text(
              'No Team Members Found',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                "You haven't added any team members yet. Click the button above to add your first team member.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 14, height: 1.45),
              ),
            ),
            const SizedBox(height: 18),
            _AddButton(key: const Key('add-team-member-empty'), onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _EmptyArt extends StatelessWidget {
  const _EmptyArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 8, left: 18, child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFF93C5FD))),
          const Positioned(top: 16, right: 16, child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFFBFDBFE))),
          const Positioned(bottom: 18, left: 12, child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFBFDBFE))),
          Container(
            width: 92,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(Icons.groups, color: _blue, size: 42),
          ),
          const Positioned(
            right: 22,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(color: _blue, shape: BoxShape.circle),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.colors, required this.value, required this.onChanged});

  final DashboardColors colors;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Team members', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
        const Spacer(),
        DecoratedBox(
          decoration: _cardDecoration(colors),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (next) => onChanged(next ?? ''),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTable extends StatelessWidget {
  const _MemberTable({
    required this.colors,
    required this.members,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final DashboardColors colors;
  final List<TeamMember> members;
  final ValueChanged<TeamMember> onView;
  final ValueChanged<TeamMember> onEdit;
  final ValueChanged<TeamMember> onDelete;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _MessageCard(
        colors: colors,
        title: 'No matching team members',
        body: 'Try a different name, mobile number, designation, or status.',
      );
    }
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 860) {
            return Column(
              children: [
                for (final member in members)
                  _MemberCard(
                    colors: colors,
                    member: member,
                    onView: () => onView(member),
                    onEdit: () => onEdit(member),
                    onDelete: () => onDelete(member),
                  ),
              ],
            );
          }
          return Column(
            children: [
              _MemberRow(
                colors: colors,
                heading: true,
                cells: const [
                  'Profile',
                  'Name',
                  'Mobile',
                  'Email',
                  'Designation',
                  'Role',
                  'Location',
                  'Status',
                  'Actions',
                ],
              ),
              for (final member in members)
                _MemberRow(
                  colors: colors,
                  member: member,
                  onView: () => onView(member),
                  onEdit: () => onEdit(member),
                  onDelete: () => onDelete(member),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.colors,
    this.heading = false,
    this.cells = const [],
    this.member,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final DashboardColors colors;
  final bool heading;
  final List<String> cells;
  final TeamMember? member;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: heading ? colors.muted : colors.text,
      fontWeight: heading ? FontWeight.w700 : FontWeight.w600,
      fontSize: heading ? 12 : 13,
    );
    Widget cell(String text, {bool strong = false}) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: strong ? style.copyWith(fontWeight: FontWeight.w800) : style,
      );
    }

    final person = member;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: [
          SizedBox(width: 52, child: heading ? cell(cells[0]) : _Avatar(name: person!.fullName)),
          Expanded(flex: 3, child: cell(heading ? cells[1] : person!.fullName, strong: !heading)),
          Expanded(flex: 3, child: cell(heading ? cells[2] : person!.mobile)),
          Expanded(flex: 4, child: cell(heading ? cells[3] : (person!.email.isEmpty ? '—' : person.email))),
          Expanded(flex: 3, child: cell(heading ? cells[4] : (person!.designation.isEmpty ? '—' : person.designation))),
          Expanded(flex: 3, child: cell(heading ? cells[5] : person!.role)),
          Expanded(flex: 3, child: cell(heading ? cells[6] : (person!.location.isEmpty ? '—' : person.location))),
          SizedBox(width: 92, child: heading ? cell(cells[7]) : _StatusChip(status: person!.status)),
          SizedBox(
            width: 132,
            child: heading
                ? cell(cells[8])
                : _Actions(onView: onView!, onEdit: onEdit!, onDelete: onDelete!),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.colors,
    required this.member,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final DashboardColors colors;
  final TeamMember member;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: member.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${member.mobile} · ${member.role}', style: TextStyle(color: colors.muted, fontSize: 13)),
                if (member.designation.isNotEmpty || member.location.isNotEmpty)
                  Text(
                    [member.designation, member.location].where((part) => part.isNotEmpty).join(' · '),
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                const SizedBox(height: 8),
                _StatusChip(status: member.status),
              ],
            ),
          ),
          _Actions(onView: onView, onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts.first.substring(0, 1).toUpperCase()
            : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE8F2FF),
      child: Text(initials, style: const TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => const Color(0xFF16A34A),
      'inactive' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
    final label = switch (status) {
      'active' => 'Active',
      'inactive' => 'Inactive',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onView, required this.onEdit, required this.onDelete});

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          visualDensity: VisualDensity.compact,
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined, color: _blue, size: 20),
        ),
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: _blue, size: 20),
        ),
        IconButton(
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.colors,
    required this.title,
    required this.body,
    this.action,
    this.onPressed,
  });

  final DashboardColors colors;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: TextStyle(color: colors.muted)),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(style: FilledButton.styleFrom(backgroundColor: _blue), onPressed: onPressed, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog({this.existing, required this.onSubmit});

  final TeamMember? existing;
  final Future<void> Function(_MemberDraft draft) onSubmit;

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _designation;
  late final TextEditingController _location;
  String? _role;
  String _status = 'pending';
  final _selectedPermissions = <String>{};
  String? _error;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.fullName ?? '');
    _mobile = TextEditingController(text: existing?.mobile ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _designation = TextEditingController(text: existing?.designation ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _role = existing?.role;
    _status = existing?.status ?? 'pending';
    _selectedPermissions.addAll(existing?.permissions ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _designation.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the full name.');
      return;
    }
    if (!RegExp(r'^\+?[0-9][0-9\s-]{6,18}$').hasMatch(mobile)) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_role == null) {
      setState(() => _error = 'Assign a role.');
      return;
    }
    final draft = _MemberDraft(
      fullName: name,
      mobile: mobile,
      email: email,
      designation: _designation.text.trim(),
      location: _location.text.trim(),
      role: _role!,
      permissions: _selectedPermissions.toList(),
      status: widget.existing == null ? null : _status,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(draft);
      if (mounted) Navigator.pop(context);
    } on TeamException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _dialogError(error.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save that team member. Please try again.';
      });
    }
  }

  String _dialogError(String code) {
    switch (code) {
      case 'unauthorized':
        return 'Sign in to manage your team.';
      case 'duplicate_mobile':
        return 'A team member with this mobile number already exists.';
      case 'invalid_phone':
        return 'Enter a valid mobile number.';
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'not_found':
        return 'The team service is not available on the API server yet.';
      case 'unreachable':
        return 'Could not reach the team service. Please try again.';
      default:
        return 'Could not save that team member. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing ? 'Edit Team Member' : 'Add Team Member',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _field(_name, 'Full Name', key: const Key('team-name')),
              _field(_mobile, 'Mobile Number', key: const Key('team-mobile'), keyboard: TextInputType.phone),
              _field(_email, 'Email Address', key: const Key('team-email'), keyboard: TextInputType.emailAddress),
              _field(_designation, 'Designation', key: const Key('team-designation')),
              _field(_location, 'Location', key: const Key('team-location')),
              _dropdown(
                label: 'Assign Role',
                fieldKey: const Key('team-role'),
                value: _role,
                items: _roles,
                onChanged: (value) => setState(() => _role = value),
              ),
              if (editing)
                _dropdown(
                  label: 'Status',
                  fieldKey: const Key('team-status'),
                  value: _status,
                  items: const ['pending', 'active', 'inactive'],
                  itemLabel: (value) => value[0].toUpperCase() + value.substring(1),
                  onChanged: (value) => setState(() => _status = value ?? 'pending'),
                ),
              const SizedBox(height: 14),
              const Text('Access Permissions', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final permission in _permissions)
                    FilterChip(
                      label: Text(permission),
                      selected: _selectedPermissions.contains(permission),
                      selectedColor: const Color(0xFFDCEBFF),
                      checkmarkColor: _blue,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPermissions.add(permission);
                          } else {
                            _selectedPermissions.remove(permission);
                          }
                        });
                      },
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const Key('team-send'),
                    style: FilledButton.styleFrom(backgroundColor: _blue),
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Saving…' : (editing ? 'Save' : 'Send Invitation')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2)),
          const SizedBox(height: 6),
          TextField(
            key: key,
            controller: controller,
            keyboardType: keyboard,
            enabled: !_saving,
            style: const TextStyle(fontSize: 15, height: 1.3),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required Key fieldKey,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? itemLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: fieldKey,
            value: value,
            isExpanded: true,
            decoration: _inputDecoration(),
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  child: Text(itemLabel == null ? item : itemLabel(item)),
                ),
            ],
            onChanged: _saving ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _MemberDetails extends StatelessWidget {
  const _MemberDetails({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final rows = [
      'Mobile',
      member.mobile,
      'Email',
      member.email.isEmpty ? '—' : member.email,
      'Designation',
      member.designation.isEmpty ? '—' : member.designation,
      'Location',
      member.location.isEmpty ? '—' : member.location,
      'Role',
      member.role,
      'Status',
      member.status,
      'Permissions',
      member.permissions.isEmpty ? '—' : member.permissions.join(', '),
    ];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (var i = 0; i < rows.length; i += 2) ...[
                Text(rows[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                Text(rows[i + 1]),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberDraft {
  const _MemberDraft({
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.designation,
    required this.location,
    required this.role,
    required this.permissions,
    this.status,
  });

  final String fullName;
  final String mobile;
  final String email;
  final String designation;
  final String location;
  final String role;
  final List<String> permissions;
  final String? status;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'designation': designation,
      'location': location,
      'role': role,
      'permissions': permissions,
      if (status != null) 'status': status,
    };
  }
}

InputDecoration _inputDecoration() {
  return const InputDecoration(
    isDense: false,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD7E6F5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: _blue, width: 1.4),
    ),
  );
}

BoxDecoration _cardDecoration(DashboardColors colors) {
  return BoxDecoration(
    color: colors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.isDark ? colors.border : const Color(0xFFD7E6F5)),
    boxShadow: [
      BoxShadow(
        color: colors.shadow,
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
