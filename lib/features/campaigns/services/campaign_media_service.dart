import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

class CampaignMediaException implements Exception {
  const CampaignMediaException(this.code);

  final String code;

  @override
  String toString() => code;
}

class CampaignMediaItem {
  const CampaignMediaItem({
    required this.id,
    required this.url,
    required this.kind,
  });

  final String id;
  final String url;
  final String kind;

  factory CampaignMediaItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final url = json['url'];
    final kind = json['kind'];
    if (id is! String || url is! String || kind is! String) {
      throw const CampaignMediaException('bad_response');
    }
    return CampaignMediaItem(id: id, url: url, kind: kind);
  }
}

class CampaignMediaCollection {
  const CampaignMediaCollection({this.logo, this.photos = const []});

  final CampaignMediaItem? logo;
  final List<CampaignMediaItem> photos;

  factory CampaignMediaCollection.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['logo'];
    final rawPhotos = json['photos'];
    return CampaignMediaCollection(
      logo:
          rawLogo is Map
              ? CampaignMediaItem.fromJson(Map<String, dynamic>.from(rawLogo))
              : null,
      photos: [
        for (final item in rawPhotos is List ? rawPhotos : const [])
          if (item is Map)
            CampaignMediaItem.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

abstract interface class CampaignMediaRepository {
  Future<CampaignMediaCollection> load();
  Future<CampaignMediaItem> uploadLogo(Uint8List bytes, String contentType);
  Future<CampaignMediaItem> uploadPhoto(Uint8List bytes, String contentType);
  Future<void> deleteLogo();
  Future<void> deletePhoto(String id);
}

/// Uses the authenticated user's existing campaign-media API and storage.
class CampaignMediaService implements CampaignMediaRepository {
  CampaignMediaService({http.Client? client, this.baseUrls = const []})
    : _client = client ?? http.Client();

  static final instance = CampaignMediaService();

  static const maxPhotos = 10;

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
  Future<CampaignMediaCollection> load() async {
    final body = await _json('GET', '/api/campaign-media');
    return CampaignMediaCollection.fromJson(body);
  }

  @override
  Future<CampaignMediaItem> uploadLogo(
    Uint8List bytes,
    String contentType,
  ) async {
    final body = await _json(
      'POST',
      '/api/campaign-media/logo',
      bytes: bytes,
      contentType: contentType,
    );
    return _item(body, 'logo');
  }

  @override
  Future<CampaignMediaItem> uploadPhoto(
    Uint8List bytes,
    String contentType,
  ) async {
    final body = await _json(
      'POST',
      '/api/campaign-media/photos',
      bytes: bytes,
      contentType: contentType,
    );
    return _item(body, 'photo');
  }

  @override
  Future<void> deleteLogo() async {
    await _json('DELETE', '/api/campaign-media/logo');
  }

  @override
  Future<void> deletePhoto(String id) async {
    await _json(
      'DELETE',
      '/api/campaign-media/photos/${Uri.encodeComponent(id)}',
    );
  }

  CampaignMediaItem _item(Map<String, dynamic> body, String key) {
    final raw = body[key];
    if (raw is! Map) throw const CampaignMediaException('bad_response');
    return CampaignMediaItem.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Uint8List? bytes,
    String? contentType,
  }) async {
    final token = AuthService.instance.session?.accessToken;
    if (token == null || token.isEmpty) {
      throw const CampaignMediaException('unauthorized');
    }

    http.Response? last;
    for (final base in _bases) {
      try {
        final headers = <String, String>{'Authorization': 'Bearer $token'};
        if (contentType != null) headers['Content-Type'] = contentType;
        final uri = Uri.parse('$base$path');
        late final http.Response response;
        switch (method) {
          case 'POST':
            response = await _client.post(uri, headers: headers, body: bytes);
          case 'DELETE':
            response = await _client.delete(uri, headers: headers);
          default:
            response = await _client.get(uri, headers: headers);
        }
        last = response;
        if (response.statusCode == 404) continue;
        break;
      } catch (_) {
        continue;
      }
    }
    if (last == null) throw const CampaignMediaException('unreachable');

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(utf8.decode(last.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const CampaignMediaException('bad_response');
      }
      body = decoded;
    } on FormatException {
      throw const CampaignMediaException('bad_response');
    }
    if (last.statusCode == 401) {
      throw const CampaignMediaException('unauthorized');
    }
    if (last.statusCode == 404) {
      throw const CampaignMediaException('not_found');
    }
    if (last.statusCode == 503) {
      throw CampaignMediaException(body['error'] as String? ?? 'unavailable');
    }
    if (last.statusCode < 200 || last.statusCode >= 300) {
      throw CampaignMediaException(
        body['error'] as String? ?? 'request_failed',
      );
    }
    return body;
  }
}
