import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/website_builder_draft.dart';

class WebsiteBuilderApiException implements Exception {
  const WebsiteBuilderApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Talks to VoteBanker backend website draft endpoints.
class WebsiteBuilderApi {
  WebsiteBuilderApi._();

  static final WebsiteBuilderApi instance = WebsiteBuilderApi._();

  Future<WebsiteBuilderDraft?> fetchMine() async {
    final session = AuthService.instance.session;
    if (session == null) return null;
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/websites/me'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final website = decoded['website'];
      if (website is! Map) return null;
      return WebsiteBuilderDraft.fromJson(Map<String, dynamic>.from(website));
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Saves draft text/settings without large image payloads.
  Future<WebsiteBuilderDraft?> saveDraft(WebsiteBuilderDraft draft) async {
    final session = AuthService.instance.session;
    if (session == null) return null;

    final payload = draft.toJson(includeBase64: false);
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/websites/me'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final website = decoded['website'];
      if (website is! Map) return null;
      final saved =
          WebsiteBuilderDraft.fromJson(Map<String, dynamic>.from(website));
      // Keep local image bytes that were not uploaded yet.
      _mergeLocalMedia(saved, draft);
      return saved;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Requests publication only after required fields are complete.
  /// Does not invent payment success — backend decides.
  Future<({WebsiteBuilderDraft? draft, String? error})> publish(
    WebsiteBuilderDraft draft,
  ) async {
    final session = AuthService.instance.session;
    if (session == null) {
      return (draft: null, error: 'sign_in_required');
    }
    final reasons = draft.publishBlockingReasons();
    if (reasons.isNotEmpty) {
      return (draft: null, error: 'validation_failed');
    }
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/websites/me/publish'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'websiteName': draft.design.websiteName}),
          )
          .timeout(const Duration(seconds: 25));
      final decoded = jsonDecode(response.body);
      final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return (
          draft: null,
          error: (body['error'] as String?) ?? 'publish_failed',
        );
      }
      final website = body['website'];
      if (website is! Map) {
        return (draft: null, error: 'publish_failed');
      }
      final saved =
          WebsiteBuilderDraft.fromJson(Map<String, dynamic>.from(website));
      _mergeLocalMedia(saved, draft);
      return (draft: saved, error: null);
    } on TimeoutException {
      return (draft: null, error: 'timeout');
    } catch (_) {
      return (draft: null, error: 'network');
    }
  }

  void _mergeLocalMedia(WebsiteBuilderDraft target, WebsiteBuilderDraft source) {
    if (!target.profilePhoto.hasImage && source.profilePhoto.hasImage) {
      target.profilePhoto = source.profilePhoto;
    }
    if (!target.coverPhoto.hasImage && source.coverPhoto.hasImage) {
      target.coverPhoto = source.coverPhoto;
    }
    if (!target.design.logo.hasImage && source.design.logo.hasImage) {
      target.design.logo = source.design.logo;
    }
    if (!target.design.heroImage.hasImage && source.design.heroImage.hasImage) {
      target.design.heroImage = source.design.heroImage;
    }
  }
}
