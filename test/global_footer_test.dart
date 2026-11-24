import 'package:flutter/gestures.dart';
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
      final footer = find.byKey(const Key('global-footer'));
      await tester.ensureVisible(footer);
      await tester.pump();
      expect(footer.hitTestable(), findsOneWidget, reason: route);
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

  testWidgets('footer link hover has no fill and turns the words teal', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 500));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: GlobalFooter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('footer-link-website-builder'));
    await tester.ensureVisible(link);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(link));
    await tester.pump(const Duration(milliseconds: 250));

    final box = tester.widget<AnimatedContainer>(
      find.ancestor(of: link, matching: find.byType(AnimatedContainer)).first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);

    final words = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Website Builder'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(words.style.color, GlobalFooter.teal);

    final pill = find.byKey(const Key('footer-link-privacy'));
    await gesture.moveTo(tester.getCenter(pill));
    await tester.pump(const Duration(milliseconds: 250));
    final pillBox = tester.widget<AnimatedContainer>(
      find.ancestor(of: pill, matching: find.byType(AnimatedContainer)).first,
    );
    expect(
      (pillBox.decoration! as BoxDecoration).color,
      GlobalFooter.pill,
    );
    await gesture.removePointer();
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

    expect(find.text('My Website'), findsWidgets);
    expect(find.byType(GlobalFooter), findsNothing);

    await tester.pumpWidget(_app(AppRoutes.about));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('footer-link-features')));
    await tester.tap(find.byKey(const Key('footer-link-features')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('About VoteBanker'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('footer-link-about')));
    await tester.tap(find.byKey(const Key('footer-link-about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('global-footer')));
    await tester.pump();
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

    final brand = tester.getTopLeft(find.text('Voter Relationship Management Private Limited'));
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
          .getTopLeft(find.text('© 2026 Voter Relationship Management Private Limited. All rights reserved.'))
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
      greaterThan(
        tester.getTopLeft(find.text('Voter Relationship Management Private Limited')).dy + 20,
      ),
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
      greaterThan(
        tester.getTopLeft(find.text('Voter Relationship Management Private Limited')).dy,
      ),
    );
  });

  testWidgets('footer stays below the page and spans the parent width', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(
      const MaterialApp(
        home: AppFooterShell(
          child: ColoredBox(key: Key('page-body'), color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final page = tester.getRect(find.byKey(const Key('page-body')));
    final footer = tester.getRect(find.byKey(const Key('global-footer')));
    expect(page.width, 1280);
    expect(footer.left, 0);
    expect(footer.width, 1280);
    expect(footer.top, greaterThanOrEqualTo(page.bottom - 1));
    expect(find.byType(VerticalDivider), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Voter Relationship Management Private Limited'), findsWidgets);
    expect(find.text('Quick Links'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Refund & Shipping Policy'), findsOneWidget);

    await _setSurface(tester, const Size(390, 900));
    await tester.pumpWidget(
      const MaterialApp(
        home: AppFooterShell(
          child: ColoredBox(key: Key('page-body'), color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final narrowPage = tester.getRect(find.byKey(const Key('page-body')));
    final narrowFooter = tester.getRect(find.byKey(const Key('global-footer')));
    expect(narrowFooter.left, 0);
    expect(narrowFooter.width, 390);
    expect(narrowFooter.top, greaterThanOrEqualTo(narrowPage.bottom - 1));
    expect(
      tester.getTopLeft(find.text('Quick Links')).dy,
      greaterThan(
        tester.getTopLeft(find.text('Voter Relationship Management Private Limited')).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Follow Us')).dy,
      greaterThan(tester.getTopLeft(find.text('Company')).dy),
    );
  });

  testWidgets('long pages scroll to the full footer below the content', (
    tester,
  ) async {
    await _setSurface(tester, const Size(800, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: AppFooterShell(
          child: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 80, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final footer = find.byKey(const Key('global-footer'));
    final before = tester.getRect(footer);
    expect(before.width, 800);
    expect(before.top, greaterThan(1500));
    expect(before.height, greaterThan(120));

    await tester.ensureVisible(footer);
    await tester.pumpAndSettle();
    final after = tester.getRect(footer);
    expect(after.top, lessThan(before.top));
    expect(after.height, before.height);
    expect(after.width, 800);
    expect(find.text('Voter Relationship Management Private Limited'), findsWidgets);
    expect(find.text('Quick Links'), findsOneWidget);
    expect(find.text('Follow Us'), findsOneWidget);
    expect(find.text('© 2026 Voter Relationship Management Private Limited. All rights reserved.'), findsOneWidget);
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
