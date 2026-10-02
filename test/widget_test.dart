import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
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

  testWidgets('english is the default and every language updates the login screen', (
    tester,
  ) async {
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

    expect(find.text('मूल प्रोफ़ाइल'), findsOneWidget);
    final profileContext = tester.element(find.text('मूल प्रोफ़ाइल'));
    expect(OnboardingScope.of(profileContext).draft.fullName, 'Arjun Verma');
    expect(find.text('VOTE BANKER में आपका स्वागत है'), findsNothing);
  });

  testWidgets('login continues to profile and shows a temporary message', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with WhatsApp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(enTranslations['authLater']!), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Basic Profile'), findsOneWidget);
  });

  testWidgets('profile, domain selection, and back keep temporary state', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(const VoteBankerApp());
    await tester.pumpAndSettle();

    await _tapLabel(tester, 'Skip for now');
    expect(find.text('Basic Profile'), findsOneWidget);

    await tester.enterText(find.byType(TextField).hitTestable().first, 'Arjun Verma');
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
    expect(find.descendant(of: card, matching: find.text('Selected')), findsOneWidget);

    await _tapLabel(tester, 'Back');
    expect(find.text('Basic Profile'), findsOneWidget);
    final profileContext = tester.element(find.text('Basic Profile'));
    expect(OnboardingScope.of(profileContext).draft.fullName, 'Arjun Verma');
    expect(
      OnboardingScope.of(profileContext).draft.selectedDomain,
      'arjunverma.com',
    );

    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Selected'), findsOneWidget);

    await _tapLabel(tester, 'Next');
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Your VOTE BANKER workspace starts here.'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
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
  await tester.tap(find.text(nativeName).last);
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
