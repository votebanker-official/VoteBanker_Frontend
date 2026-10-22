import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/domain_suggestion.dart';

class DomainException implements Exception {
  const DomainException(this.code, {this.serverIp});

  final String code;
  final String? serverIp;
}

/// Optional host so widget tests can inject a mocked [DomainService].
class DomainServiceHost extends InheritedWidget {
  const DomainServiceHost({
    required this.service,
    required super.child,
    super.key,
  });

  final DomainService service;

  static DomainService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DomainServiceHost>()
        ?.service;
  }

  @override
  bool updateShouldNotify(DomainServiceHost oldWidget) {
    return service != oldWidget.service;
  }
}

/// Asks the VOTE BANKER backend to check domain availability via Openprovider.
class DomainService {
  DomainService({
    http.Client? client,
    this.baseUrls = const [],
    this.timeout = const Duration(seconds: 240),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> baseUrls;
  final Duration timeout;

  List<String> get _bases {
    if (baseUrls.isNotEmpty) {
      return baseUrls;
    }
    final configured = AppConfig.apiBaseUrl;
    if (kDebugMode &&
        !configured.contains('127.0.0.1') &&
        !configured.contains('localhost')) {
      // Prefer local Openprovider access in debug; Railway egress IPs often fail auth.
      return ['http://127.0.0.1:5000', configured];
    }
    return [configured];
  }

  Future<List<DomainSuggestion>> search(
    String name, {
    /// Standard TLDs first, then other popular ones. Pass `allTlds: true` via
    /// a custom extensions list only when intentionally running a full catalog check.
    List<String> extensions = defaultDomainExtensions,
  }) async {
    final slug = domainSlug(name);
    if (slug == null) {
      throw const DomainException('invalid_name');
    }

    final response = await _send({
      'name': slug,
      'extensions': extensions,
    });
    if (response == null) {
      throw const DomainException('unreachable');
    }

    final body = _json(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['success'] == true) {
      final results = body['results'];
      if (results is List) {
        return [
          for (final item in results)
            if (item is Map<String, dynamic>) DomainSuggestion.fromJson(item),
        ];
      }
      throw const DomainException('bad_response');
    }

    final serverIp = body['serverIp'] as String?;
    throw DomainException(
      body['error'] as String? ?? 'search_failed',
      serverIp: serverIp != null && serverIp.trim().isNotEmpty
          ? serverIp.trim()
          : null,
    );
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
              Uri.parse('$base/api/domains/search'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(timeout);
        last = response;
        if (response.statusCode == 404) {
          continue;
        }

        // Local first may be down; try Railway next. If Railway is blocked by
        // Openprovider IP rules, keep trying other bases when available.
        if (kDebugMode &&
            _isRemoteApi(base) &&
            _isOpenproviderIpOrAuthFailure(response) &&
            base != _bases.last) {
          continue;
        }
        return response;
      } on TimeoutException {
        // A slow local Openprovider search must not be replaced by Railway's
        // login error. Railway is only a fallback when this machine is down.
        if (!_isRemoteApi(base)) {
          throw const DomainException('openprovider_timeout');
        }
      } catch (_) {
        continue;
      }
    }
    return last;
  }

  bool _isRemoteApi(String base) {
    final lower = base.toLowerCase();
    return !lower.contains('127.0.0.1') && !lower.contains('localhost');
  }

  bool _isOpenproviderIpOrAuthFailure(http.Response response) {
    if (response.statusCode != 502 && response.statusCode != 503) {
      return false;
    }
    final error = _json(response)['error'];
    return error == 'openprovider_access_denied' ||
        error == 'openprovider_auth_failed';
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
