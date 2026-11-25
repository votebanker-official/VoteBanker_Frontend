import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/person_name.dart';
import '../models/vrm_voter_record.dart';
import '../services/vrm_service.dart';
import '../../social_media/social_contact_links.dart';

enum _VoterFilter { all, complete, incomplete, review }

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _complete = Color(0xFF16A34A);
const _completeDeep = Color(0xFF15803D);
const _incomplete = Color(0xFFE11D48);
const _review = Color(0xFFD97706);

AppPalette _vrmPalette(BuildContext context) {
  return Theme.of(context).extension<AppPalette>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}

Color _primaryTextColor(BuildContext context) {
  final palette = _vrmPalette(context);
  return palette.isDark ? palette.text : _ink;
}

Color _secondaryTextColor(BuildContext context) {
  final palette = _vrmPalette(context);
  return palette.isDark ? palette.textMuted : _muted;
}

Color _recordStatusColor(BuildContext context, bool complete) {
  final palette = _vrmPalette(context);
  if (!palette.isDark) return complete ? _complete : _incomplete;
  return complete ? palette.success : palette.danger;
}

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
  _VoterFilter _filter = _VoterFilter.all;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (mounted) setState(() {});
    });
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

  Future<bool> _confirmLeave() async {
    if (_dirtyIds.isEmpty) return true;
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
    return leave == true && mounted;
  }

  Future<void> _leave() async {
    if (!await _confirmLeave()) return;
    if (_dirtyIds.isNotEmpty) {
      setState(() => _dirtyIds.clear());
    }
    AppRouter.back(context, AppRoutes.dashboard);
  }

  Future<void> _skipToCampaignTemplates() async {
    if (!await _confirmLeave()) return;
    if (_dirtyIds.isNotEmpty) {
      setState(() => _dirtyIds.clear());
    }
    AppRouter.open(context, AppRoutes.campaignTemplates);
  }

  String _message(AppLocalizations l10n, String code) {
    switch (code) {
      case 'unreachable':
        return l10n.line('vrmUnreachable');
      default:
        return l10n.line('vrmLoadError');
    }
  }

  List<VrmVoterRecord> get _visible {
    return switch (_filter) {
      _VoterFilter.all => _records,
      _VoterFilter.complete => _records.where(_savedComplete).toList(),
      _VoterFilter.incomplete =>
        _records.where((row) => !_savedComplete(row)).toList(),
      _VoterFilter.review => _records.where((row) => row.needsReview).toList(),
    };
  }

  void _searchNow() => _load(query: _search.text.trim());

  void _clearSearch() {
    _search.clear();
    _load(query: '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: _vrmPalette(context).background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 24 : 12,
                      12,
                      wide ? 24 : 12,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RecordsHeader(
                          title: l10n.cardVrm,
                          countLabel: l10n
                              .line('vrmRecordCount')
                              .replaceAll('{count}', '${_records.length}'),
                          subtitle: l10n.line('vrmRecordsBody'),
                          backTooltip: l10n.back,
                          refreshTooltip: l10n.line('vrmRefresh'),
                          skipLabel: l10n.line('blueTikSkip'),
                          onBack: _leave,
                          onRefresh: _loading ? null : () => _load(),
                          onSkip: _skipToCampaignTemplates,
                        ),
                        const SizedBox(height: 14),
                        _SearchBar(
                          controller: _search,
                          hint: l10n.line('vrmSearchHint'),
                          showClear: _search.text.isNotEmpty,
                          onSubmit: _searchNow,
                          onClear: _clearSearch,
                        ),
                        if (!_loading &&
                            _error == null &&
                            _records.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _FilterPills(
                            records: _records,
                            selected: _filter,
                            allLabel: l10n.line('vrmFilterAll'),
                            completeLabel: 'Complete',
                            incompleteLabel: 'Incomplete',
                            reviewLabel: l10n.line('vrmNeedsReview'),
                            onSelected:
                                (value) => setState(() => _filter = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _body(context, l10n, wide)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, bool wide) {
    final pad = EdgeInsets.fromLTRB(wide ? 24 : 12, 0, wide ? 24 : 12, 28);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _message(l10n, _error!),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: _incomplete),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _load(),
                child: Text(l10n.line('vrmRetry')),
              ),
            ],
          ),
        ),
      );
    }
    final rows = _visible;
    if (_records.isEmpty) {
      return ListView(
        padding: pad,
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
            onPressed: () => AppRouter.open(context, AppRoutes.vrmGetMore),
          ),
        ],
      );
    }
    return ListView.separated(
      cacheExtent: 900,
      padding: pad,
      itemCount: rows.length + 1,
      separatorBuilder: (_, __) => SizedBox(height: wide ? 16 : 12),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: _PayToGetMoreButton(
              onPressed: () => AppRouter.open(context, AppRoutes.vrmGetMore),
            ),
          );
        }
        final item = rows[index];
        return _VoterRecordCard(
          key: ValueKey(item.id),
          record: item,
          wide: wide,
          service: _service,
          onSaved: _replaceRecord,
          onDirtyChanged: (dirty) => _setDirty(item.id, dirty),
        );
      },
    );
  }
}

