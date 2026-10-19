import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

abstract final class WebsiteValidators {
  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return ok ? null : 'Enter a valid email address';
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final normalized = AuthService.normalizePhone(text) ??
        (RegExp(r'^\+?[0-9][0-9\s-]{6,18}$').hasMatch(text) ? text : null);
    if (normalized == null) {
      return 'Enter a valid phone number (${AppConfig.defaultCountryCode}…)';
    }
    return null;
  }

  static String? url(String? value, {String label = 'URL'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Enter a valid $label (https://…)';
    }
    return null;
  }
}
