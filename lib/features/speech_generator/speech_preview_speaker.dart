import 'speech_preview_speaker_stub.dart'
    if (dart.library.ui_web) 'speech_preview_speaker_web.dart'
    as platform;

abstract class SpeechPreviewSpeaker {
  /// Returns a short message when playback cannot start. Null means it started.
  String? speak({
    required String text,
    required String languageCode,
    required void Function() onDone,
  });

  void stop();
}

SpeechPreviewSpeaker createSpeechPreviewSpeaker() {
  return platform.createPlatformSpeechPreviewSpeaker();
}
