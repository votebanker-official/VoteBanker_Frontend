import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_colors.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/data/profile_languages.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/speech_generator/speech_preview_drafts.dart';
import 'package:votebanker/features/speech_generator/speech_preview_screen.dart';
import 'package:votebanker/features/speech_generator/speech_preview_speaker.dart';
import 'package:votebanker/features/speech_generator/speech_preview_voice.dart';

void main() {
  setUp(() {
    AuthService.instance.session = null;
  });

  test('every login language has a draft that names the leader and party', () {
    for (final language in ProfileLanguages.all) {
      final draft = speechPreviewDraft(
        languageCode: language.code,
        leaderName: 'Rajesh Sharma',
        partyName: 'Janata Vikas Party',
      );
      expect(draft, contains('Rajesh Sharma'), reason: language.code);
      expect(draft, contains('Janata Vikas Party'), reason: language.code);
      expect(draft.contains('{name}'), isFalse, reason: language.code);
      expect(draft.contains('{party}'), isFalse, reason: language.code);
      expect(
        draft.split('\n\n').length,
        greaterThanOrEqualTo(4),
        reason: language.code,
      );
    }
    final english = speechPreviewDraft(
      languageCode: 'en',
      leaderName: 'Rajesh Sharma',
      partyName: 'Janata Vikas Party',
    );
    expect(english.split(RegExp(r'\s+')).length, greaterThan(90));
  });

  test('a male voice in the selected language wins over a female voice', () {
    final hindi = chooseSpeechVoice(
      languageCode: 'hi',
      voices: const [
        ListedSpeechVoice(name: 'Microsoft Kalpana', lang: 'hi-IN'),
        ListedSpeechVoice(name: 'Microsoft Hemant', lang: 'hi-IN', local: true),
        ListedSpeechVoice(name: 'Microsoft David', lang: 'en-US', local: true),
      ],
    );
    expect(hindi.locale, 'hi-IN');
    expect(hindi.voiceName, 'Microsoft Hemant');
    expect(hindi.pitch, 0.92);

    final kannada = chooseSpeechVoice(
      languageCode: 'kn',
      voices: const [
        ListedSpeechVoice(name: 'Microsoft Kalpana', lang: 'kn-IN'),
      ],
    );
    expect(kannada.locale, 'kn-IN');
    expect(kannada.voiceName, 'Microsoft Kalpana');
    expect(kannada.pitch, lessThanOrEqualTo(0.92));
    expect(kannada.pitch, greaterThanOrEqualTo(0.85));
  });

  testWidgets('a guest sees the sample leader in the selected language', (
    tester,
  ) async {
    final controller = OnboardingController();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('Rajesh Sharma'), findsOneWidget);
    expect(find.text('Janata Vikas Party'), findsOneWidget);
    expect(find.text('Speech Generator'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(
      find.byKey(const Key('speech-preview-avatar-fallback')),
      findsOneWidget,
    );
    expect(find.textContaining('I am Rajesh Sharma'), findsOneWidget);
    final nameTop =
        tester.getTopLeft(find.byKey(const Key('speech-preview-name'))).dy;
    final draftTop =
        tester.getTopLeft(find.byKey(const Key('speech-preview-draft'))).dy;
    final button = tester.getRect(
      find.byKey(const Key('speech-preview-generate')),
    );
    expect(draftTop, greaterThan(nameTop));
    expect(button.top, greaterThan(draftTop));
    expect(button.bottom, lessThanOrEqualTo(844));
    expect(button.width, greaterThan(300));

    controller.setLanguageCode('hi');
    await tester.pumpAndSettle();
    expect(find.textContaining('मैं Rajesh Sharma हूँ'), findsOneWidget);
    expect(find.textContaining('I am Rajesh Sharma'), findsNothing);
  });

  testWidgets('speech preview surfaces and text follow dark mode', (
    tester,
  ) async {
    final controller = OnboardingController();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller, dark: true));
    await tester.pumpAndSettle();

    final palette = AppPalette.dark;
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final draft = tester.widget<Text>(
      find.byKey(const Key('speech-preview-draft')),
    );
    final name = tester.widget<Text>(
      find.byKey(const Key('speech-preview-name')),
    );
    expect(scaffold.backgroundColor, palette.background);
    expect(draft.style?.color, palette.text);
    expect(name.style?.color, palette.text);
  });

  testWidgets('a signed-in leader replaces the sample profile', (tester) async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-1',
      phone: '+919800000000',
      fullName: 'Meera Rao',
    );
    final controller =
        OnboardingController()
          ..draft.leaderName = 'Meera Rao'
          ..draft.party = 'River Ward';
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Meera Rao'), findsOneWidget);
    expect(find.text('River Ward'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsNothing);
    expect(find.text('Speech Generator'), findsWidgets);
    final cardLeft =
        tester.getTopLeft(find.byKey(const Key('speech-preview-name'))).dx;
    expect(cardLeft, greaterThan(200));
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('Generate your speech for free opens the speech page', (
    tester,
  ) async {
    final controller = OnboardingController();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('speech-preview-generate')));
    await tester.pumpAndSettle();

    expect(find.text('speech-destination'), findsOneWidget);
  });

  testWidgets('the microphone starts and stops male read-aloud', (
    tester,
  ) async {
    final speaker = _FakeSpeaker();
    final controller = OnboardingController();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller, speaker: speaker));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('speech-preview-listen')));
    await tester.pump();
    expect(speaker.plays, 1);
    expect(speaker.language, 'en');
    expect(speaker.text, contains('Rajesh Sharma'));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('speech-preview-listen')));
    await tester.pump();
    expect(speaker.stops, 1);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('speech-preview-listen')));
    await tester.pump();
    controller.setLanguageCode('kn');
    await tester.pump();
    expect(speaker.stops, 2);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
  });

  testWidgets('Skip Now stops playback and opens social setup', (tester) async {
    final speaker = _FakeSpeaker();
    final controller = OnboardingController();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(controller, speaker: speaker));
    await tester.pumpAndSettle();

    final skip = find.byKey(const Key('speech-preview-skip'));
    final language = find.byIcon(Icons.language);
    expect(
      tester.getTopLeft(skip).dx,
      lessThan(tester.getTopLeft(language).dx),
    );
    expect(tester.getSize(skip).height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(const Key('speech-preview-listen')));
    await tester.pump();
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(speaker.stops, 1);
    expect(find.text('social-destination'), findsOneWidget);
  });
}

class _FakeSpeaker implements SpeechPreviewSpeaker {
  int plays = 0;
  int stops = 0;
  String? language;
  String? text;

  @override
  String? speak({
    required String text,
    required String languageCode,
    required void Function() onDone,
  }) {
    plays++;
    this.text = text;
    language = languageCode;
    return null;
  }

  @override
  void stop() {
    stops++;
  }
}

Widget _app(
  OnboardingController controller, {
  SpeechPreviewSpeaker? speaker,
  bool dark = false,
}) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: controller,
      child: ValueListenableBuilder<Locale>(
        valueListenable: controller.locale,
        builder: (context, locale, _) {
          return MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.speechPreview,
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.social) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder:
                      (_) => const Scaffold(body: Text('social-destination')),
                );
              }
              if (settings.name == AppRoutes.speech) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder:
                      (_) => const Scaffold(body: Text('speech-destination')),
                );
              }
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => SpeechPreviewScreen(speaker: speaker),
              );
            },
          );
        },
      ),
    ),
  );
}
