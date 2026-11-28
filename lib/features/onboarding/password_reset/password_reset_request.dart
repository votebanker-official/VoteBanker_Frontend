import '../../../core/config/app_config.dart';

enum OtpChannel { sms, email, whatsapp }

/// Identifier collected on the first screen and carried through the flow.
class PasswordResetRequest {
  const PasswordResetRequest({
    required this.identifier,
    required this.isEmail,
    this.channel = OtpChannel.sms,
  });

  final String identifier;
  final bool isEmail;
  final OtpChannel channel;

  PasswordResetRequest withChannel(OtpChannel value) {
    return PasswordResetRequest(
      identifier: identifier,
      isEmail: isEmail,
      channel: value,
    );
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns a request when [raw] is an email or a 10-digit mobile number.
  static PasswordResetRequest? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.contains('@')) {
      if (!_email.hasMatch(value)) return null;
      return PasswordResetRequest(identifier: value, isEmail: true);
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final local =
        digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    if (local.length != 10 || local.startsWith('0')) return null;
    return PasswordResetRequest(identifier: local, isEmail: false);
  }

  String get maskedEmail {
    final at = identifier.indexOf('@');
    if (!isEmail || at <= 0) return identifier;
    final name = identifier.substring(0, at);
    final domain = identifier.substring(at);
    if (name.length <= 2) return '${name[0]}***$domain';
    return '${name[0]}***${name[name.length - 1]}$domain';
  }

  String get maskedMobile {
    final digits = identifier.replaceAll(RegExp(r'\D'), '');
    final local =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (local.length < 4) return local;
    return '${AppConfig.defaultCountryCode} ${local.substring(0, 2)}*** **${local.substring(local.length - 3)}';
  }

  String get phoneNumber {
    final digits = identifier.replaceAll(RegExp(r'\D'), '');
    return '${AppConfig.defaultCountryCode}$digits';
  }

  String destinationFor(OtpChannel value) {
    return value == OtpChannel.email ? maskedEmail : maskedMobile;
  }
}
