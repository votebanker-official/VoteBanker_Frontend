import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/website/screens/website_questions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('media step asks for more photos and a logo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(),
        child: OnboardingScope(
        controller: OnboardingController(),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WebsiteQuestionsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var step = 0; step < 4; step++) {
      final fields = find.byType(TextField);
      final count = fields.evaluate().length;
      for (var i = 0; i < count; i++) {
        await tester.enterText(fields.at(i), 'Answer $step $i');
      }
      await tester.pump();
      final next = find.text('Next');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    expect(find.text('More photos and logo'), findsOneWidget);
    expect(find.text('Photos and logo'), findsNothing);
    expect(find.text('More photos (Optional)'), findsOneWidget);
    expect(find.text('Logo (Optional)'), findsOneWidget);
    expect(find.text('Add photo'), findsNWidgets(2));
  });
}
