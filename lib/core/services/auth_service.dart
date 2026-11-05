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
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phone;
  final String fullName;
  final String email;
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
  static const _prefsExpires = 'auth.expires_at';

  AuthSession? session;

  bool get isSignedIn => session != null;

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
      expiresAt: prefs.getInt(_prefsExpires),
    );
  }

  Future<void> sendOtp(String phone) async {
    await _post('/api/auth/otp/send', {'phone': phone, 'channel': 'whatsapp'});
  }

  /// Opens a social provider in the browser. The provider sends the user back here.
  void startSocial(String provider) {
    if (!kIsWeb) {
      throw const AuthException(
        'social_web_only',
        'Open VoteBanker in the browser to sign in with Facebook, Google, or Instagram.',
      );
    }
    final origin = browserOrigin();
    final uri =
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/oauth/$provider/start')
            .replace(queryParameters: {'return_to': '$origin/'});
    redirectBrowser(uri.toString());
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

  Future<void> signOut() async {
    session = null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _prefsAccess,
      _prefsRefresh,
      _prefsUser,
      _prefsPhone,
      _prefsFullName,
      _prefsEmail,
      _prefsExpires,
    ]) {
      await prefs.remove(key);
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
    if (s.expiresAt != null) await prefs.setInt(_prefsExpires, s.expiresAt!);
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
    } catch (_) {
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
      case 'social_expired':
        return 'That sign-in expired. Please try Facebook, Google, or Instagram again.';
      case 'social_not_configured':
        return 'Facebook, Google, and Instagram sign-in are not set up on the server yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
