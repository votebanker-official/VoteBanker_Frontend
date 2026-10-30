import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../app/routing/app_router.dart';
import '../../../core/services/theme_controller.dart';
import '../models/volunteer_dashboard.dart';
import '../models/volunteer_models.dart';
import '../services/volunteer_service.dart';

/// Volunteers directory backed by the existing volunteer API.
class VolunteerManagementScreen extends StatefulWidget {
  const VolunteerManagementScreen({
    this.service,
    this.initialOverview,
    this.initialVolunteers,
    super.key,
  });

  final VolunteerService? service;
  final VolunteerOverview? initialOverview;
  final List<VolunteerRecord>? initialVolunteers;

  @override
  State<VolunteerManagementScreen> createState() =>
      _VolunteerManagementScreenState();
}

class _VolunteerManagementScreenState extends State<VolunteerManagementScreen> {
  static const _pageSize = 5;

  final _search = TextEditingController();

  List<DashboardVolunteer> _volunteers = [];
  var _loading = false;

  String _status = '';
  String _location = '';
  String _skill = '';
  String _availability = '';
  var _page = 1;
  var _nameSort = 0;

  bool get _persist =>
      widget.initialVolunteers == null && widget.initialOverview == null;

  VolunteerService get _service => widget.service ?? VolunteerService();

  @override
  void initState() {
    super.initState();
    if (widget.initialVolunteers != null) {
      _volunteers = [
        for (final record in widget.initialVolunteers!)
          dashboardVolunteerFromRecord(record),
      ];
    } else if (widget.initialOverview != null) {
      _volunteers = [
        for (final record in widget.initialOverview!.recentVolunteers)
          dashboardVolunteerFromRecord(record),
      ];
    } else {
      _loading = true;
      _loadVolunteers();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DashboardVolunteer> get _visible {
    final query = _search.text.trim().toLowerCase();
    final rows = [
      for (final row in _volunteers)
        if (_matches(row, query)) row,
    ];
    if (_nameSort != 0) {
      rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()) * _nameSort);
    }
    return rows;
  }

  bool _matches(DashboardVolunteer row, String query) {
    if (query.isNotEmpty && !row.name.toLowerCase().contains(query)) return false;
    if (_status.isNotEmpty && row.status != _status) return false;
    if (_location.isNotEmpty && row.location != _location) return false;
    if (_skill.isNotEmpty && !row.skills.contains(_skill)) return false;
    if (_availability.isNotEmpty && (row.availability ?? '') != _availability) {
      return false;
    }
    return true;
  }

