import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/website/screens/website_questions_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('website questions require every answer', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final onboarding = OnboardingController();
    addTearDown(onboarding.dispose);
    final theme = ThemeController();
    addTearDown(theme.dispose);

    await tester.pumpWidget(
      ThemeScope(
        controller: theme,
        child: OnboardingScope(
          controller: onboarding,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WebsiteQuestionsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every answer is required.'), findsOneWidget);
    expect(find.text('Full name *'), findsOneWidget);
    expect(find.text('Professional / public title *'), findsOneWidget);
    expect(find.text('Organization / party / office *'), findsOneWidget);
    expect(find.textContaining('Optional'), findsNothing);
    expect(find.text('Skip this field'), findsNothing);
    expect(find.text('1 / 5'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Fill this field first'), findsNWidgets(3));
    expect(find.text('1 / 5'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Asha Patel');
    await tester.enterText(fields.at(1), 'MLA');
    await tester.enterText(fields.at(2), 'Vote Banker');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('Short introduction *'), findsOneWidget);
    expect(onboarding.website.fullName, 'Asha Patel');
  });
}
