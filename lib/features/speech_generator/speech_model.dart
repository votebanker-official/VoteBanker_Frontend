class SpeechSection {
  const SpeechSection({
    required this.heading,
    required this.content,
  });

  final String heading;
  final String content;

  SpeechSection copyWith({String? heading, String? content}) {
    return SpeechSection(
      heading: heading ?? this.heading,
      content: content ?? this.content,
    );
  }

  factory SpeechSection.fromJson(Map<String, dynamic> json) {
    return SpeechSection(
      heading: json['heading'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class SpeechRequest {
  const SpeechRequest({
    required this.prompt,
    required this.speechType,
    required this.language,
    required this.duration,
    required this.tone,
    this.variant = 0,
  });

  final String prompt;
  final String speechType;
  final String language;
  final String duration;
  final String tone;
  final int variant;

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'speechType': speechType,
      'language': language,
      'duration': duration,
      'tone': tone,
      'variant': variant,
    };
  }
}

class GeneratedSpeech {
  const GeneratedSpeech({
    required this.title,
    required this.language,
    required this.speechType,
    required this.duration,
    required this.tone,
    required this.sections,
    required this.fullText,
    required this.source,
  });

  final String title;
  final String language;
  final String speechType;
  final String duration;
  final String tone;
  final List<SpeechSection> sections;
  final String fullText;
  final String source;

  bool get isMock => source == 'mock';

  GeneratedSpeech copyWith({
    String? title,
    List<SpeechSection>? sections,
  }) {
    final nextTitle = title ?? this.title;
    final nextSections = sections ?? this.sections;
    return GeneratedSpeech(
      title: nextTitle,
      language: language,
      speechType: speechType,
      duration: duration,
      tone: tone,
      sections: nextSections,
      fullText: renderSpeechText(nextTitle, nextSections),
      source: source,
    );
  }

  factory GeneratedSpeech.fromJson(Map<String, dynamic> json) {
    final rows = json['sections'];
    final sections = rows is List
        ? [
            for (final row in rows)
              if (row is Map<String, dynamic>) SpeechSection.fromJson(row),
          ]
        : const <SpeechSection>[];
    final title = json['title'] as String? ?? '';
    return GeneratedSpeech(
      title: title,
      language: json['language'] as String? ?? '',
      speechType: json['speechType'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      tone: json['tone'] as String? ?? '',
      sections: sections,
      fullText: json['fullText'] as String? ?? renderSpeechText(title, sections),
      source: json['source'] as String? ?? '',
    );
  }
}

String renderSpeechText(String title, List<SpeechSection> sections) {
  final blocks = <String>[title, ''];
  for (final section in sections) {
    blocks.add(section.heading);
    blocks.add('');
    blocks.add(section.content.trim());
    blocks.add('');
  }
  return blocks.join('\n').trim();
}

String formatSpeechDocument({
  required GeneratedSpeech speech,
  required List<String> metadata,
}) {
  final buffer = StringBuffer()
    ..writeln(speech.title)
    ..writeln();
  for (final line in metadata) {
    buffer.writeln(line);
  }
  buffer.writeln();
  for (final section in speech.sections) {
    buffer
      ..writeln(section.heading)
      ..writeln()
      ..writeln(section.content.trim())
      ..writeln();
  }
  return buffer.toString().trim();
}

const speechTypeKeys = <String, String>{
  'Public Meeting': 'speechTypePublic',
  'Constituency Meeting': 'speechTypeConstituency',
  'Inauguration': 'speechTypeInauguration',
  'Press Conference': 'speechTypePress',
  'Policy Announcement': 'speechTypePolicy',
  'Youth Event': 'speechTypeYouth',
  "Women's Event": 'speechTypeWomen',
  'Community Meeting': 'speechTypeCommunity',
  'Development Update': 'speechTypeDevelopment',
  'Custom': 'speechTypeCustom',
};

const speechLanguageKeys = <String, String>{
  'English': 'speechLangEn',
  'Kannada': 'speechLangKn',
  'Hindi': 'speechLangHi',
  'Telugu': 'speechLangTe',
  'Tamil': 'speechLangTa',
  'Malayalam': 'speechLangMl',
};

const speechDurationKeys = <String, String>{
  '2 minutes': 'speechMin2',
  '5 minutes': 'speechMin5',
  '10 minutes': 'speechMin10',
  '15 minutes': 'speechMin15',
};

const speechToneKeys = <String, String>{
  'Formal': 'speechToneFormal',
  'Inspirational': 'speechToneInspirational',
  'Conversational': 'speechToneConversational',
  'Development-focused': 'speechToneDevelopment',
  'Community-focused': 'speechToneCommunity',
};

String speechFileName(String title) {
  final cleaned = title.trim().replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '').trim();
  final base = cleaned.isEmpty ? 'speech' : cleaned;
  final short = base.length > 60 ? base.substring(0, 60).trim() : base;
  return '$short.txt';
}
