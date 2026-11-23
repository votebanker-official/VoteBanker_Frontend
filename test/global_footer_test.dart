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

  testWidgets('footer is on the listed app pages and not on auth pages', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));

    for (final route in AppRoutes.globalFooterRoutes) {
      await tester.pumpWidget(_app(route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const Key('global-footer')).hitTestable(),
        findsOneWidget,
        reason: route,
      );
      expect(tester.takeException(), isNull, reason: route);
    }

    for (final route in const [
      AppRoutes.login,
      AppRoutes.otp,
      AppRoutes.authCallback,
      AppRoutes.profile,
      AppRoutes.social,
    ]) {
      await tester.pumpWidget(_app(route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GlobalFooter), findsNothing, reason: route);
      expect(tester.takeException(), isNull, reason: route);
    }
  });

  testWidgets('footer links open existing routes and skip the current one', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(AppRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(
      find.byKey(const Key('footer-link-website-builder')),
    );
    await tester.tap(find.byKey(const Key('footer-link-website-builder')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Portfolio Template'), findsOneWidget);
    expect(
      find.byKey(const Key('global-footer')).hitTestable(),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('footer-link-features')));
    await tester.tap(find.byKey(const Key('footer-link-features')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Portfolio Template'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('footer-link-website-builder')),
    );
    await tester.tap(find.byKey(const Key('footer-link-website-builder')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GlobalFooter).hitTestable(), findsOneWidget);
  });

  testWidgets('desktop columns stay in order and mobile stacks', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 420));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: GlobalFooter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final brand = tester.getTopLeft(find.text('VoteBanker'));
    final quick = tester.getTopLeft(find.text('Quick Links'));
    final support = tester.getTopLeft(find.text('Support'));
    final company = tester.getTopLeft(find.text('Company'));
    final follow = tester.getTopLeft(find.text('Follow Us'));
    expect(brand.dx, lessThan(quick.dx));
    expect(quick.dx, lessThan(support.dx));
    expect(support.dx, lessThan(company.dx));
    expect(company.dx, lessThan(follow.dx));
    expect((brand.dy - quick.dy).abs(), lessThan(8));

    expect(
      tester
          .getTopLeft(find.text('© 2026 VoteBanker. All rights reserved.'))
          .dx,
      lessThan(tester.getTopLeft(find.text('Privacy Policy')).dx),
    );
    expect(tester.getSize(find.byKey(const Key('global-footer'))).width, 1280);

    await _setSurface(tester, const Size(390, 1400));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GlobalFooter())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Quick Links')).dy,
      greaterThan(tester.getTopLeft(find.text('VoteBanker')).dy + 20),
    );
    expect(
      tester.getTopLeft(find.text('Follow Us')).dy,
      greaterThan(tester.getTopLeft(find.text('Company')).dy),
    );
    final footerSize = tester.getSize(find.byKey(const Key('global-footer')));
    expect(footerSize.width, lessThanOrEqualTo(390));

    await _setSurface(tester, const Size(820, 1400));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GlobalFooter())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Support')).dy,
      greaterThan(tester.getTopLeft(find.text('VoteBanker')).dy),
    );
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
