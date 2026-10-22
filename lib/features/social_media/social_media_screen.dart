import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_card.dart';
import 'social_contact_links.dart';
import 'social_media_service.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key, this.service});

  final SocialMediaService? service;

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen> {
  late final SocialMediaService _service = widget.service ?? SocialMediaService();
  final _search = TextEditingController();

  SocialMediaContacts? _contacts;
  bool _loading = true;
  String? _error;
  String _activeQuery = '';

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
      if (query != null) _activeQuery = query;
    });
    try {
      final contacts = await _service.load(query: _activeQuery);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } on SocialMediaException catch (error) {
      if (!mounted) return;
      setState(() {
        _contacts = null;
        _loading = false;
        _error = error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contacts = null;
        _loading = false;
        _error = 'load_failed';
      });
    }
  }

  String _message(AppLocalizations l10n, String code) {
    switch (code) {
      case 'unauthorized':
        return l10n.line('socialSignIn');
      case 'unreachable':
        return l10n.line('vrmUnreachable');
      default:
        return l10n.line('socialLoadError');
    }
  }

  String _count(String template, int count) => template.replaceAll('{count}', '$count');

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).line('socialCopied'))),
    );
  }

  Future<void> _open(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).line('socialLoadError'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final contacts = _contacts;

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
                      onPressed: () => AppRouter.back(context, AppRoutes.dashboard),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l10n.back,
                    ),
                    Expanded(
                      child: Text(
                        l10n.line('socialMediaTitle'),
                        style: AppTextStyles.headline(context),
                      ),
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
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _load(query: value.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.line('socialSearchHint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => _load(query: _search.text.trim()),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _body(context, l10n, contacts)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, SocialMediaContacts? contacts) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                style: AppTextStyles.body(context).copyWith(color: context.palette.danger),
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

    final data = contacts ??
        const SocialMediaContacts(whatsapp: [], instagram: [], facebook: []);
    if (data.isEmpty && _activeQuery.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.line('socialMediaEmpty'),
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
        ],
      );
    }
    if (data.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.line('socialNoMatches'),
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountChip(label: _count(l10n.line('socialCountWhatsapp'), data.whatsappCount)),
            _CountChip(label: _count(l10n.line('socialCountInstagram'), data.instagramCount)),
            _CountChip(label: _count(l10n.line('socialCountFacebook'), data.facebookCount)),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: l10n.line('socialWhatsappSection'),
          icon: Icons.chat_rounded,
          entries: data.whatsapp,
          epicLabel: l10n.line('vrmEpic'),
          copyLabel: l10n.line('socialCopy'),
          openLabel: l10n.line('socialOpenWhatsapp'),
          openUrl: SocialContactLinks.whatsAppUrl,
          onCopy: _copy,
          onOpen: _open,
        ),
        _Section(
          title: l10n.line('socialInstagramSection'),
          icon: Icons.photo_camera_outlined,
          entries: data.instagram,
          copyLabel: l10n.line('socialCopy'),
          openLabel: l10n.line('socialOpenProfile'),
          openUrl: (value) =>
              SocialContactLinks.profileUrl(value, SocialContactLinks.instagramHosts),
          onCopy: _copy,
          onOpen: _open,
        ),
        _Section(
          title: l10n.line('socialFacebookSection'),
          icon: Icons.facebook,
          entries: data.facebook,
          copyLabel: l10n.line('socialCopy'),
          openLabel: l10n.line('socialOpenProfile'),
          openUrl: (value) =>
              SocialContactLinks.profileUrl(value, SocialContactLinks.facebookHosts),
          onCopy: _copy,
          onOpen: _open,
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Text(label, style: AppTextStyles.label(context)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.entries,
    required this.copyLabel,
    required this.openLabel,
    required this.openUrl,
    required this.onCopy,
    required this.onOpen,
    this.epicLabel,
  });

  final String title;
  final IconData icon;
  final List<SocialContactEntry> entries;
  final String copyLabel;
  final String openLabel;
  final Uri? Function(String value) openUrl;
  final ValueChanged<String> onCopy;
  final ValueChanged<Uri> onOpen;
  final String? epicLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.palette.accent),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.label(context)),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in entries) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: AppTextStyles.label(context)),
                  if (epicLabel != null && (entry.epicNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$epicLabel: ${entry.epicNumber}',
                      style: AppTextStyles.muted(context),
                    ),
                  ],
                  const SizedBox(height: 6),
                  SelectableText(entry.value, style: AppTextStyles.body(context)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => onCopy(entry.value),
                        child: Text(copyLabel),
                      ),
                      if (openUrl(entry.value) != null)
                        TextButton(
                          onPressed: () => onOpen(openUrl(entry.value)!),
                          child: Text(openLabel),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
