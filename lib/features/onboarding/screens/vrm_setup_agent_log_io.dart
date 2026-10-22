import 'dart:convert';
import 'dart:io';

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
    File(r'C:\Users\HP\Desktop\Vote Banker\debug-27385b.log').writeAsStringSync(
      '$payload\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}
