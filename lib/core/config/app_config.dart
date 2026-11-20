import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Override at build time with:
///   flutter build web --dart-define=API_BASE_URL=https://your-backend
abstract final class AppConfig {
  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Local `flutter run` talks to the API on the backend's port.
  /// Release builds keep the hosted API unless API_BASE_URL is set.
  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
    if (kDebugMode) return 'http://127.0.0.1:5000';
    return 'https://votebankerbackend-production.up.railway.app';
  }

  /// Debug calls try the local backend on port 5000, then port 3000.
  /// A machine whose backend `.env` uses PORT=3000 still reaches the API
  /// when nothing is listening on 5000. Explicit overrides stay unchanged.
  static List<String> debugApiBases([List<String> overrides = const []]) {
    final configured = overrides.isNotEmpty ? overrides : [apiBaseUrl];
    if (!kDebugMode || overrides.isNotEmpty) return configured;
    const port5000 = 'http://127.0.0.1:5000';
    const port3000 = 'http://127.0.0.1:3000';
    final bases = <String>[...configured];
    bool hasPort(String port) => bases.any(
          (base) =>
              base.contains('127.0.0.1:$port') ||
              base.contains('localhost:$port'),
        );
    if (!hasPort('5000')) bases.insert(0, port5000);
    if (!hasPort('3000')) bases.add(port3000);
    return bases;
  }

  /// Country code assumed when a user types a 10-digit mobile number.
  static const defaultCountryCode = '+91';
}
