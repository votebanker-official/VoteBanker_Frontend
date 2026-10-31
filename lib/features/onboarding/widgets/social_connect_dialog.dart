import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class SocialConnectCopy {
  const SocialConnectCopy({
    required this.providerId,
    required this.name,
    required this.summary,
    required this.permissions,
    required this.secure,
  });

  final String providerId;
  final String name;
  final String summary;
  final String permissions;
  final String secure;
}

SocialConnectCopy socialConnectCopy(AppLocalizations l10n, String providerId) {
  switch (providerId) {
    case 'instagram':
      return SocialConnectCopy(
        providerId: providerId,
        name: l10n.socialInstagram,
        summary: l10n.line('socialIgSummary'),
        permissions: l10n.line('socialIgPermissions'),
        secure: l10n.line('socialIgSecure'),
      );
    case 'facebook':
      return SocialConnectCopy(
        providerId: providerId,
        name: l10n.socialFacebook,
        summary: l10n.line('socialFbSummary'),
        permissions: l10n.line('socialFbPermissions'),
        secure: l10n.line('socialFbSecure'),
      );
    case 'whatsapp':
      return SocialConnectCopy(
        providerId: providerId,
        name: l10n.socialWhatsApp,
        summary: l10n.line('socialWaSummary'),
        permissions: l10n.line('socialWaPermissions'),
        secure: l10n.line('socialWaSecure'),
      );
    case 'x':
      return SocialConnectCopy(
        providerId: providerId,
        name: l10n.socialX,
        summary: l10n.line('socialXSummary'),
        permissions: l10n.line('socialXPermissions'),
        secure: l10n.line('socialXSecure'),
      );
    case 'youtube':
      return SocialConnectCopy(
        providerId: providerId,
        name: l10n.socialYouTube,
        summary: l10n.line('socialYtSummary'),
        permissions: l10n.line('socialYtPermissions'),
        secure: l10n.line('socialYtSecure'),
      );
    default:
      return SocialConnectCopy(
        providerId: 'email',
        name: l10n.socialEmail,
        summary: l10n.line('socialEmailSummary'),
        permissions: l10n.line('socialEmailPermissions'),
        secure: l10n.line('socialEmailSecure'),
      );
  }
}

class SocialConnectDialog extends StatelessWidget {
  const SocialConnectDialog({
    required this.copy,
    required this.mark,
    required this.busy,
    required this.error,
    required this.onContinue,
    super.key,
  });

  final SocialConnectCopy copy;
  final Widget mark;
  final bool busy;
  final String? error;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: busy
              ? _ConnectingBody(copy: copy, mark: mark)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: l10n.line('socialCancel'),
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      Row(
                        children: [
                          mark,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.line('socialConnectTitle').replaceAll('{provider}', copy.name),
                              style: AppTextStyles.headline(context).copyWith(fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(copy.summary, style: AppTextStyles.body(context)),
                      const SizedBox(height: 16),
                      _InfoBlock(
                        icon: Icons.verified_user_outlined,
                        title: l10n.line('socialSecureTitle'),
                        body: copy.secure,
                      ),
                      const SizedBox(height: 10),
                      _InfoBlock(
                        icon: Icons.lock_outline,
                        title: l10n.line('socialPermissionsTitle'),
                        body: copy.permissions,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          mark,
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 16, color: palette.textMuted),
                          const SizedBox(width: 10),
                          Icon(Icons.person_outline, size: 22, color: palette.textMuted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.line('socialRedirectNote').replaceAll('{provider}', copy.name),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted(context),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(context).copyWith(color: palette.danger),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onContinue,
                          child: Text(l10n.line('socialRetry')),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: onContinue,
                        child: Text(l10n.line('socialContinueTo').replaceAll('{provider}', copy.name)),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.line('socialCancel')),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class SocialConnectedDialog extends StatelessWidget {
  const SocialConnectedDialog({
    required this.provider,
    required this.account,
    required this.mark,
    this.detail = '',
    super.key,
  });

  final String provider;
  final String account;
  final Widget mark;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  mark,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.line('socialConnectedHeading').replaceAll('{provider}', provider),
                      style: AppTextStyles.headline(context).copyWith(fontSize: 20),
                    ),
                  ),
                  Icon(Icons.check_circle, color: palette.secondary),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: palette.surfaceSecondary,
                    child: Text(
                      account.isEmpty ? '?' : account[0].toUpperCase(),
                      style: AppTextStyles.label(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account, style: AppTextStyles.label(context)),
                        if (detail.isNotEmpty)
                          Text(detail, style: AppTextStyles.muted(context)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.line('socialConnectedBody').replaceAll('{provider}', provider),
                    style: AppTextStyles.body(context).copyWith(color: const Color(0xFF157A3A)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.line('socialDone')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectingBody extends StatelessWidget {
  const _ConnectingBody({required this.copy, required this.mark});

  final SocialConnectCopy copy;
  final Widget mark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: null,
              icon: Icon(Icons.close, color: context.palette.textMuted),
            ),
          ),
          Row(
            children: [
              mark,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.line('socialConnectTitle').replaceAll('{provider}', copy.name),
                  style: AppTextStyles.headline(context).copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(l10n.line('socialConnecting'), style: AppTextStyles.label(context)),
          const SizedBox(height: 6),
          Text(
            l10n.line('socialConnectingHint').replaceAll('{provider}', copy.name),
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label(context)),
                  const SizedBox(height: 4),
                  Text(body, style: AppTextStyles.muted(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
