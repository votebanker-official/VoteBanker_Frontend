import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/onboarding_progress_service.dart';
import '../../../core/widgets/circular_skip_button.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../services/social_connection_service.dart';
import '../widgets/social_connect_dialog.dart';

class SocialSetupScreen extends StatefulWidget {
  const SocialSetupScreen({this.service, super.key});

  final SocialConnectionService? service;

  @override
  State<SocialSetupScreen> createState() => _SocialSetupScreenState();
}

class _SocialSetupScreenState extends State<SocialSetupScreen>
    with WidgetsBindingObserver {
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
    if (status == null ||
        status.isEmpty ||
        provider == null ||
        provider.isEmpty) {
      return;
    }
    _handledReturn = true;
    if (provider == 'email') {
      clearAuthQuery();
      return;
    }
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
        builder:
            (_) => SocialConnectedDialog(
              provider: _label(l10n, provider),
              account:
                  account.isEmpty
                      ? (row?.displayName.isNotEmpty == true
                          ? row!.displayName
                          : _label(l10n, provider))
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
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      _ => const Icon(Icons.public),
    };
  }

  String _label(AppLocalizations l10n, String id) {
    return switch (id) {
      'instagram' => l10n.socialInstagram,
      'facebook' => l10n.socialFacebook,
      'whatsapp' => l10n.socialWhatsApp,
      'x' => l10n.socialX,
      'youtube' => l10n.socialYouTube,
      _ => id,
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
        description: l10n.line('socialInstagramBody'),
        mark: const _PlatformIcon(_SocialMark.instagram),
      ),
      _SocialOption(
        id: 'facebook',
        label: l10n.socialFacebook,
        description: l10n.line('socialFacebookBody'),
        mark: const _PlatformIcon(_SocialMark.facebook),
      ),
      _SocialOption(
        id: 'whatsapp',
        label: l10n.socialWhatsApp,
        description: l10n.line('socialWhatsAppBody'),
        mark: const _PlatformIcon(_SocialMark.whatsapp),
      ),
      _SocialOption(
        id: 'x',
        label: l10n.socialX,
        description: l10n.line('socialXBody'),
        mark: const _PlatformIcon(_SocialMark.x),
      ),
      _SocialOption(
        id: 'youtube',
        label: l10n.socialYouTube,
        description: l10n.line('socialYouTubeBody'),
        mark: const _PlatformIcon(_SocialMark.youtube),
      ),
    ];

    final palette = context.palette;
    final pageColor =
        palette.isDark ? palette.background : const Color(0xFFF5F8FC);

    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Column(
          children: [
            const _SocialTopBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  final gutter = wide ? 28.0 : 16.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: CircularSkipButton(
                                onPressed:
                                    () => AppRouter.open(
                                      context,
                                      AppRoutes.blueTik,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _SocialHero(
                              title: l10n.socialTitle,
                              subtitle: l10n.socialBody,
                              backLabel: l10n.line('backToProfile'),
                              onBack:
                                  () =>
                                      AppRouter.back(context, AppRoutes.domain),
                            ),
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        palette.isDark
                                            ? palette.cardShadow
                                            : const Color(0x12102A56),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: wide ? 8 : 4,
                                  vertical: 6,
                                ),
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < options.length;
                                      i++
                                    ) ...[
                                      _SocialConnectRow(
                                        option: options[i],
                                        connection: _connections[options[i].id],
                                        connectLabel: l10n.socialConnect,
                                        connectedLabel: l10n.line(
                                          'socialConnectedBadge',
                                        ),
                                        manageLabel: l10n.line('socialManage'),
                                        busy: _busyId == options[i].id,
                                        onConnect: () => _connect(options[i]),
                                        onManage:
                                            _connections[options[i].id] == null
                                                ? null
                                                : () => _manage(
                                                  _connections[options[i].id]!,
                                                ),
                                      ),
                                      if (i != options.length - 1)
                                        Divider(
                                          height: 1,
                                          indent: 18,
                                          endIndent: 18,
                                          color: palette.border.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Align(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: wide ? 420 : double.infinity,
                                ),
                                child: _GradientContinue(
                                  label: l10n.saveAndContinue,
                                  onPressed: () {
                                    unawaited(
                                      OnboardingProgressService.instance
                                          .saveProgress(
                                            completedStep: AppRoutes.social,
                                            currentStep: AppRoutes.blueTik,
                                          ),
                                    );
                                    AppRouter.open(context, AppRoutes.blueTik);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialOption {
  const _SocialOption({
    required this.id,
    required this.label,
    required this.description,
    required this.mark,
  });

  final String id;
  final String label;
  final String description;
  final Widget mark;
}

class _SocialConnectRow extends StatelessWidget {
  const _SocialConnectRow({
    required this.option,
    required this.connection,
    required this.connectLabel,
    required this.connectedLabel,
    required this.manageLabel,
    required this.busy,
    required this.onConnect,
    required this.onManage,
  });

  final _SocialOption option;
  final SocialConnection? connection;
  final String connectLabel;
  final String connectedLabel;
  final String manageLabel;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final connected = connection != null && connection!.connected;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          option.mark,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(context).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected && connection!.displayName.isNotEmpty
                      ? connection!.displayName
                      : option.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted(
                    context,
                  ).copyWith(color: muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (connected) ...[
            _StatusChip(label: connectedLabel),
            const SizedBox(width: 6),
            TextButton(onPressed: onManage, child: Text(manageLabel)),
          ] else
            _ConnectButton(
              label: connectLabel,
              busy: busy,
              onPressed: busy ? null : onConnect,
            ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background =
        palette.isDark ? palette.surfaceHighlight : const Color(0xFFEAF2FE);
    final foreground = palette.isDark ? palette.text : const Color(0xFF2563EB);
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.6),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      onPressed: onPressed,
      child:
          busy
              ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 16, color: foreground),
                  const SizedBox(width: 6),
                  Text(label),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18, color: foreground),
                ],
              ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF157A3A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

enum _SocialMark { instagram, facebook, whatsapp, x, youtube }

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon(this.mark, {this.size = 42});

  final _SocialMark mark;
  final double size;

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
  };

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.string(_icons[mark]!, width: size, height: size);
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

class _SocialTopBar extends StatelessWidget {
  const _SocialTopBar();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              AppAssets.logo,
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: narrow ? 14 : 15,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (!narrow) ...[
                  const SizedBox(width: 14),
                  Container(width: 1, height: 22, color: palette.border),
                ],
              ],
            ),
          ),
          const ThemeToggle(),
          const SizedBox(width: 8),
          const LanguageSelector(),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor:
                palette.isDark
                    ? palette.surfaceHighlight
                    : const Color(0xFFD7E6F5),
            child: Icon(Icons.person, size: 18, color: titleColor),
          ),
        ],
      ),
    );
  }
}

