import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
import 'password_reset_chrome.dart';
import 'password_reset_request.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({required this.request, super.key});

  final PasswordResetRequest request;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;
  bool _busy = false;
  bool _linkInvalid = false;

  @override
  void initState() {
    super.initState();
    if (!AuthService.instance.hasPendingPasswordReset) {
      _linkInvalid = true;
      _error =
          AuthService.instance.passwordRecoveryError ??
          'This reset link is invalid or has expired. Request a new one.';
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _longEnough => _password.text.length >= 8;
  bool get _hasLetter => RegExp(r'[A-Za-z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password.text);
  bool get _valid =>
      _longEnough && _password.text.length <= 128 && _hasLetter && _hasNumber;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_valid) {
      setState(() => _error = 'Meet every password requirement.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.completePasswordReset(
        password: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.resetSuccess, (route) => false);
    } on AuthException catch (error) {
      if (error.code == 'password_reset_session_revoke_failed') {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.resetSuccess, (route) => false);
        }
        return;
      }
      if (error.code == 'invalid_reset_link' ||
          error.code == 'reset_link_expired') {
        _linkInvalid = true;
      }
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not reset the password. Please try again.',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: ResetBrand()),
          const SizedBox(height: 18),
          const Center(
            child: ResetHeading(
              title: 'Create New Password',
              subtitle: 'Enter your new password',
            ),
          ),
          const SizedBox(height: 22),
          ResetField(
            controller: _password,
            hint: 'New Password',
            icon: Icons.lock_outline_rounded,
            obscure: _hidePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (!_linkInvalid) setState(() => _error = null);
            },
            suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: resetMutedFor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ResetField(
            controller: _confirm,
            hint: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscure: _hideConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (!_linkInvalid) setState(() => _error = null);
            },
            errorText: _error,
            suffix: IconButton(
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: resetMutedFor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Rule(met: _longEnough, label: 'Minimum 8 characters'),
          _Rule(met: _hasLetter, label: 'Include at least one letter'),
          _Rule(met: _hasNumber, label: 'Include one number'),
          const SizedBox(height: 18),
          ResetPrimaryButton(
            label: _busy ? 'Updating...' : 'Reset Password',
            onPressed:
                !_busy &&
                        AuthService.instance.hasPendingPasswordReset &&
                        _valid &&
                        _password.text == _confirm.text
                    ? _submit
                    : null,
          ),
          if (!_busy)
            Center(
              child: ResetTextLink(
                label: 'Request a new reset link or code',
                onPressed:
                    () => AppRouter.open(context, AppRoutes.forgotPassword),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: met ? resetSuccess : resetMutedFor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: met ? resetNavyFor(context) : resetMutedFor(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
