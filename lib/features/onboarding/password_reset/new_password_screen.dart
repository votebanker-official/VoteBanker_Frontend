import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
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

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _longEnough => _password.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password.text);
  bool get _valid => _longEnough && _hasUpper && _hasNumber;

  void _submit() {
    if (!_valid) {
      setState(() => _error = 'Meet every password requirement.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    AppRouter.open(context, AppRoutes.resetSuccess, arguments: widget.request);
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
            onChanged: (_) => setState(() => _error = null),
            suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: resetMuted,
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
            onChanged: (_) => setState(() => _error = null),
            errorText: _error,
            suffix: IconButton(
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: resetMuted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Rule(met: _longEnough, label: 'Minimum 8 characters'),
          _Rule(met: _hasUpper, label: 'Include one uppercase letter'),
          _Rule(met: _hasNumber, label: 'Include one number'),
          const SizedBox(height: 18),
          ResetPrimaryButton(
            label: 'Reset Password',
            onPressed:
                _valid && _password.text == _confirm.text ? _submit : null,
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
            color: met ? resetSuccess : resetMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: met ? resetNavy : resetMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
