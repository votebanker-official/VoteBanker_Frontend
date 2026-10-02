import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/onboarding_frame.dart';

enum _OtpStep { phone, code }

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  _OtpStep _step = _OtpStep.phone;
  String? _phone;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = AuthService.normalizePhone(_phoneController.text);
    if (phone == null) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _phone = phone;
        _step = _OtpStep.code;
        _codeController.clear();
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyOtp(_phone!, code);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeNumber() {
    setState(() {
      _step = _OtpStep.phone;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onCodeStep = _step == _OtpStep.code;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              title: l10n.continueMobile,
              description: onCodeStep
                  ? 'We sent a 6-digit code to $_phone.'
                  : 'Enter your mobile number. We will text you a code.',
            ),
            const SizedBox(height: 24),
            if (!onCodeStep)
              AppTextField(
                controller: _phoneController,
                label: 'Mobile number',
                hint: '98765 43210',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                onSubmitted: (_) => _busy ? null : _sendCode(),
              )
            else
              AppTextField(
                controller: _codeController,
                label: 'Verification code',
                hint: '123456',
                prefixIcon: const Icon(Icons.lock_outline),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) => _busy ? null : _verifyCode(),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _busy
                  ? 'Please wait...'
                  : (onCodeStep ? 'Verify and continue' : 'Send code'),
              icon: onCodeStep ? Icons.verified_outlined : Icons.sms_outlined,
              onPressed: _busy ? () {} : (onCodeStep ? _verifyCode : _sendCode),
            ),
            const SizedBox(height: 8),
            if (onCodeStep) ...[
              TextButton(
                onPressed: _busy ? null : _sendCode,
                child: const Text('Resend code'),
              ),
              TextButton(
                onPressed: _busy ? null : _changeNumber,
                child: const Text('Change number'),
              ),
            ] else
              TextButton(
                onPressed: () => AppRouter.back(context, AppRoutes.login),
                child: Text(l10n.back),
              ),
          ],
        ),
      ),
    );
  }
}