  List<String> _unique(Iterable<String> values) {
    final set = <String>{};
    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty) set.add(text);
    }
    return set.toList()..sort();
  }

  void _setFilter(void Function() change) {
    setState(() {
      change();
      _page = 1;
    });
  }

  Future<void> _loadVolunteers() async {
    try {
      final page = await _service.listVolunteers(page: 1, pageSize: 1000);
      if (!mounted) return;
      setState(() {
        _volunteers = [
          for (final record in page.volunteers) dashboardVolunteerFromRecord(record),
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Could not load volunteers.');
    }
  }

  Map<String, dynamic> _payload(DashboardVolunteer volunteer) {
    final location = volunteer.location.trim();
    return {
      'fullName': volunteer.name,
      'mobile': volunteer.phone ?? '',
      'email': volunteer.email,
      'role': volunteer.role.trim().isEmpty ? 'General Volunteer' : volunteer.role,
      'location': location.isEmpty || location == '—' ? null : location,
      'skills': volunteer.skills.join(', '),
      'availability': volunteer.availability,
      'status': volunteerStatusValue(volunteer.status),
      'notes': volunteer.notes,
    };
  }

  Future<void> _addOrEdit({DashboardVolunteer? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _VolunteerFormDialog(
        existing: existing,
        id: existing?.id ?? 'vol-${DateTime.now().microsecondsSinceEpoch}',
        onSave: (volunteer) => _commitVolunteer(volunteer, existing: existing),
      ),
    );
    if (saved == true && mounted) {
      _toast(existing == null ? 'Volunteer added.' : 'Volunteer updated.');
    }
  }

  Future<String?> _commitVolunteer(
    DashboardVolunteer saved, {
    DashboardVolunteer? existing,
  }) async {
    if (!_persist) {
      setState(() => _storeVolunteer(saved, existing: existing));
      return null;
    }
    try {
      final record = existing == null
          ? await _service.createVolunteer(_payload(saved))
          : await _service.updateVolunteer(existing.id, _payload(saved));
      if (!mounted) return 'Could not save the volunteer.';
      setState(() => _storeVolunteer(dashboardVolunteerFromRecord(record), existing: existing));
      // #region agent log
      _agentLog('H3', 'save succeeded', {
        'runId': 'post-fix',
        'created': existing == null,
        'hasEmail': (saved.email ?? '').isNotEmpty,
      });
      // #endregion
      return null;
    } catch (error) {
      // #region agent log
      _agentLog('H3', 'save failed', {
        'runId': 'post-fix',
        'code': error is VolunteerException ? error.code : error.runtimeType.toString(),
      });
      // #endregion
      return _errorText(error, removing: false);
    }
  }

  void _storeVolunteer(DashboardVolunteer saved, {DashboardVolunteer? existing}) {
    if (existing == null) {
      _volunteers = [saved, ..._volunteers];
      _page = 1;
      return;
    }
    _volunteers = [
      for (final row in _volunteers)
        if (row.id == existing.id) saved else row,
    ];
  }

  Future<void> _view(DashboardVolunteer volunteer) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _VolunteerDetailsDialog(volunteer: volunteer),
    );
  }

  Future<void> _delete(DashboardVolunteer volunteer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove volunteer'),
        content: const Text(
          'Are you sure you want to permanently remove this volunteer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove Volunteer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_persist) {
      try {
        await _service.deleteVolunteer(volunteer.id);
      } catch (error) {
        if (!mounted) return;
        _toast(_errorText(error, removing: true));
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _volunteers = _volunteers.where((row) => row.id != volunteer.id).toList();
      final pages = _visible.isEmpty ? 1 : (_visible.length / _pageSize).ceil();
      if (_page > pages) _page = pages;
    });
    _toast('Volunteer removed.');
  }

  String _errorText(Object error, {required bool removing}) {
    final code = error is VolunteerException ? error.code : '';
    return switch (code) {
      'invalid_phone' => 'Enter a valid phone number.',
      'invalid_email' => 'Enter a valid email address.',
      'invalid_name' => 'Enter a valid name.',
      'unauthorized' => 'Sign in again to save volunteers.',
      'not_found' => 'That volunteer is no longer in the database.',
      'duplicate_mobile' => 'A volunteer with this phone number already exists.',
      'volunteers_not_ready' => 'Volunteer storage is not ready.',
      _ => removing
          ? 'Could not remove the volunteer. It is still saved.'
          : 'Could not save the volunteer.',
    };
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.dashboard);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleTheme() {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    scope?.controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = _DashColors(dark);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: colors.page,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  colors: colors,
                  onBack: _goBack,
                  onHelp: _showHelp,
                  onTheme: _toggleTheme,
                  onAlerts: _showAlerts,
                ),
                Expanded(child: _volunteersBody(colors, constraints.maxWidth)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _volunteersBody(_DashColors colors, double width) {
    final compact = width < 1180;
    final visible = _visible;
    final pageCount = visible.isEmpty ? 1 : (visible.length / _pageSize).ceil();
    final page = _page.clamp(1, pageCount);
    final start = (page - 1) * _pageSize;
    final slice = visible.skip(start).take(_pageSize).toList();
    final from = visible.isEmpty ? 0 : start + 1;
    final to = visible.isEmpty ? 0 : start + slice.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 22, compact ? 16 : 28, 28),
      children: [
        _Heading(colors: colors, onAdd: () => _addOrEdit()),
        const SizedBox(height: 18),
        _FilterCard(
          colors: colors,
          search: _search,
          status: _status,
          location: _location,
          skill: _skill,
          availability: _availability,
          statuses: _unique(_volunteers.map((row) => row.status)),
          locations: _unique(_volunteers.map((row) => row.location)),
          skills: _unique(_volunteers.expand((row) => row.skills)),
          availabilities: _unique(
            _volunteers.map((row) => row.availability ?? ''),
          ),
          stacked: width < 1100,
          onSearch: () => _setFilter(() {}),
          onStatus: (value) => _setFilter(() => _status = value),
          onLocation: (value) => _setFilter(() => _location = value),
          onSkill: (value) => _setFilter(() => _skill = value),
          onAvailability: (value) => _setFilter(() => _availability = value),
        ),
        const SizedBox(height: 16),
        _TableCard(
          colors: colors,
          volunteers: slice,
          from: from,
          to: to,
          total: visible.length,
          page: page,
          pageCount: pageCount,
          nameSort: _nameSort,
          onSortName: () => setState(() {
            _nameSort = _nameSort == 1 ? -1 : 1;
          }),
          onPage: (next) => setState(() => _page = next),
          onView: _view,
          onEdit: (volunteer) => _addOrEdit(existing: volunteer),
          onDelete: _delete,
          loading: _loading,
          directoryEmpty: _volunteers.isEmpty && !_loading,
        ),
      ],
    );
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volunteers help'),
        content: const Text(
          'Search by name and combine the status, location, skill, and availability filters. Use the row actions to view, edit, or remove a volunteer.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlerts() async {
    final onboarding = _volunteers.where((row) => row.status == 'Onboarding').length;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Text(
          onboarding == 0
              ? 'No new notifications.'
              : '$onboarding volunteer${onboarding == 1 ? ' is' : 's are'} still onboarding.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DashColors {
  const _DashColors(this.dark);

  final bool dark;

  Color get page => dark ? const Color(0xFF0B1220) : const Color(0xFFF3F6FB);
  Color get card => dark ? const Color(0xFF121A2B) : Colors.white;
  Color get border => dark ? const Color(0xFF243044) : const Color(0xFFE5EDF5);
  Color get heading => dark ? const Color(0xFFF4F7FB) : const Color(0xFF12263F);
  Color get muted => dark ? const Color(0xFF93A4BA) : const Color(0xFF7C8DA3);
  Color get link => const Color(0xFF1D6FE8);
  Color get button => const Color(0xFF1E4ED8);
  Color get field => dark ? const Color(0xFF0E1726) : Colors.white;
  Color get skillBg => dark ? const Color(0xFF1C2838) : const Color(0xFFF2F4F7);
  Color get skillText => dark ? const Color(0xFFD5DEE8) : const Color(0xFF5E6E82);
  Color get availabilityBg => dark ? const Color(0xFF163056) : const Color(0xFFE8F1FF);
  Color get availabilityText => const Color(0xFF2F6FD0);
}

BoxDecoration _cardDecoration(_DashColors colors) {
  return BoxDecoration(
    color: colors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0C2342).withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.onBack,
    required this.onHelp,
    required this.onTheme,
    required this.onAlerts,
  });

  final _DashColors colors;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onTheme;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: colors.heading),
            ),
            const Spacer(),
            _RoundIconButton(
              colors: colors,
              icon: Icons.help_outline,
              tooltip: 'Help',
              onPressed: onHelp,
            ),
            const SizedBox(width: 8),
            _RoundIconButton(
              colors: colors,
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              tooltip: 'Theme',
              onPressed: onTheme,
            ),
            const SizedBox(width: 8),
            _RoundIconButton(
              colors: colors,
              icon: Icons.notifications_none,
              tooltip: 'Notifications',
              onPressed: onAlerts,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.colors,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final _DashColors colors;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.page,
        foregroundColor: colors.heading,
        side: BorderSide(color: colors.border),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.colors, required this.onAdd});

  final _DashColors colors;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.groups_outlined, color: colors.heading, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Volunteers',
            style: TextStyle(
              color: colors.heading,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _PrimaryButton(label: 'Add Volunteer', onPressed: onAdd),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1E4ED8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.colors,
    required this.search,
    required this.status,
    required this.location,
    required this.skill,
    required this.availability,
    required this.statuses,
    required this.locations,
    required this.skills,
    required this.availabilities,
    required this.stacked,
    required this.onSearch,
    required this.onStatus,
    required this.onLocation,
    required this.onSkill,
    required this.onAvailability,
  });

  final _DashColors colors;
  final TextEditingController search;
  final String status;
  final String location;
  final String skill;
  final String availability;
  final List<String> statuses;
  final List<String> locations;
  final List<String> skills;
  final List<String> availabilities;
  final bool stacked;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onLocation;
  final ValueChanged<String> onSkill;
  final ValueChanged<String> onAvailability;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      key: const Key('volunteer-search'),
      controller: search,
      onChanged: (_) => onSearch(),
      style: TextStyle(color: colors.heading, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.field,
        hintText: 'Search by name...',
        hintStyle: TextStyle(color: colors.muted, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: colors.muted, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _outline(colors),
        enabledBorder: _outline(colors),
        focusedBorder: _outline(colors, const Color(0xFF1E4ED8)),
      ),
    );
    final menus = [
      _FilterMenu(
        colors: colors,
        value: status,
        hint: 'All Statuses',
        options: statuses,
        onChanged: onStatus,
      ),
      _FilterMenu(
        colors: colors,
        value: location,
        hint: 'All Locations',
        options: locations,
        onChanged: onLocation,
      ),
      _FilterMenu(
        colors: colors,
        value: skill,
        hint: 'All Skills',
        options: skills,
        onChanged: onSkill,
      ),
      _FilterMenu(
        colors: colors,
        value: availability,
        hint: 'All Availability',
        options: availabilities,
        onChanged: onAvailability,
      ),
    ];
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: stacked
            ? Column(
                children: [
                  searchField,
                  for (final menu in menus) ...[
                    const SizedBox(height: 10),
                    menu,
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 5, child: searchField),
                  for (final menu in menus) ...[
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: menu),
                  ],
                ],
              ),
      ),
    );
  }
}

