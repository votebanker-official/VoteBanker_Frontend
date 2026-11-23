import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import 'blue_tik_models.dart';

class BlueTikSaveException implements Exception {
  const BlueTikSaveException();
}

class BlueTikService {
  BlueTikService._();

  static final BlueTikService instance = BlueTikService._();

  Future<void> submit(BlueTikApplication application) async {
    final session = AuthService.instance.session;
    if (session == null) throw const BlueTikSaveException();
    final payload = jsonEncode({
      'offerId': application.offerId,
      'leaderName': application.leaderName,
      'mobile': application.mobile,
      'email': application.email,
      'profileUrls': application.profileUrls,
    });
    Object? lastError;
    for (final base in AppConfig.debugApiBases()) {
      try {
        final response = await http
            .post(
              Uri.parse('$base/api/blue-tik/requests'),
              headers: {
                'Authorization': 'Bearer ${session.accessToken}',
                'Content-Type': 'application/json',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 25));
        if (response.statusCode == 404) continue;
        if (response.statusCode >= 200 && response.statusCode < 300) return;
        throw const BlueTikSaveException();
      } catch (err) {
        if (err is BlueTikSaveException) rethrow;
        lastError = err;
      }
    }
    if (lastError != null) throw const BlueTikSaveException();
    throw const BlueTikSaveException();
  }
}
