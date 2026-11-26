import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import 'password_reset_chrome.dart';
import 'password_reset_request.dart';

class OtpChannelScreen extends StatefulWidget {
  const OtpChannelScreen({required this.request, super.key});

  final PasswordResetRequest request;

  @override
  State<OtpChannelScreen> createState() => _OtpChannelScreenState();
}

class _OtpChannelScreenState extends State<OtpChannelScreen> {
  late OtpChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel =
        widget.request.isEmail ? OtpChannel.email : widget.request.channel;
  }

  void _send() {
    AppRouter.open(
      context,
      AppRoutes.resetOtp,
      arguments: widget.request.withChannel(_channel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return PasswordResetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResetBrand(),
          const SizedBox(height: 18),
          const ResetHeading(
            title: 'Reset Your Password',
            subtitle: 'Choose how you want to receive your verification OTP',
          ),
          const SizedBox(height: 20),
          _ChannelTile(
            selected: _channel == OtpChannel.sms,
            enabled: !request.isEmail,
            icon: Icons.phone_outlined,
            iconColor: resetBlueFor(context),
            title: 'Via SMS',
            subtitle:
                request.isEmail
                    ? 'Add a mobile number to use SMS'
                    : 'Get OTP on ${request.maskedMobile}',
            onTap: () => setState(() => _channel = OtpChannel.sms),
          ),
          const SizedBox(height: 10),
          _ChannelTile(
            selected: _channel == OtpChannel.email,
            enabled: request.isEmail,
            icon: Icons.mail_outline_rounded,
            iconColor: const Color(0xFF7A5AF8),
            title: 'Via Email',
            subtitle:
                request.isEmail
                    ? 'Get OTP on ${request.maskedEmail}'
                    : 'Add an email address to use email',
            onTap: () => setState(() => _channel = OtpChannel.email),
          ),
          const SizedBox(height: 10),
          _ChannelTile(
            selected: _channel == OtpChannel.whatsapp,
            enabled: !request.isEmail,
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF12B76A),
            title: 'Via WhatsApp',
            subtitle:
                request.isEmail
                    ? 'Add a mobile number to use WhatsApp'
                    : 'Get OTP on WhatsApp ${request.maskedMobile}',
            onTap: () => setState(() => _channel = OtpChannel.whatsapp),
          ),
          const SizedBox(height: 20),
          ResetPrimaryButton(label: 'Send OTP', onPressed: _send),
          ResetTextLink(
            label: 'Back to Login',
            onPressed: () => goToLogin(context),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color:
            selected
                ? theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF3F8FF)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    selected
                        ? resetBlueFor(context)
                        : theme.brightness == Brightness.dark
                        ? theme.dividerColor
                        : const Color(0xFFD7E8F8),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: resetNavyFor(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: resetMutedFor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color:
                      selected ? resetBlueFor(context) : resetMutedFor(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
