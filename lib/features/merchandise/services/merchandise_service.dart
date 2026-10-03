import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/merchandise_product.dart';

class MerchandiseException implements Exception {
  const MerchandiseException(this.code);

  final String code;
}

class MerchandiseCatalog {
  const MerchandiseCatalog({
    required this.products,
    required this.storageReady,
  });

  final List<MerchandiseProduct> products;
  final bool storageReady;
}

/// Talks only to the VOTE BANKER backend. Supabase keys stay on the server.
class MerchandiseService {
  MerchandiseService({http.Client? client, this.baseUrls = const []})
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

  Future<MerchandiseCatalog> loadCatalog() async {
    final response = await _send('GET', '/api/merchandise/products');
    if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
      throw const MerchandiseException('load_failed');
    }
    final body = _json(response);
    final rows = body['products'];
    return MerchandiseCatalog(
      products: rows is List
          ? [
              for (final row in rows)
                if (row is Map<String, dynamic>) MerchandiseProduct.fromJson(row),
            ]
          : const [],
      storageReady: body['storageReady'] == true,
    );
  }

  Future<List<MerchandiseOrder>> loadOrders() async {
    final response = await _send('GET', '/api/merchandise/orders');
    if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final rows = _json(response)['orders'];
    if (rows is! List) {
      return const [];
    }
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) MerchandiseOrder.fromJson(row),
    ];
  }

  Future<MerchandiseOrder> placeOrder(Map<String, dynamic> payload) async {
    final response = await _send('POST', '/api/merchandise/orders', payload);
    if (response == null) {
      throw const MerchandiseException('save_failed');
    }
    final body = _json(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final order = body['order'];
      if (order is Map<String, dynamic>) {
        return MerchandiseOrder.fromJson(order);
      }
    }
    throw MerchandiseException(body['error'] as String? ?? 'save_failed');
  }

  Future<http.Response?> _send(
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
        final response = method == 'POST'
            ? await _client
                .post(uri, headers: headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 20))
            : await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));
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
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }
}
