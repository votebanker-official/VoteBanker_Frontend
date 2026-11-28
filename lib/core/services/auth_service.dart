import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_browser.dart';

class AuthException implements Exception {
  const AuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phone,
    this.fullName = '',
    this.email = '',
    this.avatarUrl = '',
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phone;
  final String fullName;
  final String email;
  final String avatarUrl;
  final int? expiresAt;
}

/// Talks to the VoteBanker backend for phone-OTP sign in.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _prefsAccess = 'auth.access_token';
  static const _prefsRefresh = 'auth.refresh_token';
  static const _prefsUser = 'auth.user_id';
  static const _prefsPhone = 'auth.phone';
  static const _prefsFullName = 'auth.full_name';
  static const _prefsEmail = 'auth.email';
  static const _prefsAvatar = 'auth.avatar_url';
  static const _prefsExpires = 'auth.expires_at';

  AuthSession? session;
  final List<void Function()> _sessionCleared = [];
  String? _pendingSocialTicket;
  String? _pendingSocialError;

  /// Set when Facebook sends the browser back with an error before a session exists.
  String? socialLaunchError;

  /// True after this page load redeemed a Facebook sign-in ticket.
  bool openProfileAfterLogin = false;

  String? _pendingPostLoginRoute;

  bool get isSignedIn => session != null;

  void rememberPostLoginRoute(String route) {
    _pendingPostLoginRoute = route;
    saveSessionValue('vb_post_login_route', route);
  }

  String? takePostLoginRoute() {
    final route = _pendingPostLoginRoute;
    _pendingPostLoginRoute = null;
    final savedRoute = takeSessionValue('vb_post_login_route');
    return route ?? savedRoute;
  }

  String get signedInEmail {
    final current = session;
    if (current == null) return '';
    final tokenEmail = _usableEmail(emailFromAccessToken(current.accessToken));
    if (tokenEmail.isNotEmpty) return tokenEmail;
    final sessionEmail = _usableEmail(current.email);
    return sessionEmail.isNotEmpty ? sessionEmail : current.email.trim();
  }

  static String _usableEmail(String email) {
    final normalized = email.trim();
    final lower = normalized.toLowerCase();
    if (lower.endsWith('@social.votebanker.app') ||
        lower.endsWith('@phone.votebanker.app')) {
      return '';
    }
    return normalized;
  }

  static String emailFromAccessToken(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length != 3) return '';
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      if (claims is! Map || claims['email'] is! String) return '';
      return (claims['email'] as String).trim();
    } on FormatException {
      return '';
    }
  }

  /// Runs after the saved session is cleared. Used so admin visibility cannot outlive logout.
  void onSessionCleared(void Function() listener) {
    _sessionCleared.add(listener);
  }

  void _notifySessionCleared() {
    for (final listener in List<void Function()>.from(_sessionCleared)) {
      listener();
    }
  }

  /// Reads the Google return query once, before routing can drop it.
  void captureSocialReturn() {
    final params = Uri.base.queryParameters;
    final ticket = params['auth_ticket'];
    final error = params['auth_error'];
    if ((ticket == null || ticket.isEmpty) &&
        (error == null || error.isEmpty)) {
      return;
    }
    _pendingSocialTicket = ticket;
    _pendingSocialError = error;
    clearAuthQuery();
  }

  ({String? ticket, String? error}) takeSocialReturn() {
    final ticket = _pendingSocialTicket;
    final error = _pendingSocialError;
    _pendingSocialTicket = null;
    _pendingSocialError = null;
    final params = Uri.base.queryParameters;
    return (
      ticket:
          (ticket != null && ticket.isNotEmpty)
              ? ticket
              : params['auth_ticket'],
      error: (error != null && error.isNotEmpty) ? error : params['auth_error'],
    );
  }

  /// Turns user input into E.164, or returns null if it is not a valid number.
  static String? normalizePhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty) return null;

    String candidate;
    if (cleaned.startsWith('+')) {
      candidate = cleaned;
    } else if (RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      candidate = '${AppConfig.defaultCountryCode}$cleaned';
    } else {
      return null;
    }

    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(candidate) ? candidate : null;
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_prefsAccess);
    final refresh = prefs.getString(_prefsRefresh);
    final user = prefs.getString(_prefsUser);
    final phone = prefs.getString(_prefsPhone);
    if (access == null || refresh == null || user == null || phone == null) {
      return;
    }
    session = AuthSession(
      accessToken: access,
      refreshToken: refresh,
      userId: user,
      phone: phone,
      fullName: prefs.getString(_prefsFullName) ?? '',
      email: prefs.getString(_prefsEmail) ?? '',
      avatarUrl: prefs.getString(_prefsAvatar) ?? '',
      expiresAt: prefs.getInt(_prefsExpires),
    );
  }

  Future<void> sendOtp(String phone) async {
    await _post('/api/auth/otp/send', {'phone': phone, 'channel': 'whatsapp'});
  }

  Future<AuthSession> register({
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) async {
    final body = await _post('/api/auth/register', {
      'email': email.trim(),
      'mobile': mobile.trim(),
      'password': password,
      'confirm_password': confirmPassword,
      'terms_accepted': termsAccepted,
    });
    return _sessionFromResponse(body, fallbackPhone: mobile.trim());
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final body = await _post('/api/auth/login', {
      'identifier': identifier.trim(),
      'password': password,
    });
    return _sessionFromResponse(body);
  }

  AuthSession _sessionFromResponse(
    Map<String, dynamic> body, {
    String fallbackPhone = '',
  }) {
    final user = body['user'] as Map<String, dynamic>? ?? const {};
    final result = AuthSession(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      userId: (user['id'] ?? '') as String,
      phone: (user['phone'] ?? fallbackPhone) as String,
      fullName: (user['full_name'] ?? '') as String,
      email: (user['email'] ?? '') as String,
      avatarUrl: (user['avatar_url'] ?? '') as String,
      expiresAt: body['expires_at'] as int?,
    );
    session = result;
    unawaited(_persist(result));
    return result;
  }

  /// Opens a social provider in the browser. The provider sends the user back here.
  Future<void> startSocial(String provider) async {
    if (!kIsWeb) {
      throw const AuthException(
        'social_web_only',
        'Open VoteBanker in the browser to sign in with Facebook, Google, or Instagram.',
      );
    }
    final origin = browserOrigin();
    final returnTo =
        provider == 'google' ? '$origin/profile' : '$origin/auth/callback';
    final apiBase = await _reachableApiBase();
    final uri = Uri.parse(
      '$apiBase/api/auth/oauth/$provider/start',
    ).replace(queryParameters: {'return_to': returnTo});
    redirectBrowser(uri.toString());
  }

  /// Redeems a Facebook return ticket before the first screen is built.
  /// The browser URL is then the leader profile, with the query removed.
  Future<void> completeSocialLaunch() async {
    final location = browserLocation();
    final ticket =
        takeSessionValue('vb_auth_ticket') ??
        location.queryParameters['auth_ticket'];
    final error =
        takeSessionValue('vb_auth_error') ??
        location.queryParameters['auth_error'];
    if ((ticket == null || ticket.isEmpty) &&
        (error == null || error.isEmpty)) {
      return;
    }
    if (error != null && error.isNotEmpty) {
      socialLaunchError = error;
      replaceBrowserPath('/');
      return;
    }
    try {
      await exchangeSocialTicket(ticket!);
      openProfileAfterLogin = true;
      replaceBrowserPath('/profile');
    } on AuthException catch (error) {
      socialLaunchError = error.code;
      replaceBrowserPath('/');
    }
  }

  /// Redeems a Google or Facebook return ticket before the first screen is built.
  /// index.html moves the ticket into session storage before Flutter can read the URL.
  Future<void> completePendingSocialSignIn() async {
    final pending = takeSocialReturn();
    var ticket = pending.ticket;
    var error = pending.error;
    var source = (ticket != null && ticket.isNotEmpty) ? 'query' : '';
    if (ticket == null || ticket.isEmpty) {
      ticket = takeSessionValue('vb_auth_ticket');
      if (ticket != null && ticket.isNotEmpty) source = 'session';
    }
    if (error == null || error.isEmpty) {
      error = takeSessionValue('vb_auth_error');
    }
    if (ticket == null || ticket.isEmpty || error == null || error.isEmpty) {
      final location = browserLocation();
      if (ticket == null || ticket.isEmpty) {
        final fromLocation = location.queryParameters['auth_ticket'];
        if (fromLocation != null && fromLocation.isNotEmpty) {
          ticket = fromLocation;
          source = 'location';
        }
      }
      if (error == null || error.isEmpty) {
        error = location.queryParameters['auth_error'];
      }
    }
    if (error != null && error.isNotEmpty) {
      socialLaunchError = error;
      return;
    }
    if (ticket == null || ticket.isEmpty) return;
    try {
      await exchangeSocialTicket(ticket);
      openProfileAfterLogin = true;
    } on AuthException catch (error) {
      socialLaunchError = error.code;
    }
  }

  Future<AuthSession> exchangeSocialTicket(String ticket) async {
    final body = await _post('/api/auth/oauth/exchange', {'ticket': ticket});
    final user = body['user'] as Map<String, dynamic>? ?? const {};
    final result = AuthSession(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      userId: (user['id'] ?? '') as String,
      phone: (user['phone'] ?? '') as String,
      fullName: (user['full_name'] ?? '') as String,
      email: (user['email'] ?? '') as String,
      avatarUrl: (user['avatar_url'] ?? '') as String,
      expiresAt: body['expires_at'] as int?,
    );
    session = result;
    await _persist(result);
    return result;
  }

  Future<AuthSession> verifyOtp(String phone, String code) async {
    final body = await _post('/api/auth/otp/verify', {
      'phone': phone,
      'code': code,
    });

    final user = body['user'] as Map<String, dynamic>? ?? const {};
    final result = AuthSession(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      userId: (user['id'] ?? '') as String,
      phone: (user['phone'] ?? phone) as String,
      expiresAt: body['expires_at'] as int?,
    );
    session = result;
    await _persist(result);
    return result;
  }

  /// Asks the API for a new access token when the saved one is near expiry.
  Future<void> refreshIfExpired() async {
    final current = session;
    final expiresAt = current?.expiresAt;
    if (current == null || expiresAt == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt > now + 60) return;
    await refreshSession();
  }

  /// Replaces an expired access token. Returns false when the refresh token is rejected.
  Future<bool> refreshSession() async {
    final current = session;
    if (current == null || current.refreshToken.trim().isEmpty) return false;
    try {
      final body = await _post('/api/auth/session/refresh', {
        'refresh_token': current.refreshToken,
      });
      final user = body['user'] as Map<String, dynamic>? ?? const {};
      final result = AuthSession(
        accessToken: body['access_token'] as String,
        refreshToken:
            (body['refresh_token'] as String?) ?? current.refreshToken,
        userId: (user['id'] ?? current.userId) as String,
        phone: (user['phone'] ?? current.phone) as String,
        fullName:
            ((user['full_name'] as String?) ?? '').trim().isEmpty
                ? current.fullName
                : user['full_name'] as String,
        email:
            ((user['email'] as String?) ?? '').trim().isEmpty
                ? current.email
                : user['email'] as String,
        avatarUrl:
            ((user['avatar_url'] as String?) ?? '').trim().isEmpty
                ? current.avatarUrl
                : user['avatar_url'] as String,
        expiresAt: body['expires_at'] as int? ?? current.expiresAt,
      );
      session = result;
      await _persist(result);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    final token = session?.accessToken;
    session = null;
    _notifySessionCleared();
    if (token != null && token.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${AppConfig.apiBaseUrl}/api/auth/session/end'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Signing out locally still succeeds when the activity call cannot reach the API.
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        _prefsAccess,
        _prefsRefresh,
        _prefsUser,
        _prefsPhone,
        _prefsFullName,
        _prefsEmail,
        _prefsAvatar,
        _prefsExpires,
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Session is already cleared; storage may be unavailable in tests.
    }
  }

  Future<void> _persist(AuthSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAccess, s.accessToken);
    await prefs.setString(_prefsRefresh, s.refreshToken);
    await prefs.setString(_prefsUser, s.userId);
    await prefs.setString(_prefsPhone, s.phone);
    await prefs.setString(_prefsFullName, s.fullName);
    await prefs.setString(_prefsEmail, s.email);
    await prefs.setString(_prefsAvatar, s.avatarUrl);
    if (s.expiresAt != null) await prefs.setInt(_prefsExpires, s.expiresAt!);
  }

  /// Debug builds try port 5000, then 3000. A full-page Google redirect can
  /// only use one address, so pick the API that is actually listening.
  Future<String> _reachableApiBase() async {
    final bases = AppConfig.debugApiBases();
    if (bases.length <= 1) return bases.first;
    for (final base in bases) {
      try {
        final response = await http
            .get(Uri.parse('$base/api/health'))
            .timeout(const Duration(milliseconds: 800));
        if (response.statusCode >= 200 && response.statusCode < 500) {
          return base;
        }
      } catch (_) {
        // Try the next local port.
      }
    }
    return bases.first;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AuthException(
        'timeout',
        'The server took too long to respond. Please try again.',
      );
    } catch (error) {
      throw const AuthException(
        'network',
        'Could not reach the server. Check your internet connection.',
      );
    }

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // Non-JSON body; handled by the status check below.
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    final code = (body['error'] as String?) ?? 'server_error';
    throw AuthException(code, _messageFor(code));
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'invalid_phone':
        return 'Enter a valid mobile number.';
      case 'invalid_email':
        return 'Enter a valid email address.';
      case 'invalid_password':
        return 'Enter a valid password.';
      case 'password_too_short':
        return 'Password must be at least 8 characters long.';
      case 'password_weak':
        return 'Password must include at least one letter and one number.';
      case 'password_mismatch':
        return 'Passwords do not match.';
      case 'terms_required':
        return 'Please accept the Terms & Conditions.';
      case 'email_already_registered':
        return 'This email address is already registered. Please log in.';
      case 'mobile_already_registered':
        return 'This mobile number is already registered. Please log in.';
      case 'invalid_credentials':
        return 'Incorrect email/mobile number or password.';
      case 'invalid_code':
        return 'Enter the 6-digit code.';
      case 'incorrect_code':
        return 'That code is not correct. Please try again.';
      case 'code_expired':
        return 'That code has expired. Request a new one.';
      case 'channel_unavailable':
        return 'WhatsApp OTP is not configured yet. Please contact the administrator.';
      case 'demo_number_not_allowed':
        return 'This number is not enabled for the demo.';
      case 'whatsapp_only':
        return 'Only WhatsApp OTP is supported.';
      case 'profile_unavailable':
        return 'We could not load your profile. Please try again.';
      case 'number_not_verified':
        return 'This number is not enabled for testing yet. '
            'Ask the VoteBanker team to add it, then try again.';
      case 'too_many_requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'registration_unavailable':
        return 'Account registration is temporarily unavailable. Please try again shortly.';
      case 'social_expired':
        return 'That sign-in expired. Please try Facebook, Google, or Instagram again.';
      case 'social_not_configured':
        return 'Facebook, Google, and Instagram sign-in are not set up on the server yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
