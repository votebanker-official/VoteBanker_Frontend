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
    // Use localhost, not 127.0.0.1. The Flutter page is opened on localhost,
    // and Chrome blocks its requests to 127.0.0.1 as a private-network call.
    if (kDebugMode) return 'http://localhost:5000';
    return 'https://votebankerbackend-production.up.railway.app';
  }

  /// Debug calls try the local backend on port 5000, then port 3000.
  /// A machine whose backend `.env` uses PORT=3000 still reaches the API
  /// when nothing is listening on 5000. Explicit overrides stay unchanged.
  static List<String> debugApiBases([List<String> overrides = const []]) {
    final configured = overrides.isNotEmpty ? overrides : [apiBaseUrl];
    if (!kDebugMode || overrides.isNotEmpty) return configured;
    const localhost5000 = 'http://localhost:5000';
    const loopback5000 = 'http://127.0.0.1:5000';
    const port3000 = 'http://localhost:3000';
    final bases = <String>[...configured];
    bool hasHostPort(String host, String port) =>
        bases.any((base) => base.contains('$host:$port'));
    if (!hasHostPort('localhost', '5000')) bases.insert(0, localhost5000);
    if (!hasHostPort('127.0.0.1', '5000')) bases.add(loopback5000);
    if (!hasHostPort('localhost', '3000') &&
        !hasHostPort('127.0.0.1', '3000')) {
      bases.add(port3000);
    }
    return bases;
  }

  /// Country code assumed when a user types a 10-digit mobile number.
  static const defaultCountryCode = '+91';

  static const _configuredVrmRecordsUrl = String.fromEnvironment(
    'VRM_RECORDS_URL',
    defaultValue: '',
  );

  /// Voter records application. Local runs open the dev page on port 61714.
  /// Set VRM_RECORDS_URL at build time for the production address.
  static String get vrmRecordsUrl {
    if (_configuredVrmRecordsUrl.isNotEmpty) return _configuredVrmRecordsUrl;
    if (kDebugMode) return 'http://localhost:61714/vrm/records';
    return '';
  }

  static const _configuredReadyUrl = String.fromEnvironment(
    'READY_URL',
    defaultValue: '',
  );

  /// Optional external ready page. Without an override, the app uses its
  /// internal ready route so local navigation stays on the active dev server.
  static String get readyUrl {
    return _configuredReadyUrl;
  }
}
