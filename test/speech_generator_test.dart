import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/speech_generator/speech_generator_screen.dart';
import 'package:votebanker/features/speech_generator/speech_model.dart';
import 'package:votebanker/features/speech_generator/speech_service.dart';

void main() {
  test('a speech document keeps the title, metadata, and edited wording', () {
    const speech = GeneratedSpeech(
      title: 'Address on roads',
      language: 'English',
      speechType: 'Public Meeting',
      duration: '5 minutes',
      tone: 'Formal',
      source: 'mock',
      fullText: '',
      sections: [
        SpeechSection(heading: 'Opening', content: 'We will discuss roads.'),
      ],
    );

    final document = formatSpeechDocument(
      speech: speech,
      metadata: const ['Language: English'],
    );

    expect(document, contains('Address on roads'));
    expect(document, contains('Language: English'));
    expect(document, contains('We will discuss roads.'));
    expect(speechFileName('Address on roads'), 'Address on roads.txt');
  });

  test('the speech service posts the brief and reads the structured speech', () async {
    http.Request? sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': true,
          'speech': {
            'title': 'ರಸ್ತೆಗಳ ಕುರಿತ ಭಾಷಣ',
            'language': 'Kannada',
            'speechType': 'Public Meeting',
            'duration': '5 minutes',
            'tone': 'Formal',
            'source': 'ai',
            'sections': [
              {'heading': 'ನಮಸ್ಕಾರ', 'content': 'ರಸ್ತೆಗಳ ಬಗ್ಗೆ ಮಾತ್ರ ಮಾತನಾಡುತ್ತೇವೆ.'},
            ],
            'fullText': 'ರಸ್ತೆಗಳ ಕುರಿತ ಭಾಷಣ',
          },
        })),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final speech = await SpeechService(
      client: client,
      baseUrls: const ['http://speech.test'],
    ).generate(
      const SpeechRequest(
        prompt: 'improving roads in the constituency',
        speechType: 'Public Meeting',
        language: 'Kannada',
        duration: '5 minutes',
        tone: 'Formal',
      ),
    );

    expect(sentRequest?.url.path, '/api/speeches/generate');
    final posted = jsonDecode(sentRequest!.body) as Map<String, dynamic>;
    expect(posted['prompt'], contains('roads'));
    expect(posted['language'], 'Kannada');
    expect(speech.title, 'ರಸ್ತೆಗಳ ಕುರಿತ ಭಾಷಣ');
    expect(speech.isMock, isFalse);
    expect(speech.sections.single.heading, 'ನಮಸ್ಕಾರ');
  });

  testWidgets('an empty prompt cannot generate, and a brief returns a full speech', (tester) async {
    tester.view.physicalSize = const Size(1280, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SpeechRequest? sent;
    final gate = Completer<GeneratedSpeech>();
    await tester.pumpWidget(
      _app(
        SpeechGeneratorScreen(
          stageDelay: Duration.zero,
          service: _ScriptedSpeechService((request) {
            sent = request;
            return gate.future;
          }),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Speech Generator'), findsWidgets);
    expect(find.text('What should the speech be about?'), findsOneWidget);
    final generate = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Generate Speech'),
    );
    expect(generate.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('speech-prompt')),
      'improving education, roads and employment',
    );
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Generate Speech')).onPressed,
      isNotNull,
    );

    await tester.ensureVisible(find.text('Generate Speech'));
    await tester.tap(find.text('Generate Speech'));
    await tester.pump();

    expect(find.text('Creating your speech...'), findsOneWidget);
    expect(find.text('Understanding your topic'), findsOneWidget);
    expect(sent?.prompt, 'improving education, roads and employment');

    gate.complete(
      GeneratedSpeech(
        title: 'Address on education',
        language: sent!.language,
        speechType: sent!.speechType,
        duration: sent!.duration,
        tone: sent!.tone,
        source: 'mock',
        fullText: sent!.prompt,
        sections: [
          SpeechSection(heading: 'Greeting / Opening', content: 'Welcome. ${sent!.prompt}'),
          const SpeechSection(heading: 'Closing', content: 'Thank you for attending this public meeting.'),
        ],
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(sent?.prompt, 'improving education, roads and employment');
    expect(find.text('Address on education'), findsOneWidget);
    expect(find.textContaining('improving education, roads and employment'), findsWidgets);
    expect(find.text('Greeting / Opening'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.textContaining('development draft'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'A revised opening about education and roads.');
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('A revised opening about education and roads.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ScriptedSpeechService extends SpeechService {
  _ScriptedSpeechService(this._generate);

  final Future<GeneratedSpeech> Function(SpeechRequest request) _generate;

  @override
  Future<GeneratedSpeech> generate(SpeechRequest request) => _generate(request);
}

Widget _app(Widget home) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