OutlineInputBorder _outline(_DashColors colors, [Color? color]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color ?? colors.border),
  );
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.colors,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final _DashColors colors;
  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = options.contains(value) ? value : '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: current,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down, color: colors.muted),
            style: TextStyle(color: colors.heading, fontSize: 14),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(hint, overflow: TextOverflow.ellipsis),
              ),
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (next) => onChanged(next ?? ''),
          ),
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.colors,
    required this.volunteers,
    required this.from,
    required this.to,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.nameSort,
    required this.onSortName,
    required this.onPage,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.loading,
    required this.directoryEmpty,
  });

  final _DashColors colors;
  final List<DashboardVolunteer> volunteers;
  final int from;
  final int to;
  final int total;
  final int page;
  final int pageCount;
  final int nameSort;
  final VoidCallback onSortName;
  final ValueChanged<int> onPage;
  final ValueChanged<DashboardVolunteer> onView;
  final ValueChanged<DashboardVolunteer> onEdit;
  final ValueChanged<DashboardVolunteer> onDelete;
  final bool loading;
  final bool directoryEmpty;

  @override
  Widget build(BuildContext context) {
    final showing = total == 0
        ? 'Showing 0 of 0 volunteers'
        : 'Showing $from–$to of $total volunteers';
    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < 1080 ? 1080.0 : constraints.maxWidth;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _HeaderRow(
                        colors: colors,
                        nameSort: nameSort,
                        onSortName: onSortName,
                      ),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (directoryEmpty)
                        const _DirectoryEmpty()
                      else if (volunteers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'No volunteers match your search.',
                            style: TextStyle(color: colors.muted),
                          ),
                        )
                      else
                        for (final volunteer in volunteers)
                          _VolunteerRow(
                            colors: colors,
                            volunteer: volunteer,
                            onView: () => onView(volunteer),
                            onEdit: () => onEdit(volunteer),
                            onDelete: () => onDelete(volunteer),
                          ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          showing,
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ),
                      _PageButton(
                        colors: colors,
                        icon: Icons.chevron_left,
                        enabled: page > 1,
                        onPressed: () => onPage(page - 1),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.button,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$page',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PageButton(
                        colors: colors,
                        icon: Icons.chevron_right,
                        enabled: page < pageCount,
                        onPressed: () => onPage(page + 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.colors,
    required this.nameSort,
    required this.onSortName,
  });

  final _DashColors colors;
  final int nameSort;
  final VoidCallback onSortName;

  @override
  Widget build(BuildContext context) {
    Text label(String text) {
      return Text(
        text,
        style: TextStyle(
          color: colors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 56, child: label('PHOTO')),
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onSortName,
                child: Row(
                  children: [
                    label('NAME'),
                    const SizedBox(width: 4),
                    Icon(
                      nameSort == -1 ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 3, child: label('LOCATION')),
            Expanded(flex: 3, child: label('STATUS')),
            Expanded(flex: 6, child: label('SKILLS')),
            Expanded(flex: 2, child: label('AVAILABILITY')),
            SizedBox(width: 132, child: label('ACTIONS')),
          ],
        ),
      ),
    );
  }
}

