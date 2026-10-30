import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../../features/onboarding/state/onboarding_controller.dart';
import '../dashboard/widgets/dashboard_colors.dart';
import 'social_integration_service.dart';
import 'social_post_media.dart';

class SocialIntegrationScreen extends StatefulWidget {
  const SocialIntegrationScreen({super.key, this.service, this.picker});

  final SocialIntegrationService? service;
  final ImagePicker? picker;

  @override
  State<SocialIntegrationScreen> createState() => _SocialIntegrationScreenState();
}

class _SocialIntegrationScreenState extends State<SocialIntegrationScreen> {
  late final SocialIntegrationService _service =
      widget.service ?? SocialIntegrationService();
  final _caption = TextEditingController();
  final _hashtag = TextEditingController();
  final _link = TextEditingController();

  SocialIntegrationStatus? _status;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  String _platform = 'facebook';
  final List<String> _hashtags = [];
  SocialPostMedia? _media;
  bool _advanced = false;
  bool _allowComments = true;

  static const _captionLimit = 500;

  @override
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _caption.dispose();
    _hashtag.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _service.loadStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on SocialIntegrationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code;
        _loading = false;
      });
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _failure(AppLocalizations l10n, String code) {
    switch (code) {
      case 'unauthorized':
        return l10n.line('smiSignIn');
      case 'unreachable':
        return l10n.line('smiUnreachable');
      case 'scheduling':
      case 'scheduling_not_configured':
        return l10n.line('smiScheduleUnsupported');
      case 'caption_ai_not_configured':
        return l10n.line('smiAiBody');
      default:
        return l10n.line('smiNotConfigured');
    }
  }

  Future<void> _save(String action, {DateTime? when}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _service.savePost(
        action: action,
        platform: _platform,
        caption: _caption.text.trim(),
        hashtags: List<String>.from(_hashtags),
        mediaName: _media?.name,
        scheduledFor: when,
        allowComments: _allowComments,
        link: _link.text.trim(),
      );
      if (!mounted) return;
      _notice(
        action == 'publish'
            ? l10n.line('smiPublished')
            : action == 'schedule'
                ? l10n.line('smiScheduled')
                : l10n.line('smiDraftSaved'),
      );
    } on SocialIntegrationException catch (error) {
      if (!mounted) return;
      final code = action == 'schedule' && error.code == 'publishing_not_configured'
          ? 'scheduling'
          : error.code;
      _notice(_failure(l10n, code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _schedule() async {
    final l10n = AppLocalizations.of(context);
    _notice(l10n.line('smiPickSchedule'));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _save('schedule', when: when);
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result = await _service.generateCaption(
        platform: _platform,
        caption: _caption.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        if (result.caption.isNotEmpty) _caption.text = result.caption;
        for (final tag in result.hashtags) {
          final clean = tag.replaceAll('#', '').trim();
          if (clean.isNotEmpty && !_hashtags.contains(clean)) _hashtags.add(clean);
        }
      });
      _notice(l10n.line('smiCaptionReady'));
    } on SocialIntegrationException catch (error) {
      if (!mounted) return;
      _notice(_failure(l10n, error.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(SocialMediaKind kind) async {
    final l10n = AppLocalizations.of(context);
    if (kind == SocialMediaKind.document) {
      _notice(l10n.line('smiMediaStorage'));
      return;
    }
    final picker = widget.picker ?? ImagePicker();
    final file = kind == SocialMediaKind.image
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.length();
    final media = SocialPostMedia.validate(name: file.name, bytes: bytes, kind: kind);
    if (!mounted) return;
    if (media == null) {
      _notice(l10n.line('smiFileType'));
      return;
    }
    setState(() => _media = media);
    _notice(l10n.line('smiMediaStorage'));
  }

  void _addHashtag() {
    final clean = _hashtag.text.replaceAll('#', '').trim();
    if (clean.isEmpty || _hashtags.contains(clean)) return;
    setState(() {
      _hashtags.add(clean);
      _hashtag.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = DashboardColors.of(context);
    final draft = OnboardingScope.maybeOf(context)?.draft;
    return Scaffold(
      backgroundColor: colors.page,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.back,
                        onPressed: () => AppRouter.back(context, AppRoutes.dashboard),
                        icon: Icon(Icons.arrow_back, color: colors.accent),
                      ),
                      Expanded(
                        child: Text(
                          l10n.line('smiTitle'),
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _failure(l10n, _error!),
                        style: TextStyle(color: colors.muted),
                      ),
                    ),
                  _Hero(colors: colors, l10n: l10n, status: _status),
                  const SizedBox(height: 16),
                  Text(
                    l10n.line('smiConnectedAccounts'),
                    style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final cards = [
                        _AccountCard(
                          colors: colors,
                          title: 'Facebook',
                          connected: _status?.facebook.connected == true,
                          detail: l10n
                              .line('smiFacebookPages')
                              .replaceAll('{count}', '${_status?.facebook.pageCount ?? 0}'),
                          icon: Icons.facebook,
                          onOpen: () => _openAccount(l10n, 'Facebook'),
                        ),
                        _AccountCard(
                          colors: colors,
                          title: 'Instagram',
                          connected: _status?.instagram.connected == true,
                          detail: l10n.line('smiInstagramAccounts').replaceAll(
                                '{count}',
                                '${_status?.instagram.accountCount ?? 0}',
                              ),
                          icon: Icons.camera_alt_outlined,
                          onOpen: () => _openAccount(l10n, 'Instagram'),
                        ),
                        _AccountCard(
                          colors: colors,
                          title: 'WhatsApp',
                          connected: _status?.whatsapp.connected == true &&
                              _status?.whatsapp.businessReady == true,
                          detail: _status?.whatsapp.businessReady == true
                              ? l10n.line('smiWhatsappBusiness')
                              : l10n.line('smiWhatsappNotReady'),
                          icon: Icons.chat_outlined,
                          onOpen: () => _openAccount(l10n, 'WhatsApp'),
                        ),
                      ];
                      if (!wide) {
                        return Column(
                          children: [
                            for (final card in cards) ...[card, const SizedBox(height: 10)],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (final card in cards)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: card,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final composer = _composer(l10n, colors);
                      final preview = _Preview(
                        colors: colors,
                        l10n: l10n,
                        platform: _platform,
                        caption: _caption.text,
                        hashtags: _hashtags,
                        mediaName: _media?.name,
                        name: draft?.fullName.trim() ?? '',
                        photo: draft?.photoBytes,
                        onPlatform: (value) => setState(() => _platform = value),
                      );
                      if (!wide) {
                        return Column(
                          children: [composer, const SizedBox(height: 12), preview],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: composer),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: preview),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  void _openAccount(AppLocalizations l10n, String platform) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(platform, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.line('smiSetupBody')),
          ],
        ),
      ),
    );
  }

  Widget _composer(AppLocalizations l10n, DashboardColors colors) {
    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.line('smiCreatePost'),
            style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(l10n.line('smiCreatePostHint'), style: TextStyle(color: colors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final platform in const ['facebook', 'instagram', 'whatsapp'])
                ChoiceChip(
                  label: Text(platform[0].toUpperCase() + platform.substring(1)),
                  selected: _platform == platform,
                  onSelected: (_) => setState(() => _platform = platform),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.line('smiCaption'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            key: const Key('smi-caption'),
            controller: _caption,
            maxLength: _captionLimit,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(hintText: l10n.line('smiCaptionHint')),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(SocialMediaKind.image),
                icon: const Icon(Icons.image_outlined),
                label: Text(l10n.line('smiAddImage')),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(SocialMediaKind.video),
                icon: const Icon(Icons.videocam_outlined),
                label: Text(l10n.line('smiAddVideo')),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(SocialMediaKind.document),
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.line('smiAddDocument')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Panel(
            colors: colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.line('smiAiTitle'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(l10n.line('smiAiBody'), style: TextStyle(color: colors.muted)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.line('smiGenerate')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.line('smiHashtags'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('smi-hashtag'),
                  controller: _hashtag,
                  decoration: InputDecoration(hintText: l10n.line('smiHashtagHint')),
                  onSubmitted: (_) => _addHashtag(),
                ),
              ),
              IconButton(
                tooltip: l10n.line('smiAddHashtag'),
                onPressed: _addHashtag,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final tag in _hashtags)
                InputChip(
                  label: Text('#$tag'),
                  onDeleted: () => setState(() => _hashtags.remove(tag)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _advanced = !_advanced),
            child: Text(l10n.line('smiAdvanced')),
          ),
          if (_advanced) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.line('smiAllowComments')),
              value: _allowComments,
              onChanged: (value) => setState(() => _allowComments = value),
            ),
            TextField(
              controller: _link,
              decoration: InputDecoration(labelText: l10n.line('smiLink')),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _schedule,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(l10n.line('smiSchedule')),
              ),
              OutlinedButton(
                key: const Key('smi-save-draft'),
                onPressed: _busy ? null : () => _save('draft'),
                child: Text(l10n.line('smiSaveDraft')),
              ),
              FilledButton.icon(
                key: const Key('smi-post-now'),
                onPressed: _busy ? null : () => _save('publish'),
                icon: const Icon(Icons.send),
                label: Text(l10n.line('smiPostNow')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.colors, required this.l10n, required this.status});

  final DashboardColors colors;
  final AppLocalizations l10n;
  final SocialIntegrationStatus? status;

  @override
  Widget build(BuildContext context) {
    final any = status?.facebook.connected == true ||
        status?.instagram.connected == true ||
        (status?.whatsapp.connected == true && status?.whatsapp.businessReady == true);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [colors.card, colors.accent.withValues(alpha: 0.35)],
        ),
        border: Border.all(color: colors.accent.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.share, color: colors.accent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.line('smiTitle'),
                  style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(l10n.line('smiSubtitle'), style: TextStyle(color: colors.muted)),
              ],
            ),
          ),
          _StatusPill(connected: any, label: any ? l10n.line('smiConnected') : l10n.line('smiNotConnected')),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.colors,
    required this.title,
    required this.connected,
    required this.detail,
    required this.icon,
    required this.onOpen,
  });

  final DashboardColors colors;
  final String title;
  final bool connected;
  final String detail;
  final IconData icon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
                    Text(
                      connected ? l10n.line('smiConnected') : l10n.line('smiSetupRequired'),
                      style: TextStyle(
                        color: connected ? const Color(0xFF12C47A) : colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(detail, style: TextStyle(color: colors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.colors,
    required this.l10n,
    required this.platform,
    required this.caption,
    required this.hashtags,
    required this.mediaName,
    required this.name,
    required this.photo,
    required this.onPlatform,
  });

  final DashboardColors colors;
  final AppLocalizations l10n;
  final String platform;
  final String caption;
  final List<String> hashtags;
  final String? mediaName;
  final String name;
  final Uint8List? photo;
  final ValueChanged<String> onPlatform;

  @override
  Widget build(BuildContext context) {
    final tags = hashtags.map((tag) => '#$tag').join(' ');
    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.line('smiPreview'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
          Text(l10n.line('smiPreviewNote'), style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: platform,
            items: const [
              DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
              DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
              DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
            ],
            onChanged: (value) {
              if (value != null) onPlatform(value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: photo == null ? null : MemoryImage(photo!),
                child: photo == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isEmpty ? l10n.line('smiNameMissing') : name,
                  key: const Key('smi-preview-name'),
                  style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caption.isEmpty ? l10n.line('smiCaptionHint') : caption,
            key: const Key('smi-preview-caption'),
            style: TextStyle(color: colors.text),
          ),
          if (tags.isNotEmpty) Text(tags, key: const Key('smi-preview-tags'), style: TextStyle(color: colors.accent)),
          const SizedBox(height: 8),
          Text(
            mediaName ?? l10n.line('smiNoMedia'),
            key: const Key('smi-preview-media'),
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected, required this.label});

  final bool connected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = connected ? const Color(0xFF12C47A) : const Color(0xFF93A6BD);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.colors, required this.child});

  final DashboardColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