class _SocialHero extends StatelessWidget {
  const _SocialHero({
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: muted,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: Text(backLabel),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: wide ? 34 : 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: muted,
                fontSize: wide ? 16 : 14,
                height: 1.4,
              ),
            ),
          ],
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  palette.isDark
                      ? [palette.surface, palette.backgroundRaised]
                      : const [Color(0xFFF7FBFF), Color(0xFFEEF8F4)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 22 : 12,
              12,
              wide ? 18 : 8,
              wide ? 22 : 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 8),
                _SocialHeroArt(compact: !wide),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SocialHeroArt extends StatelessWidget {
  const _SocialHeroArt({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 108.0 : 210.0;
    final icon = compact ? 28.0 : 42.0;
    return SizedBox(
      width: size,
      height: compact ? 96 : 148,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: compact ? 0 : 8,
            bottom: 0,
            child: Icon(
              Icons.campaign,
              size: compact ? 42 : 78,
              color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: compact ? 4 : 18,
            top: compact ? 8 : 16,
            child: _PlatformIcon(_SocialMark.instagram, size: icon),
          ),
          Positioned(
            right: compact ? 8 : 36,
            top: 0,
            child: _PlatformIcon(_SocialMark.facebook, size: icon),
          ),
          Positioned(
            left: compact ? 28 : 78,
            top: compact ? 36 : 58,
            child: _PlatformIcon(_SocialMark.whatsapp, size: icon * 0.9),
          ),
          Positioned(
            left: compact ? 0 : 8,
            bottom: compact ? 4 : 10,
            child: _PlatformIcon(_SocialMark.x, size: icon * 0.86),
          ),
          Positioned(
            right: compact ? 2 : 16,
            bottom: compact ? 18 : 28,
            child: _PlatformIcon(_SocialMark.youtube, size: icon * 0.9),
          ),
        ],
      ),
    );
  }
}

class _GradientContinue extends StatelessWidget {
  const _GradientContinue({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
