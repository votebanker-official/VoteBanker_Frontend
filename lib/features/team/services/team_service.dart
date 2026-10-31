import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/team_member.dart';

class TeamException implements Exception {
  const TeamException(this.code);

  final String code;
}

abstract class TeamRepository {
  Future<List<TeamMember>> list();
  Future<TeamMember> create(Map<String, dynamic> payload);
  Future<TeamMember> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
}

class TeamService implements TeamRepository {
  TeamService({http.Client? client, this.baseUrls = const []})
      : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> baseUrls;

  List<String> get _bases {
    if (baseUrls.isNotEmpty) return baseUrls;
    final configured = AppConfig.apiBaseUrl;
    if (kDebugMode &&
        !configured.contains('127.0.0.1') &&
        !configured.contains('localhost')) {
      return ['http://127.0.0.1:5000', configured];
    }
    return [configured];
  }

  @override
  Future<List<TeamMember>> list() async {
    final body = await _json('GET', '/api/team-members');
    final rows = body['members'];
    return [
      for (final row in rows is List ? rows : const [])
        if (row is Map<String, dynamic>) TeamMember.fromJson(row),
    ];
  }

  @override
  Future<TeamMember> create(Map<String, dynamic> payload) async {
    final body = await _json('POST', '/api/team-members', payload);
    return _member(body);
  }

  @override
  Future<TeamMember> update(String id, Map<String, dynamic> payload) async {
    final body = await _json('PATCH', '/api/team-members/$id', payload);
    return _member(body);
  }

  @override
  Future<void> delete(String id) async {
    await _json('DELETE', '/api/team-members/$id');
  }

  TeamMember _member(Map<String, dynamic> body) {
    final member = body['member'];
    if (member is! Map<String, dynamic>) {
      throw const TeamException('bad_response');
    }
    return TeamMember.fromJson(member);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, [
    Map<String, dynamic>? payload,
  ]) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = AuthService.instance.session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final uri = Uri.parse('$base$path');
        late final http.Response response;
        switch (method) {
          case 'POST':
            response = await _client.post(uri, headers: headers, body: jsonEncode(payload));
          case 'PATCH':
            response = await _client.patch(uri, headers: headers, body: jsonEncode(payload));
          case 'DELETE':
            response = await _client.delete(uri, headers: headers);
          default:
            response = await _client.get(uri, headers: headers);
        }
        last = response;
        final logged = _decode(response);
        // #region agent log
        _socialLog(method, logged, payload);
        _agentLog(
          'team api response',
          {
            'method': method,
            'host': uri.host,
            'status': response.statusCode,
            'error': logged['error'],
            'hasToken': token != null && token.isNotEmpty,
          },
          response.statusCode == 401 ? 'B' : 'A',
        );
        // #endregion
        // A missing route on one host is not the final answer. An auth
        // decision is, so a later 404 cannot hide it.
        if (response.statusCode == 404 || response.statusCode == 0) continue;
        break;
      } catch (_) {
        continue;
      }
    }
    if (last == null) throw const TeamException('unreachable');
    final body = _decode(last);
    if (last.statusCode == 401) throw const TeamException('unauthorized');
    if (last.statusCode == 404) throw const TeamException('not_found');
    if (last.statusCode == 409) {
      throw TeamException(body['error'] as String? ?? 'conflict');
    }
    if (last.statusCode == 503) throw const TeamException('team_members_not_ready');
    if (last.statusCode < 200 || last.statusCode >= 300 || body['success'] == false) {
      throw TeamException(body['error'] as String? ?? 'request_failed');
    }
    return body;
  }

  void _socialLog(String method, Map<String, dynamic> body, Map<String, dynamic>? payload) {
    final members = body['members'];
    final created = body['member'];
    final first = members is List && members.isNotEmpty && members.first is Map
        ? Map<String, dynamic>.from(members.first as Map)
        : created is Map
            ? Map<String, dynamic>.from(created)
            : const <String, dynamic>{};
    final sentFacebook = payload?['facebookUrl'];
    final sentInstagram = payload?['instagramUrl'];
    try {
      http
          .post(
            Uri.parse('http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c'),
            headers: const {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'f11656',
            },
            body: jsonEncode({
              'sessionId': 'f11656',
              'location': 'team_service.dart',
              'message': 'team social field round trip',
              'data': {
                'method': method,
                'sentFacebook': sentFacebook is String && sentFacebook.trim().isNotEmpty,
                'sentInstagram': sentInstagram is String && sentInstagram.trim().isNotEmpty,
                'responseHasFacebook': first['facebookUrl'] is String &&
                    (first['facebookUrl'] as String).trim().isNotEmpty,
                'responseHasInstagram': first['instagramUrl'] is String &&
                    (first['instagramUrl'] as String).trim().isNotEmpty,
                'responseKeys': first.keys.map((key) => '$key').toList(),
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'hypothesisId': 'B',
            }),
          )
          .then((_) {}, onError: (_) {});
    } catch (_) {}
  }

  void _agentLog(String message, Map<String, Object?> data, String hypothesisId) {
    try {
      http
          .post(
            Uri.parse('http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c'),
            headers: const {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'afb56a',
            },
            body: jsonEncode({
              'sessionId': 'afb56a',
              'location': 'team_service.dart',
              'message': message,
              'data': data,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'hypothesisId': hypothesisId,
            }),
          )
          .then((_) {}, onError: (_) {});
    } catch (_) {}
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
