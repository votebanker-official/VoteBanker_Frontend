import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../models/volunteer_models.dart';
import '../services/volunteer_service.dart';
import 'volunteer_form_screen.dart';

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({
    required this.volunteerId,
    this.service,
    this.teams = const [],
    super.key,
  });

  final String volunteerId;
  final VolunteerService? service;
  final List<VolunteerTeam> teams;

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  late final VolunteerService _service = widget.service ?? VolunteerService();
  VolunteerRecord? _volunteer;
  List<VolunteerTask> _tasks = const [];
  List<VolunteerActivity> _activity = const [];
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _service.getVolunteer(widget.volunteerId);
      if (!mounted) return;
      setState(() {
        _volunteer = result.volunteer;
        _tasks = result.tasks;
        _activity = result.activity;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _edit() async {
    final volunteer = _volunteer;
    if (volunteer == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VolunteerFormScreen(
          service: _service,
          volunteer: volunteer,
          teams: widget.teams,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _assignTeam() async {
    final volunteer = _volunteer;
    if (volunteer == null) return;
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.line('volAssignTeam')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(l10n.line('volUnassigned')),
            ),
            for (final team in widget.teams)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, team.id),
                child: Text('${team.name} (${team.memberCount})'),
              ),
          ],
        );
      },
    );
    if (selected == null) return;
    try {
      await _service.updateVolunteer(volunteer.id, {
        'teamId': selected.isEmpty ? null : selected,
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.line('volSaved'))),
      );
    } on VolunteerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.code)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final volunteer = _volunteer;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        l10n.line('volProfile'),
                        style: AppTextStyles.headline(context),
                      ),
                    ),
                    if (volunteer != null) ...[
                      TextButton(
                        onPressed: _assignTeam,
                        child: Text(l10n.line('volAssignTeam')),
                      ),
                      FilledButton(
                        onPressed: _edit,
                        child: Text(l10n.line('volEdit')),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _failed || volunteer == null
                            ? Center(
                                child: Text(
                                  l10n.line('volLoadError'),
                                  style: AppTextStyles.body(context),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                children: [
                                  AppCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volunteer.fullName,
                                          style: AppTextStyles.headline(context),
                                        ),
                                        const SizedBox(height: 8),
                                        _InfoRow(l10n.line('volId'), volunteer.volunteerCode),
                                        _InfoRow(l10n.line('volMobile'), volunteer.mobile),
                                        _InfoRow(
                                          l10n.line('volEmail'),
                                          volunteer.email?.isNotEmpty == true
                                              ? volunteer.email!
                                              : '—',
                                        ),
                                        _InfoRow(l10n.line('volRole'), volunteer.role),
                                        _InfoRow(
                                          l10n.line('volTeam'),
                                          volunteer.teamName ?? l10n.line('volUnassigned'),
                                        ),
                                        _InfoRow(l10n.line('volStatus'), volunteer.status),
                                        _InfoRow(
                                          l10n.line('volRegistered'),
                                          _formatDate(volunteer.registeredAt),
                                        ),
                                        if (volunteer.skills?.isNotEmpty == true)
                                          _InfoRow(l10n.line('volSkills'), volunteer.skills!),
                                        if (volunteer.availability?.isNotEmpty == true)
                                          _InfoRow(
                                            l10n.line('volAvailability'),
                                            volunteer.availability!,
                                          ),
                                        if (volunteer.notes?.isNotEmpty == true)
                                          _InfoRow(l10n.line('volNotes'), volunteer.notes!),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(l10n.line('volTasks'), style: AppTextStyles.label(context)),
                                  const SizedBox(height: 8),
                                  if (_tasks.isEmpty)
                                    Text(l10n.line('volNoTasks'), style: AppTextStyles.muted(context))
                                  else
                                    for (final task in _tasks)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: AppCard(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(task.title, style: AppTextStyles.label(context)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${task.status} · ${task.priority}',
                                                style: AppTextStyles.muted(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.line('volActivity'),
                                    style: AppTextStyles.label(context),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_activity.isEmpty)
                                    Text(
                                      l10n.line('volNoActivity'),
                                      style: AppTextStyles.muted(context),
                                    )
                                  else
                                    for (final item in _activity)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          '${_formatDate(item.createdAt)} · ${item.action}'
                                          '${item.detail == null || item.detail!.isEmpty ? '' : ' · ${item.detail}'}',
                                          style: AppTextStyles.body(context),
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
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTextStyles.muted(context)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body(context))),
        ],
      ),
    );
  }
}