class _VolunteerRow extends StatelessWidget {
  const _VolunteerRow({
    required this.colors,
    required this.volunteer,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final _DashColors colors;
  final DashboardVolunteer volunteer;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: _InitialsAvatar(name: volunteer.name, radius: 18),
            ),
            Expanded(
              flex: 3,
              child: Text(
                volunteer.name,
                style: TextStyle(
                  color: colors.link,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 15, color: colors.muted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      volunteer.location,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.heading, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: _StatusPill(status: volunteer.status))),
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < volunteer.skills.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.skillBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            volunteer.skills[i],
                            style: TextStyle(
                              color: colors.skillText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: (volunteer.availability ?? '').isEmpty
                  ? Text('—', style: TextStyle(color: colors.muted, fontSize: 16))
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.availabilityBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            volunteer.availability!,
                            style: TextStyle(
                              color: colors.availabilityText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: 132,
              child: Row(
                children: [
                  _ActionIcon(
                    colors: colors,
                    icon: Icons.visibility_outlined,
                    tooltip: 'View',
                    onPressed: onView,
                  ),
                  const SizedBox(width: 6),
                  _ActionIcon(
                    colors: colors,
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onView();
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View details')),
                      PopupMenuItem(value: 'edit', child: Text('Edit volunteer')),
                      PopupMenuItem(value: 'delete', child: Text('Remove volunteer')),
                    ],
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC5D9F5)),
                      ),
                      child: Icon(Icons.more_horiz, size: 16, color: colors.link),
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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.colors,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final _DashColors colors;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: colors.link,
        backgroundColor: colors.card,
        side: const BorderSide(color: Color(0xFFC5D9F5)),
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 16),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final onboarding = status == 'Onboarding';
    final inactive = status == 'Inactive';
    final background = onboarding
        ? const Color(0xFFFFF4D8)
        : inactive
            ? const Color(0xFFEEF2F6)
            : const Color(0xFFE5F8EC);
    final foreground = onboarding
        ? const Color(0xFFC89212)
        : inactive
            ? const Color(0xFF5C6D82)
            : const Color(0xFF1E9D55);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: foreground,
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

class _DirectoryEmpty extends StatelessWidget {
  const _DirectoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 42, color: Color(0xFF8AA0B8)),
          SizedBox(height: 12),
          Text(
            'No volunteers found',
            style: TextStyle(
              color: Color(0xFF5E738C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Start by adding your first volunteer.',
            style: TextStyle(color: Color(0xFF8AA0B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.colors,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final _DashColors colors;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: colors.card,
        foregroundColor: colors.heading,
        disabledForegroundColor: colors.muted.withValues(alpha: 0.4),
        side: BorderSide(color: colors.border),
        minimumSize: const Size(34, 34),
        fixedSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.radius = 18});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF5B7CFA),
      Color(0xFF2FA36A),
      Color(0xFFE09A2B),
      Color(0xFF7C6BF2),
      Color(0xFF3D8BFF),
    ];
    final color = palette[name.hashCode.abs() % palette.length];
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : parts.length == 1
            ? parts.first.substring(0, 1).toUpperCase()
            : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}

class _VolunteerFormDialog extends StatefulWidget {
  const _VolunteerFormDialog({
    required this.id,
    required this.onSave,
    this.existing,
  });

  final String id;
  final DashboardVolunteer? existing;
  final Future<String?> Function(DashboardVolunteer volunteer) onSave;

  @override
  State<_VolunteerFormDialog> createState() => _VolunteerFormDialogState();
}

class _VolunteerFormDialogState extends State<_VolunteerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _skills;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  late String _status;
  late String _availability;
  var _saving = false;
  String? _error;

  static final _phonePattern = RegExp(r'^\+?[0-9][0-9\s-]{6,18}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final location = existing?.location ?? '';
    _name = TextEditingController(text: existing?.name ?? '');
    _location = TextEditingController(text: location == '—' ? '' : location);
    _skills = TextEditingController(text: existing?.skills.join(', ') ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _status = existing?.status ?? 'Active';
    _availability = existing?.availability ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _logEmailField());
  }

  void _logEmailField() {
    final render = _emailFieldKey.currentContext?.findRenderObject();
    final size = render is RenderBox && render.hasSize ? render.size : null;
    // #region agent log
    _agentLog('H1', 'email field layout', {
      'runId': 'post-fix',
      'width': size?.width ?? -1,
      'height': size?.height ?? -1,
      'hasBox': size != null,
    });
    // #endregion
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _skills.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      DashboardVolunteer(
        id: widget.id,
        name: _name.text.trim(),
        location: _location.text.trim(),
        status: _status,
        skills: splitVolunteerSkills(_skills.text),
        availability: _availability.isEmpty ? null : _availability,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        role: widget.existing?.role ?? 'General Volunteer',
      ),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final viewHeight = MediaQuery.sizeOf(context).height;
    final viewWidth = MediaQuery.sizeOf(context).width;
    final fieldWidth = viewWidth < 508 ? viewWidth - 80 : 460.0;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(editing ? 'Edit volunteer' : 'Add Volunteer'),
      content: SizedBox(
        width: fieldWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: viewHeight * 0.62),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _labeledField(
                    label: 'Full Name',
                    field: TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Enter full name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Name is required.' : null,
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  _labeledField(
                    label: 'Location',
                    field: TextFormField(
                      controller: _location,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Enter location'),
                    ),
                  ),
                  _labeledField(
                    label: 'Status',
                    field: _choiceField(
                      value: _status,
                      items: [
                        for (final status in dashboardStatuses)
                          DropdownMenuItem(value: status, child: Text(status)),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _status = value);
                            },
                    ),
                  ),
                  _labeledField(
                    label: 'Skills',
                    field: TextFormField(
                      controller: _skills,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Select or enter skills'),
                    ),
                  ),
                  _labeledField(
                    label: 'Availability',
                    field: _choiceField(
                      value: _availability,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Not set')),
                        DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                        DropdownMenuItem(value: 'Ad Hoc', child: Text('Ad Hoc')),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _availability = value);
                            },
                    ),
                  ),
                  _labeledField(
                    label: 'Email',
                    field: TextFormField(
                      key: _emailFieldKey,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Enter email address').copyWith(
                        constraints: const BoxConstraints(minHeight: 52),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address.';
                        return null;
                      },
                    ),
                  ),
                  _labeledField(
                    label: 'Phone',
                    field: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Enter phone number'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        if (!_phonePattern.hasMatch(text)) return 'Enter a valid phone number.';
                        return null;
                      },
                    ),
                  ),
                  _labeledField(
                    label: 'Notes',
                    field: TextFormField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDecoration('Enter notes'),
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _choiceField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final decoration = Theme.of(context).inputDecorationTheme;
    final border = decoration.enabledBorder;
    final radius = border is OutlineInputBorder ? border.borderRadius : BorderRadius.circular(14);
    final borderColor = border is OutlineInputBorder ? border.borderSide.color : const Color(0xFF2A4562);
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: decoration.fillColor,
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              borderRadius: radius is BorderRadius ? radius : BorderRadius.circular(14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget field}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF12263F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          field,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      errorMaxLines: 2,
    );
  }
}

void _agentLog(String hypothesisId, String message, Map<String, Object?> data) {
  // #region agent log
  http
      .post(
        Uri.parse('http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c'),
        headers: const {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': '89cc1e',
        },
        body: jsonEncode({
          'sessionId': '89cc1e',
          'hypothesisId': hypothesisId,
          'location': 'volunteer_management_screen.dart',
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      )
      .catchError((_) => http.Response('', 500));
  // #endregion
}

class _VolunteerDetailsDialog extends StatelessWidget {
  const _VolunteerDetailsDialog({required this.volunteer});

  final DashboardVolunteer volunteer;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: Color(0xFF7C8DA3))),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(volunteer.name),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('Location', volunteer.location),
            row('Status', volunteer.status),
            row(
              'Skills',
              volunteer.skills.isEmpty ? '—' : volunteer.skills.join(', '),
            ),
            row('Availability', volunteer.availability ?? '—'),
            row('Email', volunteer.email ?? '—'),
            row('Phone', volunteer.phone ?? '—'),
            row('Notes', volunteer.notes ?? '—'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

