import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../widgets/onboarding_frame.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSocialReturn());
  }

  Future<void> _finishSocialReturn() async {
    final params = Uri.base.queryParameters;
    final error = params['auth_error'];
    final ticket = params['auth_ticket'];
    if ((error == null || error.isEmpty) && (ticket == null || ticket.isEmpty)) {
      return;
    }
    clearAuthQuery();
    if (!mounted) return;
    if (error != null && error.isNotEmpty) {
      _showMessage(_messageFor(AppLocalizations.of(context), error));
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.instance.exchangeSocialTicket(ticket!);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AppLocalizations l10n, String code) {
    switch (code) {
      case 'social_not_configured':
        return l10n.socialNotConfigured;
      case 'social_denied':
        return l10n.socialDenied;
      default:
        return l10n.socialFailed;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startSocial(AppLocalizations l10n, String provider) {
    if (!kIsWeb) {
      _showMessage(l10n.socialWebOnly);
      return;
    }
    try {
      AuthService.instance.startSocial(provider);
    } on AuthException catch (e) {
      _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.palette.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.palette.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                l10n.principle,
                textAlign: TextAlign.center,
                style: AppTextStyles.principle(context),
              ),
            ),
            const SizedBox(height: 22),
            OnboardingHeader(
              title: l10n.welcomeTitle,
              description: l10n.welcomeBody,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.continueWhatsApp,
              icon: Icons.chat_rounded,
              onPressed: _busy
                  ? null
                  : () => AppRouter.open(
                        context,
                        AppRoutes.otp,
                        arguments: 'whatsapp',
                      ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.continueMobile,
              icon: Icons.sms_outlined,
              onPressed: _busy ? () {} : () => AppRouter.open(context, AppRoutes.otp),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.continueFacebook,
              icon: Icons.facebook,
              onPressed: _busy ? () {} : () => _startSocial(l10n, 'facebook'),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.continueInstagram,
              icon: Icons.photo_camera_outlined,
              onPressed: _busy ? () {} : () => _startSocial(l10n, 'instagram'),
            ),
            TextButton(
              onPressed: _busy ? null : () => AppRouter.open(context, AppRoutes.profile),
              child: Text(l10n.skipForNow),
            ),
          ],
        ),
      ),
    );
  }
}
