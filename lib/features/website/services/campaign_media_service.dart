import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

class CampaignMediaException implements Exception {
  const CampaignMediaException(this.code);

  final String code;
}

class CampaignMediaItem {
  const CampaignMediaItem({
    required this.id,
    required this.url,
    required this.userId,
  });

  final String id;
  final String url;
  final String userId;
}

class CampaignMediaSnapshot {
  const CampaignMediaSnapshot({
    required this.userId,
    required this.logo,
    required this.photos,
  });

  final String userId;
  final CampaignMediaItem? logo;
  final List<CampaignMediaItem> photos;
}

/// Uploads the onboarding logo and additional photos through the backend,
/// which stores the files in Supabase Storage and their URLs on the user.
class CampaignMediaService {
  CampaignMediaService({http.Client? client}) : _client = client ?? http.Client();

  static const maxBytes = 5 * 1024 * 1024;
  static const maxPhotos = 10;

  static CampaignMediaService instance = CampaignMediaService();

  final http.Client _client;

  /// Null when the file is a JPG, JPEG, PNG, or WebP within the size limit.
  static String? validateBytes(Uint8List bytes, {String filename = ''}) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      return bytes.length > maxBytes ? 'file_too_large' : 'invalid_photo';
    }
    final type = ProfileService.photoContentType(bytes);
    if (type == null) return 'invalid_photo';
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return null;
    final ext = filename.substring(dot + 1).toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(ext)) return 'invalid_photo';
    if ((ext == 'jpg' || ext == 'jpeg') && type != 'image/jpeg') {
      return 'invalid_photo';
    }
    if (ext == 'png' && type != 'image/png') return 'invalid_photo';
    if (ext == 'webp' && type != 'image/webp') return 'invalid_photo';
    return null;
  }

  Future<CampaignMediaSnapshot?> fetch() async {
    final session = AuthService.instance.session;
    if (session == null) return null;
    final response = await _request(
      () => _client.get(_uri(''), headers: _headers(session.accessToken)),
    );
    final body = _readMap(response);
    return CampaignMediaSnapshot(
      userId: _text(body['userId']),
      logo: _item(body['logo']),
      photos: [
        for (final entry in (body['photos'] is List ? body['photos'] as List : const []))
          if (_item(entry) case final item?) item,
      ],
    );
  }

  Future<CampaignMediaItem> uploadLogo(Uint8List bytes) {
    return _upload('logo', bytes, key: 'logo');
  }

  Future<CampaignMediaItem> uploadPhoto(Uint8List bytes) {
    return _upload('photos', bytes, key: 'photo');
  }

  Future<void> deleteLogo() {
    return _delete('logo');
  }

  Future<void> deletePhoto(String id) {
    return _delete('photos/$id');
  }

  Future<Uint8List?> download(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (validateBytes(response.bodyBytes) != null) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<CampaignMediaItem> _upload(
    String path,
    Uint8List bytes, {
    required String key,
  }) async {
    final type = ProfileService.photoContentType(bytes);
    final problem = validateBytes(bytes);
    if (type == null || problem != null) {
      throw CampaignMediaException(problem ?? 'invalid_photo');
    }
    final session = _session();
    final response = await _request(
      () => _client.post(
        _uri(path),
        headers: _headers(session.accessToken, contentType: type),
        body: bytes,
      ),
      timeout: const Duration(seconds: 40),
    );
    final item = _item(_readMap(response)[key]);
    if (item == null || item.url.isEmpty) {
      throw const CampaignMediaException('upload_failed');
    }
    return item;
  }

  Future<void> _delete(String path) async {
    final session = _session();
    try {
      final response = await _client
          .delete(_uri(path), headers: _headers(session.accessToken))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      final code = _errorCode(response);
      if (code == 'unauthorized' || code == 'storage_not_ready') {
        throw CampaignMediaException(code);
      }
      throw const CampaignMediaException('delete_failed');
    } on CampaignMediaException {
      rethrow;
    } catch (_) {
      throw const CampaignMediaException('delete_failed');
    }
  }

  AuthSession _session() {
    final session = AuthService.instance.session;
    if (session == null) throw const CampaignMediaException('unauthorized');
    return session;
  }

  Future<http.Response> _request(
    Future<http.Response> Function() send, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final response = await send().timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw CampaignMediaException(_errorCode(response));
    } on CampaignMediaException {
      rethrow;
    } catch (_) {
      throw const CampaignMediaException('upload_failed');
    }
  }

  Map<String, dynamic> _readMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Fall through to the shared failure below.
    }
    throw const CampaignMediaException('upload_failed');
  }

  String _errorCode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      final error = decoded is Map ? decoded['error'] : null;
      if (error is String && error.isNotEmpty) return error;
    } catch (_) {
      // Use the status when the body is not JSON.
    }
    if (response.statusCode == 401) return 'unauthorized';
    if (response.statusCode == 413) return 'file_too_large';
    if (response.statusCode == 503) return 'storage_not_ready';
    return 'upload_failed';
  }

  CampaignMediaItem? _item(Object? value) {
    if (value is! Map) return null;
    final id = _text(value['id']);
    final url = _text(value['url']);
    final userId = _text(value['userId']);
    if (id.isEmpty || url.isEmpty) return null;
    return CampaignMediaItem(id: id, url: url, userId: userId);
  }

  String _text(Object? value) => value is String ? value.trim() : '';

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final suffix = path.isEmpty ? '' : '/$path';
    return Uri.parse('$base/api/campaign-media$suffix');
  }

  Map<String, String> _headers(String token, {String? contentType}) {
    return {
      'Authorization': 'Bearer $token',
      if (contentType != null) 'Content-Type': contentType,
    };
  }
}
