import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import 'letter_model.dart';

class LetterException implements Exception {
  const LetterException(this.code);

  final String code;
}

/// Asks the VOTE BANKER backend to draft an official letter. The model key stays on the server.
class LetterService {
  LetterService({http.Client? client, this.baseUrls = const []})
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
      return [configured, 'http://127.0.0.1:5000'];
    }
    return [configured];
  }

  Future<GeneratedLetter> generate(LetterDraft draft) async {
    final response = await _send(draft.toJson());
    if (response == null) {
      throw const LetterException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
      final letter = body['letter'];
      if (letter is Map<String, dynamic> && (letter['text'] as String? ?? '').trim().isNotEmpty) {
        return GeneratedLetter.fromJson(letter);
      }
    }
    throw LetterException(body['error'] as String? ?? 'generation_failed');
  }

  Future<http.Response?> _send(Map<String, dynamic> payload) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = AuthService.instance.session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final response = await _client
            .post(
              Uri.parse('$base/api/letters/generate'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 360));
        last = response;
        if (response.statusCode != 404) {
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
