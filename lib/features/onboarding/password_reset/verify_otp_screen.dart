import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routing/app_router.dart';
import 'password_reset_chrome.dart';
import 'password_reset_request.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({required this.request, super.key});

  final PasswordResetRequest request;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const _seconds = 30;

  final _nodes = List.generate(6, (_) => FocusNode());
  final _boxes = List.generate(6, (_) => TextEditingController());
  Timer? _timer;
  int _remaining = _seconds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final node in _nodes) {
      node.dispose();
    }
    for (final box in _boxes) {
      box.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  String get _code => _boxes.map((box) => box.text).join();

  String get _channelLabel {
    switch (widget.request.channel) {
      case OtpChannel.sms:
        return 'SMS';
      case OtpChannel.email:
        return 'email';
      case OtpChannel.whatsapp:
        return 'WhatsApp';
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 6; i++) {
        _boxes[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, 5);
      _nodes[next].requestFocus();
      setState(() => _error = null);
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
  }

  void _verify() {
    if (_code.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP.');
      return;
    }
    AppRouter.open(context, AppRoutes.resetPassword, arguments: widget.request);
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.request.destinationFor(widget.request.channel);
    final clock =
        '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';

    return PasswordResetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResetBrand(),
          const SizedBox(height: 18),
          ResetHeading(
            title: 'Verify OTP',
            subtitle:
                'Enter the 6-digit OTP sent by $_channelLabel to $destination',
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 6; i++)
                SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _boxes[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: resetNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: resetField),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: resetBlue, width: 1.4),
                      ),
                    ),
                    onChanged: (value) => _onChanged(i, value),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: resetDanger, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          _remaining > 0
              ? Text(
                  'Resend OTP in $clock',
                  style: const TextStyle(color: resetMuted, fontSize: 13),
                )
              : TextButton(
                  onPressed: () {
                    for (final box in _boxes) {
                      box.clear();
                    }
                    _nodes.first.requestFocus();
                    _startTimer();
                  },
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: resetBlue, fontWeight: FontWeight.w700),
                  ),
                ),
          const SizedBox(height: 8),
          ResetPrimaryButton(label: 'Verify', onPressed: _verify),
          ResetTextLink(
            label: 'Change OTP channel',
            onPressed: () => AppRouter.back(context, AppRoutes.resetChannel),
          ),
          TextButton(
            onPressed: () => goToLogin(context),
            child: const Text(
              'Back to Login',
              style: TextStyle(color: resetNavy, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
