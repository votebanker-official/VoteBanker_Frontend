import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/services/auth_service.dart';
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
  String? _error;
  bool _busy = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _channel =
        widget.request.isEmail ? OtpChannel.email : widget.request.channel;
  }

  Future<void> _send() async {
    if (_busy) return;
    if (!widget.request.isEmail && _channel != OtpChannel.sms) {
      setState(() {
        _error = 'Phone password recovery is available by SMS only.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.request.isEmail) {
        await AuthService.instance.requestPasswordReset(
          widget.request.identifier,
        );
        if (mounted) setState(() => _sent = true);
      } else {
        await AuthService.instance.sendPasswordResetOtp(
          widget.request.phoneNumber,
        );
        if (mounted) {
          AppRouter.open(
            context,
            AppRoutes.resetOtp,
            arguments: widget.request.withChannel(OtpChannel.sms),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not start recovery. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                    ? 'Get a reset link at ${request.maskedEmail}'
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
          if (_sent) ...[
            Text(
              'If an account exists for this email, a password reset link has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: resetNavyFor(context),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: resetDanger, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
          ResetPrimaryButton(
            label:
                _busy
                    ? 'Sending...'
                    : widget.request.isEmail
                    ? _sent
                        ? 'Send Another Link'
                        : 'Send Reset Link'
                    : 'Send OTP',
            onPressed: _busy ? null : _send,
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
