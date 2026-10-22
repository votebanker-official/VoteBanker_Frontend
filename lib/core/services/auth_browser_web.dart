import 'package:web/web.dart';

String browserOrigin() => window.location.origin;

void redirectBrowser(String url) {
  window.location.assign(url);
}

void clearAuthQuery() {
  final clean = '${window.location.origin}${window.location.pathname}';
  window.history.replaceState(null, '', clean);
}
