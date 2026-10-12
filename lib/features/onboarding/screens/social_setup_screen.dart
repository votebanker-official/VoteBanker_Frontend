import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../widgets/onboarding_frame.dart';

class SocialSetupScreen extends StatelessWidget {
  const SocialSetupScreen({super.key});

  void _connect(BuildContext context, String platform) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.socialConnectSoon(platform))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <_SocialOption>[
      _SocialOption(
        label: l10n.socialInstagram,
        mark: const _PlatformIcon(_SocialMark.instagram),
      ),
      _SocialOption(
        label: l10n.socialFacebook,
        mark: const _PlatformIcon(_SocialMark.facebook),
      ),
      _SocialOption(
        label: l10n.socialWhatsApp,
        mark: const _PlatformIcon(_SocialMark.whatsapp),
      ),
      _SocialOption(
        label: l10n.socialX,
        mark: const _PlatformIcon(_SocialMark.x),
      ),
      _SocialOption(
        label: l10n.socialYouTube,
        mark: const _PlatformIcon(_SocialMark.youtube),
      ),
      _SocialOption(
        label: l10n.socialEmail,
        mark: const _PlatformIcon(_SocialMark.email),
      ),
    ];

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeader(
          compact: true,
          title: l10n.socialTitle,
          description: l10n.socialBody,
        ),
        const SizedBox(height: 18),
        for (final option in options) ...[
          _SocialConnectRow(
            option: option,
            connectLabel: l10n.socialConnect,
            onConnect: () => _connect(context, option.label),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          onPressed: () => AppRouter.open(context, AppRoutes.vrm),
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
        TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onPressed: () => AppRouter.open(context, AppRoutes.dashboard),
          child: Text(l10n.skipForNow),
        ),
      ],
    );

    return OnboardingFrame(child: form);
  }
}

class _SocialOption {
  const _SocialOption({required this.label, required this.mark});

  final String label;
  final Widget mark;
}

class _SocialConnectRow extends StatelessWidget {
  const _SocialConnectRow({
    required this.option,
    required this.connectLabel,
    required this.onConnect,
  });

  final _SocialOption option;
  final String connectLabel;
  final VoidCallback onConnect;

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
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
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
