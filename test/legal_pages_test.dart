import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/core/widgets/global_footer.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('footer drops pricing and opens every support and legal page', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(AppRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pricing / Plans'), findsNothing);
    expect(find.text('Help Center / FAQs'), findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);

    final destinations = {
      'footer-link-help': 'Who can open an account?',
      'footer-link-contact': 'Prepare support request',
      'footer-link-terms': 'Who may use VoteBanker',
      'footer-link-deletion': 'Prepare deletion request',
      'footer-link-disclaimer': 'not affiliated with, endorsed by',
      'footer-link-refund': 'does not publish a pricing or plans page',
    };

    for (final entry in destinations.entries) {
      await tester.pumpWidget(_app(AppRoutes.dashboard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byKey(Key(entry.key)));
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining(entry.value), findsWidgets, reason: entry.key);
      expect(find.byKey(const Key('public-back')), findsOneWidget, reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  for (final size in const [Size(1280, 900), Size(390, 844)]) {
    testWidgets('legal pages lay out at ${size.width.toInt()}px', (tester) async {
      await _setSurface(tester, size);
      for (final route in [
        AppRoutes.helpCenter,
        AppRoutes.faqs,
        AppRoutes.terms,
        AppRoutes.dataDeletion,
        AppRoutes.electionDisclaimer,
        AppRoutes.refundPolicy,
        AppRoutes.contactSupport,
      ]) {
        await tester.pumpWidget(_app(route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: route);
        final footer = find.byKey(const Key('global-footer'));
        if (size.width >= GlobalFooter.mobileBreakpoint) {
          await tester.ensureVisible(footer);
          await tester.pump();
          expect(footer.hitTestable(), findsOneWidget, reason: route);
        } else {
          expect(footer, findsNothing, reason: route);
        }
      }
    });
  }

  testWidgets('help search filters topics and forms validate', (tester) async {
    await _setSurface(tester, const Size(1100, 900));
    await tester.pumpWidget(_app(AppRoutes.helpCenter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Who can open an account?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('help-search')), 'silence period');
    await tester.pump();
    expect(find.textContaining('Who can open an account?'), findsNothing);
    expect(find.textContaining('silence period'), findsWidgets);
    expect(find.text('Pricing / Plans'), findsNothing);

    await tester.pumpWidget(_app(AppRoutes.dataDeletion));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('deletion-submit')));
    await tester.tap(find.byKey(const Key('deletion-submit')));
    await tester.pump();
    expect(find.textContaining('fill in every field'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('deletion-name')), 'Asha Rao');
    await tester.enterText(find.byKey(const Key('deletion-contact')), 'asha@example.com');
    await tester.enterText(find.byKey(const Key('deletion-workspace')), 'Ward 12');
    await tester.enterText(find.byKey(const Key('deletion-details')), 'Delete the workspace.');
    await _reveal(tester, find.byKey(const Key('deletion-confirm')));
    await tester.tap(find.byKey(const Key('deletion-confirm')));
    await tester.pump();
    await _reveal(tester, find.byKey(const Key('deletion-submit')));
    await tester.tap(find.byKey(const Key('deletion-submit')));
    await tester.pump();
    expect(find.textContaining('fill in every field'), findsOneWidget);

    await _reveal(tester, find.text('Delete my account'));
    await tester.tap(find.text('Delete my account'));
    await tester.pump();
    await _reveal(tester, find.byKey(const Key('deletion-submit')));
    await tester.tap(find.byKey(const Key('deletion-submit')));
    await tester.pump();
    expect(find.byKey(const Key('deletion-ready')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollables = find.byType(Scrollable);
  for (final element in scrollables.evaluate()) {
    final state = tester.state<ScrollableState>(find.byWidget(element.widget));
    if (!state.position.hasContentDimensions) continue;
    if (state.position.maxScrollExtent <= 2) continue;
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byWidget(element.widget),
    );
    await tester.pump();
    final top = tester.getTopLeft(target).dy;
    if (top >= 0 && top < 700) return;
  }
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
        theme: AppTheme.light().copyWith(platform: TargetPlatform.windows),
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
