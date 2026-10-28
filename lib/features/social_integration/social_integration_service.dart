import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';

class SocialIntegrationException implements Exception {
  const SocialIntegrationException(this.code);

  final String code;
}

class SocialAccountStatus {
  const SocialAccountStatus({
    required this.connected,
    required this.status,
    this.pageCount = 0,
    this.accountCount = 0,
    this.businessReady = false,
  });

  final bool connected;
  final String status;
  final int pageCount;
  final int accountCount;
  final bool businessReady;

  factory SocialAccountStatus.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return SocialAccountStatus(
      connected: data['connected'] == true,
      status: data['status'] as String? ?? 'setup_required',
      pageCount: data['pageCount'] as int? ?? 0,
      accountCount: data['accountCount'] as int? ?? 0,
      businessReady: data['businessReady'] == true,
    );
  }
}

class SocialIntegrationStatus {
  const SocialIntegrationStatus({
    required this.facebook,
    required this.instagram,
    required this.whatsapp,
    required this.drafts,
    required this.scheduling,
    required this.publishing,
    required this.captions,
    required this.mediaStorage,
  });

  final SocialAccountStatus facebook;
  final SocialAccountStatus instagram;
  final SocialAccountStatus whatsapp;
  final bool drafts;
  final bool scheduling;
  final bool publishing;
  final bool captions;
  final bool mediaStorage;

  factory SocialIntegrationStatus.fromJson(Map<String, dynamic> json) {
    final accounts = json['accounts'];
    final map = accounts is Map<String, dynamic> ? accounts : const <String, dynamic>{};
    final capabilities = json['capabilities'];
    final caps =
        capabilities is Map<String, dynamic> ? capabilities : const <String, dynamic>{};
    SocialAccountStatus account(String key) {
      final value = map[key];
      return SocialAccountStatus.fromJson(
        value is Map<String, dynamic> ? value : null,
      );
    }

    return SocialIntegrationStatus(
      facebook: account('facebook'),
      instagram: account('instagram'),
      whatsapp: account('whatsapp'),
      drafts: caps['drafts'] == true,
      scheduling: caps['scheduling'] == true,
      publishing: caps['publishing'] == true,
      captions: caps['captions'] == true,
      mediaStorage: caps['mediaStorage'] == true,
    );
  }
}

class SocialCaptionResult {
  const SocialCaptionResult({required this.caption, required this.hashtags});

  final String caption;
  final List<String> hashtags;
}

class SocialIntegrationService {
  SocialIntegrationService({http.Client? client, this.baseUrls = const []})
      : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> baseUrls;

  List<String> get _bases {
    if (baseUrls.isNotEmpty) return baseUrls;
    return [AppConfig.apiBaseUrl];
  }

  Future<SocialIntegrationStatus> loadStatus() async {
    final response = await _send('GET', '/api/social-media/integrations');
    final body = _json(response);
    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['success'] == true) {
      return SocialIntegrationStatus.fromJson(body);
    }
    throw SocialIntegrationException(_errorCode(response, body));
  }

  Future<void> savePost({
    required String action,
    required String platform,
    required String caption,
    required List<String> hashtags,
    String? mediaName,
    DateTime? scheduledFor,
    bool allowComments = true,
    String? link,
  }) async {
    final response = await _send(
      'POST',
      '/api/social-media/posts',
      body: {
        'action': action,
        'platform': platform,
        'caption': caption,
        'hashtags': hashtags,
        'allowComments': allowComments,
        if (link != null && link.isNotEmpty) 'link': link,
        if (mediaName != null) 'mediaName': mediaName,
        if (scheduledFor != null) 'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      },
    );
    final json = _json(response);
    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json['success'] == true) {
      return;
    }
    throw SocialIntegrationException(_errorCode(response, json));
  }

  Future<SocialCaptionResult> generateCaption({
    required String platform,
    required String caption,
  }) async {
    final response = await _send(
      'POST',
      '/api/social-media/captions',
      body: {'platform': platform, 'caption': caption},
    );
    final json = _json(response);
    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json['success'] == true) {
      final tags = json['hashtags'];
      return SocialCaptionResult(
        caption: json['caption'] as String? ?? '',
        hashtags: tags is List ? [for (final tag in tags) '$tag'] : const [],
      );
    }
    throw SocialIntegrationException(_errorCode(response, json));
  }

  Future<http.Response?> _send(String method, String path, {Map<String, dynamic>? body}) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = AuthService.instance.session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final uri = Uri.parse('$base$path');
        final Future<http.Response> call = method == 'GET'
            ? _client.get(uri, headers: headers)
            : _client.post(uri, headers: headers, body: jsonEncode(body ?? const {}));
        final response = await call.timeout(const Duration(seconds: 30));
        last = response;
        if (response.statusCode == 404 && base != _bases.last) continue;
        return response;
      } catch (error) {
        if (kDebugMode) {
          debugPrint('social integration request failed: $error');
        }
      }
    }
    return last;
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

  String _errorCode(http.Response? response, Map<String, dynamic> body) {
    final code = body['error'];
    if (code is String && code.isNotEmpty) return code;
    if (response == null) return 'unreachable';
    if (response.statusCode == 401) return 'unauthorized';
    return 'publishing_not_configured';
  }
}
