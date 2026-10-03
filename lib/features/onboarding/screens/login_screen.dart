import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../widgets/onboarding_frame.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _emailComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email sign-in is coming soon. Please use mobile OTP.'),
      ),
    );
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
              onPressed: () => AppRouter.open(
                context,
                AppRoutes.otp,
                arguments: 'whatsapp',
              ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.continueMobile,
              icon: Icons.sms_outlined,
              onPressed: () => AppRouter.open(context, AppRoutes.otp),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.continueEmail,
              icon: Icons.mail_outline,
              onPressed: () => _emailComingSoon(context),
            ),
            TextButton(
              onPressed: () => AppRouter.open(context, AppRoutes.profile),
              child: Text(l10n.skipForNow),
            ),
          ],
        ),
      ),
    );
  }
}
