class ListedSpeechVoice {
  const ListedSpeechVoice({
    required this.name,
    required this.lang,
    this.local = false,
  });

  final String name;
  final String lang;
  final bool local;
}

class SpeechVoiceChoice {
  const SpeechVoiceChoice({
    required this.locale,
    required this.pitch,
    this.voiceName,
  });

  final String locale;
  final double pitch;
  final String? voiceName;
}

const speechPreviewLocales = <String, String>{
  'en': 'en-IN',
  'as': 'as-IN',
  'bn': 'bn-IN',
  'brx': 'brx-IN',
  'doi': 'doi-IN',
  'gu': 'gu-IN',
  'hi': 'hi-IN',
  'kn': 'kn-IN',
  'ks': 'ks-IN',
  'kok': 'kok-IN',
  'mai': 'mai-IN',
  'ml': 'ml-IN',
  'mni': 'mni-IN',
  'mr': 'mr-IN',
  'ne': 'ne-IN',
  'or': 'or-IN',
  'pa': 'pa-IN',
  'sa': 'sa-IN',
  'sat': 'sat-IN',
  'sd': 'sd-IN',
  'ta': 'ta-IN',
  'te': 'te-IN',
  'ur': 'ur-IN',
};

const _maleHints = [
  'male',
  'david',
  'daniel',
  'guy',
  'alex',
  'fred',
  'george',
  'james',
  'mark',
  'brian',
  'ryan',
  'thomas',
  'matthew',
  'andrew',
  'arthur',
  'christopher',
  'hemant',
  'ravi',
  'prabhat',
  'valluvar',
  'madhur',
];

const _femaleHints = [
  'female',
  'woman',
  'zira',
  'susan',
  'samantha',
  'hazel',
  'heera',
  'kalpana',
  'veena',
  'sangeeta',
  'neerja',
  'swara',
  'priya',
  'heather',
  'linda',
  'victoria',
  'karen',
  'moira',
  'fiona',
  'tessa',
];

bool speechVoiceSoundsFemale(String name) {
  return _femaleHints.any((hint) => _mentions(name, hint));
}

bool speechVoiceSoundsMale(String name) {
  if (speechVoiceSoundsFemale(name)) return false;
  return _maleHints.any((hint) => _mentions(name, hint));
}

bool _mentions(String name, String hint) {
  return RegExp(
    '\\b${RegExp.escape(hint)}\\b',
    caseSensitive: false,
  ).hasMatch(name);
}

SpeechVoiceChoice chooseSpeechVoice({
  required String languageCode,
  required List<ListedSpeechVoice> voices,
}) {
  final locale = speechPreviewLocales[languageCode] ?? 'en-IN';
  if (voices.isEmpty) {
    return SpeechVoiceChoice(locale: locale, pitch: 0.9);
  }

  ListedSpeechVoice? best;
  var bestScore = -100;
  for (final voice in voices) {
    final score = _score(voice, languageCode, locale);
    if (score > bestScore) {
      best = voice;
      bestScore = score;
    }
  }
  final selected = best ?? voices.first;
  final male = speechVoiceSoundsMale(selected.name);
  final languageMatch =
      _languageScore(selected.lang, languageCode, locale) >= 3;
  final pitch = male && languageMatch ? 0.92 : 0.86;
  return SpeechVoiceChoice(
    locale: locale,
    pitch: pitch,
    voiceName: selected.name,
  );
}

int _score(ListedSpeechVoice voice, String languageCode, String locale) {
  var score = _languageScore(voice.lang, languageCode, locale);
  if (speechVoiceSoundsFemale(voice.name)) {
    score -= 4;
  } else if (speechVoiceSoundsMale(voice.name)) {
    score += 4;
  }
  if (voice.local) score += 1;
  return score;
}

int _languageScore(String lang, String languageCode, String locale) {
  final value = lang.toLowerCase().replaceAll('_', '-');
  if (value == locale.toLowerCase()) return 6;
  if (value.startsWith('${languageCode.toLowerCase()}-') ||
      value == languageCode.toLowerCase()) {
    return 4;
  }
  if (value.startsWith('en')) return 1;
  return 0;
}
