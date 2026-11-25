import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import 'password_reset_chrome.dart';
import 'password_reset_request.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _continue() {
    final request = PasswordResetRequest.parse(_identifier.text);
    if (request == null) {
      setState(() {
        _error = 'Enter a valid email or 10-digit mobile number.';
      });
      return;
    }
    AppRouter.open(context, AppRoutes.resetChannel, arguments: request);
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
          ResetField(
            controller: _identifier,
            hint: 'Email / Mobile Number',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continue(),
            errorText: _error,
          ),
          const SizedBox(height: 18),
          ResetPrimaryButton(label: 'Continue', onPressed: _continue),
          ResetTextLink(
            label: 'Back to Login',
            onPressed: () => goToLogin(context),
          ),
        ],
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
      decoration: const BoxDecoration(
        color: Color(0xFFE8F3FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.shield_outlined, color: resetBlue, size: 36),
    );
  }
}
