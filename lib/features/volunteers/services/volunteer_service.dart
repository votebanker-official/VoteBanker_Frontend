import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/volunteer_models.dart';

class VolunteerException implements Exception {
  const VolunteerException(this.code);

  final String code;
}

class VolunteerService {
  VolunteerService({http.Client? client, this.baseUrls = const []})
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

  Future<VolunteerStats> loadStats() async {
    final body = await _jsonGet('/api/volunteers/stats');
    final stats = body['stats'];
    if (stats is! Map<String, dynamic>) {
      return VolunteerStats.empty;
    }
    return VolunteerStats.fromJson(stats);
  }

  Future<VolunteerOverview> loadOverview() async {
    final body = await _jsonGet('/api/volunteers/overview');
    return VolunteerOverview.fromJson(body);
  }

  Future<List<VolunteerTeam>> loadTeams() async {
    final body = await _jsonGet('/api/volunteers/teams');
    final rows = body['teams'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) VolunteerTeam.fromJson(row),
    ];
  }

  Future<VolunteerPage> listVolunteers({
    String q = '',
    String role = '',
    String teamId = '',
    String status = '',
    String location = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (role.trim().isNotEmpty) 'role': role.trim(),
      if (teamId.trim().isNotEmpty) 'teamId': teamId.trim(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
      if (location.trim().isNotEmpty) 'location': location.trim(),
    };
    final query = Uri(queryParameters: params).query;
    final body = await _jsonGet('/api/volunteers/volunteers?$query');
    final rows = body['volunteers'];
    return VolunteerPage(
      volunteers: [
        for (final row in rows is List ? rows : const [])
          if (row is Map<String, dynamic>) VolunteerRecord.fromJson(row),
      ],
      page: body['page'] is int ? body['page'] as int : page,
      pageSize: body['pageSize'] is int ? body['pageSize'] as int : pageSize,
      total: body['total'] is int ? body['total'] as int : 0,
      locations: [
        for (final item in body['locations'] is List ? body['locations'] as List : const [])
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ],
    );
  }

  Future<({VolunteerRecord volunteer, List<VolunteerTask> tasks, List<VolunteerActivity> activity})>
      getVolunteer(String id) async {
    final body = await _jsonGet('/api/volunteers/volunteers/$id');
    final volunteer = body['volunteer'];
    if (volunteer is! Map<String, dynamic>) {
      throw const VolunteerException('not_found');
    }
    return (
      volunteer: VolunteerRecord.fromJson(volunteer),
      tasks: [
        for (final row in body['tasks'] is List ? body['tasks'] as List : const [])
          if (row is Map<String, dynamic>) VolunteerTask.fromJson(row),
      ],
      activity: [
        for (final row in body['activity'] is List ? body['activity'] as List : const [])
          if (row is Map<String, dynamic>) VolunteerActivity.fromJson(row),
      ],
    );
  }

  Future<VolunteerRecord> createVolunteer(Map<String, dynamic> payload) async {
    final body = await _jsonSend('POST', '/api/volunteers/volunteers', payload);
    final volunteer = body['volunteer'];
    if (volunteer is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    return VolunteerRecord.fromJson(volunteer);
  }

  Future<VolunteerRecord> updateVolunteer(String id, Map<String, dynamic> payload) async {
    final body = await _jsonSend('PATCH', '/api/volunteers/volunteers/$id', payload);
    final volunteer = body['volunteer'];
    if (volunteer is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    return VolunteerRecord.fromJson(volunteer);
  }

  Future<void> deleteVolunteer(String id) async {
    await _jsonSend('DELETE', '/api/volunteers/volunteers/$id', null);
  }

  Future<List<VolunteerTask>> listTasks({String status = ''}) async {
    final path = status.trim().isEmpty
        ? '/api/volunteers/tasks'
        : '/api/volunteers/tasks?status=${Uri.encodeQueryComponent(status.trim())}';
    final body = await _jsonGet(path);
    final rows = body['tasks'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) VolunteerTask.fromJson(row),
    ];
  }

  Future<VolunteerTask> createTask(Map<String, dynamic> payload) async {
    final body = await _jsonSend('POST', '/api/volunteers/tasks', payload);
    final task = body['task'];
    if (task is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    return VolunteerTask.fromJson(task);
  }

  Future<VolunteerTask> updateTask(String id, Map<String, dynamic> payload) async {
    final body = await _jsonSend('PATCH', '/api/volunteers/tasks/$id', payload);
    final task = body['task'];
    if (task is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    return VolunteerTask.fromJson(task);
  }

  Future<List<VolunteerApplication>> listApplications({String status = ''}) async {
    final path = status.trim().isEmpty
        ? '/api/volunteers/applications'
        : '/api/volunteers/applications?status=${Uri.encodeQueryComponent(status.trim())}';
    final body = await _jsonGet(path);
    final rows = body['applications'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) VolunteerApplication.fromJson(row),
    ];
  }

  Future<VolunteerApplication> createApplication(Map<String, dynamic> payload) async {
    final body = await _jsonSend('POST', '/api/volunteers/applications', payload);
    final application = body['application'];
    if (application is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    return VolunteerApplication.fromJson(application);
  }

  Future<({VolunteerApplication application, VolunteerRecord? volunteer})> reviewApplication(
    String id,
    String status,
  ) async {
    final body = await _jsonSend(
      'POST',
      '/api/volunteers/applications/$id/review',
      {'status': status},
    );
    final application = body['application'];
    if (application is! Map<String, dynamic>) {
      throw const VolunteerException('bad_response');
    }
    final volunteer = body['volunteer'];
    return (
      application: VolunteerApplication.fromJson(application),
      volunteer: volunteer is Map<String, dynamic>
          ? VolunteerRecord.fromJson(volunteer)
          : null,
    );
  }

  Future<Map<String, dynamic>> _jsonGet(String path) async {
    final response = await _send('GET', path);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _jsonSend(
    String method,
    String path,
    Map<String, dynamic>? payload,
  ) async {
    final response = await _send(method, path, body: payload);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response? response) {
    if (response == null) {
      throw const VolunteerException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode == 401) {
      throw const VolunteerException('unauthorized');
    }
    if (response.statusCode == 403) {
      throw const VolunteerException('forbidden');
    }
    if (response.statusCode == 404) {
      throw const VolunteerException('not_found');
    }
    if (response.statusCode == 409) {
      throw VolunteerException(body['error'] as String? ?? 'conflict');
    }
    if (response.statusCode == 503) {
      throw const VolunteerException('volunteers_not_ready');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] == false) {
      throw VolunteerException(body['error'] as String? ?? 'request_failed');
    }
    return body;
  }

  Future<http.Response?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final uri = Uri.parse('$base$path');
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = AuthService.instance.session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        late final http.Response response;
        switch (method) {
          case 'POST':
            response = await _client.post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            );
          case 'PATCH':
            response = await _client.patch(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            );
          case 'DELETE':
            response = await _client.delete(uri, headers: headers);
          default:
            response = await _client.get(uri, headers: headers);
        }
        last = response;
        if (response.statusCode != 0) {
          return response;
        }
      } catch (_) {
        continue;
      }
    }
    return last;
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }
}
