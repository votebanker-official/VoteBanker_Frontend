import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/dashboard/screens/administrations_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('speech and letter open, coming later stays on the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Administrations'), findsWidgets);
    expect(find.text('Speech Generator'), findsOneWidget);
    expect(tester.getTopRight(find.text('English')).dx, greaterThan(1000));
    expect(find.text('Letter Generator'), findsOneWidget);
    expect(find.text('Coming later'), findsWidgets);
    expect(find.text('Get Support'), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(find.text('Administrations'), findsWidgets);
    expect(find.text('/speech'), findsNothing);

    await tester.tap(find.text('Speech Generator'));
    await tester.pumpAndSettle();
    expect(find.text('/speech'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Administrations'), findsWidgets);

    await tester.tap(find.text('Letter Generator'));
    await tester.pumpAndSettle();
    expect(find.text('/letter'), findsOneWidget);
  });

  testWidgets('administrations lays out on phone and desktop', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in const [Size(390, 844), Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.text('Billing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _app() {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const AdministrationsScreen(),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder:
                (_) => Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Text(settings.name ?? '')),
                ),
          );
        },
      ),
    ),
  );
}
