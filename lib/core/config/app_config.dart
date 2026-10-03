/// Build-time configuration.
///
/// Override at build time with:
///   flutter build web --dart-define=API_BASE_URL=https://your-backend
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://votebankerbackend-production.up.railway.app',
  );

  /// Country code assumed when a user types a 10-digit mobile number.
  static const defaultCountryCode = '+91';
}
