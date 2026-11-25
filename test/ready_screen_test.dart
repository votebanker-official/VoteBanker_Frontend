import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/screens/ready_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ready back arrow is visible and returns to the previous step', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final themeController = ThemeController();
    final onboardingController = OnboardingController();
    addTearDown(themeController.dispose);
    addTearDown(onboardingController.dispose);

    for (final size in const [
      Size(390, 844),
      Size(820, 1180),
      Size(1440, 1000),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(themeController, onboardingController));
      await tester.tap(find.byKey(const Key('open-ready')));
      await tester.pumpAndSettle();

      final back = find.byKey(const Key('ready-back'));
      expect(back, findsOneWidget);
      expect(
        tester.getRect(back).overlaps(tester.getRect(find.text('VOTE BANKER'))),
        isFalse,
      );

      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('Previous setup'), findsOneWidget);
    }
  });
}

Widget _app(
  ThemeController themeController,
  OnboardingController onboardingController,
) {
  return ThemeScope(
    controller: themeController,
    child: OnboardingScope(
      controller: onboardingController,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('open-ready'),
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReadyScreen(),
                        ),
                      );
                    },
                    child: const Text('Previous setup'),
                  ),
                ),
              ),
        ),
      ),
    ),
  );
}
