import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

class SocialConnectionException implements Exception {
  const SocialConnectionException(this.code);

  final String code;
}

class SocialConnection {
  const SocialConnection({
    required this.provider,
    required this.status,
    required this.accountName,
    required this.accountUsername,
    required this.detail,
  });

  final String provider;
  final String status;
  final String accountName;
  final String accountUsername;
  final String detail;

  bool get connected => status == 'connected';

  String get displayName {
    if (accountUsername.isNotEmpty) return accountUsername;
    return accountName;
  }

  factory SocialConnection.fromJson(Map<String, dynamic> json) {
    return SocialConnection(
      provider: json['provider'] as String? ?? '',
      status: json['status'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      accountUsername: json['accountUsername'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class SocialConnectionService {
  SocialConnectionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<SocialConnection>> load() async {
    final response = await _send('GET', '/api/social-connections');
    final body = _json(response);
    if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      final rows = body['connections'];
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map<String, dynamic>) SocialConnection.fromJson(row),
      ];
    }
    if (response != null && response.statusCode == 401) {
      throw const SocialConnectionException('unauthorized');
    }
    throw SocialConnectionException(_code(body, 'load_failed'));
  }

  Future<String> start(String provider, String returnTo) async {
    final response = await _send(
      'POST',
      '/api/social-connections/$provider/start',
      {'return_to': returnTo},
    );
    final body = _json(response);
    if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      final url = body['authorizeUrl'] as String? ?? '';
      if (url.isEmpty) throw const SocialConnectionException('not_configured');
      return url;
    }
    throw SocialConnectionException(_code(body, 'not_configured'));
  }

  Future<void> disconnect(String provider) async {
    final response = await _send('DELETE', '/api/social-connections/$provider');
    if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw SocialConnectionException(_code(_json(response), 'disconnect_failed'));
  }

  Future<http.Response?> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final token = AuthService.instance.session?.accessToken ?? '';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    try {
      if (method == 'GET') return await _client.get(uri, headers: headers);
      if (method == 'DELETE') return await _client.delete(uri, headers: headers);
      return await _client.post(uri, headers: headers, body: jsonEncode(body ?? const {}));
    } catch (error) {
      if (kDebugMode) debugPrint('social connection request failed: $error');
      return null;
    }
  }

  Map<String, dynamic> _json(http.Response? response) {
    if (response == null) return const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return const {};
    }
    return const {};
  }

  String _code(Map<String, dynamic> body, String fallback) {
    final code = body['error'];
    if (code is String && code.isNotEmpty) return code;
    return fallback;
  }
}
