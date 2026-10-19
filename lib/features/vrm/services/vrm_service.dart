import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/vrm_voter_record.dart';

class VrmException implements Exception {
  const VrmException(this.code);

  final String code;
}

/// Loads and updates VRM voter records via the VOTE BANKER API.
class VrmService {
  VrmService({http.Client? client, this.baseUrls = const []})
      : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> baseUrls;

  List<String> get _bases {
    if (baseUrls.isNotEmpty) {
      return baseUrls;
    }
    final configured = AppConfig.apiBaseUrl;
    if (kDebugMode &&
        !configured.contains('127.0.0.1') &&
        !configured.contains('localhost')) {
      return ['http://127.0.0.1:5000', configured];
    }
    return [configured];
  }

  Future<List<VrmVoterRecord>> listRecords({String query = ''}) async {
    final q = query.trim();
    final path = q.isEmpty
        ? '/api/vrm/records'
        : '/api/vrm/records?q=${Uri.encodeQueryComponent(q)}';
    final response = await _send('GET', path);
    if (response == null) {
      throw const VrmException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw VrmException(body['error'] as String? ?? 'load_failed');
    }
    final rows = body['records'];
    if (rows is! List) {
      return const [];
    }
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) VrmVoterRecord.fromJson(row),
    ];
  }

  Future<VrmVoterRecord> saveContacts({
    required String recordId,
    required String? whatsappContact,
    required String? instagramContact,
    required String? facebookContact,
  }) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) {
      throw const VrmException('unauthorized');
    }

    final response = await _send(
      'PATCH',
      '/api/vrm/records/$recordId/contacts',
      body: {
        'whatsappContact': whatsappContact,
        'instagramContact': instagramContact,
        'facebookContact': facebookContact,
      },
      token: token,
    );
    if (response == null) {
      throw const VrmException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode == 401) {
      throw const VrmException('unauthorized');
    }
    if (response.statusCode == 403) {
      throw const VrmException('forbidden');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw VrmException(body['error'] as String? ?? 'save_failed');
    }
    final record = body['record'];
    if (record is! Map<String, dynamic>) {
      throw const VrmException('bad_response');
    }
    return VrmVoterRecord.fromJson(record);
  }

  Future<http.Response?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final uri = Uri.parse('$base$path');
        final headers = <String, String>{'Content-Type': 'application/json'};
        final authToken = token ?? AuthService.instance.session?.accessToken;
        if (authToken != null && authToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $authToken';
        }

        late final http.Response response;
        if (method == 'GET') {
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
        } else if (method == 'PATCH') {
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 30));
        } else {
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 30));
        }
        last = response;
        if (response.statusCode == 404) {
          continue;
        }
        return response;
      } catch (_) {
        continue;
      }
    }
    return last;
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }
}
