import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/routing/app_routes.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/core/widgets/global_footer.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final size in const [Size(1280, 900), Size(390, 844)]) {
    testWidgets('about page lays out at ${size.width.toInt()}px', (
      tester,
    ) async {
      await _setSurface(tester, size);
      await tester.pumpWidget(_app(AppRoutes.about));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('About VoteBanker'), findsOneWidget);
      expect(
        find.text('Empowering Modern Political Campaigns & Voter Outreach.'),
        findsWidgets,
      );
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Our Vision'), findsOneWidget);
      expect(find.text('Voter Relationship Management (VRM)'), findsOneWidget);
      expect(find.text('Website Builder'), findsWidgets);
      expect(find.text('Team & Volunteer Coordination'), findsOneWidget);
      expect(find.text('Merchandise'), findsWidgets);
      if (size.width >= 1000) {
        final opens = find.widgetWithText(TextButton, 'Open');
        expect(opens, findsNWidgets(4));
        final tops = tester.widgetList(opens).map((widget) {
          return tester.getTopLeft(find.byWidget(widget)).dy;
        }).toList();
        for (final top in tops.skip(1)) {
          expect(top, closeTo(tops.first, 0.5));
        }
      }
      expect(find.text('Coming Soon'), findsNothing);
      expect(find.text('Clarity'), findsOneWidget);
      expect(find.text('Security & Privacy'), findsOneWidget);
      expect(find.text('Ready to Organize Your Campaign?'), findsOneWidget);
      expect(
        find.textContaining('not affiliated with, endorsed by'),
        findsOneWidget,
      );

      final footer = find.byKey(const Key('global-footer'));
      await tester.ensureVisible(footer);
      await tester.pump();
      expect(footer.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('about actions and footer link reach live routes', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(AppRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('footer-link-about')));
    await tester.tap(find.byKey(const Key('footer-link-about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('About VoteBanker'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('about-explore')));
    await tester.tap(find.byKey(const Key('about-explore')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Campaign Overview'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('footer-link-about')));
    await tester.tap(find.byKey(const Key('footer-link-about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.byKey(const Key('about-start')));
    await tester.tap(find.byKey(const Key('about-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Welcome to Vote Banker!'), findsWidgets);
    expect(find.byType(GlobalFooter), findsNothing);

    await tester.pumpWidget(_app(AppRoutes.about));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('about-contact')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Contact Support'), findsWidgets);
    expect(find.textContaining('support@votebanker.in'), findsWidgets);
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