bool _savedComplete(VrmVoterRecord item) {
  final hasCore =
      item.name.trim().isNotEmpty &&
      item.age != null &&
      (item.gender?.trim().isNotEmpty ?? false) &&
      (item.epicNumber?.trim().isNotEmpty ?? false);
  if (!hasCore) return false;
  final whatsapp = item.whatsappContact?.trim() ?? '';
  final instagram = item.instagramContact?.trim() ?? '';
  final facebook = item.facebookContact?.trim() ?? '';
  if (whatsapp.isEmpty || instagram.isEmpty || facebook.isEmpty) return false;
  return SocialContactLinks.validWhatsapp(whatsapp) &&
      SocialContactLinks.validProfile(
        instagram,
        SocialContactLinks.instagramHosts,
      ) &&
      SocialContactLinks.validProfile(
        facebook,
        SocialContactLinks.facebookHosts,
      );
}

class _PayToGetMoreButton extends StatelessWidget {
  const _PayToGetMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = _vrmPalette(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              palette.isDark ? palette.accent : const Color(0xFF1D4ED8),
          backgroundColor:
              palette.isDark ? palette.surfaceSecondary : Colors.white,
          side: BorderSide(
            color: palette.isDark ? palette.border : const Color(0xFFBFDBFE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          l10n.line('vrmPayToGetMore'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
    required this.wide,
    super.key,
  });

  final VrmVoterRecord record;
  final VrmService service;
  final ValueChanged<VrmVoterRecord> onSaved;
  final ValueChanged<bool> onDirtyChanged;
  final bool wide;

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
    _whatsapp = TextEditingController(
      text: widget.record.whatsappContact ?? '',
    );
    _instagram = TextEditingController(
      text: widget.record.instagramContact ?? '',
    );
    _facebook = TextEditingController(
      text: widget.record.facebookContact ?? '',
    );
    for (final controller in [_whatsapp, _instagram, _facebook]) {
      controller.addListener(_onContactChanged);
    }
  }

  @override
  void didUpdateWidget(covariant _VoterRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameId = oldWidget.record.id == widget.record.id;
    final contactsChanged =
        oldWidget.record.whatsappContact != widget.record.whatsappContact ||
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

  void _onContactChanged() {
    if (mounted) setState(() {});
    _notifyDirty();
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
        SocialContactLinks.validProfile(
          _instagram.text,
          SocialContactLinks.instagramHosts,
        ) &&
        SocialContactLinks.validProfile(
          _facebook.text,
          SocialContactLinks.facebookHosts,
        );
  }

  /// Green only when core voter fields AND WhatsApp, Instagram, Facebook
  /// are all filled with valid values. Any empty social field = red.
  bool get _detailsComplete {
    final item = widget.record;
    final hasCore =
        item.name.trim().isNotEmpty &&
        item.age != null &&
        (item.gender?.trim().isNotEmpty ?? false) &&
        (item.epicNumber?.trim().isNotEmpty ?? false);
    if (!hasCore) return false;

    final whatsapp = _whatsapp.text.trim();
    final instagram = _instagram.text.trim();
    final facebook = _facebook.text.trim();
    if (whatsapp.isEmpty || instagram.isEmpty || facebook.isEmpty) {
      return false;
    }
    return SocialContactLinks.validWhatsapp(whatsapp) &&
        SocialContactLinks.validProfile(
          instagram,
          SocialContactLinks.instagramHosts,
        ) &&
        SocialContactLinks.validProfile(
          facebook,
          SocialContactLinks.facebookHosts,
        );
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

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    final palette = _vrmPalette(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
      isDense: true,
      filled: true,
      fillColor: palette.surfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = _vrmPalette(context);
    final item = widget.record;
    final wide = widget.wide;
    final complete = _detailsComplete;
    final statusColor = _recordStatusColor(context, complete);
    final statusLabel = complete ? 'Complete details' : 'Incomplete details';
    final feedback = _status;
    final feedbackColor =
        feedback == null
            ? (palette.isDark ? palette.success : _completeDeep)
            : feedback == l10n.line('vrmContactSaved')
            ? (palette.isDark ? palette.success : _completeDeep)
            : feedback == l10n.line('vrmContactSaving')
            ? _secondaryTextColor(context)
            : (palette.isDark ? palette.danger : _incomplete);
    final note =
        feedback ?? (complete ? l10n.line('vrmContactVerified') : null);

    final contacts = [
      _ContactField(
        label: l10n.line('vrmWhatsapp'),
        icon: Icons.chat_rounded,
        iconColor: const Color(0xFF16A34A),
        child: TextField(
          controller: _whatsapp,
          style: palette.isDark ? TextStyle(color: palette.text) : null,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(context, l10n.line('vrmWhatsappHint')),
        ),
      ),
      _ContactField(
        label: l10n.line('vrmInstagram'),
        icon: Icons.photo_camera_outlined,
        iconColor: const Color(0xFFDB2777),
        child: TextField(
          controller: _instagram,
          style: palette.isDark ? TextStyle(color: palette.text) : null,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(context, l10n.line('vrmInstagramHint')),
        ),
      ),
      _ContactField(
        label: l10n.line('vrmFacebook'),
        icon: Icons.facebook,
        iconColor: const Color(0xFF2563EB),
        child: TextField(
          controller: _facebook,
          style: palette.isDark ? TextStyle(color: palette.text) : null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saving ? null : _save(),
          decoration: _fieldDecoration(context, l10n.line('vrmFacebookHint')),
        ),
      ),
    ];

    final saveButton = SizedBox(
      height: 44,
      width: wide ? null : double.infinity,
      child: OutlinedButton(
        onPressed: _saving ? null : _save,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              palette.isDark ? palette.accent : const Color(0xFF2563EB),
          backgroundColor:
              palette.isDark
                  ? palette.surfaceSecondary
                  : const Color(0xFFEFF6FF),
          side: BorderSide(
            color: palette.isDark ? palette.border : const Color(0xFFBFDBFE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
        child: Text(
          l10n.line('vrmContactSave'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          wide ? 22 : 14,
          wide ? 20 : 14,
          wide ? 22 : 14,
          wide ? 18 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    formatPersonName(item.name),
                    style: TextStyle(
                      color: _primaryTextColor(context),
                      fontSize: wide ? 20 : 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n.line('vrmEpic')}: ${item.epicNumber ?? '—'}',
                        style: TextStyle(
                          color: _primaryTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if ((item.epicNumber ?? '').trim().isNotEmpty)
                        IconButton(
                          tooltip: l10n.line('vrmEpic'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: item.epicNumber!.trim()),
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: _secondaryTextColor(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${l10n.line('vrmAge')}: ${item.age?.toString() ?? '—'}',
                  style: TextStyle(
                    color: _secondaryTextColor(context),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '·',
                  style: TextStyle(
                    color:
                        palette.isDark
                            ? palette.textMuted
                            : const Color(0xFFCBD5E1),
                  ),
                ),
                Text(
                  '${l10n.line('vrmGender')}: ${item.gender ?? '—'}',
                  style: TextStyle(
                    color: _secondaryTextColor(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (item.needsReview)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.line('vrmNeedsReview'),
                  style: TextStyle(
                    color: palette.isDark ? palette.campaign : _review,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Divider(height: 1, color: palette.isDark ? palette.border : _line),
            const SizedBox(height: 14),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < contacts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: contacts[i]),
                  ],
                ],
              )
            else
              Column(
                children: [
                  for (var i = 0; i < contacts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    contacts[i],
                  ],
                ],
              ),
            const SizedBox(height: 14),
            if (wide)
              Row(
                children: [
                  if (note != null)
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          color: feedbackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  saveButton,
                ],
              )
            else ...[
              if (note != null) ...[
                Text(
                  note,
                  style: TextStyle(
                    color: feedbackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              saveButton,
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            palette.isDark ? palette.surfaceSecondary : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.isDark ? palette.border : _line),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: child,
      ),
    );
  }
}

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader({
    required this.title,
    required this.countLabel,
    required this.subtitle,
    required this.backTooltip,
    required this.refreshTooltip,
    required this.skipLabel,
    required this.onBack,
    required this.onRefresh,
    required this.onSkip,
  });

  final String title;
  final String countLabel;
  final String subtitle;
  final String backTooltip;
  final String refreshTooltip;
  final String skipLabel;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RoundIconButton(
              tooltip: backTooltip,
              icon: Icons.arrow_back,
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryTextColor(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color:
                    palette.isDark
                        ? palette.surfaceSecondary
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  countLabel,
                  style: TextStyle(
                    color:
                        palette.isDark
                            ? palette.accent
                            : const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const Spacer(),
            _RoundIconButton(
              tooltip: refreshTooltip,
              icon: Icons.refresh,
              onPressed: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            subtitle,
            style: TextStyle(color: _secondaryTextColor(context), fontSize: 14),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('vrm-records-skip'),
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(skipLabel),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: _primaryTextColor(context)),
      style: IconButton.styleFrom(
        backgroundColor:
            palette.isDark ? palette.surfaceSecondary : Colors.white,
        side: BorderSide(color: palette.isDark ? palette.border : _line),
        fixedSize: const Size(40, 40),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.showClear,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final bool showClear;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    return TextField(
      controller: controller,
      style: palette.isDark ? TextStyle(color: palette.text) : null,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: palette.isDark ? palette.textMuted : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: palette.surface,
        prefixIcon: Icon(
          Icons.search,
          color: palette.isDark ? palette.textMuted : _muted,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showClear)
              IconButton(
                tooltip: hint,
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: palette.isDark ? palette.textMuted : _muted,
                ),
              ),
            IconButton(
              tooltip: hint,
              onPressed: onSubmit,
              icon: Icon(
                Icons.arrow_forward,
                color: _primaryTextColor(context),
              ),
            ),
          ],
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 48,
          minWidth: 48,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: palette.isDark ? palette.border : _line,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: palette.isDark ? palette.border : _line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: palette.isDark ? palette.accent : const Color(0xFF93C5FD),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({
    required this.records,
    required this.selected,
    required this.allLabel,
    required this.completeLabel,
    required this.incompleteLabel,
    required this.reviewLabel,
    required this.onSelected,
  });

  final List<VrmVoterRecord> records;
  final _VoterFilter selected;
  final String allLabel;
  final String completeLabel;
  final String incompleteLabel;
  final String reviewLabel;
  final ValueChanged<_VoterFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    final complete = records.where(_savedComplete).length;
    final incomplete = records.length - complete;
    final review = records.where((row) => row.needsReview).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: allLabel,
            count: records.length,
            selected: selected == _VoterFilter.all,
            onTap: () => onSelected(_VoterFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: completeLabel,
            count: complete,
            dot: palette.isDark ? palette.success : _complete,
            selected: selected == _VoterFilter.complete,
            onTap: () => onSelected(_VoterFilter.complete),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: incompleteLabel,
            count: incomplete,
            dot: palette.isDark ? palette.danger : _incomplete,
            selected: selected == _VoterFilter.incomplete,
            onTap: () => onSelected(_VoterFilter.incomplete),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: reviewLabel,
            count: review,
            dot: palette.isDark ? palette.campaign : _review,
            selected: selected == _VoterFilter.review,
            onTap: () => onSelected(_VoterFilter.review),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final palette = _vrmPalette(context);
    final bg =
        selected
            ? (palette.isDark ? palette.accent : _ink)
            : (palette.isDark ? palette.surfaceSecondary : Colors.white);
    final fg = selected ? Colors.white : _primaryTextColor(context);
    final borderColor =
        selected
            ? (palette.isDark ? palette.accent : _ink)
            : (palette.isDark ? palette.border : _line);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : _secondaryTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
