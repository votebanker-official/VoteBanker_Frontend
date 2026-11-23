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
        _error = err.forbidden || err.notReady ? null : 'The admin data could not be loaded.';
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
    final path = kind == 'purchases' && _section == AdminSection.purchases
        ? '/api/admin/purchases.csv${adminQuery({'q': _search.text, 'paymentStatus': _paymentStatus, 'range': _range})}'
        : '/api/admin/reports.csv${adminQuery({'kind': kind, 'range': _range})}';
    try {
      final csv = await AdminService.instance.getText(path);
      await saveAdminCsv('$kind.csv', csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export ready.')));
    } on AdminApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export was denied.')));
    }
  }

  Future<void> _updateUser(Map<String, dynamic> user, Map<String, String> patch, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('This changes ${user['fullName'] ?? 'this account'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.instance.patchJson('/api/admin/users/${user['id']}', patch);
      await _load();
    } on AdminApiException catch (err) {
      if (!mounted) return;
      final message = err.code == 'last_admin'
          ? 'The last active admin cannot be removed.'
          : 'The account could not be updated.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          drawer: wide ? null : Drawer(backgroundColor: colors.sidebar, child: SafeArea(child: sidebar)),
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
    if (_loading) return Center(child: CircularProgressIndicator(color: colors.accent));
    if (_denied) {
      return const AdminStateMessage(message: 'You do not have access to the admin panel.');
    }
    if (_notReady) {
      return AdminStateMessage(
        message: 'Admin records are not available until the admin database migration has been applied.',
        onRetry: _load,
      );
    }
    if (_error != null) return AdminStateMessage(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _sectionBar(colors),
        const SizedBox(height: 12),
        _toolbar(colors),
        const SizedBox(height: 12),
        _sectionBody(colors),
      ],
    );
  }

  Widget _sectionBar(DashboardColors colors) {
    const labels = {
      AdminSection.overview: 'Overview',
      AdminSection.clients: 'Clients',
      AdminSection.profiles: 'Profiles',
      AdminSection.blueTik: 'Blue Tik',
      AdminSection.activity: 'Activity',
      AdminSection.purchases: 'Purchases',
      AdminSection.payments: 'Payments',
      AdminSection.campaigns: 'Campaigns',
      AdminSection.users: 'Users',
      AdminSection.reports: 'Reports',
      AdminSection.audit: 'Audit',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _section == entry.key,
                onSelected: (_) => _choose(entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolbar(DashboardColors colors) {
    final showSearch = _section != AdminSection.overview && _section != AdminSection.reports;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final range in ['day', 'week', 'month', 'year'])
          ChoiceChip(
            label: Text(range),
            selected: _range == range,
            onSelected: (_) {
              setState(() => _range = range);
              _load();
            },
          ),
        if (showSearch)
          SizedBox(
            width: 260,
            child: AdminSearchField(
              controller: _search,
              hint: 'Search',
              onChanged: (_) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 350), () {
                  _page = 1;
                  _load();
                });
              },
            ),
          ),
        if (_section == AdminSection.clients || _section == AdminSection.users)
          DropdownButton<String>(
            value: _status.isEmpty ? 'all' : _status,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All statuses')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ],
            onChanged: (value) {
              setState(() {
                _status = value == null || value == 'all' ? '' : value;
                _page = 1;
              });
              _load();
            },
          ),
        if (_section == AdminSection.purchases || _section == AdminSection.payments)
          DropdownButton<String>(
            value: _paymentStatus.isEmpty ? 'all' : _paymentStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All payments')),
              DropdownMenuItem(value: 'successful', child: Text('Successful')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'failed', child: Text('Failed')),
              DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
            ],
            onChanged: (value) {
              setState(() {
                _paymentStatus = value == null || value == 'all' ? '' : value;
                _page = 1;
              });
              _load();
            },
          ),
        if (_section != AdminSection.blueTik)
          TextButton.icon(onPressed: _export, icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Export CSV')),
      ],
    );
  }

  Widget _sectionBody(DashboardColors colors) {
    return switch (_section) {
      AdminSection.overview => _overview(colors),
      AdminSection.clients => _clients(),
      AdminSection.profiles => _profiles(),
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
    final cards = _data['cards'] is Map ? Map<String, dynamic>.from(_data['cards'] as Map) : <String, dynamic>{};
    final items = [
      ('Registered clients', cards['totalClients'], Icons.groups_outlined),
      ('Active clients', cards['activeClients'], Icons.verified_outlined),
      ('Inactive clients', cards['inactiveClients'], Icons.person_off_outlined),
      ('New registrations', cards['newRegistrations'], Icons.person_add_alt_1_outlined),
      ('Purchases', cards['totalPurchases'], Icons.shopping_bag_outlined),
      ('Revenue', adminMoney(cards['totalRevenue']), Icons.payments_outlined),
      ('Pending payments', cards['pendingPayments'], Icons.hourglass_empty),
      ('Successful payments', cards['successfulPayments'], Icons.check_circle_outline),
      ('Failed payments', cards['failedPayments'], Icons.error_outline),
      ('Active campaigns', cards['activeCampaigns'], Icons.campaign_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registered, active, and inactive clients are current totals. Registrations, purchases, payments, revenue, and campaigns follow this $_range.',
          style: TextStyle(color: colors.muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(_data['revenueNote']?.toString() ?? '', style: TextStyle(color: colors.muted, fontSize: 12, height: 1.35)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 5 : constraints.maxWidth >= 640 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 2 ? 1.55 : 2.15,
              children: [
                for (final item in items)
                  AdminCard(
                    title: item.$1,
                    value: item.$1 == 'Revenue' ? item.$2.toString() : '${item.$2 ?? 0}',
                    icon: item.$3,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        AdminBarChart(
          title: 'Client registrations',
          points: _series('registrationSeries'),
        ),
        const SizedBox(height: 12),
        AdminBarChart(title: 'Revenue', points: _series('revenueSeries')),
        const SizedBox(height: 16),
        Text('Recent registrations', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
        _simplePeople(_list('recentRegistrations')),
        const SizedBox(height: 12),
        Text('Recent purchases and transactions', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
        _purchaseTable(_list('recentPurchases'), paged: false),
        const SizedBox(height: 12),
        Text('Recent activity', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
        _activityTable(_list('recentActivities'), paged: false),
      ],
    );
  }

  Widget _clients() {
    final rows = _list('clients');
    return Column(
      children: [
        AdminDataTable(
          columns: const ['Name', 'Phone', 'Email', 'Status', 'Created', 'Last login'],
          onRow: (index) => AppRouter.open(context, AppRoutes.adminClient, arguments: rows[index]['id']?.toString() ?? ''),
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
                SizedBox(width: 240, child: Text(_profileUrls(row['profileUrls']))),
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
          onRow: (index) => AppRouter.open(context, AppRoutes.adminClient, arguments: rows[index]['id']?.toString() ?? ''),
          rows: [
            for (final row in rows)
              [
                Text(row['fullName']?.toString() ?? ''),
                Text(row['organization']?.toString() ?? ''),
                Text(row['designation']?.toString() ?? ''),
                Text(row['state']?.toString() ?? ''),
                Text(row['constituency']?.toString() ?? ''),
                Text(row['assemblyConstituency']?.toString() ?? ''),
                Text('${row['boothNumber'] ?? ''} ${row['boothName'] ?? ''}'.trim()),
                Text((row['publicContact']?.toString().trim().isNotEmpty ?? false)
                    ? row['publicContact'].toString()
                    : (row['phone']?.toString() ?? '')),
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

  Widget _activityTable(List<Map<String, dynamic>> rows, {required bool paged}) {
    return Column(
      children: [
        AdminDataTable(
          columns: const ['When', 'Client', 'Type', 'Description', 'Status'],
          onRow: (index) {
            final id = rows[index]['clientId']?.toString() ?? '';
            if (id.isNotEmpty) AppRouter.open(context, AppRoutes.adminClient, arguments: id);
          },
          rows: [
            for (final row in rows)
              [
                Text(adminWhen(row['createdAt'])),
                Text(row['clientName']?.toString() ?? ''),
                Text(row['type']?.toString() ?? ''),
                SizedBox(width: 280, child: Text(row['description']?.toString() ?? '')),
                AdminStatusBadge(label: row['status']?.toString() ?? 'recorded'),
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
    final summary = _data['summary'] is Map ? Map<String, dynamic>.from(_data['summary'] as Map) : null;
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

  Widget _purchaseTable(List<Map<String, dynamic>> rows, {required bool paged}) {
    return Column(
      children: [
        AdminDataTable(
          columns: const ['Order', 'Name', 'Email', 'Contact', 'Product', 'Qty', 'Total', 'Status', 'Date'],
          onRow: (index) {
            final id = rows[index]['clientId']?.toString() ?? '';
            if (id.isNotEmpty) AppRouter.open(context, AppRoutes.adminClient, arguments: id);
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
                AdminStatusBadge(label: row['orderStatus']?.toString() ?? 'pending'),
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
          columns: const ['Campaign', 'Owner', 'Kind', 'Status', 'Created', 'Updated'],
          onRow: (index) {
            final id = rows[index]['ownerId']?.toString() ?? '';
            if (id.isNotEmpty) AppRouter.open(context, AppRoutes.adminClient, arguments: id);
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
                      onPressed: () => _updateUser(
                        row,
                        {'app_role': row['role'] == 'admin' ? 'client' : 'admin'},
                        row['role'] == 'admin' ? 'Remove admin role?' : 'Make this account an admin?',
                      ),
                      child: Text(row['role'] == 'admin' ? 'Make client' : 'Make admin'),
                    ),
                    TextButton(
                      onPressed: () => _updateUser(
                        row,
                        {'account_status': row['status'] == 'inactive' ? 'active' : 'inactive'},
                        row['status'] == 'inactive' ? 'Activate this account?' : 'Deactivate this account?',
                      ),
                      child: Text(row['status'] == 'inactive' ? 'Activate' : 'Deactivate'),
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
      final cards = overview['cards'] is Map ? Map<String, dynamic>.from(overview['cards'] as Map) : <String, dynamic>{};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report for this $_range', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final entry in cards.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${entry.key}: ${entry.value}', style: TextStyle(color: colors.text)),
            ),
        ],
      );
    }
    return AdminDataTable(
      columns: rows.isEmpty ? const ['Report'] : rows.first.keys.map((key) => key.toString()).toList(),
      rows: [
        for (final row in rows) [for (final value in row.values) Text(value?.toString() ?? '')],
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
      onRow: (index) => AppRouter.open(context, AppRoutes.adminClient, arguments: rows[index]['id']?.toString() ?? ''),
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
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  List<Map<String, dynamic>> _series(String key) => _list(key);
}

class _AdminBar extends StatelessWidget {
  const _AdminBar({required this.colors, required this.wide, required this.title, required this.onMenu});

  final DashboardColors colors;
  final bool wide;
  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            if (!wide) IconButton(onPressed: onMenu, icon: Icon(Icons.menu, color: colors.accent)),
            Expanded(
              child: Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
