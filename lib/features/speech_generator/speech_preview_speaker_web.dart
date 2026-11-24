import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'speech_preview_speaker.dart';
import 'speech_preview_voice.dart';

SpeechPreviewSpeaker createPlatformSpeechPreviewSpeaker() {
  return WebSpeechPreviewSpeaker();
}

class WebSpeechPreviewSpeaker implements SpeechPreviewSpeaker {
  var _generation = 0;

  @override
  String? speak({
    required String text,
    required String languageCode,
    required void Function() onDone,
  }) {
    try {
      final synth = web.window.speechSynthesis;
      final generation = ++_generation;
      var started = false;

      void begin(bool allowEmpty) {
        if (generation != _generation || started) return;
        final available = synth.getVoices().toDart;
        if (available.isEmpty && !allowEmpty) return;
        started = true;
        final choice = chooseSpeechVoice(
          languageCode: languageCode,
          voices: [
            for (final voice in available)
              ListedSpeechVoice(
                name: voice.name,
                lang: voice.lang,
                local: voice.localService,
              ),
          ],
        );
        web.SpeechSynthesisVoice? selected;
        for (final voice in available) {
          if (voice.name == choice.voiceName) {
            selected = voice;
            break;
          }
        }
        final utterance = web.SpeechSynthesisUtterance(text);
        utterance.lang = choice.locale;
        utterance.pitch = choice.pitch;
        utterance.rate = 0.92;
        if (selected != null) utterance.voice = selected;
        utterance.onend = ((web.Event _) {
          if (generation == _generation) onDone();
        }).toJS;
        utterance.onerror = ((web.Event _) {
          if (generation == _generation) onDone();
        }).toJS;
        synth.cancel();
        Timer(const Duration(milliseconds: 40), () {
          if (generation != _generation) return;
          try {
            synth.speak(utterance);
          } catch (_) {
            onDone();
          }
        });
      }

      if (synth.getVoices().toDart.isEmpty) {
        synth.onvoiceschanged = ((web.Event _) => begin(false)).toJS;
        Timer(const Duration(milliseconds: 450), () => begin(true));
      } else {
        begin(true);
      }
      return null;
    } catch (_) {
      return 'Read-aloud is not supported in this browser.';
    }
  }

  @override
  void stop() {
    _generation++;
    try {
      web.window.speechSynthesis.cancel();
    } catch (_) {}
  }
}
