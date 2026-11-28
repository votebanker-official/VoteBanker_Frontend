import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import 'password_reset_chrome.dart';

class ResetSuccessScreen extends StatefulWidget {
  const ResetSuccessScreen({super.key});

  @override
  State<ResetSuccessScreen> createState() => _ResetSuccessScreenState();
}

class _ResetSuccessScreenState extends State<ResetSuccessScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(seconds: 4), _goToLogin);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (mounted) goToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final sessionRevocationFailed =
        AuthService.instance.passwordResetSessionRevocationFailed;
    final authSyncPending = AuthService.instance.passwordResetAuthSyncPending;
    return PasswordResetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResetBrand(),
          const SizedBox(height: 22),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : const Color(0xFFE7F8EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: resetSuccess,
              size: 52,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Password Reset Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resetBlueFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionRevocationFailed
                ? 'Your password was changed, but other sessions could not be closed. Please sign in with your new password.'
                : authSyncPending
                ? 'Your password was saved. Sign in with your new password to finish syncing your account.'
                : 'Your password has been updated. You can now login with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resetNavyFor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ResetPrimaryButton(label: 'Go to Login', onPressed: _goToLogin),
          const SizedBox(height: 8),
          Text(
            'Redirecting to Login...',
            style: TextStyle(color: resetMutedFor(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
