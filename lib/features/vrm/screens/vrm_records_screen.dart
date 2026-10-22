import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../models/vrm_voter_record.dart';
import '../services/vrm_service.dart';
import '../../social_media/social_contact_links.dart';

class VrmRecordsScreen extends StatefulWidget {
  const VrmRecordsScreen({super.key, this.service});

  final VrmService? service;

  @override
  State<VrmRecordsScreen> createState() => _VrmRecordsScreenState();
}

class _VrmRecordsScreenState extends State<VrmRecordsScreen> {
  late final VrmService _service = widget.service ?? VrmService();
  final _search = TextEditingController();

  List<VrmVoterRecord> _records = const [];
  bool _loading = true;
  String? _error;
  String _activeQuery = '';
  final Set<String> _dirtyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (query != null) {
        _activeQuery = query;
      }
    });

    try {
      final rows = await _service.listRecords(query: _activeQuery);
      if (!mounted) return;
      setState(() {
        _records = rows;
        _loading = false;
      });
    } on VrmException catch (error) {
      if (!mounted) return;
      setState(() {
        _records = const [];
        _loading = false;
        _error = error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _records = const [];
        _loading = false;
        _error = 'load_failed';
      });
    }
  }

  void _replaceRecord(VrmVoterRecord updated) {
    setState(() {
      _dirtyIds.remove(updated.id);
      _records = [
        for (final row in _records)
          if (row.id == updated.id) updated else row,
      ];
    });
  }

  void _setDirty(String id, bool dirty) {
    final changed = dirty ? _dirtyIds.add(id) : _dirtyIds.remove(id);
    if (changed && mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (_dirtyIds.isEmpty) {
      AppRouter.back(context, AppRoutes.dashboard);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.line('vrmUnsavedTitle')),
        content: Text(l10n.line('vrmUnsavedBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.line('vrmStay')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.line('vrmLeave')),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _dirtyIds.clear());
      AppRouter.back(context, AppRoutes.dashboard);
    }
  }

  String _message(AppLocalizations l10n, String code) {
    switch (code) {
      case 'unreachable':
        return l10n.line('vrmUnreachable');
      default:
        return l10n.line('vrmLoadError');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _leave(),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l10n.back,
                    ),
                    Expanded(
                      child: Text(l10n.cardVrm, style: AppTextStyles.headline(context)),
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => _load(),
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.line('vrmRefresh'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.line('vrmRecordsBody'), style: AppTextStyles.muted(context)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _load(query: value.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.line('vrmSearchHint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => _load(query: _search.text.trim()),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _message(l10n, _error!),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body(context)
                                        .copyWith(color: palette.danger),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => _load(),
                                    child: Text(l10n.line('vrmRetry')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _records.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      l10n.line('vrmEmpty'),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.muted(context),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _PayToGetMoreButton(
                                    onPressed: () =>
                                        AppRouter.open(context, AppRoutes.vrmGetMore),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                itemCount: _records.length + 1,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index == _records.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                                      child: _PayToGetMoreButton(
                                        onPressed: () => AppRouter.open(
                                          context,
                                          AppRoutes.vrmGetMore,
                                        ),
                                      ),
                                    );
                                  }
                                  final item = _records[index];
                                  return _VoterRecordCard(
                                    key: ValueKey(item.id),
                                    record: item,
                                    service: _service,
                                    onSaved: _replaceRecord,
                                    onDirtyChanged: (dirty) => _setDirty(item.id, dirty),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayToGetMoreButton extends StatelessWidget {
  const _PayToGetMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(l10n.line('vrmPayToGetMore')),
      ),
    );
  }
}

class _VoterRecordCard extends StatefulWidget {
  const _VoterRecordCard({
    required this.record,
    required this.service,
    required this.onSaved,
    required this.onDirtyChanged,
    super.key,
  });

  final VrmVoterRecord record;
  final VrmService service;
  final ValueChanged<VrmVoterRecord> onSaved;
  final ValueChanged<bool> onDirtyChanged;

  @override
  State<_VoterRecordCard> createState() => _VoterRecordCardState();
}

class _VoterRecordCardState extends State<_VoterRecordCard> {
  late final TextEditingController _whatsapp;
  late final TextEditingController _instagram;
  late final TextEditingController _facebook;
  bool _saving = false;
  String? _status;
  bool _reportedDirty = false;

  @override
  void initState() {
    super.initState();
    _whatsapp = TextEditingController(text: widget.record.whatsappContact ?? '');
    _instagram = TextEditingController(text: widget.record.instagramContact ?? '');
    _facebook = TextEditingController(text: widget.record.facebookContact ?? '');
    for (final controller in [_whatsapp, _instagram, _facebook]) {
      controller.addListener(_notifyDirty);
    }
  }

  @override
  void didUpdateWidget(covariant _VoterRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameId = oldWidget.record.id == widget.record.id;
    final contactsChanged = oldWidget.record.whatsappContact != widget.record.whatsappContact ||
        oldWidget.record.instagramContact != widget.record.instagramContact ||
        oldWidget.record.facebookContact != widget.record.facebookContact;
    if (!sameId || (contactsChanged && !_isDirty)) {
      _whatsapp.text = widget.record.whatsappContact ?? '';
      _instagram.text = widget.record.instagramContact ?? '';
      _facebook.text = widget.record.facebookContact ?? '';
      _status = null;
      _notifyDirty();
    }
  }

  @override
  void dispose() {
    _whatsapp.dispose();
    _instagram.dispose();
    _facebook.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _whatsapp.text.trim() != (widget.record.whatsappContact ?? '') ||
        _instagram.text.trim() != (widget.record.instagramContact ?? '') ||
        _facebook.text.trim() != (widget.record.facebookContact ?? '');
  }

  void _notifyDirty() {
    final dirty = _isDirty;
    if (dirty == _reportedDirty) return;
    _reportedDirty = dirty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onDirtyChanged(_isDirty);
    });
  }

  bool get _contactsValid {
    return SocialContactLinks.validWhatsapp(_whatsapp.text) &&
        SocialContactLinks.validProfile(_instagram.text, SocialContactLinks.instagramHosts) &&
        SocialContactLinks.validProfile(_facebook.text, SocialContactLinks.facebookHosts);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_contactsValid) {
      setState(() => _status = l10n.line('vrmContactInvalid'));
      return;
    }
    setState(() {
      _saving = true;
      _status = l10n.line('vrmContactSaving');
    });
    try {
      final updated = await widget.service.saveContacts(
        recordId: widget.record.id,
        whatsappContact: _whatsapp.text.trim(),
        instagramContact: _instagram.text.trim(),
        facebookContact: _facebook.text.trim(),
      );
      if (!mounted) return;
      widget.onSaved(updated);
      setState(() {
        _saving = false;
        _status = l10n.line('vrmContactSaved');
      });
    } on VrmException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'unauthorized' => l10n.line('vrmContactSignIn'),
        'forbidden' => l10n.line('vrmContactForbidden'),
        'invalid_contact' => l10n.line('vrmContactInvalid'),
        _ => l10n.line('vrmContactSaveError'),
      };
      setState(() {
        _saving = false;
        _status = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _status = l10n.line('vrmContactSaveError');
      });
    }
  }

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final item = widget.record;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: AppTextStyles.label(context)),
          const SizedBox(height: 8),
          Text(
            '${l10n.line('vrmEpic')}: ${item.epicNumber ?? '—'}',
            style: AppTextStyles.body(context),
          ),
          Text(
            '${l10n.line('vrmAge')}: ${item.age?.toString() ?? '—'}'
            '   ${l10n.line('vrmGender')}: ${item.gender ?? '—'}',
            style: AppTextStyles.muted(context),
          ),
          if (item.needsReview)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.line('vrmNeedsReview'),
                style: AppTextStyles.muted(context).copyWith(color: palette.campaign),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    l10n.line('vrmWhatsapp'),
                    l10n.line('vrmWhatsappHint'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _instagram,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    l10n.line('vrmInstagram'),
                    l10n.line('vrmInstagramHint'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _facebook,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saving ? null : _save(),
                  decoration: _fieldDecoration(
                    l10n.line('vrmFacebook'),
                    l10n.line('vrmFacebookHint'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.line('vrmContactSave')),
              ),
              if (_status != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status!,
                    style: AppTextStyles.muted(context).copyWith(
                      color: _status == l10n.line('vrmContactSaved')
                          ? palette.success
                          : (_status == l10n.line('vrmContactSaving')
                              ? palette.textMuted
                              : palette.danger),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
