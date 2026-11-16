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

  /// Debug calls try the local backend first when the configured address is
  /// another port, so a pulled default of port 3000 does not blank API pages.
  static List<String> debugApiBases([List<String> overrides = const []]) {
    final configured = overrides.isNotEmpty ? overrides : [apiBaseUrl];
    if (!kDebugMode || overrides.isNotEmpty) return configured;
    const localApi = 'http://127.0.0.1:5000';
    final alreadyLocal = configured.any(
      (base) => base.contains('127.0.0.1:5000') || base.contains('localhost:5000'),
    );
    if (alreadyLocal) return configured;
    return [localApi, ...configured];
  }

  /// Country code assumed when a user types a 10-digit mobile number.
  static const defaultCountryCode = '+91';
}
