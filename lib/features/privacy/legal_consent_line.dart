import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';

/// Consent line for sign-in, registration, and OTP. Privacy Policy is tappable.
/// Terms has no page yet, so that word stays text.
class LegalConsentLine extends StatefulWidget {
  const LegalConsentLine({super.key});

  @override
  State<LegalConsentLine> createState() => _LegalConsentLineState();
}

class _LegalConsentLineState extends State<LegalConsentLine> {
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => AppNav.open(context, AppRoutes.privacyPolicy);

  @override
  void dispose() {
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      color: Color(0xFF263B60),
      fontSize: 12.5,
      height: 1.45,
    );
    const link = TextStyle(
      color: Color(0xFF1765C5),
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      height: 1.45,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: body,
        children: [
          const TextSpan(text: 'By continuing, you agree to our Terms & '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
