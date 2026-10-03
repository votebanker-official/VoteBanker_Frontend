import '../../../core/services/auth_service.dart';

/// Whether [input] can be kept as a profile contact number.
///
/// An empty value is allowed. National 10-digit numbers follow
/// [AuthService.normalizePhone]. International numbers may use a leading
/// +, a leading 00, or a single trunk 0 before a 10-digit national number.
/// Spaces, dots, hyphens, and parentheses are ignored.
bool isValidContactNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return true;
  }

  final compact = trimmed.replaceAll(RegExp(r'[\s\-.()]'), '');
  if (!RegExp(r'^(?:\+|00)?\d+$').hasMatch(compact)) {
    return false;
  }
  if (AuthService.normalizePhone(compact) != null) {
    return true;
  }

  final trunk = RegExp(r'^0(\d{10})$').firstMatch(compact);
  if (trunk != null && AuthService.normalizePhone(trunk.group(1)!) != null) {
    return true;
  }
  if (compact.startsWith('00')) {
    return AuthService.normalizePhone('+${compact.substring(2)}') != null;
  }
  return false;
}
