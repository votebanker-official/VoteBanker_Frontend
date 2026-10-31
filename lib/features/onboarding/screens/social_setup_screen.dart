import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../services/social_connection_service.dart';
import '../widgets/onboarding_frame.dart';
import '../widgets/social_connect_dialog.dart';

class SocialSetupScreen extends StatefulWidget {
  const SocialSetupScreen({this.service, super.key});

  final SocialConnectionService? service;

  @override
  State<SocialSetupScreen> createState() => _SocialSetupScreenState();
}

class _SocialSetupScreenState extends State<SocialSetupScreen> with WidgetsBindingObserver {
  late final SocialConnectionService _service =
      widget.service ?? SocialConnectionService();
  final Map<String, SocialConnection> _connections = {};
  String? _busyId;
  var _handledReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _handleReturn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    if (AuthService.instance.session == null) return;
    try {
      final rows = await _service.load();
      if (!mounted) return;
      setState(() {
        _connections
          ..clear()
          ..addEntries(rows.map((row) => MapEntry(row.provider, row)));
      });
    } catch (_) {
      // A missing table or signed-out session leaves every provider disconnected.
    }
  }

  Future<void> _handleReturn() async {
    if (_handledReturn || !kIsWeb) return;
    final params = Uri.base.queryParameters;
    final status = params['social_status'];
    final provider = params['provider'];
    if (status == null || status.isEmpty || provider == null || provider.isEmpty) {
      return;
    }
    _handledReturn = true;
    final account = params['account'] ?? '';
    clearAuthQuery();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (status == 'connected') {
      await _load();
      if (!mounted) return;
      final row = _connections[provider];
      await showDialog<void>(
        context: context,
        builder: (_) => SocialConnectedDialog(
          provider: _label(l10n, provider),
          account: account.isEmpty
              ? (row?.displayName.isNotEmpty == true ? row!.displayName : _label(l10n, provider))
              : account,
          mark: _markFor(provider),
          detail: row?.detail ?? '',
        ),
      );
      return;
    }
    if (status == 'cancelled') {
      _toast(l10n.line('socialCancelled'));
      return;
    }
    _toast(_errorText(l10n, status));
  }

  Future<void> _connect(_SocialOption option) async {
    if (_busyId != null) return;
    final l10n = AppLocalizations.of(context);
    String? errorText;
    var busy = false;
    final copy = socialConnectCopy(l10n, option.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return SocialConnectDialog(
              copy: copy,
              mark: option.mark,
              busy: busy,
              error: errorText,
              onContinue: () async {
                if (AuthService.instance.session == null) {
                  setDialog(() => errorText = l10n.line('socialNotSignedIn'));
                  return;
                }
                setDialog(() {
                  busy = true;
                  errorText = null;
                });
                if (mounted) setState(() => _busyId = option.id);
                try {
                  final url = await _service.start(option.id, _returnTo());
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (kIsWeb) {
                    redirectBrowser(url);
                  } else {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                } on SocialConnectionException catch (error) {
                  setDialog(() {
                    busy = false;
                    errorText = _errorText(l10n, error.code);
                  });
                } catch (_) {
                  setDialog(() {
                    busy = false;
                    errorText = _errorText(l10n, 'failed');
                  });
                } finally {
                  if (mounted) setState(() => _busyId = null);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _manage(SocialConnection connection) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                connection.displayName.isEmpty
                    ? _label(l10n, connection.provider)
                    : connection.displayName,
                style: AppTextStyles.headline(context),
              ),
              if (connection.detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(connection.detail, style: AppTextStyles.muted(context)),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await _service.disconnect(connection.provider);
                    if (!mounted) return;
                    setState(() => _connections.remove(connection.provider));
                  } on SocialConnectionException catch (error) {
                    _toast(_errorText(l10n, error.code));
                  }
                },
                child: Text(l10n.line('socialDisconnect')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _returnTo() {
    if (kIsWeb) {
      final origin = browserOrigin();
      if (origin.isNotEmpty) return '$origin/social';
    }
    final uri = Uri.base;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return '${uri.origin}/social';
    }
    return 'http://localhost/social';
  }

  Widget _markFor(String id) {
    return switch (id) {
      'instagram' => const _PlatformIcon(_SocialMark.instagram),
      'facebook' => const _PlatformIcon(_SocialMark.facebook),
      'whatsapp' => const _PlatformIcon(_SocialMark.whatsapp),
      'x' => const _PlatformIcon(_SocialMark.x),
      'youtube' => const _PlatformIcon(_SocialMark.youtube),
      _ => const _PlatformIcon(_SocialMark.email),
    };
  }

  String _label(AppLocalizations l10n, String id) {
    return switch (id) {
      'instagram' => l10n.socialInstagram,
      'facebook' => l10n.socialFacebook,
      'whatsapp' => l10n.socialWhatsApp,
      'x' => l10n.socialX,
      'youtube' => l10n.socialYouTube,
      _ => l10n.socialEmail,
    };
  }

  String _errorText(AppLocalizations l10n, String code) {
    return switch (code) {
      'unauthorized' || 'socialNotSignedIn' => l10n.line('socialNotSignedIn'),
      'not_configured' => l10n.line('socialNotConfiguredProvider'),
      'cancelled' => l10n.line('socialCancelled'),
      'no_page' => l10n.line('socialNoPage'),
      'professional_required' => l10n.line('socialProfessionalRequired'),
      'no_channel' => l10n.line('socialNoChannel'),
      'whatsapp_incomplete' => l10n.line('socialWhatsappIncomplete'),
      'storage_not_ready' => l10n.line('socialStorageNotReady'),
      _ => l10n.line('socialFailedConnect'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <_SocialOption>[
      _SocialOption(
        id: 'instagram',
        label: l10n.socialInstagram,
        mark: const _PlatformIcon(_SocialMark.instagram),
      ),
      _SocialOption(
        id: 'facebook',
        label: l10n.socialFacebook,
        mark: const _PlatformIcon(_SocialMark.facebook),
      ),
      _SocialOption(
        id: 'whatsapp',
        label: l10n.socialWhatsApp,
        mark: const _PlatformIcon(_SocialMark.whatsapp),
      ),
      _SocialOption(
        id: 'x',
        label: l10n.socialX,
        mark: const _PlatformIcon(_SocialMark.x),
      ),
      _SocialOption(
        id: 'youtube',
        label: l10n.socialYouTube,
        mark: const _PlatformIcon(_SocialMark.youtube),
      ),
      _SocialOption(
        id: 'email',
        label: l10n.socialEmail,
        mark: const _PlatformIcon(_SocialMark.email),
      ),
    ];

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (Navigator.of(context).canPop())
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: l10n.back,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => AppRouter.popIfPossible(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        OnboardingHeader(
          compact: true,
          showDescriptor: false,
          title: l10n.socialTitle,
          description: l10n.socialBody,
        ),
        const SizedBox(height: 18),
        for (final option in options) ...[
          _SocialConnectRow(
            option: option,
            connection: _connections[option.id],
            connectLabel: l10n.socialConnect,
            connectedLabel: l10n.line('socialConnectedBadge'),
            manageLabel: l10n.line('socialManage'),
            onConnect: () => _connect(option),
            onManage: _connections[option.id] == null
                ? null
                : () => _manage(_connections[option.id]!),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => AppRouter.open(context, AppRoutes.merchandise),
          child: Text(l10n.skipForNow),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          onPressed: () => AppRouter.open(context, AppRoutes.merchandise),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.saveAndContinue),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );

    return OnboardingFrame(child: form);
  }
}

class _SocialOption {
  const _SocialOption({required this.id, required this.label, required this.mark});

  final String id;
  final String label;
  final Widget mark;
}

class _SocialConnectRow extends StatelessWidget {
  const _SocialConnectRow({
    required this.option,
    required this.connection,
    required this.connectLabel,
    required this.connectedLabel,
    required this.manageLabel,
    required this.onConnect,
    required this.onManage,
  });

  final _SocialOption option;
  final SocialConnection? connection;
  final String connectLabel;
  final String connectedLabel;
  final String manageLabel;
  final VoidCallback onConnect;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            option.mark,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(context).copyWith(fontSize: 16),
                  ),
                  if (connection != null && connection!.connected) ...[
                    const SizedBox(height: 2),
                    Text(
                      connection!.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (connection != null && connection!.connected)
              TextButton(
                onPressed: onManage,
                child: Text(manageLabel),
              ),
            if (connection != null && connection!.connected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  connectedLabel,
                  style: const TextStyle(
                    color: Color(0xFF157A3A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const StadiumBorder(),
                ),
                onPressed: onConnect,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(connectLabel),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _SocialMark { instagram, facebook, whatsapp, x, youtube, email }

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon(this.mark);

  final _SocialMark mark;

  static const _icons = <_SocialMark, String>{
    _SocialMark.instagram: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="13" y="13" width="22" height="22" rx="7" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="24" cy="24" r="5.2" fill="none" stroke="#fff" stroke-width="2.6"/>
  <circle cx="32.2" cy="15.8" r="1.7" fill="#fff"/>
</svg>''',
    _SocialMark.facebook: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#1877F2"/>
  <path fill="#fff" d="M26.6 38V26.2h4l.6-4.6h-4.6v-2.9c0-1.3.4-2.2 2.3-2.2H31.4v-4.1c-.4 0-1.7-.2-3.2-.2-3.2 0-5.4 1.9-5.4 5.5v3.9H18.4v4.6h4.4V38h3.8z"/>
</svg>''',
    _SocialMark.whatsapp: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#25D366"/>
  <path fill="#fff" d="M24 11.2c-6.7 0-12.1 5.4-12.1 12 0 2.1.6 4.1 1.6 5.9L12 36.8l7.9-2c1.7.9 3.6 1.4 5.6 1.4 6.7 0 12.1-5.4 12.1-12S30.7 11.2 24 11.2zm6.9 16.7c-.3.8-1.6 1.4-2.2 1.5-.6.1-1.1.1-3.6-.8-3-1.1-5-4-5.2-4.2-.2-.2-1.2-1.6-1.2-3.1 0-1.5.8-2.2 1-2.5.3-.3.6-.4.9-.4h.6c.2 0 .5 0 .7.6.3.7 1 2.4 1.1 2.6.1.2.1.4 0 .6-.1.2-.2.4-.3.6-.2.2-.3.4-.2.6.2.3.8 1.4 1.8 2.2 1.2 1.1 2.3 1.5 2.6 1.6.3.2.5.1.7-.1.2-.2.8-.9 1-1.3.2-.3.5-.3.7-.2.3.1 1.9.9 2.2 1 .3.2.5.2.6.4.1.1.1.8-.2 1.5z"/>
</svg>''',
    _SocialMark.x: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#111"/>
  <path fill="#fff" d="M28.4 14h3.3l-7.2 8.2L33 34h-6.6l-5.2-6.8L15.4 34H12l7.7-8.8L15 14h6.8l4.7 6.2L28.4 14zm-1.2 18h1.8L20.9 16h-2l8.3 16z"/>
</svg>''',
    _SocialMark.youtube: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#FF0033"/>
  <path fill="#fff" d="M20 16.5v15l13-7.5-13-7.5z"/>
</svg>''',
    _SocialMark.email: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#4C8DFF"/>
  <rect x="13" y="16" width="22" height="16" rx="2.5" fill="none" stroke="#fff" stroke-width="2.4"/>
  <path d="M13.5 17.2 L24 26.5 L34.5 17.2" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>
</svg>''',
  };

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.string(_icons[mark]!, width: 42, height: 42);
    if (mark != _SocialMark.instagram) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFFEDA77),
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
          ),
        ),
        child: icon,
      ),
    );
  }
}
