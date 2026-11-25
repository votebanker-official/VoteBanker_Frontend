import 'package:flutter/material.dart';

import 'password_reset_chrome.dart';

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PasswordResetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResetBrand(),
          const SizedBox(height: 22),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F8EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: resetSuccess,
              size: 52,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Password Reset Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resetBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your password has been updated. You can now login with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resetNavy,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ResetPrimaryButton(
            label: 'Go to Login',
            onPressed: () => goToLogin(context),
          ),
        ],
      ),
    );
  }
}
