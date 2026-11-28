import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import 'password_reset_chrome.dart';
import 'password_reset_request.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  _RecoveryMethod _method = _RecoveryMethod.email;
  String? _error;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _selectMethod(_RecoveryMethod method) {
    if (_method == method) return;
    setState(() {
      _method = method;
      _error = null;
      _sent = false;
    });
  }

  Future<void> _continue() async {
    if (_busy) return;
    final raw =
        _method == _RecoveryMethod.email
            ? _email.text.trim()
            : '${AppConfig.defaultCountryCode}${_phone.text.trim()}';
    final request = PasswordResetRequest.parse(raw);
    if (request == null ||
        (_method == _RecoveryMethod.email &&
            (request.isEmail == false || request.identifier.length > 160)) ||
        (_method == _RecoveryMethod.phone && request.isEmail)) {
      setState(() {
        _error =
            _method == _RecoveryMethod.email
                ? 'Enter a valid email address.'
                : 'Enter a valid 10-digit phone number.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (request.isEmail) {
        await AuthService.instance.requestPasswordReset(request.identifier);
      } else {
        await AuthService.instance.sendPasswordResetOtp(request.phoneNumber);
      }
      if (!mounted) return;
      if (request.isEmail) {
        setState(() => _sent = true);
      } else {
        AppRouter.open(context, AppRoutes.resetOtp, arguments: request);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not request a reset link. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PasswordResetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResetBrand(),
          const SizedBox(height: 16),
          const _ShieldMark(),
          const SizedBox(height: 16),
          const ResetHeading(
            title: 'Forgot Password?',
            subtitle: 'Enter your registered Email or Mobile Number',
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 4,
            children: [
              _RecoveryOption(
                label: 'Email Address',
                selected: _method == _RecoveryMethod.email,
                onTap: () => _selectMethod(_RecoveryMethod.email),
              ),
              _RecoveryOption(
                label: 'Phone Number',
                selected: _method == _RecoveryMethod.phone,
                onTap: () => _selectMethod(_RecoveryMethod.phone),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_sent) ...[
            Text(
              'If an account exists for this email, a password reset link has been sent. Check your inbox and spam folder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: resetNavyFor(context),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
          ],
          ResetField(
            controller: _method == _RecoveryMethod.email ? _email : _phone,
            hint:
                _method == _RecoveryMethod.email
                    ? 'Email Address'
                    : 'Phone Number',
            icon:
                _method == _RecoveryMethod.email
                    ? Icons.mail_outline_rounded
                    : Icons.phone_android_rounded,
            prefixText:
                _method == _RecoveryMethod.phone
                    ? '${AppConfig.defaultCountryCode} '
                    : null,
            keyboardType:
                _method == _RecoveryMethod.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continue(),
            onChanged: (_) {
              if (_error != null || _sent) {
                setState(() {
                  _error = null;
                  _sent = false;
                });
              }
            },
            errorText: _error,
          ),
          const SizedBox(height: 18),
          ResetPrimaryButton(
            label:
                _busy
                    ? 'Sending...'
                    : _sent
                    ? 'Send Another Link'
                    : 'Continue',
            onPressed: _busy ? null : _continue,
          ),
          ResetTextLink(
            label: 'Back to Login',
            onPressed: () => goToLogin(context),
          ),
        ],
      ),
    );
  }
}

enum _RecoveryMethod { email, phone }

class _RecoveryOption extends StatelessWidget {
  const _RecoveryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? resetBlueFor(context) : resetMutedFor(context),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: resetNavyFor(context),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShieldMark extends StatelessWidget {
  const _ShieldMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : const Color(0xFFE8F3FF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: resetBlueFor(context),
        size: 36,
      ),
    );
  }
}
