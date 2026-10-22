import 'dart:convert';

import 'package:http/http.dart' as http;

void vrmAgentLog(String hypothesisId, String message, Map<String, Object?> data) {
  try {
    final payload = jsonEncode({
      'sessionId': '27385b',
      'runId': 'post-controls',
      'hypothesisId': hypothesisId,
      'location': 'vrm_setup_screen.dart',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c',
          ),
          headers: const {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '27385b',
          },
          body: payload,
        )
        .catchError((Object _) => http.Response('', 500));
  } catch (_) {}
}
