import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import 'speech_model.dart';

class SpeechException implements Exception {
  const SpeechException(this.code);

  final String code;
}

/// Asks the VOTE BANKER backend to draft a speech. The model key stays on the server.
class SpeechService {
  SpeechService({http.Client? client, this.baseUrls = const []})
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

  Future<GeneratedSpeech> generate(SpeechRequest request) async {
    final response = await _send(request.toJson());
    if (response == null) {
      throw const SpeechException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
      final speech = body['speech'];
      if (speech is Map<String, dynamic>) {
        return GeneratedSpeech.fromJson(speech);
      }
    }
    throw SpeechException(body['error'] as String? ?? 'generation_failed');
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
              Uri.parse('$base/api/speeches/generate'),
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
