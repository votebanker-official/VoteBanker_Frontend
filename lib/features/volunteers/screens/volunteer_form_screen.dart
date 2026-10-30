import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../models/volunteer_models.dart';
import '../services/volunteer_service.dart';

class VolunteerFormScreen extends StatefulWidget {
  const VolunteerFormScreen({
    this.service,
    this.volunteer,
    this.teams = const [],
    this.asApplication = false,
    super.key,
  });

  final VolunteerService? service;
  final VolunteerRecord? volunteer;
  final List<VolunteerTeam> teams;
  final bool asApplication;

  @override
  State<VolunteerFormScreen> createState() => _VolunteerFormScreenState();
}

class _VolunteerFormScreenState extends State<VolunteerFormScreen> {
  late final VolunteerService _service = widget.service ?? VolunteerService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _skills;
  late final TextEditingController _availability;
  late final TextEditingController _notes;
  late String _role;
  late String _status;
  String? _teamId;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final volunteer = widget.volunteer;
    _name = TextEditingController(text: volunteer?.fullName ?? '');
    _mobile = TextEditingController(text: volunteer?.mobile ?? '');
    _email = TextEditingController(text: volunteer?.email ?? '');
    _skills = TextEditingController(text: volunteer?.skills ?? '');
    _availability = TextEditingController(text: volunteer?.availability ?? '');
    _notes = TextEditingController(text: volunteer?.notes ?? '');
    _role = volunteer?.role ?? volunteerRoles.first;
    _status = volunteer?.status ?? 'active';
    _teamId = volunteer?.teamId;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _skills.dispose();
    _availability.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final payload = <String, dynamic>{
        'fullName': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'role': _role,
        'skills': _skills.text.trim().isEmpty ? null : _skills.text.trim(),
        'availability':
            _availability.text.trim().isEmpty ? null : _availability.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      };
      if (widget.asApplication) {
        await _service.createApplication(payload);
      } else {
        payload['teamId'] = _teamId;
        payload['status'] = _status;
        if (widget.volunteer == null) {
          await _service.createVolunteer(payload);
        } else {
          await _service.updateVolunteer(widget.volunteer!.id, payload);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.line('volSaved'))),
      );
      Navigator.of(context).pop(true);
    } on VolunteerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(l10n, error.code))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(AppLocalizations l10n, String code) {
    return switch (code) {
      'unauthorized' => l10n.line('volSignIn'),
      'invalid_phone' => l10n.line('volInvalidPhone'),
      'invalid_email' => l10n.line('volInvalidEmail'),
      'duplicate_mobile' => l10n.line('volDuplicateMobile'),
      'volunteers_not_ready' => l10n.line('volNotReady'),
      _ => l10n.line('volSaveError'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editing = widget.volunteer != null;
    final title = widget.asApplication
        ? l10n.line('volNewApplication')
        : editing
            ? l10n.line('volEdit')
            : l10n.line('volAdd');

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
                      child: Text(title, style: AppTextStyles.headline(context)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        AppCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _name,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volFullName'),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.line('volRequired');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _mobile,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volMobile'),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return l10n.line('volRequired');
                                    }
                                    if (!RegExp(r'^\+?[0-9][0-9\s-]{6,18}$')
                                        .hasMatch(text)) {
                                      return l10n.line('volInvalidPhone');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _email,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volEmail'),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) return null;
                                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(text)) {
                                      return l10n.line('volInvalidEmail');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _role,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volRole'),
                                  ),
                                  items: [
                                    for (final role in volunteerRoles)
                                      DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _role = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _skills,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volSkills'),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _availability,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volAvailability'),
                                  ),
                                  maxLines: 2,
                                ),
                                if (!widget.asApplication) ...[
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String?>(
                                    initialValue: _teamId,
                                    decoration: InputDecoration(
                                      labelText: l10n.line('volTeam'),
                                    ),
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(l10n.line('volUnassigned')),
                                      ),
                                      for (final team in widget.teams)
                                        DropdownMenuItem<String?>(
                                          value: team.id,
                                          child: Text(team.name),
                                        ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _teamId = value),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _status,
                                    decoration: InputDecoration(
                                      labelText: l10n.line('volStatus'),
                                    ),
                                    items: [
                                      for (final status in volunteerStatuses)
                                        DropdownMenuItem(
                                          value: status,
                                          child: Text(_statusLabel(l10n, status)),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _status = value);
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _notes,
                                  decoration: InputDecoration(
                                    labelText: l10n.line('volNotes'),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _saving ? null : _save,
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l10n.line('volSave')),
                                ),
                              ],
                            ),
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

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'active' => l10n.line('volStatusActive'),
      'inactive' => l10n.line('volStatusInactive'),
      'pending' => l10n.line('volStatusPending'),
      _ => status,
    };
  }
}
