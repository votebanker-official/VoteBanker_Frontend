import 'package:web/web.dart';

String browserOrigin() => window.location.origin;

/// The real page address, including `auth_ticket`. `Uri.base` follows the
/// `<base href>` and drops that query, so Facebook's return would be ignored.
Uri browserLocation() => Uri.parse(window.location.href);

/// Reads a value stashed by index.html, then removes it so it cannot be reused.
String? takeSessionValue(String key) {
  final value = window.sessionStorage.getItem(key);
  if (value == null || value.isEmpty) return null;
  window.sessionStorage.removeItem(key);
  return value;
}

void redirectBrowser(String url) {
  window.location.assign(url);
}

void replaceBrowserPath(String path) {
  final normalized = path.startsWith('/') ? path : '/$path';
  window.history.replaceState(null, '', '${window.location.origin}$normalized');
}

void clearAuthQuery() {
  replaceBrowserPath(window.location.pathname);
}
