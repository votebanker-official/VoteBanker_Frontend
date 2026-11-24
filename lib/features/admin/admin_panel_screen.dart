import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../dashboard/widgets/dashboard_colors.dart';
import '../dashboard/widgets/dashboard_sidebar.dart';
import 'admin_csv.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

enum AdminSection {
  overview,
  clients,
  profiles,
  voterLists,
  blueTik,
  activity,
  purchases,
  payments,
  campaigns,
  users,
  reports,
  audit,
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  AdminSection _section = AdminSection.overview;
  String _range = 'month';
  String _status = '';
  String _paymentStatus = '';
  int _page = 1;
  var _loading = true;
  var _denied = false;
  var _notReady = false;
  String? _error;
  Map<String, dynamic> _data = {};
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _denied = false;
      _notReady = false;
    });
    try {
      await AdminService.instance.getJson('/api/admin/me');
      final data = await AdminService.instance.getJson(_path());
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on AdminApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _denied = err.forbidden;
        _notReady = err.notReady;
        _error =
            err.forbidden || err.notReady
                ? null
                : 'The admin data could not be loaded.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The admin data could not be loaded.';
      });
    }
  }

  String _path() {
    final query = adminQuery({
      'range': _range,
      'q': _search.text,
      'status': _status,
      'paymentStatus': _paymentStatus,
      'page': '$_page',
      'pageSize': '20',
      'kind': _section == AdminSection.reports ? 'overview' : '',
    });
    return switch (_section) {
      AdminSection.overview => '/api/admin/overview$query',
      AdminSection.clients => '/api/admin/clients$query',
      AdminSection.profiles => '/api/admin/profiles$query',
      AdminSection.voterLists => '/api/admin/voter-lists$query',
      AdminSection.blueTik => '/api/admin/blue-tik$query',
      AdminSection.activity => '/api/admin/activity$query',
      AdminSection.purchases => '/api/admin/purchases$query',
      AdminSection.payments => '/api/admin/payments$query',
      AdminSection.campaigns => '/api/admin/campaigns$query',
      AdminSection.users => '/api/admin/users$query',
      AdminSection.reports => '/api/admin/reports$query',
      AdminSection.audit => '/api/admin/audit$query',
    };
  }

  void _choose(AdminSection section) {
    setState(() {
      _section = section;
      _page = 1;
      _status = '';
      _paymentStatus = '';
      _search.clear();
    });
    _load();
  }

  Future<void> _export() async {
    final kind = switch (_section) {
      AdminSection.purchases || AdminSection.payments => 'purchases',
      AdminSection.clients => 'clients',
      AdminSection.profiles => 'profiles',
      AdminSection.campaigns => 'campaigns',
      AdminSection.activity => 'engagement',
      _ => 'overview',
    };
    final path =
        kind == 'purchases' && _section == AdminSection.purchases
            ? '/api/admin/purchases.csv${adminQuery({'q': _search.text, 'paymentStatus': _paymentStatus, 'range': _range})}'
            : '/api/admin/reports.csv${adminQuery({'kind': kind, 'range': _range})}';
    try {
      final csv = await AdminService.instance.getText(path);
      await saveAdminCsv('$kind.csv', csv);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export ready.')));
    } on AdminApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export was denied.')));
    }
  }

  Future<void> _updateUser(
    Map<String, dynamic> user,
    Map<String, String> patch,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(
              'This changes ${user['fullName'] ?? 'this account'}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.instance.patchJson(
        '/api/admin/users/${user['id']}',
        patch,
      );
      await _load();
    } on AdminApiException catch (err) {
      if (!mounted) return;
      final message =
          err.code == 'last_admin'
              ? 'The last active admin cannot be removed.'
              : 'The account could not be updated.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = DashboardColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final sidebar = DashboardSidebar(
          colors: colors,
          items: dashboardSidebarItems(l10n),
          selectedRoute: AppRoutes.admin,
          onNavigate: wide ? null : () => Navigator.of(context).pop(),
        );
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.page,
          drawer:
              wide
                  ? null
                  : Drawer(
                    backgroundColor: colors.sidebar,
                    child: SafeArea(child: sidebar),
                  ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) SizedBox(width: 248, child: sidebar),
                Expanded(
                  child: Column(
                    children: [
                      _AdminBar(
                        colors: colors,
                        wide: wide,
                        title: l10n.line('adminPanel'),
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(child: _body(colors)),
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

  Widget _body(DashboardColors colors) {
    if (_loading)
      return Center(child: CircularProgressIndicator(color: colors.accent));
    if (_denied) {
      return const AdminStateMessage(
        message: 'You do not have access to the admin panel.',
      );
    }
    if (_notReady) {
      return AdminStateMessage(
        message:
            'Admin records are not available until the admin database migration has been applied.',
        onRetry: _load,
      );
    }
    if (_error != null)
      return AdminStateMessage(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
      children: [
        _pageHeading(colors),
        const SizedBox(height: 18),
        _sectionBar(colors),
        const SizedBox(height: 14),
        _toolbar(colors),
        const SizedBox(height: 20),
        _sectionBody(colors),
      ],
    );
  }

  Widget _pageHeading(DashboardColors colors) {
    const titles = {
      AdminSection.overview: 'Overview',
      AdminSection.clients: 'Clients',
      AdminSection.profiles: 'Profiles',
      AdminSection.voterLists: 'Voter Lists',
      AdminSection.blueTik: 'Blue Tik requests',
      AdminSection.activity: 'Activity',
      AdminSection.purchases: 'Purchases',
      AdminSection.payments: 'Payments',
      AdminSection.campaigns: 'Campaigns',
      AdminSection.users: 'Users',
      AdminSection.reports: 'Reports',
      AdminSection.audit: 'Audit log',
    };
    const descriptions = {
      AdminSection.overview:
          'A live snapshot of registrations, payments, and platform activity.',
      AdminSection.clients:
          'Review client accounts and open a record for more detail.',
      AdminSection.profiles:
          'Browse leader profiles and their latest account information.',
      AdminSection.voterLists:
          'Review voter package requests with the requester’s name and phone number.',
      AdminSection.blueTik:
          'Review submitted verification requests and their status.',
      AdminSection.activity:
          'Follow recent activity across the VoteBanker platform.',
      AdminSection.purchases:
          'Review purchases, payment status, and transaction details.',
      AdminSection.payments: 'Track payment outcomes and transaction records.',
      AdminSection.campaigns:
          'Review campaigns created by clients across the platform.',
      AdminSection.users: 'Manage account roles and access status.',
      AdminSection.reports:
          'Review platform totals for the selected reporting period.',
      AdminSection.audit: 'Review administrative changes and their outcomes.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[_section]!,
          style: TextStyle(
            color: colors.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          descriptions[_section]!,
          style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _sectionBar(DashboardColors colors) {
    const sections = <(AdminSection, String, IconData)>[
      (AdminSection.overview, 'Overview', Icons.space_dashboard_outlined),
      (AdminSection.clients, 'Clients', Icons.groups_outlined),
      (AdminSection.profiles, 'Profiles', Icons.badge_outlined),
      (AdminSection.voterLists, 'Voter Lists', Icons.how_to_vote_outlined),
      (AdminSection.blueTik, 'Blue Tik', Icons.verified_outlined),
      (AdminSection.activity, 'Activity', Icons.timeline_outlined),
      (AdminSection.purchases, 'Purchases', Icons.shopping_bag_outlined),
      (AdminSection.payments, 'Payments', Icons.payments_outlined),
      (AdminSection.campaigns, 'Campaigns', Icons.campaign_outlined),
      (AdminSection.users, 'Users', Icons.manage_accounts_outlined),
      (AdminSection.reports, 'Reports', Icons.bar_chart_outlined),
      (AdminSection.audit, 'Audit', Icons.policy_outlined),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _AdminSectionTab(
                  label: section.$2,
                  icon: section.$3,
                  selected: _section == section.$1,
                  colors: colors,
                  onPressed: () => _choose(section.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(DashboardColors colors) {
    final showSearch =
        _section != AdminSection.overview && _section != AdminSection.reports;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchWidth =
              constraints.maxWidth >= 850 ? 260.0 : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _filterDropdown(
                colors: colors,
                width: 190,
                icon: Icons.calendar_month_outlined,
                value: _range,
                options: const [
                  ('day', 'Today'),
                  ('week', 'Last 7 days'),
                  ('month', 'Last 30 days'),
                  ('year', 'This year'),
                ],
                onChanged: (value) {
                  setState(() => _range = value);
                  _load();
                },
              ),
              if (showSearch)
                SizedBox(
                  width: searchWidth,
                  child: AdminSearchField(
                    controller: _search,
                    hint: 'Search records',
                    onChanged: (_) {
                      _searchTimer?.cancel();
                      _searchTimer = Timer(
                        const Duration(milliseconds: 350),
                        () {
                          _page = 1;
                          _load();
                        },
                      );
                    },
                  ),
                ),
              if (_section == AdminSection.clients ||
                  _section == AdminSection.users)
                _filterDropdown(
                  colors: colors,
                  width: 178,
                  icon: Icons.filter_list,
                  value: _status.isEmpty ? 'all' : _status,
                  options: const [
                    ('all', 'All statuses'),
                    ('active', 'Active'),
                    ('inactive', 'Inactive'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value == 'all' ? '' : value;
                      _page = 1;
                    });
                    _load();
                  },
                ),
              if (_section == AdminSection.purchases ||
                  _section == AdminSection.payments)
                _filterDropdown(
                  colors: colors,
                  width: 190,
                  icon: Icons.filter_list,
                  value: _paymentStatus.isEmpty ? 'all' : _paymentStatus,
                  options: const [
                    ('all', 'All payments'),
                    ('successful', 'Successful'),
                    ('pending', 'Pending'),
                    ('failed', 'Failed'),
                    ('refunded', 'Refunded'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _paymentStatus = value == 'all' ? '' : value;
                      _page = 1;
                    });
                    _load();
                  },
                ),
              if (_section != AdminSection.blueTik &&
                  _section != AdminSection.voterLists)
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Export CSV'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required DashboardColors colors,
    required double width,
    required IconData icon,
    required String value,
    required List<(String, String)> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.keyboard_arrow_down, color: colors.muted),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  for (final option in options)
                    DropdownMenuItem(
                      value: option.$1,
                      child: Text(
                        option.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (selected) {
                  if (selected != null) onChanged(selected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody(DashboardColors colors) {
    return switch (_section) {
      AdminSection.overview => _overview(colors),
      AdminSection.clients => _clients(),
      AdminSection.profiles => _profiles(),
      AdminSection.voterLists => _voterLists(),
      AdminSection.blueTik => _blueTik(),
      AdminSection.activity => _activity(),
      AdminSection.purchases || AdminSection.payments => _purchases(),
      AdminSection.campaigns => _campaigns(),
      AdminSection.users => _users(),
      AdminSection.reports => _reports(colors),
      AdminSection.audit => _audit(),
    };
  }

  Widget _overview(DashboardColors colors) {
    final cards =
        _data['cards'] is Map
            ? Map<String, dynamic>.from(_data['cards'] as Map)
            : <String, dynamic>{};
    final items = <(String, Object?, IconData, Color)>[
      (
        'Registered clients',
        cards['totalClients'],
        Icons.groups_outlined,
        const Color(0xFF2563EB),
      ),
      (
        'Active clients',
        cards['activeClients'],
        Icons.verified_outlined,
        const Color(0xFF0FAD8A),
      ),
      (
        'Inactive clients',
        cards['inactiveClients'],
        Icons.person_off_outlined,
        const Color(0xFF8B5CF6),
      ),
      (
        'New registrations',
        cards['newRegistrations'],
        Icons.person_add_alt_1_outlined,
        const Color(0xFF10B981),
      ),
      (
        'Purchases',
        cards['totalPurchases'],
        Icons.shopping_bag_outlined,
        const Color(0xFFEC4899),
      ),
      (
        'Revenue',
        adminMoney(cards['totalRevenue']),
        Icons.payments_outlined,
        const Color(0xFF14B8A6),
      ),
      (
        'Pending payments',
        cards['pendingPayments'],
        Icons.hourglass_empty,
        const Color(0xFFF59E0B),
      ),
      (
        'Successful payments',
        cards['successfulPayments'],
        Icons.check_circle_outline,
        const Color(0xFF7C3AED),
      ),
      (
        'Failed payments',
        cards['failedPayments'],
        Icons.error_outline,
        const Color(0xFFF97316),
      ),
      (
        'Active campaigns',
        cards['activeCampaigns'],
        Icons.campaign_outlined,
        const Color(0xFF0EA5E9),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colors.accent, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client figures are current totals; activity and financial metrics use the selected period.',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if ((_data['revenueNote']?.toString() ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _data['revenueNote'].toString(),
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 1050
                    ? 4
                    : constraints.maxWidth >= 700
                    ? 3
                    : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio:
                  columns == 4
                      ? 2.45
                      : columns == 3
                      ? 2.2
                      : 2.0,
              children: [
                for (final item in items)
                  AdminCard(
                    title: item.$1,
                    value:
                        item.$1 == 'Revenue'
                            ? item.$2.toString()
                            : '${item.$2 ?? 0}',
                    icon: item.$3,
                    accentColor: item.$4,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final registrations = AdminBarChart(
              title: 'Client registrations',
              points: _series('registrationSeries'),
            );
            final revenue = AdminBarChart(
              title: 'Revenue',
              points: _series('revenueSeries'),
            );
            if (constraints.maxWidth < 760) {
              return Column(
                children: [registrations, const SizedBox(height: 14), revenue],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: registrations),
                const SizedBox(width: 14),
                Expanded(child: revenue),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final registrations = _overviewSection(
              colors,
              title: 'Recent registrations',
              icon: Icons.person_add_alt_1_outlined,
              child: _simplePeople(_list('recentRegistrations')),
            );
            final activity = _overviewSection(
              colors,
              title: 'Recent activity',
              icon: Icons.bolt_outlined,
              child: _activityTable(_list('recentActivities'), paged: false),
            );
            if (constraints.maxWidth < 900) {
              return Column(
                children: [registrations, const SizedBox(height: 18), activity],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: registrations),
                const SizedBox(width: 14),
                Expanded(child: activity),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _overviewSection(
          colors,
          title: 'Recent purchases and transactions',
          icon: Icons.receipt_long_outlined,
          child: _purchaseTable(_list('recentPurchases'), paged: false),
        ),
      ],
    );
  }

  Widget _overviewSection(
    DashboardColors colors, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: colors.accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _clients() {
    final rows = _list('clients');
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Name',
            'Phone',
            'Email',
            'Status',
            'Created',
            'Last login',
          ],
          onRow:
              (index) => AppRouter.open(
                context,
                AppRoutes.adminClient,
                arguments: rows[index]['id']?.toString() ?? '',
              ),
          rows: [
            for (final row in rows)
              [
                Text(row['fullName']?.toString() ?? ''),
                Text(row['phone']?.toString() ?? ''),
                Text(row['email']?.toString() ?? ''),
                AdminStatusBadge(label: row['status']?.toString() ?? 'active'),
                Text(adminWhen(row['createdAt'])),
                Text(adminWhen(row['lastLoginAt'])),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _blueTik() {
    final rows = _list('requests');
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Leader',
            'Mobile',
            'Email',
            'Option',
            'Price',
            'Profile URLs',
            'Submitted',
            'Status',
          ],
          rows: [
            for (final row in rows)
              [
                Text(row['leaderName']?.toString() ?? ''),
                Text(row['mobile']?.toString() ?? ''),
                Text(row['email']?.toString() ?? ''),
                Text(row['serviceName']?.toString() ?? ''),
                Text(adminMoney(row['priceInr'])),
                SizedBox(
                  width: 240,
                  child: Text(_profileUrls(row['profileUrls'])),
                ),
                Text(adminWhen(row['createdAt'])),
                AdminStatusBadge(label: row['status']?.toString() ?? 'pending'),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  String _profileUrls(Object? value) {
    if (value is! Map) return '';
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  Widget _voterLists() {
    final rows = _list('rows');
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Requester',
            'Phone',
            'Package',
            'Amount',
            'Status',
            'Requested',
          ],
          rows: [
            for (final row in rows)
              [
                Text(row['userName']?.toString() ?? ''),
                Text(row['phone']?.toString() ?? ''),
                Text('${row['voterCount'] ?? 0} voters'),
                Text(adminMoney(row['amountInr'])),
                AdminStatusBadge(
                  label: row['status']?.toString() ?? 'requested',
                ),
                Text(adminWhen(row['createdAt'])),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _profiles() {
    final rows = _list('profiles');
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Name',
            'Party',
            'Designation',
            'State',
            'District',
            'Assembly',
            'Booth',
            'Contact',
            'Updated',
          ],
          onRow:
              (index) => AppRouter.open(
                context,
                AppRoutes.adminClient,
                arguments: rows[index]['id']?.toString() ?? '',
              ),
          rows: [
            for (final row in rows)
              [
                Text(row['fullName']?.toString() ?? ''),
                Text(row['organization']?.toString() ?? ''),
                Text(row['designation']?.toString() ?? ''),
                Text(row['state']?.toString() ?? ''),
                Text(row['constituency']?.toString() ?? ''),
                Text(row['assemblyConstituency']?.toString() ?? ''),
                Text(
                  '${row['boothNumber'] ?? ''} ${row['boothName'] ?? ''}'
                      .trim(),
                ),
                Text(
                  (row['publicContact']?.toString().trim().isNotEmpty ?? false)
                      ? row['publicContact'].toString()
                      : (row['phone']?.toString() ?? ''),
                ),
                Text(adminWhen(row['updatedAt'])),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _activity() => _activityTable(_list('rows'), paged: true);

  Widget _activityTable(
    List<Map<String, dynamic>> rows, {
    required bool paged,
  }) {
    return Column(
      children: [
        AdminDataTable(
          columns: const ['When', 'Client', 'Type', 'Description', 'Status'],
          onRow: (index) {
            final id = rows[index]['clientId']?.toString() ?? '';
            if (id.isNotEmpty)
              AppRouter.open(context, AppRoutes.adminClient, arguments: id);
          },
          rows: [
            for (final row in rows)
              [
                Text(adminWhen(row['createdAt'])),
                Text(row['clientName']?.toString() ?? ''),
                Text(row['type']?.toString() ?? ''),
                SizedBox(
                  width: 280,
                  child: Text(row['description']?.toString() ?? ''),
                ),
                AdminStatusBadge(
                  label: row['status']?.toString() ?? 'recorded',
                ),
              ],
          ],
        ),
        if (paged)
          AdminPager(
            page: _page,
            pageSize: 20,
            total: (_data['total'] as num?)?.toInt() ?? rows.length,
            onPage: (page) {
              setState(() => _page = page);
              _load();
            },
          ),
      ],
    );
  }

  Widget _purchases() {
    final summary =
        _data['summary'] is Map
            ? Map<String, dynamic>.from(_data['summary'] as Map)
            : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Successful ${summary['successful'] ?? 0} · Pending ${summary['pending'] ?? 0} · Failed ${summary['failed'] ?? 0} · Refunded ${summary['refunded'] ?? 0} · ${adminMoney(summary['revenue'])}',
            ),
          ),
        _purchaseTable(_list('rows'), paged: true),
      ],
    );
  }

  Widget _purchaseTable(
    List<Map<String, dynamic>> rows, {
    required bool paged,
  }) {
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Order',
            'Name',
            'Email',
            'Contact',
            'Product',
            'Qty',
            'Total',
            'Status',
            'Date',
          ],
          onRow: (index) {
            final id = rows[index]['clientId']?.toString() ?? '';
            if (id.isNotEmpty)
              AppRouter.open(context, AppRoutes.adminClient, arguments: id);
          },
          rows: [
            for (final row in rows)
              [
                Text((row['reference'] ?? row['id'] ?? '').toString()),
                Text(row['clientName']?.toString() ?? ''),
                Text(row['clientEmail']?.toString() ?? ''),
                Text(row['clientPhone']?.toString() ?? ''),
                Text(row['product']?.toString() ?? ''),
                Text('${row['quantity'] ?? ''}'),
                Text(adminMoney(row['finalAmount'])),
                AdminStatusBadge(
                  label: row['orderStatus']?.toString() ?? 'pending',
                ),
                Text(adminWhen(row['purchasedAt'])),
              ],
          ],
        ),
        if (paged)
          AdminPager(
            page: _page,
            pageSize: 20,
            total: (_data['total'] as num?)?.toInt() ?? rows.length,
            onPage: (page) {
              setState(() => _page = page);
              _load();
            },
          ),
      ],
    );
  }

  Widget _campaigns() {
    final rows = _list('rows');
    return Column(
      children: [
        AdminDataTable(
          columns: const [
            'Campaign',
            'Owner',
            'Kind',
            'Status',
            'Created',
            'Updated',
          ],
          onRow: (index) {
            final id = rows[index]['ownerId']?.toString() ?? '';
            if (id.isNotEmpty)
              AppRouter.open(context, AppRoutes.adminClient, arguments: id);
          },
          rows: [
            for (final row in rows)
              [
                Text(row['name']?.toString() ?? ''),
                Text(row['ownerName']?.toString() ?? ''),
                Text(row['kind']?.toString() ?? ''),
                AdminStatusBadge(label: row['status']?.toString() ?? ''),
                Text(adminWhen(row['createdAt'])),
                Text(adminWhen(row['updatedAt'])),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _users() {
    final rows = _list('users');
    return Column(
      children: [
        AdminDataTable(
          columns: const ['Name', 'Phone', 'Role', 'Status', 'Actions'],
          rows: [
            for (final row in rows)
              [
                Text(row['fullName']?.toString() ?? ''),
                Text(row['phone']?.toString() ?? ''),
                AdminStatusBadge(label: row['role']?.toString() ?? 'client'),
                AdminStatusBadge(label: row['status']?.toString() ?? 'active'),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed:
                          () => _updateUser(
                            row,
                            {
                              'app_role':
                                  row['role'] == 'admin' ? 'client' : 'admin',
                            },
                            row['role'] == 'admin'
                                ? 'Remove admin role?'
                                : 'Make this account an admin?',
                          ),
                      child: Text(
                        row['role'] == 'admin' ? 'Make client' : 'Make admin',
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => _updateUser(
                            row,
                            {
                              'account_status':
                                  row['status'] == 'inactive'
                                      ? 'active'
                                      : 'inactive',
                            },
                            row['status'] == 'inactive'
                                ? 'Activate this account?'
                                : 'Deactivate this account?',
                          ),
                      child: Text(
                        row['status'] == 'inactive' ? 'Activate' : 'Deactivate',
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _reports(DashboardColors colors) {
    final rows = _list('rows');
    if (_data['overview'] is Map) {
      final overview = Map<String, dynamic>.from(_data['overview'] as Map);
      final cards =
          overview['cards'] is Map
              ? Map<String, dynamic>.from(overview['cards'] as Map)
              : <String, dynamic>{};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report for this $_range',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in cards.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(color: colors.text),
              ),
            ),
        ],
      );
    }
    return AdminDataTable(
      columns:
          rows.isEmpty
              ? const ['Report']
              : rows.first.keys.map((key) => key.toString()).toList(),
      rows: [
        for (final row in rows)
          [for (final value in row.values) Text(value?.toString() ?? '')],
      ],
    );
  }

  Widget _audit() {
    final rows = _list('rows');
    return Column(
      children: [
        AdminDataTable(
          columns: const ['When', 'Action', 'Target', 'Outcome', 'Detail'],
          rows: [
            for (final row in rows)
              [
                Text(adminWhen(row['createdAt'])),
                Text(row['action']?.toString() ?? ''),
                Text(row['targetId']?.toString() ?? ''),
                AdminStatusBadge(label: row['outcome']?.toString() ?? ''),
                Text(row['detail']?.toString() ?? ''),
              ],
          ],
        ),
        AdminPager(
          page: _page,
          pageSize: 20,
          total: (_data['total'] as num?)?.toInt() ?? rows.length,
          onPage: (page) {
            setState(() => _page = page);
            _load();
          },
        ),
      ],
    );
  }

  Widget _simplePeople(List<Map<String, dynamic>> rows) {
    return AdminDataTable(
      columns: const ['Name', 'Phone', 'Created'],
      onRow:
          (index) => AppRouter.open(
            context,
            AppRoutes.adminClient,
            arguments: rows[index]['id']?.toString() ?? '',
          ),
      rows: [
        for (final row in rows)
          [
            Text(row['fullName']?.toString() ?? ''),
            Text(row['phone']?.toString() ?? ''),
            Text(adminWhen(row['createdAt'])),
          ],
      ],
    );
  }

  List<Map<String, dynamic>> _list(String key) {
    final value = _data[key];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<Map<String, dynamic>> _series(String key) => _list(key);
}

class _AdminBar extends StatelessWidget {
  const _AdminBar({
    required this.colors,
    required this.wide,
    required this.title,
    required this.onMenu,
  });

  final DashboardColors colors;
  final bool wide;
  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            if (!wide)
              IconButton(
                tooltip: 'Open navigation',
                onPressed: onMenu,
                icon: Icon(Icons.menu, color: colors.accent),
              ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: colors.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VOTEBANKER  /  ADMINISTRATION',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 10,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
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

class _AdminSectionTab extends StatelessWidget {
  const _AdminSectionTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final DashboardColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : colors.muted;
    return Material(
      color: selected ? colors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
