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

  /// Country code assumed when a user types a 10-digit mobile number.
  static const defaultCountryCode = '+91';
}
