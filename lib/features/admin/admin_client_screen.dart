import 'package:flutter/material.dart';

import '../../app/routing/app_router.dart';
import '../dashboard/widgets/dashboard_colors.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';

class AdminClientScreen extends StatefulWidget {
  const AdminClientScreen({required this.clientId, super.key});

  final String clientId;

  @override
  State<AdminClientScreen> createState() => _AdminClientScreenState();
}

class _AdminClientScreenState extends State<AdminClientScreen> {
  var _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.clientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This client could not be found.';
      });
      return;
    }
    try {
      final data = await AdminService.instance.getJson(
        '/api/admin/clients/${widget.clientId}',
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on AdminApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            err.forbidden
                ? 'You do not have access to this client.'
                : err.status == 404
                ? 'This client could not be found.'
                : 'The client profile could not be loaded.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The client profile could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DashboardColors.of(context);
    final profile =
        _data['profile'] is Map
            ? Map<String, dynamic>.from(_data['profile'] as Map)
            : <String, dynamic>{};
    return Scaffold(
      backgroundColor: colors.page,
      appBar: AppBar(
        backgroundColor: colors.topBar,
        foregroundColor: colors.text,
        elevation: 0,
        title: Text(
          profile['fullName']?.toString().isNotEmpty == true
              ? profile['fullName'].toString()
              : 'Client',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.back(context, AppRoutes.admin),
        ),
      ),
      body:
          _loading
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : _error != null
              ? AdminStateMessage(message: _error!, onRetry: _load)
              : DefaultTabController(
                length: 7,
                child: Column(
                  children: [
                    Material(
                      color: colors.topBar,
                      child: TabBar(
                        isScrollable: true,
                        labelColor: colors.accent,
                        unselectedLabelColor: colors.muted,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Profile'),
                          Tab(text: 'Activity'),
                          Tab(text: 'Purchases'),
                          Tab(text: 'Payments'),
                          Tab(text: 'Campaigns'),
                          Tab(text: 'Engagement'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _overview(colors, profile),
                          _profile(colors, profile),
                          _activity(),
                          _purchases(false),
                          _purchases(true),
                          _campaigns(),
                          _engagement(colors),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _overview(DashboardColors colors, Map<String, dynamic> profile) {
    final engagement =
        _data['engagement'] is Map
            ? Map<String, dynamic>.from(_data['engagement'] as Map)
            : <String, dynamic>{};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          profile['designation']?.toString() ?? '',
          style: TextStyle(color: colors.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            AdminStatusBadge(label: profile['status']?.toString() ?? 'active'),
            AdminStatusBadge(label: profile['role']?.toString() ?? 'client'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Created ${adminWhen(profile['createdAt'])}',
          style: TextStyle(color: colors.text),
        ),
        Text(
          'Last login ${adminWhen(profile['lastLoginAt'])}',
          style: TextStyle(color: colors.text),
        ),
        const SizedBox(height: 16),
        AdminCard(
          title: 'Purchases',
          value: '${engagement['purchases'] ?? 0}',
          icon: Icons.shopping_bag_outlined,
        ),
        const SizedBox(height: 8),
        AdminCard(
          title: 'Campaigns',
          value: '${engagement['campaigns'] ?? 0}',
          icon: Icons.campaign_outlined,
        ),
        const SizedBox(height: 8),
        AdminCard(
          title: 'Activities',
          value: '${engagement['activities'] ?? 0}',
          icon: Icons.timeline_outlined,
        ),
      ],
    );
  }

  Widget _profile(DashboardColors colors, Map<String, dynamic> profile) {
    const fields = {
      'Phone': 'phone',
      'Email': 'email',
      'Public contact': 'publicContact',
      'Organization': 'organization',
      'Designation': 'designation',
      'State': 'state',
      'Constituency': 'constituency',
      'Language': 'language',
      'Domain': 'domain',
      'Booth': 'boothName',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final field in fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(field.key, style: TextStyle(color: colors.muted)),
                ),
                Expanded(
                  child: Text(
                    profile[field.value]?.toString() ?? '—',
                    style: TextStyle(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _activity() {
    final rows = _maps('activity');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminDataTable(
          columns: const ['When', 'Type', 'Description', 'Status'],
          rows: [
            for (final row in rows)
              [
                Text(adminWhen(row['createdAt'])),
                Text(row['type']?.toString() ?? ''),
                SizedBox(
                  width: 280,
                  child: Text(row['description']?.toString() ?? ''),
                ),
                AdminStatusBadge(label: row['status']?.toString() ?? ''),
              ],
          ],
        ),
      ],
    );
  }

  Widget _purchases(bool paymentsOnly) {
    final rows =
        _maps('purchases').where((row) {
          if (!paymentsOnly) return true;
          return row['source'] == 'website' || row['paymentStatus'] != null;
        }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (paymentsOnly)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Payment status comes from stored order and website records. Card numbers are not stored.',
            ),
          ),
        AdminDataTable(
          columns: const [
            'Product',
            'Amount',
            'Payment',
            'Order',
            'Reference',
            'Date',
          ],
          rows: [
            for (final row in rows)
              [
                Text(row['product']?.toString() ?? ''),
                Text(adminMoney(row['finalAmount'])),
                AdminStatusBadge(
                  label: row['paymentStatus']?.toString() ?? 'pending',
                ),
                AdminStatusBadge(label: row['orderStatus']?.toString() ?? ''),
                Text(row['reference']?.toString() ?? ''),
                Text(adminWhen(row['purchasedAt'])),
              ],
          ],
        ),
      ],
    );
  }

  Widget _campaigns() {
    final rows = _maps('campaigns');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminDataTable(
          columns: const ['Name', 'Kind', 'Status', 'Updated'],
          rows: [
            for (final row in rows)
              [
                Text(row['name']?.toString() ?? ''),
                Text(row['kind']?.toString() ?? ''),
                AdminStatusBadge(label: row['status']?.toString() ?? ''),
                Text(adminWhen(row['updatedAt'])),
              ],
          ],
        ),
      ],
    );
  }

  Widget _engagement(DashboardColors colors) {
    final engagement =
        _data['engagement'] is Map
            ? Map<String, dynamic>.from(_data['engagement'] as Map)
            : <String, dynamic>{};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in engagement.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(color: colors.text, fontSize: 16),
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _maps(String key) {
    final value = _data[key];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}
