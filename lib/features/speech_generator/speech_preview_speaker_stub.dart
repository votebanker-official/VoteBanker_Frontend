import 'speech_preview_speaker.dart';

SpeechPreviewSpeaker createPlatformSpeechPreviewSpeaker() {
  return const UnsupportedSpeechPreviewSpeaker();
}

class UnsupportedSpeechPreviewSpeaker implements SpeechPreviewSpeaker {
  const UnsupportedSpeechPreviewSpeaker();

  @override
  String? speak({
    required String text,
    required String languageCode,
    required void Function() onDone,
  }) {
    return 'Read-aloud is not supported in this browser.';
  }

  @override
  void stop() {}
}
