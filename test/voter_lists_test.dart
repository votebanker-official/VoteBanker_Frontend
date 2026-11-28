import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/config/app_config.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/core/widgets/language_selector.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/onboarding/voter_lists/voter_lists_screen.dart';

void main() {
  test(
    'voter records use the in-app route unless an external URL is configured',
    () {
      expect(AppConfig.vrmRecordsUrl, isEmpty);
    },
  );

  testWidgets(
    'Get your Voter Lists opens voter roll records and back returns to Blue Tik',
    (tester) async {
      openedUrl = null;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Get Your Voter Lists'), findsWidgets);
      expect(find.text('Constituency-wise Records'), findsOneWidget);
      expect(find.text('Booth-wise Records'), findsOneWidget);
      expect(find.text('Voter Roll Details'), findsOneWidget);
      expect(
        find.text('Continue to the Voter Records section.'),
        findsOneWidget,
      );
      final button = tester.getRect(find.byKey(const Key('voter-lists-open')));
      expect(button.bottom, lessThanOrEqualTo(844));
      expect(button.width, greaterThan(300));

      final skip = find.byKey(const Key('voter-lists-skip'));
      final language = find.byType(LanguageSelector);
      final theme = find.byIcon(Icons.dark_mode_outlined);
      expect(
        tester.getTopLeft(language).dx,
        lessThan(tester.getTopLeft(theme).dx),
      );
      _expectFullLanguageLabel(tester, 'English');
      expect(tester.getSize(skip).height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(const Key('voter-lists-open')));
      await tester.pumpAndSettle();
      expect(openedUrl, isNull);
      expect(find.text('records-destination'), findsOneWidget);
      Navigator.of(tester.element(find.text('records-destination'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(language);
      await tester.pumpAndSettle();
      final hindi = find.textContaining('Hindi');
      await tester.scrollUntilVisible(
        hindi,
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(hindi, findsOneWidget);
      await tester.tap(hindi.last);
      await tester.pumpAndSettle();
      expect(find.text('हिन्दी'), findsWidgets);

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

      openedUrl = null;
      await tester.tap(find.byKey(const Key('voter-lists-skip')));
      await tester.pumpAndSettle();
      expect(openedUrl, isNull);
      expect(find.text('campaign-templates-destination'), findsOneWidget);
    },
  );

  testWidgets('mobile header keeps the full language name', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    _expectFullLanguageLabel(tester, 'English');
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.language), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back returns to Blue Tik', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('voter-lists-back')));
    await tester.pumpAndSettle();
    expect(find.text('blue-tik-destination'), findsOneWidget);
  });
}

String? openedUrl;

void _expectFullLanguageLabel(WidgetTester tester, String label) {
  final finder = find.descendant(
    of: find.byType(LanguageSelector),
    matching: find.text(label),
  );
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  final painter = TextPainter(
    text: TextSpan(text: label, style: text.style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  expect(
    tester.getSize(finder).width,
    greaterThanOrEqualTo(painter.width - 0.5),
  );
}

Widget _app() {
  final themeController = ThemeController();
  final onboarding = OnboardingController();
  return ThemeScope(
    controller: themeController,
    child: OnboardingScope(
      controller: onboarding,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, themeMode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: onboarding.locale,
            builder: (context, locale, _) {
              return _materialApp(themeMode, locale);
            },
          );
        },
      ),
    ),
  );
}

Widget _materialApp(ThemeMode themeMode, Locale locale) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    initialRoute: AppRoutes.voterLists,
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.campaignTemplates) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder:
              (_) =>
                  const Scaffold(body: Text('campaign-templates-destination')),
        );
      }
      if (settings.name == AppRoutes.ready) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('ready-destination')),
        );
      }
      if (settings.name == AppRoutes.vrmRecords) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('records-destination')),
        );
      }
      if (settings.name == AppRoutes.blueTik) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('blue-tik-destination')),
        );
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => VoterListsScreen(redirect: (url) => openedUrl = url),
      );
    },
    onGenerateInitialRoutes: (initialRoute) {
      return [
        MaterialPageRoute<void>(
          settings: RouteSettings(name: initialRoute),
          builder: (_) => VoterListsScreen(redirect: (url) => openedUrl = url),
        ),
      ];
    },
  );
}
