import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final size in const [Size(1280, 900), Size(390, 844)]) {
    testWidgets('privacy policy lays out at ${size.width.toInt()}px', (
      tester,
    ) async {
      await _setSurface(tester, size);
      await tester.pumpWidget(_app(AppRoutes.privacyPolicy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.textContaining('Election Commission of India'), findsOneWidget);
      expect(find.textContaining('Data Processor'), findsOneWidget);
      expect(find.textContaining('Data Fiduciary'), findsWidgets);
      expect(find.textContaining('[Grievance Officer Name]'), findsOneWidget);
      expect(find.textContaining('[grievance@votebanker.in]'), findsOneWidget);
      expect(
        find.textContaining('[Company Legal Name & Address]'),
        findsOneWidget,
      );
      expect(find.textContaining('18 years'), findsOneWidget);
      expect(find.byKey(const Key('privacy-back')), findsOneWidget);
      expect(find.byKey(const Key('privacy-toc-toggle')), findsOneWidget);

      final footer = find.byKey(const Key('global-footer'));
      await tester.ensureVisible(footer);
      await tester.pump();
      expect(footer.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('footer and settings open privacy, deletion scrolls the section', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(AppRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('footer-link-privacy')));
    await tester.tap(find.byKey(const Key('footer-link-privacy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Election Commission of India'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('privacy-back')));
    await tester.tap(find.byKey(const Key('privacy-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(_app(AppRoutes.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Account & data deletion'), findsOneWidget);
    await tester.tap(find.text('Account & data deletion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Data Deletion'), findsWidgets);
    expect(find.text('Prepare deletion request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in screens show the consent line', (tester) async {
    await _setSurface(tester, const Size(800, 1100));
    await tester.pumpWidget(_app(AppRoutes.login));
    await tester.pump();
    expect(
      find.textContaining('By continuing, you agree to our Terms'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_app(AppRoutes.otp));
    await tester.pump();
    expect(
      find.textContaining('By continuing, you agree to our Terms'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(String route) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        key: ValueKey(route),
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: route,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (initialRoute) {
          return [AppRouter.onGenerateRoute(RouteSettings(name: initialRoute))];
        },
      ),
    ),
  );
}
