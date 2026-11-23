import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';

class AdminApiException implements Exception {
  const AdminApiException(this.status, this.code);

  final int status;
  final String code;

  bool get forbidden => status == 401 || status == 403;
  bool get notReady => status == 503 || code == 'admin_not_ready';
}

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  Future<bool> isAdmin() async {
    try {
      await getJson('/api/admin/me');
      return true;
    } on AdminApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _send('GET', path);
    return _decode(response);
  }

  Future<String> getText(String path) async {
    final response = await _send('GET', path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(response.statusCode, _errorCode(response.body));
    }
    return response.body;
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final response = await _send('PATCH', path, body);
    return _decode(response);
  }

  Future<http.Response> _send(String method, String path, [Map<String, dynamic>? body]) async {
    var session = AuthService.instance.session;
    if (session == null) throw const AdminApiException(401, 'unauthorized');
    final response = await _request(method, path, session.accessToken, body);
    if (response.statusCode != 401) return response;
    final refreshed = await AuthService.instance.refreshSession();
    if (!refreshed) return response;
    session = AuthService.instance.session;
    if (session == null) return response;
    return _request(method, path, session.accessToken, body);
  }

  Future<http.Response> _request(
    String method,
    String path,
    String accessToken,
    Map<String, dynamic>? body,
  ) async {
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    AdminApiException? last;
    for (final base in AppConfig.debugApiBases()) {
      try {
        final uri = Uri.parse('$base$path');
        final response = await switch (method) {
          'PATCH' => http.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
          _ => http.get(uri, headers: headers),
        }.timeout(const Duration(seconds: 25));
        if (response.statusCode == 404) continue;
        return response;
      } catch (err) {
        if (err is AdminApiException) rethrow;
        last = const AdminApiException(0, 'network');
      }
    }
    throw last ?? const AdminApiException(0, 'network');
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(response.statusCode, _errorCode(response.body));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  String _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) return decoded['error'] as String;
    } catch (_) {}
    return 'request_failed';
  }
}

String adminQuery(Map<String, String> params) {
  final kept = <String, String>{};
  params.forEach((key, value) {
    if (value.trim().isNotEmpty) kept[key] = value.trim();
  });
  if (kept.isEmpty) return '';
  return '?${Uri(queryParameters: kept).query}';
}
