import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/app/theme/app_colors.dart';
import 'package:votebanker/app/localization/translations/en.dart';
import 'package:votebanker/app/localization/translations/hi.dart';
import 'package:votebanker/app/localization/translations/kn.dart';
import 'package:votebanker/app/localization/translations/ml.dart';
import 'package:votebanker/app/localization/translations/ta.dart';
import 'package:votebanker/app/localization/translations/te.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/onboarding/widgets/domain_result_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'english is the default and every language updates the login screen',
    (tester) async {
      await _setSurface(tester, const Size(1280, 900));
      await tester.pumpWidget(const VoteBankerApp());
      await tester.pumpAndSettle();

      final catalogs = {
        'English': enTranslations,
        'ಕನ್ನಡ': knTranslations,
        'हिन्दी': hiTranslations,
        'తెలుగు': teTranslations,
        'தமிழ்': taTranslations,
        'മലയാളം': mlTranslations,
      };

      for (final entry in catalogs.entries) {
        if (entry.key != 'English') {
          await _chooseLanguage(tester, entry.key);
        }
        expect(find.text(entry.value['welcomeTitle']!), findsOneWidget);
        expect(find.text(entry.value['continueWhatsApp']!), findsOneWidget);
        expect(find.text(entry.value['appName']!), findsWidgets);
      }
    },
  );

  testWidgets('a language Flutter does not ship still leaves the page usable', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _chooseLanguage(tester, 'Hausa');

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    final context = tester.element(find.byIcon(Icons.language));
    expect(MaterialLocalizations.of(context), isNotNull);
    expect(Localizations.localeOf(context).languageCode, 'ha');
  });

  testWidgets('language change keeps the profile screen and typed name', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _tapLabel(tester, 'Skip for now');
    await tester.enterText(
      find.byType(TextField).hitTestable().first,
      'Arjun Verma',
    );
    await _chooseLanguage(tester, 'हिन्दी');

    expect(find.text('लीडर प्रोफ़ाइल'), findsOneWidget);
    final profileContext = tester.element(find.text('लीडर प्रोफ़ाइल'));
    expect(OnboardingScope.of(profileContext).draft.fullName, 'Arjun Verma');
    expect(find.text('VOTE BANKER में आपका स्वागत है'), findsNothing);
  });

  testWidgets('login opens the mobile OTP screen', (tester) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text(enTranslations['continueMobile']!), findsWidgets);
  });

  testWidgets('light mode is the default and the toggle switches to dark', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    BuildContext appContext() => tester.element(find.byType(Scaffold).first);
    expect(Theme.of(appContext()).brightness, Brightness.light);
    expect(appContext().palette.isDark, isFalse);

    // The toggle sits to the left of the language selector.
    final toggle = find.byIcon(Icons.dark_mode_outlined);
    final language = find.byIcon(Icons.language);
    expect(toggle, findsOneWidget);
    expect(
      tester.getCenter(toggle).dx,
      lessThan(tester.getCenter(language).dx),
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(Theme.of(appContext()).brightness, Brightness.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(Theme.of(appContext()).brightness, Brightness.light);
  });

  testWidgets('profile, domain selection, and back keep temporary state', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _tapLabel(tester, 'Skip for now');
    expect(find.text('Leader Profile'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).hitTestable().first,
      'Arjun Verma',
    );
    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Domain Name Search'), findsOneWidget);

    await tester.enterText(find.byType(TextField).hitTestable(), 'Arjun Verma');
    await tester.pump();
    expect(find.text('arjunverma.com'), findsOneWidget);
    expect(find.text('₹999'), findsOneWidget);

    final card = find.ancestor(
      of: find.text('arjunverma.com'),
      matching: find.byType(DomainResultCard),
    );
    await tester.ensureVisible(card);
    await tester.tap(find.descendant(of: card, matching: find.text('Add')));
    await tester.pump();
    expect(
      find.descendant(of: card, matching: find.text('Selected')),
      findsOneWidget,
    );

    await _tapLabel(tester, 'Back');
    expect(find.text('Leader Profile'), findsOneWidget);
    final profileContext = tester.element(find.text('Leader Profile'));
    expect(OnboardingScope.of(profileContext).draft.fullName, 'Arjun Verma');
    expect(
      OnboardingScope.of(profileContext).draft.selectedDomain,
      'arjunverma.com',
    );

    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Selected'), findsOneWidget);

    await _tapLabel(tester, 'Next');
    expect(find.text('Portfolio Website'), findsOneWidget);

    await _tapLabel(tester, 'Skip for now');
    expect(find.text('Meta Social Media'), findsOneWidget);

    await _tapLabel(tester, 'Skip for now');
    expect(find.text('Dashboard'), findsOneWidget);
    expect(
      find.text('Your VOTE BANKER workspace starts here.'),
      findsOneWidget,
    );
    expect(find.text('Marketplace'), findsOneWidget);
  });

  testWidgets('filled website is shown before the price', (tester) async {
    await _setSurface(tester, const Size(1280, 1400));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _tapLabel(tester, 'Skip for now');
    await _tapLabel(tester, 'Skip for now');
    await _tapLabel(tester, 'Next');
    await _tapLabel(tester, 'Continue');

    await tester.enterText(
      find.byType(TextField).hitTestable().first,
      'Clean streets and open meetings for River Ward.',
    );
    await _tapLabel(tester, 'Continue');

    final identity = find.byType(TextField).hitTestable();
    await tester.enterText(identity.at(0), 'Meera Rao');
    await tester.enterText(identity.at(1), 'Community organizer');
    await tester.enterText(identity.at(2), 'River Ward Collective');
    await _tapLabel(tester, 'Next');
    await _tapLabel(tester, 'Next');
    await _tapLabel(tester, 'Next');
    await _tapLabel(tester, 'Next');
    await _tapLabel(tester, 'Continue');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text('Continue').last);
    await tester.tap(find.text('Continue').last);
    await tester.pump();
    for (var step = 0; step < 8; step++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('Meera Rao'), findsWidgets);
    expect(
      find.text('Clean streets and open meetings for River Ward.'),
      findsOneWidget,
    );
    expect(find.text('Community organizer'), findsOneWidget);
    expect(find.text(enTranslations['websiteOffer']!), findsNothing);

    await _tapLabel(tester, 'Continue');
    expect(find.text('Meera Rao'), findsWidgets);
    expect(find.text(enTranslations['websiteOffer']!), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Meera Rao').first).dy,
      lessThan(
        tester.getTopLeft(find.text(enTranslations['websiteOffer']!)).dy,
      ),
    );
  });

  testWidgets('narrow malayalam layout does not overflow', (tester) async {
    await _setSurface(tester, const Size(320, 740));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _chooseLanguage(tester, 'മലയാളം');
    expect(find.text(mlTranslations['welcomeTitle']!), findsOneWidget);

    await _tapLabel(tester, mlTranslations['skipForNow']!);
    expect(find.text(mlTranslations['basicProfile']!), findsOneWidget);

    await _tapLabel(tester, mlTranslations['skipForNow']!);
    expect(find.text(mlTranslations['domainTitle']!), findsOneWidget);

    await tester.enterText(find.byType(TextField).hitTestable(), 'Arjun Verma');
    await tester.pump();
    expect(find.text('arjunverma.com'), findsOneWidget);

    await _tapLabel(tester, mlTranslations['skipForNow']!);
    expect(find.text(mlTranslations['dashboard']!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _chooseLanguage(WidgetTester tester, String nativeName) async {
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();
  final item = find.textContaining(nativeName);
  await tester.scrollUntilVisible(
    item,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(item.last);
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  var finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    finder = find.text(text);
  }
  final target = finder.last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
