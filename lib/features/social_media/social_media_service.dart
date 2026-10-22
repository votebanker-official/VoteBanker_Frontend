import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';

class SocialMediaException implements Exception {
  const SocialMediaException(this.code);

  final String code;
}

class SocialContactEntry {
  const SocialContactEntry({
    required this.id,
    required this.name,
    required this.value,
    this.epicNumber,
  });

  final String id;
  final String name;
  final String value;
  final String? epicNumber;
}

class SocialMediaContacts {
  const SocialMediaContacts({
    required this.whatsapp,
    required this.instagram,
    required this.facebook,
  });

  final List<SocialContactEntry> whatsapp;
  final List<SocialContactEntry> instagram;
  final List<SocialContactEntry> facebook;

  int get whatsappCount => whatsapp.length;
  int get instagramCount => instagram.length;
  int get facebookCount => facebook.length;

  bool get isEmpty => whatsapp.isEmpty && instagram.isEmpty && facebook.isEmpty;

  static SocialMediaContacts fromJson(Map<String, dynamic> json) {
    return SocialMediaContacts(
      whatsapp: _entries(json['whatsapp'], 'whatsappContact'),
      instagram: _entries(json['instagram'], 'instagramContact'),
      facebook: _entries(json['facebook'], 'facebookContact'),
    );
  }

  static List<SocialContactEntry> _entries(Object? raw, String valueKey) {
    if (raw is! List) return const [];
    final seen = <String>{};
    final rows = <SocialContactEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = map['id'] as String? ?? '';
      final name = (map['name'] as String? ?? '').trim();
      final value = (map[valueKey] as String? ?? '').trim();
      if (id.isEmpty || name.isEmpty || value.isEmpty) continue;
      final key = '$id|$value';
      if (!seen.add(key)) continue;
      rows.add(
        SocialContactEntry(
          id: id,
          name: name,
          value: value,
          epicNumber: map['epicNumber'] as String?,
        ),
      );
    }
    return rows;
  }
}

/// Reads saved VRM social contacts from the VoteBanker API.
class SocialMediaService {
  SocialMediaService({http.Client? client, this.baseUrls = const []})
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

  Future<SocialMediaContacts> load({String query = ''}) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) {
      throw const SocialMediaException('unauthorized');
    }
    final q = query.trim();
    final path = q.isEmpty
        ? '/api/social-media/contacts'
        : '/api/social-media/contacts?q=${Uri.encodeQueryComponent(q)}';

    http.Response? response;
    for (final base in _bases) {
      try {
        response = await _client
            .get(
              Uri.parse('$base$path'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 404) continue;
        break;
      } catch (_) {
        response = null;
      }
    }
    if (response == null) throw const SocialMediaException('unreachable');

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = const {};
    }
    if (response.statusCode == 401) {
      throw const SocialMediaException('unauthorized');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw SocialMediaException(body['error'] as String? ?? 'load_failed');
    }
    return SocialMediaContacts.fromJson(body);
  }
}
