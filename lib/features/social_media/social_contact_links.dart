/// Safe links for saved VRM social contacts.
/// Usernames stay as text. Only a real http(s) profile URL on the expected host opens.
abstract final class SocialContactLinks {
  static const instagramHosts = {
    'instagram.com',
    'www.instagram.com',
  };

  static const facebookHosts = {
    'facebook.com',
    'www.facebook.com',
    'm.facebook.com',
    'fb.com',
    'www.fb.com',
    'm.fb.com',
  };

  static bool validWhatsapp(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return true;
    if (!RegExp(r'^[0-9+\-().\s]+$').hasMatch(value)) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  static bool validProfile(String raw, Set<String> hosts) {
    final value = raw.trim();
    if (value.isEmpty) return true;
    final url = profileUrl(value, hosts);
    if (url != null) return true;
    if (value.contains(RegExp(r'[\s/\\]')) || value.contains('://')) return false;
    final handle = value.startsWith('@') ? value.substring(1) : value;
    return RegExp(r'^[A-Za-z0-9._]{1,50}$').hasMatch(handle);
  }

  static Uri? whatsAppUrl(String raw) {
    if (!validWhatsapp(raw) || raw.trim().isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) return null;
    return Uri.parse('https://wa.me/$digits');
  }

  static Uri? profileUrl(String raw, Set<String> hosts) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.userInfo.isNotEmpty) return null;
    if (!hosts.contains(uri.host.toLowerCase())) return null;
    return uri;
  }
}
